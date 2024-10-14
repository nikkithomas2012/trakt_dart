part of trakt_dart;

/// The API uses OAuth2. If you know what's up with OAuth2, grab your library and starting rolling.
/// If you have access to a web browser (mobile app, desktop app, website), use standard OAuth.
/// If you don't have web browser access (media center plugins, smart watches, smart TVs, command line scripts, system services),
/// use Device authentication.To obtain a client_id and client_secret, create an application on the Trakt website.
///
/// Here are some helpful links to get your started:
/// Create a new API app: https://trakt.tv/oauth/applications/new
/// View your API apps: https://trakt.tv/oauth/applications
class Authentication extends Category {
  Authentication(TraktManager manager) : super(manager);

  /// Construct then redirect to this URL.
  ///
  /// The Trakt website will request permissions for your app, which the user needs to approve.
  /// If the user isn't signed into Trakt, it will ask them to do so.
  /// Send signup=true if you prefer the account sign up page to be the default.
  Future<void> authorizeApplication({bool? signup}) async {
    final url = Uri.parse(_manager._oauthURL);
    await ChromeSafariBrowser().open(url: url);
  }

  void authorizeApplicationWithTokens({required String accessToken, required String refreshToken}) {
    _manager._accessToken = accessToken;
    _manager._refreshToken = refreshToken;
  }

  /// Use the authorization code GET parameter sent back to your redirect_uri to get an access_token.
  ///
  /// Save the access_token so your app can authenticate the user by sending the Authorization header.
  ///
  /// The access_token is valid for 3 months.
  /// Save and use the refresh_token to get a new access_token without asking the user to re-authenticate.
  Future<AccessTokenResponse> getAccessToken(String code) async {
    return _oauthToken({"code": code});
  }

  /// Use the refresh_token to get a new access_token without asking the user to re-authenticate.
  ///
  /// The access_token is valid for 3 months before it needs to be refreshed again.
  Future<AccessTokenResponse> refreshAccessToken({String? refreshToken}) async {
    if (refreshToken != null) {
      _manager._refreshToken = refreshToken;
    }

    if (_manager._refreshToken == null) {
      throw Exception("Refresh token is null");
    }

    return _oauthToken({"refresh_token": _manager._refreshToken!});
  }

  /// An access_token can be revoked when a user signs out of their Trakt account in your app.
  ///
  /// This is not required, but might improve the user experience so the user doesn't have an unused app connection hanging around.
  Future<void> revokeAccessToken() async {
    final url = Uri.https(_manager._baseURL, "oauth/token");
    final body = {
      "token": _manager._accessToken,
      "client_id": _manager._clientId!,
      "client_secret": _manager._clientSecret!,
    };
    final response = await _manager.client.post(url, headers: {"Content-Type": "application/json"}, body: body);

    if (![200, 201, 204].contains(response.statusCode)) {
      throw TraktManagerAPIError(response.statusCode, response.reasonPhrase, response);
    }

    _manager._accessToken = null;
    _manager._refreshToken = null;

    return;
  }

  Future<AccessTokenResponse> _oauthToken(Map<String, String> body) async {
    final url = Uri.https(_manager._baseURL, "oauth/token");
    body.addAll({
      "client_id": _manager._clientId!,
      "client_secret": _manager._clientSecret!,
      "redirect_uri": _manager._redirectURI!,
      "grant_type": "authorization_code"
    });
    final response = await _manager.client.post(url, headers: {"Content-Type": "application/json"}, body: body);

    if (![200, 201, 204].contains(response.statusCode)) {
      throw TraktManagerAPIError(response.statusCode, response.reasonPhrase, response);
    }

    final jsonResult = jsonDecode(response.body);
    final accessTokenResponse = AccessTokenResponse.fromJsonModel(jsonResult);

    _manager._accessToken = accessTokenResponse.accessToken;
    _manager._refreshToken = accessTokenResponse.refreshToken;

    return accessTokenResponse;
  }

  /// Generate new codes to start the device authentication process.
  ///
  /// The device_code and interval will be used later to poll for the access_token.
  /// The user_code and verification_url should be presented to the user as mentioned in the flow steps above.
  Future<DeviceCodeResponse> generateDeviceCodes({bool? signup}) async {
    final url = Uri.https(_manager._baseURL, "oauth/device/code");
    final response = await _manager.client
        .post(url, headers: {"Content-Type": "application/json"}, body: jsonEncode({"client_id": _manager._clientId}));

    if (![200, 201, 204].contains(response.statusCode)) {
      throw TraktManagerAPIError(response.statusCode, response.reasonPhrase, response);
    }

    final jsonResult = jsonDecode(response.body);
    return DeviceCodeResponse.fromJsonModel(jsonResult);
  }

  /// Use the authorization code GET parameter sent back to your redirect_uri to get an access_token.
  ///
  /// Save the access_token so your app can authenticate the user by sending the Authorization header.
  ///
  /// The access_token is valid for 3 months.
  /// Save and use the refresh_token to get a new access_token without asking the user to re-authenticate.
  Future<AccessTokenResponse> getDeviceAccessToken(String code) async {
    final url = Uri.https(_manager._baseURL, "oauth/device/token");
    Map<String, String> body = {
      "code": code,
      "client_id": _manager._clientId!,
      "client_secret": _manager._clientSecret!,
    };
    final response = await _manager.client.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (![200, 201, 204].contains(response.statusCode)) {
      throw TraktManagerAPIError(response.statusCode, response.reasonPhrase, response);
    }

    final jsonResult = jsonDecode(response.body);
    final accessTokenResponse = AccessTokenResponse.fromJsonModel(jsonResult);

    _manager._accessToken = accessTokenResponse.accessToken;
    _manager._refreshToken = accessTokenResponse.refreshToken;

    return accessTokenResponse;
  }
}
