import 'package:flutter/foundation.dart';
import '../models/channel.dart';
import '../models/playlist.dart';
import '../services/m3u_parser.dart';
import '../services/storage_service.dart';
import '../services/epg_service.dart';
import '../services/xtream_service.dart';

enum LoadingState { idle, loading, loaded, error }

/// رقم إصدار القوائم الافتراضية — زيادته تُعيد تحميل القنوات تلقائياً
const _defaultPlaylistsVersion = 9;

/// مجلدات القنوات المدمجة — الترتيب يحدد الأولوية في الواجهة
const _defaultPlaylists = [
  // ⭐ القناوات المنتقاة — raw GitHub (يتجاوز كاش Service Worker دائماً)
  _DefaultPlaylist(
    name: '⭐ قنوات مختارة',
    url: 'https://raw.githubusercontent.com/alwal56/t-tv/main/web/playlists/arabic.m3u',
    maxChannels: 500,
  ),
  // ⚽ رياضة دولية — كل قنوات الرياضة من iptv-org (بدون حد عملي)
  _DefaultPlaylist(
    name: '⚽ رياضة دولية',
    url: 'https://iptv-org.github.io/iptv/categories/sports.m3u',
    groupOverride: 'رياضة | دولية',
    maxChannels: 2000,
  ),
  // 🌍 قنوات عربية عامة
  _DefaultPlaylist(
    name: '🌍 قنوات عربية',
    url: 'https://iptv-org.github.io/iptv/languages/ara.m3u',
    groupOverride: 'عربية | دولية',
    maxChannels: 300,
  ),
  // 📰 أخبار دولية
  _DefaultPlaylist(
    name: '📰 أخبار',
    url: 'https://iptv-org.github.io/iptv/categories/news.m3u',
    groupOverride: 'أخبار | دولية',
    maxChannels: 200,
  ),
];

class _DefaultPlaylist {
  final String name;
  final String url;
  final String? groupOverride;
  final int maxChannels;
  const _DefaultPlaylist({
    required this.name,
    required this.url,
    this.groupOverride,
    this.maxChannels = 200,
  });
}

class ChannelsProvider extends ChangeNotifier {
  List<Channel> _allChannels = [];
  List<Channel> _filteredChannels = [];
  List<Playlist> _playlists = [];
  String _selectedCategory = 'الكل';
  String _searchQuery = '';
  LoadingState _state = LoadingState.idle;
  String _errorMessage = '';
  bool _showFavoritesOnly = false;
  String _loadingLabel = '';

  List<Channel> get channels => _filteredChannels;
  List<Channel> get allChannels => _allChannels;
  List<Playlist> get playlists => _playlists;
  LoadingState get state => _state;
  String get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;
  bool get showFavoritesOnly => _showFavoritesOnly;
  bool get isLoading => _state == LoadingState.loading;
  String get loadingLabel => _loadingLabel;

  List<String> get categories {
    // الترتيب المفضل للفئات الرئيسية
    const preferredOrder = ['رياضة', 'أخبار', 'عربية', 'ترفيه'];

    // استخلاص الفئة الرئيسية من تنسيق "رئيسية | فرعية"
    final allParents = _allChannels
        .map((c) {
          final g = c.group ?? 'عام';
          return g.contains(' | ') ? g.split(' | ').first : g;
        })
        .toSet();

    final ordered = <String>[];
    for (final g in preferredOrder) {
      if (allParents.contains(g)) ordered.add(g);
    }
    // الفئات غير المعروفة بالترتيب الأبجدي
    final remaining = allParents
        .where((g) => !ordered.contains(g))
        .toList()
      ..sort();
    ordered.addAll(remaining);

    return ['الكل', 'المفضلة', ...ordered];
  }

  int get favoriteCount => _allChannels.where((c) => c.isFavorite).length;

  // ─── Initialization ───────────────────────────────────────────────────────

