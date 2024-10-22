library trakt_dart;

import 'dart:convert';

import 'package:http/http.dart' show Client, Response;
import 'package:json_annotation/json_annotation.dart';
import 'package:tuple/tuple.dart';

part 'category/category.dart';
part 'models/authentication_models.dart';
part 'models/calendar_models.dart';
part 'models/certification_models.dart';
part 'models/check_in_models.dart';
part 'models/comment_models.dart';
part 'models/common_models.dart';
part 'models/countries_models.dart';
part 'models/episode_models.dart';
part 'models/extensions.dart';
part 'models/genre_models.dart';
part 'models/language_models.dart';
part 'models/list_models.dart';
part 'models/movie_models.dart';
part 'models/network_models.dart';
part 'models/people_models.dart';
part 'models/scrobble_models.dart';
part 'models/search_models.dart';
part 'models/season_models.dart';
part 'models/show_models.dart';
part 'models/sync_models.dart';
part 'models/users_models.dart';
part 'models/request_models.dart';
part 'trakt_manager_requests/authentication_requests.dart';
part 'trakt_manager_requests/calendar_requests.dart';
part 'trakt_manager_requests/certification_requests.dart';
part 'trakt_manager_requests/check_in_requests.dart';
part 'trakt_manager_requests/comment_requests.dart';
part 'trakt_manager_requests/countries_requests.dart';
part 'trakt_manager_requests/episode_requests.dart';
part 'trakt_manager_requests/genre_requests.dart';
part 'trakt_manager_requests/language_requests.dart';
part 'trakt_manager_requests/list_requests.dart';
part 'trakt_manager_requests/movie_requests.dart';
part 'trakt_manager_requests/network_requests.dart';
part 'trakt_manager_requests/people_requests.dart';
part 'trakt_manager_requests/recommendation_requests.dart';
part 'trakt_manager_requests/scrobble_requests.dart';
part 'trakt_manager_requests/search_requests.dart';
part 'trakt_manager_requests/season_requests.dart';
part 'trakt_manager_requests/show_requests.dart';
part 'trakt_manager_requests/sync_requests.dart';
part 'trakt_manager_requests/user_requests.dart';

part 'trakt_dart.g.dart';

class TraktManager {
  String? _clientId;
  String? _clientSecret;
  String? _redirectURI;
  String _baseURL = "api.trakt.tv";
  String? _accessToken;
  String? _refreshToken;
  Map<String, String> _headers = {};

  Client client;

  Authentication? _authentication;
  Calendar? _calendar;
  Certifications? _certifications;
  CheckIn? _checkIn;
  Comments? _comments;
  Countries? _countries;
  Episodes? _episodes;
  Genres? _genres;
  Languages? _languages;
  Lists? _lists;
  Movies? _movies;
  Networks? _networks;
  People? _people;
  Recommendations? _recommendations;
  Scrobble? _scrobble;
  Search? _search;
  Seasons? _seasons;
  Shows? _shows;
  Users? _users;
  Sync? _sync;

  Authentication get authentication => _authentication!;
  Calendar get calendar => _calendar!;
  Certifications get certifications => _certifications!;
  CheckIn get checkIn => _checkIn!;
  Comments get comments => _comments!;
  Countries get countries => _countries!;
  Episodes get episodes => _episodes!;
  Genres get genres => _genres!;
  Languages get languages => _languages!;
  Lists get lists => _lists!;
  Movies get movies => _movies!;
  Networks get networks => _networks!;
  People get people => _people!;
  Recommendations get recommendations => _recommendations!;
  Scrobble get scrobble => _scrobble!;
  Search get search => _search!;
  Seasons get seasons => _seasons!;
  Shows get shows => _shows!;
  Users get users => _users!;
  Sync get sync => _sync!;

  /// Initializes the TraktManager for making API calls. This must be called before making any API calls!
  ///
  /// [clientId] - The ClientId listed under your Trakt applications
  /// [clientSecret] - The Client secret listed under your Trakt applications
  /// [redirectURI] - the redirect uri set under your Trakt applications for OAuth.
  /// [useStaging] - whether to use the Trakt Staging environment. Default to false.
  TraktManager({required String clientId, required String clientSecret, required String redirectURI, bool useStaging = false}) : client = Client() {
    _clientId = clientId;
    _clientSecret = clientSecret;
    _redirectURI = redirectURI;

    _headers = {"trakt-api-version": "2", "trakt-api-key": clientId, "Content-type": "application/json"};

    if (useStaging) {
      _baseURL = "api-staging.trakt.tv";
    }

    _authentication = Authentication(this);
    _calendar = Calendar(this);
    _certifications = Certifications(this);
    _checkIn = CheckIn(this);
    _comments = Comments(this);
    _countries = Countries(this);
    _episodes = Episodes(this);
    _genres = Genres(this);
    _languages = Languages(this);
    _lists = Lists(this);
    _movies = Movies(this);
    _networks = Networks(this);
    _people = People(this);
    _recommendations = Recommendations(this);
    _scrobble = Scrobble(this);
    _search = Search(this);
    _seasons = Seasons(this);
    _shows = Shows(this);
    _users = Users(this);
    _sync = Sync(this);
  }

  Future<T> _get<T>(String request, {bool extendedFull = false, bool includeGuestStars = false, RequestPagination? pagination, Map<String, dynamic>? queryParamameters}) async {
    final queryParams = queryParamameters ?? {};
    queryParams.addAll(pagination?.toMap() ?? {});

    List<String> extendedParams = [];
    if (extendedFull) {
      extendedParams.add("full");
    }
    if (includeGuestStars) {
      extendedParams.add("guest_stars");
    }
    if (extendedParams.isNotEmpty) {
      queryParams["extended"] = extendedParams.join(",");
    }

    final url = Uri.https(_baseURL, request, queryParams);
    final response = await client.get(url, headers: _headers);

    if (![200, 201, 204].contains(response.statusCode)) {
      throw TraktManagerAPIError(response.statusCode, response.reasonPhrase, response);
    }

    final jsonResult = jsonDecode(response.body);
    return (T).jsonDecoder(jsonResult);
  }

