part of trakt_dart;

/// User's with public data will return info with all GET methods.
/// Private user's (including yourself) require valid OAuth and a friend relationship to return data.
///
/// Username vs. slug
///
/// All users methods should use the slug to identify the user. The slug is a URL safe and globally unique version of the username.
///
/// Special id for the OAuth user
///
/// If you send valid OAuth, you can use me to identify the OAuth user instead of needing their actual slug.
/// You can of course still use their actual slug, it's up to you.
///
/// Extra headers
///
/// If valid OAuth is sent, additional headers will be sent to better determine it is a
/// data permissions issue (they aren't friends) and not bad OAuth.
/// For example, you might try and access a private user's list you aren't friends with.
/// This will return a 401 HTTP status code and the additional headers.
/// This means the OAuth is valid, but authorization ultimately failed because there is no friend relationship.
class Users extends Category {
  Users(TraktManager manager) : super(manager);

  /// Get the user's settings so you can align your app's experience with what they're used to on the trakt website.
  ///
  /// A globally unique uuid is also returned, which can be used to identify the user locally in your app if needed.
  /// However, the uuid can't be used to retrieve data from the Trakt API.
  ///
  /// 🔒 OAuth Required
  Future<UserSettings> getSettings() async {
    return await _manager._authenticatedGet<UserSettings>("users/settings");
  }

  /// List a user's pending following requests that they're waiting for the other user's to approve.
  ///
  /// 🔒 OAuth Required ✨ Extended Info
  Future<List<FollowRequest>> getFollowingRequests({bool extendedFull = false}) async {
    return await _manager._authenticatedGetList<FollowRequest>("users/requests/following", extendedFull: extendedFull);
  }

  /// List a user's pending follow requests so they can either approve or deny them.
  ///
  /// 🔒 OAuth Required ✨ Extended Info
  Future<List<FollowRequest>> getFollowerRequests({bool extendedFull = false}) async {
    return await _manager._authenticatedGetList<FollowRequest>("users/requests/following", extendedFull: extendedFull);
  }

  /// Approve a follower using the id of the request.
  ///
  /// If the id is not found, was already approved, or was already denied, a 404 error will be returned.
  ///
  /// [id] - ID of the follower request.
  ///
  /// 🔒 OAuth Required
  Future<Follower> approveFollowerRequest(int id) async {
    return await _manager._authenticatedPost<Follower>("users/requests/$id");
  }

  /// Deny a follower using the id of the request.
  ///
  /// If the id is not found, was already approved, or was already denied, a 404 error will be returned.
  ///
  /// [id] - ID of the follower request.
  ///
  /// 🔒 OAuth Required
  Future<void> denyFollowerRequest(int id) async {
    return await _manager._authenticatedDelete("users/requests/$id");
  }

  /// Get hidden items for a section.
  ///
  /// This will return an array of standard media objects. You can optionally limit the type of results to return.
  ///
  /// [section] - Possible values:  calendar , progress_watched , progress_watched_reset , progress_collected , recommendations .
  /// [type] - Possible values:  movie , show , season .
  ///
  /// 🔒 OAuth Required 📄 Pagination ✨ Extended Info
  Future<List<HiddenItem>> getHiddenItems(
      {required HiddenItemSection section,
      HiddenItemType? type,
      bool extendedFull = false,
      RequestPagination? pagination}) async {
    return await _manager._authenticatedGetList<HiddenItem>("users/hidden/${section.value}",
        extendedFull: extendedFull,
        pagination: pagination,
        queryParamameters: (type != null) ? {"type": type.value} : null);
  }

  /// Hide items for a specific section. Here's what type of items can hidden for each section.
  ///
  /// [section] - Possible values:  calendar , progress_watched , progress_watched_reset , progress_collected , recommendations .
  /// [movies] - Movies to hide
  /// [shows] - Shows to hide
  /// [seasons] - Seasons to hide
  ///
  /// 🔒 OAuth Required
  Future<HiddenItem> addHiddenItems(
      {required HiddenItemSection section,
      List<Movie> movies = const [],
      List<Show> shows = const [],
      List<Season> seasons = const []}) async {
    Map<String, dynamic> body = {};
    final metaMovies = movies.map((movie) => movie.metadata).toList();
    final metaShows = shows.map((show) => show.metadata).toList();
    final metaSeasons = seasons.map((season) => season.metadata).toList();

    if (metaMovies.isNotEmpty) {
      body["movies"] = metaMovies;
    }
    if (metaShows.isNotEmpty) {
      body["shows"] = metaShows;
    }
    if (metaSeasons.isNotEmpty) {
      body["seasons"] = metaSeasons;
    }

    return await _manager._authenticatedPost<HiddenItem>("users/hidden/${section.value}", body: jsonEncode(body));
  }

