import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/values/pagination_result.dart';
import 'package:flutter/foundation.dart';

class SongListScreenProvider with ChangeNotifier, StreamSubscriber {
  final SongProvider _songProvider;
  final SearchProvider _searchProvider;

  List<Song> songs = [];

  SongListScreenProvider({
    required songProvider,
    required searchProvider,
  })  : _songProvider = songProvider,
        _searchProvider = searchProvider {
    subscribe(AuthProvider.userLoggedOutStream.listen((_) {
      songs.clear();
      notifyListeners();
    }));
  }

  Future<PaginationResult?> fetch({
    SongPaginationConfig? paginationConfig,
    String searchQuery = '',
  }) async {
    assert(paginationConfig != null || searchQuery.isNotEmpty);
    PaginationResult? result;

    if (searchQuery.isNotEmpty) {
      songs = await _searchProvider.searchSongs(searchQuery);
    } else {
      result = await _songProvider.paginate(paginationConfig!);
      songs = _songProvider.songs;
    }

    notifyListeners();

    return result;
  }
}