  Future<void> init() async {
    _playlists = StorageService.getPlaylists();
    final savedVersion = StorageService.defaultPlaylistsVersion;

    if (_playlists.isEmpty || savedVersion != _defaultPlaylistsVersion) {
      await _loadDefaultPlaylists();
    } else {
      await _loadAllSavedPlaylists();
    }

    final favoriteIds = StorageService.getFavoriteIds();
    for (var ch in _allChannels) {
      if (favoriteIds.contains(ch.id)) ch.isFavorite = true;
    }
    _applyFilters();
    notifyListeners();
  }

  /// إعادة تحميل القنوات الافتراضية (من الإعدادات)
  Future<void> resetToDefaults() async {
    _allChannels = [];
    _playlists = [];
    _selectedCategory = 'الكل';
    await StorageService.savePlaylists([]);
    await StorageService.saveDefaultPlaylistsVersion(0);
    notifyListeners();
    await _loadDefaultPlaylists();
    final favoriteIds = StorageService.getFavoriteIds();
    for (var ch in _allChannels) {
      if (favoriteIds.contains(ch.id)) ch.isFavorite = true;
    }
    _applyFilters();
    notifyListeners();
  }

  // ─── Load from saved playlists ────────────────────────────────────────────

  Future<void> _loadAllSavedPlaylists() async {
    _state = LoadingState.loading;
    notifyListeners();

    final List<Channel> allChannels = [];
    final seenUrls = <String>{};
    final favoriteIds = StorageService.getFavoriteIds();

    for (final playlist in _playlists) {
      try {
        _loadingLabel = 'جاري تحميل ${playlist.name}...';
        notifyListeners();
        final channels =
            await M3uParser.parseFromUrl(playlist.url, maxChannels: 300);
        for (final ch in channels) {
          if (!seenUrls.contains(ch.url)) {
            seenUrls.add(ch.url);
            ch.isFavorite = favoriteIds.contains(ch.id);
            allChannels.add(ch);
          }
        }
      } catch (_) {}
    }

    _allChannels = allChannels;
    _loadingLabel = '';
    _state =
        allChannels.isNotEmpty ? LoadingState.loaded : LoadingState.idle;
    notifyListeners();
  }

  Future<void> _loadDefaultPlaylists() async {
    _state = LoadingState.loading;
    _loadingLabel = '';
    notifyListeners();

    final List<Channel> allChannels = [];
    final List<Playlist> savedPlaylists = [];
    final seenUrls = <String>{};

    for (final dp in _defaultPlaylists) {
      try {
        _loadingLabel = 'جاري تحميل ${dp.name}...';
        notifyListeners();

        final channels = await M3uParser.parseFromUrl(
          dp.url,
          maxChannels: dp.maxChannels,
        );

        for (final ch in channels) {
          if (!seenUrls.contains(ch.url)) {
            seenUrls.add(ch.url);
            final grouped = dp.groupOverride != null
                ? Channel(
                    id: ch.id,
                    name: ch.name,
                    url: ch.url,
                    logo: ch.logo,
                    group: dp.groupOverride,
                    tvgId: ch.tvgId,
                    tvgName: ch.tvgName,
                  )
                : ch;
            allChannels.add(grouped);
          }
        }

        savedPlaylists.add(Playlist(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: dp.name,
          url: dp.url,
          addedAt: DateTime.now(),
          channelCount: channels.length,
        ));
      } catch (_) {
        // تجاهل القائمة إذا تعذّر تحميلها
      }
    }

    if (allChannels.isNotEmpty) {
      _allChannels = allChannels;
      _playlists = savedPlaylists;
      await StorageService.savePlaylists(_playlists);
      await StorageService.saveDefaultPlaylistsVersion(_defaultPlaylistsVersion);
      _state = LoadingState.loaded;
    } else {
      _state = LoadingState.idle;
    }
    _loadingLabel = '';
    notifyListeners();
  }

  // ─── Load M3U from URL ────────────────────────────────────────────────────