  /// Unhide items for a specific section. Here's what type of items can unhidden for each section.
  ///
  /// [section] - Possible values:  calendar , progress_watched , progress_watched_reset , progress_collected , recommendations .
  /// [movies] - Movies to hide
  /// [shows] - Shows to hide
  /// [seasons] - Seasons to hide
  ///
  /// 🔒 OAuth Required
  Future<HiddenItem> removeHiddenItems(
      {required HiddenItemSection section,
      List<Movie> movies = const [],
      List<Show> shows = const [],
      List<Season> seasons = const []}) async {
    Map<String, dynamic> body = {};
    final metaMovies = movies.map((movie) => movie.metadata).toList();
    final metaShows = shows.map((show) => show.metadata).toList();
    final metaSeasons = seasons.map((season) => season.metadata).toList();

    if (metaMovies.isNotEmpty) {
      body["movies"] = metaMovies;
    }
    if (metaShows.isNotEmpty) {
      body["shows"] = metaShows;
    }
    if (metaSeasons.isNotEmpty) {
      body["seasons"] = metaSeasons;
    }

    return await _manager._authenticatedPost<HiddenItem>("users/hidden/${section.value}/remove",
        body: jsonEncode(body));
  }

  /// Get items a user likes.
  ///
  /// This will return an array of standard media objects. You can optionally limit the type of results to return.
  ///
  /// [type] - Possible values:  comments , lists .
  ///
  /// 🔒 OAuth Required 📄 Pagination
  Future<List<UserLike>> getLikes({UserLikesType? type, RequestPagination? pagination}) async {
    return await _manager._authenticatedGetList<UserLike>("users/likes/$type", pagination: pagination);
  }

  /// Get a user's profile information.
  ///
  /// If the user is private, info will only be returned if you send OAuth and are either that user or an approved follower.
  /// Adding [extendedVIP] will return some additional VIP related fields so you can display the user's Trakt VIP status and year count.
  ///
  /// [id] - User slug
  /// [useOAuth] - whether to make the request using OAuth header
  ///
  /// 🔓 OAuth Optional ✨ Extended Info
  Future<User> getProfile(String id, {bool extendedFull = false, bool? extendedVIP, bool useOAuth = false}) async {
    Map<String, dynamic>? params;
    List<String> extended = [];
    if (extendedFull) {
      extended.add("full");
    }
    if (extendedVIP ?? false) {
      extended.add("vip");
    }
    if (extended.isNotEmpty) {
      params = {};
      params["extended"] = extended.join(",");
    }
    if (useOAuth) {
      return await _manager._authenticatedGet<User>("users/$id", queryParamameters: params);
    }

    return await _manager._get<User>("users/$id", queryParamameters: params);
  }

  /// Get all collected items in a user's collection.
  ///
  /// A collected item indicates availability to watch digitally or on physical media.
  ///
  /// Each movie object contains collected_at and updated_at timestamps. Since users can set custom dates when they collected movies,
  /// it is possible for collected_at to be in the past. We also include updated_at to help sync Trakt data with your app.
  /// Cache this timestamp locally and only re-process the movie if you see a newer timestamp.
  ///
  /// Each show object contains last_collected_at and last_updated_at timestamps. Since users can set custom dates when they collected episodes,
  /// it is possible for last_collected_at to be in the past. We also include last_updated_at to help sync Trakt data with your app.
  /// Cache this timestamp locally and only re-process the show if you see a newer timestamp.
  ///
  /// If you add ?extended=metadata to the URL, it will return the additional media_type, resolution, hdr, audio, audio_channels and '3d' metadata.
  /// It will use null if the metadata isn't set for an item.
  ///
  /// [id] - User slug
  /// [type] - Possible values:  movies , shows .
  /// [useOAuth] - whether to make the request using OAuth header
  ///
  /// 🔓 OAuth Optional ✨ Extended Info
  Future<List<UserCollectionItem>> getCollection(String id, UserCollectionType type,
      {bool extendedFull = false, bool? extendedMetadata, bool useOAuth = false}) async {
    Map<String, dynamic>? params;
    List<String> extended = [];
    if (extendedFull) {
      extended.add("full");
    }
    if (extendedMetadata ?? false) {
      extended.add("metadata");
    }
    if (extended.isNotEmpty) {
      params = {};
      params["extended"] = extended.join(",");
    }

    if (useOAuth) {
      return await _manager._authenticatedGetList<UserCollectionItem>("users/$id/collection/${type.value}",
          queryParamameters: params);
    }

    return await _manager._getList<UserCollectionItem>("users/$id/collection/${type.value}", queryParamameters: params);
  }