  Future<T> _authenticatedGet<T>(String request, {bool extendedFull = false, Map<String, dynamic>? queryParamameters}) async {
    assert(_accessToken != null, "Autheticate app and get access token before making authenticated request.");

    final queryParams = queryParamameters ?? {};
    if (extendedFull) {
      queryParams["extended"] = "full";
    }
    final headers = _headers;
    headers["Authorization"] = "Bearer ${_accessToken!}";

    final url = Uri.https(_baseURL, request, queryParams);
    final response = await client.get(url, headers: _headers);

    if (![200, 201, 204].contains(response.statusCode)) {
      throw TraktManagerAPIError(response.statusCode, response.reasonPhrase, response);
    }

    final jsonResult = jsonDecode(response.body);
    return (T).jsonDecoder(jsonResult);
  }

  Future<List<T>> _getList<T>(String request, {bool extendedFull = false, RequestPagination? pagination, Filters? filters, Map<String, dynamic>? queryParamameters}) async {
    final queryParams = queryParamameters ?? {};

    queryParams.addAll(pagination?.toMap() ?? {});
    queryParams.addAll(filters?.toMap() ?? {});

    if (extendedFull) {
      queryParams["extended"] = "full";
    }

    final url = Uri.https(_baseURL, request, queryParams);
    final response = await client.get(url, headers: _headers);

    if (![200, 201, 204].contains(response.statusCode)) {
      throw TraktManagerAPIError(response.statusCode, response.reasonPhrase, response);
    }

    final jsonResult = jsonDecode(response.body);

    if (jsonResult is Iterable) {
      return jsonResult.map((json) => (T).jsonDecoder(json) as T).toList();
    }
    return [];
  }

  Future<List<T>> _authenticatedGetList<T>(String request, {bool extendedFull = false, RequestPagination? pagination, Filters? filters, Map<String, dynamic>? queryParamameters}) async {
    final queryParams = queryParamameters ?? {};

    queryParams.addAll(pagination?.toMap() ?? {});
    queryParams.addAll(filters?.toMap() ?? {});

    if (extendedFull) {
      queryParams["extended"] = "full";
    }

    final headers = _headers;
    headers["Authorization"] = "Bearer ${_accessToken!}";

    final url = Uri.https(_baseURL, request, queryParams);
    final response = await client.get(url, headers: _headers);

    if (![200, 201, 204].contains(response.statusCode)) {
      throw TraktManagerAPIError(response.statusCode, response.reasonPhrase, response);
    }

    final jsonResult = jsonDecode(response.body);

    if (jsonResult is Iterable) {
      return jsonResult.map((json) => (T).jsonDecoder(json) as T).toList();
    }
    return [];
  }

  Future<List<int>> _getIds<T>(String request, {RequestPagination? pagination}) async {
    final queryParams = <String, dynamic>{};

    queryParams.addAll(pagination?.toMap() ?? {});

    final url = Uri.https(_baseURL, request, queryParams);
    final response = await client.get(url, headers: _headers);

    if (![200, 201, 204].contains(response.statusCode)) {
      throw TraktManagerAPIError(response.statusCode, response.reasonPhrase, response);
    }

    final jsonResult = jsonDecode(response.body);
    if (jsonResult is Iterable) {
      return jsonResult.toList().cast<int>();
    }
    return [];
  }

  Future<T> _authenticatedPost<T>(String request, {String? body}) async {
    assert(_accessToken != null, "Autheticate app and get access token before making authenticated request.");

    final headers = _headers;
    headers["Authorization"] = "Bearer ${_accessToken!}";

    final url = Uri.https(_baseURL, request);
    final response = await client.post(url, headers: _headers, body: body);

    if (![200, 201, 204].contains(response.statusCode)) {
      throw TraktManagerAPIError(response.statusCode, response.reasonPhrase, response);
    }

    final jsonResult = jsonDecode(response.body);
    return (T).jsonDecoder(jsonResult);
  }

  Future<T> _authenticatedPut<T>(String request, {String? body}) async {
    assert(_accessToken != null, "Autheticate app and get access token before making authenticated request.");

    final headers = _headers;
    headers["Authorization"] = "Bearer ${_accessToken!}";

    final url = Uri.https(_baseURL, request);
    final response = await client.put(url, headers: _headers, body: body);

    if (![200, 201, 204].contains(response.statusCode)) {
      throw TraktManagerAPIError(response.statusCode, response.reasonPhrase, response);
    }

    final jsonResult = jsonDecode(response.body);
    return (T).jsonDecoder(jsonResult);
  }

  Future<void> _authenticatedDelete(String request) async {
    assert(_accessToken != null, "Autheticate app and get access token before making authenticated request.");

    final headers = _headers;
    headers["Authorization"] = "Bearer ${_accessToken!}";

    final url = Uri.https(_baseURL, request);
    final response = await client.delete(url, headers: _headers);

    if (![200, 201, 204].contains(response.statusCode)) {
      throw TraktManagerAPIError(response.statusCode, response.reasonPhrase, response);
    }
    return;
  }
}

class TraktManagerAPIError {
  final int statusCode;
  final String? reasonPhrase;
  final Response response;

  TraktManagerAPIError(this.statusCode, this.reasonPhrase, this.response);
}
