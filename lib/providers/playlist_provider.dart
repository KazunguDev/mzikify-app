import 'package:app/app_state.dart';
import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/auth_provider.dart';
import 'package:app/utils/api_request.dart';
import 'package:flutter/foundation.dart';

class PlaylistProvider with ChangeNotifier, StreamSubscriber {
  var _playlists = <Playlist>[];

  PlaylistProvider() {
    subscribe(AuthProvider.userLoggedOutStream.listen((_) {
      _playlists.clear();
      notifyListeners();
    }));
  }

  Future<void> init(List<dynamic> playlistData) async {
    _playlists = _parsePlaylistsFromJson(playlistData);
    notifyListeners();
  }

  List<Playlist> get playlists => _playlists;

  List<Playlist> get standardPlaylists =>
      _playlists.where((playlist) => playlist.isStandard).toList();

  Future<void> addSongToPlaylist(
    Song song, {
    required Playlist playlist,
  }) async {
    assert(!playlist.isSmart, 'Cannot manually mutate smart playlists.');

    await post('playlists/${playlist.id}/songs', data: {
      'songs': [song.id],
    });

    final cachedSongs =
        AppState.get<List<Song>>(['playlist.songs', playlist.id]);

    if (cachedSongs != null && !cachedSongs.contains(song)) {
      // add the song into the playlist's songs cache
      AppState.set(['playlist.songs', playlist.id], cachedSongs..add(song));
    }
  }

  Future<void> removeSongFromPlaylist(
    Song song, {
    required Playlist playlist,
  }) async {
    assert(!playlist.isSmart, 'Cannot manually mutate smart playlists.');

    await delete('playlists/${playlist.id}/songs', data: {
      'songs': [song.id],
    });

    final cachedSongs =
        AppState.get<List<Song>>(['playlist.songs', playlist.id]);

    if (cachedSongs != null && cachedSongs.contains(song)) {
      // remove the song from the playlist's songs cache
      AppState.set(['playlist.songs', playlist.id], cachedSongs..remove(song));
    }
  }

  Future<Playlist> create({required String name}) async {
    final json = await post('playlist', data: {
      'name': name,
    });

    Playlist playlist = Playlist.fromJson(json);
    _playlists.add(playlist);
    notifyListeners();

    return playlist;
  }

  Future<void> remove(Playlist playlist) async {
    // For a snappier experience, we don't `await` the operation.
    delete('playlists/${playlist.id}');
    _playlists.remove(playlist);

    notifyListeners();
  }

  Future<void> fetchAll() async {
    _playlists = _parsePlaylistsFromJson(await get('playlists'));
    notifyListeners();
  }

  List<Playlist> _parsePlaylistsFromJson(List<dynamic> json) {
    return json.map<Playlist>((j) => Playlist.fromJson(j)).toList();
  }
}