  /// Returns the most recently written comments for the user.
  ///
  /// You can optionally filter by the comment_type and media type to limit what gets returned.
  /// By default, only top level comments are returned.
  /// Set [includeReplies]=true to return replies in addition to top level comments.
  /// Set [includeReplies]=only to return only replies and no top level comments.
  ///
  /// [id] - User slug
  /// [commentType] - Possible values:  all , reviews , shouts .
  /// [mediaType] - Possible values:  all , movies , shows , seasons , episodes , lists .
  /// [includeReplies] - include comment replies
  /// [useOAuth] - whether to make the request using OAuth header
  ///
  /// 🔓 OAuth Optional 📄 Pagination ✨ Extended Info
  Future<List<MediaComment>> getComments(String id,
      {CommentType? commentType,
      MediaType? mediaType,
      String? includeReplies,
      bool extendedFull = false,
      RequestPagination? pagination,
      bool useOAuth = false}) async {
    Map<String, dynamic>? params;
    assert(includeReplies == null || includeReplies == "true" || includeReplies == "false" || includeReplies == "only",
        "Invalid includeReplies. Valid values are \"true\", \"false\", or \"only\"");

    if (includeReplies != null) {
      params = {"includeReplies": includeReplies};
    }
    var request = "";
    if (commentType != null) {
      request = "/${commentType.value}";
    }

    if (mediaType != null) {
      request += "/${mediaType.value}";
    }

    if (useOAuth) {
      return await _manager._authenticatedGetList<MediaComment>("users/$id/comments$request",
          queryParamameters: params, pagination: pagination, extendedFull: extendedFull);
    }

    return await _manager._getList<MediaComment>("users/$id/comments$request",
        queryParamameters: params, pagination: pagination, extendedFull: extendedFull);
  }

  /// Returns all custom lists for a user.
  ///
  /// Use the /users/:id/lists/:list_id/items method to get the actual items a specific list contains.
  ///
  /// [id] - User slug
  /// [useOAuth] - whether to make the request using OAuth header
  ///
  /// 🔓 OAuth Optional ✨ Extended Info
  Future<List<TraktList>> getLists(String id, {bool useOAuth = false}) async {
    if (useOAuth) {
      return await _manager._authenticatedGetList<TraktList>("users/$id/lists");
    }

    return await _manager._getList<TraktList>("users/$id/lists");
  }

  /// Create a new custom list.
  ///
  /// The name is the only required field, but the other info is recommended to ask for.
  ///
  /// [id] - User slug
  /// [name] - Name of the list.
  /// [description] - Description for this list.
  /// [privacy] - Possible values: private, friends, or public
  /// [displayNumbers] - Should each item be numbered?
  /// [allowComments] - Are comments allowed?
  /// [sortBy] - Possible values: rank, added, title, released, runtime, popularity, percentage, votes, my_rating, random, watched, collected
  /// [sortHow] - Possible values: asc, desc
  ///
  /// 🔒 OAuth Required
  Future<TraktList> createCustomList(String id,
      {required String name,
      String? description,
      CustomListPrivacy privacy = CustomListPrivacy.private,
      bool displayNumbers = false,
      bool allowComments = true,
      CustomListSort sortBy = CustomListSort.rank,
      CustomListSortHow sortHow = CustomListSortHow.asc}) async {
    Map<String, dynamic> body = {
      "name": name,
      "privacy": privacy.value,
      "display_numbers": displayNumbers,
      "allow_comments": allowComments,
      "sort_by": sortBy.value,
      "sort_how": sortHow.value
    };

    if (description != null) {
      body["description"] = description;
    }
    return await _manager._authenticatedPost<TraktList>("users/$id/lists", body: jsonEncode(body));
  }

