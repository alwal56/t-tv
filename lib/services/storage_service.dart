import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/channel.dart';
import '../models/playlist.dart';

class StorageService {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ─── First Launch ─────────────────────────────────────────────────────────
  static bool get isFirstLaunch => !(_prefs.getBool('first_launch_done') ?? false);
  static Future<void> setFirstLaunchDone() =>
      _prefs.setBool('first_launch_done', true);

  // ─── Playlists ────────────────────────────────────────────────────────────
  static List<Playlist> getPlaylists() {
    final jsonList = _prefs.getStringList('playlists') ?? [];
    return jsonList.map((j) => Playlist.fromJson(jsonDecode(j))).toList();
  }

  static Future<void> savePlaylists(List<Playlist> playlists) async {
    final jsonList = playlists.map((p) => jsonEncode(p.toJson())).toList();
    await _prefs.setStringList('playlists', jsonList);
  }

  static Future<void> addPlaylist(Playlist playlist) async {
    final playlists = getPlaylists();
    playlists.add(playlist);
    await savePlaylists(playlists);
  }

  static Future<void> removePlaylist(String id) async {
    final playlists = getPlaylists().where((p) => p.id != id).toList();
    await savePlaylists(playlists);
  }

  // ─── Xtream Sources ───────────────────────────────────────────────────────
  static List<Map<String, String>> getXtreamSources() {
    final jsonList = _prefs.getStringList('xtream_sources') ?? [];
    return jsonList
        .map((j) => Map<String, String>.from(jsonDecode(j)))
        .toList();
  }

  static Future<void> saveXtreamSources(List<Map<String, String>> sources) async {
    final jsonList = sources.map((s) => jsonEncode(s)).toList();
    await _prefs.setStringList('xtream_sources', jsonList);
  }

  static Future<void> addXtreamSource(Map<String, String> source) async {
    final sources = getXtreamSources();
    sources.add(source);
    await saveXtreamSources(sources);
  }

  // ─── Favorites ────────────────────────────────────────────────────────────
  static Set<String> getFavoriteIds() {
    return (_prefs.getStringList('favorites') ?? []).toSet();
  }

  static Future<void> toggleFavorite(String channelId) async {
    final favorites = getFavoriteIds();
    if (favorites.contains(channelId)) {
      favorites.remove(channelId);
    } else {
      favorites.add(channelId);
    }
    await _prefs.setStringList('favorites', favorites.toList());
  }

  static bool isFavorite(String channelId) {
    return getFavoriteIds().contains(channelId);
  }

  // ─── Settings ─────────────────────────────────────────────────────────────
  static String get epgUrl => _prefs.getString('epg_url') ?? '';
  static Future<void> setEpgUrl(String url) =>
      _prefs.setString('epg_url', url);

  static String get lastPlaylistUrl =>
      _prefs.getString('last_playlist_url') ?? '';
  static Future<void> setLastPlaylistUrl(String url) =>
      _prefs.setString('last_playlist_url', url);

  static bool get isDarkMode => _prefs.getBool('dark_mode') ?? true;
  static Future<void> setDarkMode(bool val) =>
      _prefs.setBool('dark_mode', val);

  // إصدار القوائم الافتراضية
  static int get defaultPlaylistsVersion =>
      _prefs.getInt('default_playlists_version') ?? 0;
  static Future<void> saveDefaultPlaylistsVersion(int version) =>
      _prefs.setInt('default_playlists_version', version);

  // ─── Recent Channels ──────────────────────────────────────────────────────
  static List<String> getRecentChannelIds() {
    return _prefs.getStringList('recent_channels') ?? [];
  }

  static Future<void> addRecentChannel(String channelId) async {
    final recent = getRecentChannelIds();
    recent.remove(channelId);
    recent.insert(0, channelId);
    if (recent.length > 20) recent.removeLast();
    await _prefs.setStringList('recent_channels', recent);
  }
}
