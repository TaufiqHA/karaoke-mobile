import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/song_model.dart';
import 'song_service.dart';

class DummySongService implements SongService {
  static const String _keySongs = 'app_songs_data';

  final List<SongModel> _defaultSongs = const [
    SongModel(
      songid: 1,
      songtitle: 'Sial',
      songsinger: 'Mahalini',
      songurl: 'https://www.youtube.com/watch?v=0kFh_0l33rM',
      songcategory: 1,
      songnada: 'Wanita',
      songduration: '04:03',
    ),
    SongModel(
      songid: 2,
      songtitle: 'Rungkad',
      songsinger: 'Happy Asmara',
      songurl: 'https://www.youtube.com/watch?v=4E-l_P4_pYQ',
      songcategory: 2,
      songnada: 'Wanita',
      songduration: '04:15',
    ),
    SongModel(
      songid: 3,
      songtitle: 'Separuh Nafas',
      songsinger: 'Dewa 19',
      songurl: 'https://www.youtube.com/watch?v=vVj44t-j3tA',
      songcategory: 3,
      songnada: 'Pria',
      songduration: '03:45',
    ),
    SongModel(
      songid: 4,
      songtitle: 'Perfect',
      songsinger: 'Ed Sheeran',
      songurl: 'https://www.youtube.com/watch?v=2Vv-BfVoq4g',
      songcategory: 4,
      songnada: 'Pria',
      songduration: '04:23',
    ),
    SongModel(
      songid: 5,
      songtitle: 'Komang',
      songsinger: 'Raim Laode',
      songurl: 'https://www.youtube.com/watch?v=UqNZZq3KzM4',
      songcategory: 1,
      songnada: 'Pria',
      songduration: '03:42',
    ),
    SongModel(
      songid: 6,
      songtitle: 'Nemen',
      songsinger: 'Gildcoustic',
      songurl: 'https://www.youtube.com/watch?v=fM87R5-G5x8',
      songcategory: 2,
      songnada: 'Pria',
      songduration: '04:50',
    ),
    SongModel(
      songid: 7,
      songtitle: 'Dynamite',
      songsinger: 'BTS',
      songurl: 'https://www.youtube.com/watch?v=gdZLi9oWNZg',
      songcategory: 5,
      songnada: 'Pria',
      songduration: '03:19',
    ),
  ];

  Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  @override
  Future<List<SongModel>> getSongs({String? search, int? categoryId}) async {
    final prefs = await _getPrefs();
    final jsonString = prefs.getString(_keySongs);

    List<SongModel> songs;

    if (jsonString == null || jsonString.isEmpty) {
      await _saveAll(_defaultSongs);
      await prefs.setBool('migrated_youtube_urls_v1', true);
      songs = List.from(_defaultSongs);
    } else {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
        songs = decoded
            .map((item) => SongModel.fromJson(item as Map<String, dynamic>))
            .toList();

        // Jalankan migrasi satu kali untuk memperbarui cache dummy legacy ke URL YouTube
        final bool isMigrated = prefs.getBool('migrated_youtube_urls_v1') ?? false;
        if (!isMigrated) {
          await _saveAll(_defaultSongs);
          await prefs.setBool('migrated_youtube_urls_v1', true);
          songs = List.from(_defaultSongs);
        }
      } catch (_) {
        songs = List.from(_defaultSongs);
      }
    }

    if (search != null && search.trim().isNotEmpty) {
      final query = search.trim().toLowerCase();
      songs = songs.where((s) {
        return s.songtitle.toLowerCase().contains(query) ||
            s.songsinger.toLowerCase().contains(query);
      }).toList();
    }

    if (categoryId != null) {
      songs = songs.where((s) => s.songcategory == categoryId).toList();
    }

    return songs;
  }

  @override
  Future<SongModel> getSong(int id) async {
    final songs = await getSongs();
    try {
      return songs.firstWhere((s) => s.songid == id);
    } catch (_) {
      throw Exception('Lagu tidak ditemukan.');
    }
  }

  @override
  Future<SongModel> createSong({
    required String songtitle,
    required String songsinger,
    required String songurl,
    required int songcategory,
    String? songnada,
    String? songduration,
  }) async {
    final songs = await getSongs();

    int nextId = 1;
    if (songs.isNotEmpty) {
      final maxId = songs.map((s) => s.songid).reduce((a, b) => a > b ? a : b);
      nextId = maxId + 1;
    }

    final newSong = SongModel(
      songid: nextId,
      songtitle: songtitle.trim(),
      songsinger: songsinger.trim(),
      songurl: songurl.trim(),
      songcategory: songcategory,
      songnada: songnada?.trim().isNotEmpty == true ? songnada!.trim() : null,
      songduration: songduration?.trim().isNotEmpty == true ? songduration!.trim() : null,
    );

    songs.insert(0, newSong);
    await _saveAll(songs);
    return newSong;
  }

  @override
  Future<SongModel> updateSong(SongModel song) async {
    final songs = await getSongs();
    final index = songs.indexWhere((s) => s.songid == song.songid);

    if (index == -1) {
      throw Exception('Lagu tidak ditemukan');
    }

    songs[index] = song;
    await _saveAll(songs);
    return song;
  }

  @override
  Future<bool> deleteSong(int songid) async {
    final songs = await getSongs();
    final initialLength = songs.length;
    songs.removeWhere((s) => s.songid == songid);

    if (songs.length < initialLength) {
      await _saveAll(songs);
      return true;
    }
    return false;
  }

  Future<void> _saveAll(List<SongModel> songs) async {
    final prefs = await _getPrefs();
    final jsonList = songs.map((s) => s.toJson()).toList();
    await prefs.setString(_keySongs, jsonEncode(jsonList));
  }
}