  /// Reorder all lists by sending the updated rank of list ids.
  ///
  /// Use the /users/:id/lists method to get all list ids.
  ///
  /// [id] - User slug
  /// [listIds] - the updated rank of list ids.
  ///
  /// 🔒 OAuth Required
  Future<ReorderListResponse> reorderLists(String id, List<int> listIds) async {
    return await _manager._authenticatedPost<ReorderListResponse>("users/$id/lists/reorder",
        body: jsonEncode({"rank": listIds}));
  }

  /// Returns a single custom list.
  ///
  /// Use the /users/:id/lists/:list_id/items method to get the actual items this list contains.
  ///
  /// [id] - User slug
  /// [listId] - Trakt ID or Trakt slug
  /// [useOAuth] - whether to make the request using OAuth header
  ///
  /// 🔓 OAuth Optional 😁 Emojis
  Future<TraktList> getList(String id, String listId, {bool useOAuth = false}) async {
    if (useOAuth) {
      return await _manager._authenticatedGet<TraktList>("users/$id/lists/$listId");
    }

    return await _manager._get<TraktList>("users/$id/lists/$listId");
  }

  /// Update a custom list by sending 1 or more parameters.
  ///
  /// If you update the list name, the original slug will still be retained so existing references to this list won't break.
  ///
  /// [id] - User slug
  /// [listId] - Trakt ID or Trakt slug
  /// [name] - Name of the list.
  /// [description] - Description for this list.
  /// [privacy] - Possible values: private, friends, or public
  /// [displayNumbers] - Should each item be numbered?
  /// [allowComments] - Are comments allowed?
  /// [sortBy] - Possible values: rank, added, title, released, runtime, popularity, percentage, votes, my_rating, random, watched, collected
  /// [sortHow] - Possible values: asc, desc
  ///
  /// 🔒 OAuth Required
  Future<TraktList> updateCustomList(String id, String listId,
      {String? name,
      String? description,
      CustomListPrivacy? privacy,
      bool? displayNumbers,
      bool? allowComments,
      CustomListSort? sortBy,
      CustomListSortHow? sortHow}) async {
    Map<String, dynamic> body = {};

    if (name != null) {
      body["name"] = name;
    }
    if (description != null) {
      body["description"] = description;
    }
    if (privacy != null) {
      body["privacy"] = privacy.value;
    }
    if (displayNumbers ?? false) {
      body["display_numbers"] = displayNumbers;
    }
    if (allowComments ?? false) {
      body["allow_comments"] = allowComments;
    }
    if (sortBy != null) {
      body["sort_by"] = sortBy.value;
    }
    if (sortHow != null) {
      body["sort_how"] = sortHow.value;
    }
    return await _manager._authenticatedPut<TraktList>("users/$id/lists/$listId", body: jsonEncode(body));
  }

  /// Remove a custom list and all items it contains.
  ///
  /// [id] - User slug
  /// [listId] - Trakt ID or Trakt slug
  ///
  /// 🔒 OAuth Required
  Future<void> deleteList(String id, String listId) async {
    return await _manager._authenticatedDelete("users/$id/lists/$listId");
  }

  /// Returns all users who liked a list.
  ///
  /// [id] - User slug
  /// [listId] - Trakt ID or Trakt slug
  /// [useOAuth] - whether to make the request using OAuth header
  ///
  /// 🔓 OAuth Optional 📄 Pagination
  Future<List<ListLikes>> getListLikes(int id, String listId,
      {bool useOAuth = false, RequestPagination? pagination}) async {
    if (useOAuth) {
      return await _manager._authenticatedGetList<ListLikes>("users/$id/lists/$listId/likes", pagination: pagination);
    }
    return await _manager._getList<ListLikes>("users/$id/lists/$listId/likes", pagination: pagination);
  }

  /// Votes help determine popular lists. Only one like is allowed per list per user.
  ///
  /// [id] - User slug
  /// [listId] - Trakt ID or Trakt slug
  ///
  /// 🔒 OAuth Required
  Future<void> likeList(int id, String listId) async {
    return await _manager._authenticatedPost("users/$id/lists/$listId/like");
  }

