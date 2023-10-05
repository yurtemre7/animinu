import 'package:myanimelist_api/myanimelist_api.dart' as mal_api;

class MALApi {
  late mal_api.Client api;

  /// Get anime based of query
  MALApi({String accessToken = "", String clientToken = ""}) {
    api = mal_api.Client(accessToken: accessToken, clientToken: clientToken);
  }
}