  Future<void> loadPlaylist(String url) async {
    _state = LoadingState.loading;
    _loadingLabel = 'جاري تحميل القائمة...';
    _errorMessage = '';
    notifyListeners();

    try {
      final channels = await M3uParser.parseFromUrl(url);
      final favoriteIds = StorageService.getFavoriteIds();

      final seenUrls = _allChannels.map((c) => c.url).toSet();
      final newChannels = channels
          .where((ch) => !seenUrls.contains(ch.url))
          .map((ch) {
        ch.isFavorite = favoriteIds.contains(ch.id);
        return ch;
      }).toList();

      _allChannels.addAll(newChannels);
      _state = LoadingState.loaded;

      final existing = _playlists.any((p) => p.url == url);
      if (!existing) {
        final playlist = Playlist(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'قائمة ${_playlists.length + 1}',
          url: url,
          addedAt: DateTime.now(),
          channelCount: channels.length,
        );
        _playlists.add(playlist);
        await StorageService.savePlaylists(_playlists);
      }

      final epgUrl = StorageService.epgUrl;
      if (epgUrl.isNotEmpty) EpgService.loadEpg(epgUrl);
    } catch (e) {
      _state = LoadingState.error;
      _errorMessage = e.toString();
    }

    _loadingLabel = '';
    _applyFilters();
    notifyListeners();
  }

  // ─── Load Xtream Codes ────────────────────────────────────────────────────

  Future<void> loadXtream({
    required String server,
    required String username,
    required String password,
  }) async {
    _state = LoadingState.loading;
    _loadingLabel = 'جاري تحميل Xtream Codes...';
    _errorMessage = '';
    notifyListeners();

    try {
      final channels = await XtreamService.loadChannels(
        server: server,
        username: username,
        password: password,
      );

      final favoriteIds = StorageService.getFavoriteIds();
      final seenUrls = _allChannels.map((c) => c.url).toSet();
      final newChannels = channels
          .where((ch) => !seenUrls.contains(ch.url))
          .map((ch) {
        ch.isFavorite = favoriteIds.contains(ch.id);
        return ch;
      }).toList();

      _allChannels.addAll(newChannels);
      _state = LoadingState.loaded;

      // Save xtream source as playlist entry
      final sourceKey = '$server|$username|$password';
      final existing = _playlists.any((p) => p.url == sourceKey);
      if (!existing) {
        _playlists.add(Playlist(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'Xtream: $username',
          url: sourceKey,
          addedAt: DateTime.now(),
          channelCount: channels.length,
        ));
        await StorageService.savePlaylists(_playlists);

        // Save credentials for later reload
        await StorageService.addXtreamSource({
          'server': server,
          'username': username,
          'password': password,
        });
      }
    } catch (e) {
      _state = LoadingState.error;
      _errorMessage = 'خطأ Xtream: $e';
    }

    _loadingLabel = '';
    _applyFilters();
    notifyListeners();
  }

  // ─── Filters & UI ─────────────────────────────────────────────────────────

  void setCategory(String category) {
    _selectedCategory = category;
    _showFavoritesOnly = category == 'المفضلة';
    _applyFilters();
    notifyListeners();
  }

  void search(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  Future<void> toggleFavorite(Channel channel) async {
    await StorageService.toggleFavorite(channel.id);
    channel.isFavorite = !channel.isFavorite;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    List<Channel> result = List.from(_allChannels);

    if (_selectedCategory == 'المفضلة') {
      result = result.where((c) => c.isFavorite).toList();
    } else if (_selectedCategory != 'الكل') {
      // دعم تنسيق "رئيسية | فرعية" — التصفية بالفئة الرئيسية
      result = result.where((c) {
        final g = c.group ?? 'عام';
        if (g.contains(' | ')) {
          return g.split(' | ').first == _selectedCategory;
        }
        return g == _selectedCategory;
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result
          .where((c) =>
              c.name.toLowerCase().contains(query) ||
              (c.group?.toLowerCase().contains(query) ?? false))
          .toList();
    }

    _filteredChannels = result;
  }

  Future<void> removePlaylist(String id) async {
    _playlists.removeWhere((p) => p.id == id);
    await StorageService.savePlaylists(_playlists);
    notifyListeners();
  }
}