  /// Remove a like on a list.
  ///
  /// [id] - User slug
  /// [listId] - Trakt ID or Trakt slug
  ///
  /// 🔒 OAuth Required
  Future<void> removeListLike(int id, String listId) async {
    return await _manager._authenticatedDelete("users/$id/lists/$listId/like");
  }

  /// Get all items on a custom list.
  ///
  /// Items can be a movie, show, season, episode, or person.
  /// You can optionally specify the type parameter with a single value or comma delimited string for multiple item types.
  ///
  /// All list items are sorted by ascending rank. We also send X-Sort-By and X-Sort-How headers which can be used to
  /// custom sort the list in your app based on the user's preference.
  /// Values for X-Sort-By include rank, added, title, released, runtime, popularity, percentage, votes, my_rating, random,
  /// watched, and collected. Values for X-Sort-How include asc and desc.
  ///
  /// [id] - User slug
  /// [listId] - Trakt ID or Trakt slug
  /// [listType] - Filter for a specific item type
  /// [useOAuth] - whether to make the request using OAuth header
  ///
  /// 🔓 OAuth Optional 📄 Pagination Optional ✨ Extended Info 😁 Emojis
  Future<List<ListItem>> getListItems(
    String id,
    String listId, {
    bool useOAuth = false,
    ListType? listType,
    RequestPagination? pagination,
    bool extendedFull = false,
  }) async {
    var request = "users/$id/lists/$listId/items";
    if (listType != null) {
      request = "$request/${listType.value}";
    }

    if (useOAuth) {
      return await _manager._authenticatedGetList<ListItem>(request, pagination: pagination);
    }

    return await _manager._getList<ListItem>(request, pagination: pagination);
  }

  /// Add one or more items to a custom list. Items can be movies, shows, seasons, episodes, or people.
  ///
  /// [id] - User slug
  /// [listId] - Trakt ID or Trakt slug
  /// [movies] - Movies to add
  /// [shows] - Shows to add
  /// [seasons] - Seasons to add
  /// [episodes] - Episodes to add
  /// [people] - Persons to add
  ///
  /// 🔒 OAuth Required 😁 Emojis
  Future<AddToCustomListResponse> addItemsToCustomList(int id, String listId,
      {List<Movie> movies = const [],
      List<Show> shows = const [],
      List<Season> seasons = const [],
      List<Episode> episodes = const [],
      List<Person> people = const []}) async {
    Map<String, dynamic> body = {};
    if (movies.isNotEmpty) {
      body["movies"] = movies.map((movie) => movie.metadata).toList();
    }

    if (shows.isNotEmpty) {
      body["shows"] = shows.map((show) => show.metadata).toList();
    }

    if (seasons.isNotEmpty) {
      body["seasons"] = seasons.map((season) => season.metadata).toList();
    }

    if (episodes.isNotEmpty) {
      body["episodes"] = episodes.map((episode) => episode.metadata).toList();
    }

    if (people.isNotEmpty) {
      body["people"] = people.map((person) => person.metadata).toList();
    }

    return await _manager._authenticatedPost<AddToCustomListResponse>("users/$id/lists/$listId/items",
        body: jsonEncode(body));
  }

  /// Remove one or more items from a custom list.
  ///
  /// [id] - User slug
  /// [listId] - Trakt ID or Trakt slug
  ///
  /// 🔒 OAuth Required 😁 Emojis
  Future<RemoveFromCustomListResponse> removeItemsFromCustomList(int id, String listId,
      {List<Movie> movies = const [],
      List<Show> shows = const [],
      List<Season> seasons = const [],
      List<Episode> episodes = const [],
      List<Person> people = const []}) async {
    Map<String, dynamic> body = {};
    if (movies.isNotEmpty) {
      body["movies"] = movies.map((movie) => movie.metadata).toList();
    }

    if (shows.isNotEmpty) {
      body["shows"] = shows.map((show) => show.metadata).toList();
    }

    if (seasons.isNotEmpty) {
      body["seasons"] = seasons.map((season) => season.metadata).toList();
    }

    if (episodes.isNotEmpty) {
      body["episodes"] = episodes.map((episode) => episode.metadata).toList();
    }

    if (people.isNotEmpty) {
      body["people"] = people.map((person) => person.metadata).toList();
    }

    return await _manager._authenticatedPost<RemoveFromCustomListResponse>("users/$id/lists/$listId/items/remove",
        body: jsonEncode(body));
  }

  /// Reorder all items on a list by sending the updated rank of list item ids.
  ///
  /// Use the /users/:id/lists/:list_id/items method to get all list item ids.
  ///
  /// [id] - User slug
  /// [listId] - Trakt ID or Trakt slug
  /// [itemIds] - the updated rank of list ids.
  ///
  /// 🔒 OAuth Required
  Future<ReorderListResponse> reorderListItems(String id, String listId, List<int> itemIds) async {
    return await _manager._authenticatedPost<ReorderListResponse>("users/$id/lists/$listId/items/reorder",
        body: jsonEncode({"rank": itemIds}));
  }

  /// Returns all top level comments for a list.
  ///
  /// By default, the newest comments are returned first. Other sorting options include oldest, most likes, and most replies.
  ///
  /// [id] - Trakt ID
  /// [listId] - Trakt ID or Trakt slug
  /// [sort] - How to sort
  ///
  /// 🔓 OAuth Optional 📄 Pagination 😁 Emojis
  Future<List<Comment>> getListComments(int id, String listId,
      {bool useOAuth = false,
      ListCommentsSortBy sort = ListCommentsSortBy.newest,
      RequestPagination? pagination}) async {
    if (useOAuth) {
      return await _manager._authenticatedGetList<Comment>("users/$id/lists/$listId/comments/${sort.value}",
          pagination: pagination);
    }
    return await _manager._getList<Comment>("users/$id/lists/$listId/comments/${sort.value}", pagination: pagination);
  }

  /// If the user has a private profile, the follow request will require approval (approved_at will be null).
  ///
  /// If a user is public, they will be followed immediately (approved_at will have a date).
  ///
  /// Note: If this user is already being followed, a 409 HTTP status code will returned.
  ///
  /// [id] - User slug
  ///
  /// 🔒 OAuth Required
  Future<Following> followUser(String id) async {
    return await _manager._authenticatedPost<Following>("users/$id/follow");
  }

  /// Unfollow someone you already follow.
  ///
  /// [id] - User slug
  ///
  /// 🔒 OAuth Required
  Future<void> unfollowUser(String id) async {
    return await _manager._authenticatedDelete("users/$id/follow");
  }

  /// Returns all followers including when the relationship began.
  ///
  /// [id] - User slug
  /// [useOAuth] - whether to make the request using OAuth header
  ///
  /// 🔓 OAuth Optional ✨ Extended Info
  Future<List<Follower>> getFollowers(String id, {bool useOAuth = false, bool extendedFull = false}) async {
    if (useOAuth) {
      return await _manager._authenticatedGetList<Follower>("users/$id/followers", extendedFull: extendedFull);
    }
    return await _manager._getList<Follower>("users/$id/followers", extendedFull: extendedFull);
  }

  /// Returns all friends for a user including when the relationship began.
  ///
  /// Friendship is a 2 way relationship where each user follows the other.
  ///
  /// [id] - User slug
  /// [useOAuth] - whether to make the request using OAuth header
  ///
  /// 🔓 OAuth Optional ✨ Extended Info
  Future<List<Follower>> getFollowing(String id, {bool useOAuth = false, bool extendedFull = false}) async {
    if (useOAuth) {
      return await _manager._authenticatedGetList<Follower>("users/$id/following", extendedFull: extendedFull);
    }
    return await _manager._getList<Follower>("users/$id/following", extendedFull: extendedFull);
  }

  /// Returns all friends for a user including when the relationship began.
  ///
  /// Friendship is a 2 way relationship where each user follows the other.
  ///
  /// [id] - User slug
  /// [useOAuth] - whether to make the request using OAuth header
  ///
  /// 🔓 OAuth Optional ✨ Extended Info
  Future<List<Friend>> getFriends(String id, {bool useOAuth = false, bool extendedFull = false}) async {
    if (useOAuth) {
      return await _manager._authenticatedGetList<Friend>("users/$id/friends", extendedFull: extendedFull);
    }
    return await _manager._getList<Friend>("users/$id/friends", extendedFull: extendedFull);
  }

  /// Returns movies and episodes that a user has watched, sorted by most recent.
  ///
  /// You can optionally limit the type to movies or episodes. The id (64-bit integer) in each history
  /// item uniquely identifies the event and can be used to remove individual events by using the /sync/history/remove method.
  /// The action will be set to scrobble, checkin, or watch.Specify a type and trakt item_id to limit the history for just that item.
  /// If the item_id is valid, but there is no history, an empty array will be returned.
  ///
  /// [id] - User slug
  /// [type] - Possible values:  movies , shows , seasons , episodes
  /// [itemId] - Trakt ID for a specific item
  /// [startAt] - Starting date
  /// [endAt] - Ending data
  /// [useOAuth] - whether to make the request using OAuth header
  ///
  /// 🔓 OAuth Optional 📄 Pagination ✨ Extended Info
  Future<List<HistoryItem>> getHistory(String id,
      {WatchedItemType? type,
      String? itemId,
      String? startAt,
      String? endAt,
      bool useOAuth = false,
      bool extendedFull = false,
      RequestPagination? pagination}) async {
    var request = "users/$id/history";
    if (type != null && itemId != null) {
      request += "/${type.value}/$itemId";
    }

    Map<String, dynamic>? params;
    if (startAt != null) {
      params = {};
      params["start_at"] = startAt;
    }

    if (endAt != null) {
      params = params ?? {};
      params["end_at"] = endAt;
    }

    if (useOAuth) {
      return await _manager._authenticatedGetList<HistoryItem>(request,
          extendedFull: extendedFull, pagination: pagination, queryParamameters: params);
    }
    return await _manager._getList<HistoryItem>(request,
        extendedFull: extendedFull, pagination: pagination, queryParamameters: params);
  }

  /// Get a user's ratings filtered by type.
  ///
  /// You can optionally filter for a specific rating between 1 and 10.
  /// Send a comma separated string for rating if you need multiple ratings.
  ///
  /// [id] - User slug
  /// [type] - Possible values:  movies , shows , seasons , episodes , all .
  /// [ratings] - Filter for a specific rating. Possible values:  1 , 2 , 3 , 4 , 5 , 6 , 7 , 8 , 9 , 10 .
  /// [useOAuth] - whether to make the request using OAuth header
  ///
  /// 🔓 OAuth Optional 📄 Pagination Optional ✨ Extended Info
  Future<List<RatedItem>> getRatings(String id,
      {MediaType? type,
      List<int>? ratings,
      bool useOAuth = false,
      bool extendedFull = false,
      RequestPagination? pagination}) async {
    var request = "users/$id/ratings";
    if (type != null) {
      request += "/${type.value}";
      if (ratings?.isNotEmpty ?? false) {
        request += "/${ratings!.join(",")}";
      }
    }

    if (useOAuth) {
      return await _manager._authenticatedGetList<RatedItem>(request,
          extendedFull: extendedFull, pagination: pagination);
    }
    return await _manager._getList<RatedItem>(request, extendedFull: extendedFull, pagination: pagination);
  }

  /// Returns all items in a user's watchlist filtered by type.
  ///
  /// Sorting Headers
  ///
  /// By default, all list items are sorted by rank asc. We send X-Applied-Sort-By and X-Applied-Sort-How headers
  /// to indicate how the results are actually being sorted.We also send X-Sort-By and X-Sort-How headers which
  /// indicate the user's sort preference. Use these to to custom sort the watchlist in your app for more advanced
  /// sort abilities we can't do in the API. Values for X-Sort-By include rank, added, title, released, runtime, popularity,
  /// percentage, and votes. Values for X-Sort-How include asc and desc.
  ///
  /// Auto Removal
  ///
  /// When an item is watched, it will be automatically removed from the watchlist.
  /// For shows and seasons, watching 1 episode will remove the entire show or season.
  ///
  /// The watchlist should not be used as a list of what the user is actively watching.
  ///
  /// Use a combination of the /sync/watched and /shows/:id/progress methods to get what the user is actively watching.
  ///
  /// [id] - User slug
  /// [type] - Possible values:  movies , shows , seasons , episodes.
  /// [sortBy] - How to sort (only if type is also sent). Possible values:  rank , added , released , title .
  /// [useOAuth] - whether to make the request using OAuth header
  ///
  /// 🔓 OAuth Optional 📄 Pagination Optional ✨ Extended Info
  Future<List<WatchlistItem>> getWatchlist(String id,
      {WatchedItemType? type,
      SortBy? sortBy,
      bool useOAuth = false,
      bool extendedFull = false,
      RequestPagination? pagination}) async {
    var request = "users/$id/watchlist";
    if (type != null) {
      request += "/${type.value}";
      if (sortBy != null) {
        request += "/${sortBy.value}";
      }
    }

    if (useOAuth) {
      return await _manager._authenticatedGetList<WatchlistItem>(request,
          extendedFull: extendedFull, pagination: pagination);
    }
    return await _manager._getList<WatchlistItem>(request, extendedFull: extendedFull, pagination: pagination);
  }

  /// Returns all items a user personally recommendeds to others including optional notes explaining why they recommended an item.
  ///
  /// These recommendations are used to enchance Trakt's social recommendation algorithm.
  /// Apps should encourage user's to build their personal recommendations so the algorithm keeps getting better.
  ///
  /// [id] - User slug
  /// [type] - Possible values:  movies , shows.
  /// [sortBy] - How to sort (only if type is also sent). Possible values:  rank , added , released , title .
  ///
  /// 🔒 OAuth Required 📄 Pagination Optional ✨ Extended Info 😁 Emojis
  Future<List<PersonalRecommendation>> getPersonalRecommendations(String id,
      {MoviesShowsType? type, SortBy? sortBy, bool extendedFull = false, RequestPagination? pagination}) async {
    var request = "";
    if (type != null) {
      request += "/${type.value}";
      if (sortBy != null) {
        request += "/${sortBy.value}";
      }
    }
    return await _manager._authenticatedGetList<PersonalRecommendation>("users/$id/recommendations$request",
        extendedFull: extendedFull, pagination: pagination);
  }

  /// Returns a movie or episode if the user is currently watching something.
  ///
  /// If they are not, it returns no data and a 204 HTTP status code.
  ///
  /// [id] - User slug
  /// [useOAuth] - whether to make the request using OAuth header
  ///
  /// 🔓 OAuth Optional ✨ Extended Info
  Future<Watching> getWatching(String id, {bool useOAuth = false, bool extendedFull = false}) async {
    if (useOAuth) {
      return await _manager._authenticatedGet<Watching>("users/$id/watching", extendedFull: extendedFull);
    }
    return await _manager._get<Watching>("users/$id/watching", extendedFull: extendedFull);
  }

  /// Returns all movies or shows a user has watched sorted by most plays.
  ///
  /// If type is set to shows and you add [extendedNoSeasons], it won't return season or episode info.
  ///
  /// Each movie and show object contains last_watched_at and last_updated_at timestamps.
  /// Since users can set custom dates when they watched movies and episodes, it is possible for last_watched_at to be in the past.
  /// We also include last_updated_at to help sync Trakt data with your app.
  /// Cache this timestamp locally and only re-process the movies and shows if you see a newer timestamp.
  ///
  /// Each show object contains a reset_at timestamp. If not null, this is when the user started re-watching the show.
  /// Your app can adjust the progress by ignoring episodes with a last_watched_at prior to the reset_at.
  ///
  /// [id] - User slug
  /// [useOAuth] - whether to make the request using OAuth header
  ///
  /// 🔓 OAuth Optional ✨ Extended Info
  Future<List<WatchedItem>> getWatched(String id, MoviesShowsType type,
      {bool useOAuth = false, bool extendedFull = false, bool? extendedNoSeasons}) async {
    Map<String, dynamic>? params;
    List<String> extended = [];
    if (extendedFull) {
      extended.add("full");
    }
    if ((extendedNoSeasons ?? false) && type == MoviesShowsType.shows) {
      extended.add("noseasons");
    }
    if (extended.isNotEmpty) {
      params = {};
      params["extended"] = extended.join(",");
    }

    if (useOAuth) {
      return await _manager._authenticatedGetList<WatchedItem>("users/$id/watched/${type.value}",
          queryParamameters: params);
    }
    return await _manager._getList<WatchedItem>("users/$id/watched/${type.value}", queryParamameters: params);
  }

  /// Returns stats about the movies, shows, and episodes a user has watched, collected, and rated.
  ///
  /// [id] - User slug
  /// [useOAuth] - whether to make the request using OAuth header
  ///
  /// 🔓 OAuth Optional
  Future<Stats> getStats(String id, {bool useOAuth = false}) async {
    if (useOAuth) {
      return await _manager._authenticatedGet<Stats>("users/$id/stats");
    }
    return await _manager._get<Stats>("users/$id/stats");
  }
}
