import 'package:flutter/foundation.dart';
import '../models/channel.dart';
import '../services/storage_service.dart';

// Conditional import: WebVideoPlayer on Web, media_kit Player on native
import 'player_native_stub.dart'
    if (dart.library.io) 'player_native.dart';

class PlayerProvider extends ChangeNotifier {
  dynamic _player;
  Channel? _currentChannel;
  bool _isPlaying = false;
  bool _isBuffering = false;
  bool _hasError = false;
  String _errorMsg = '';
  double _volume = 1.0;
  bool _isMuted = false;
  bool _isFullscreen = false;

  dynamic get player => _player;
  Channel? get currentChannel => _currentChannel;
  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  bool get hasError => _hasError;
  String get errorMsg => _errorMsg;
  double get volume => _volume;
  bool get isMuted => _isMuted;
  bool get isFullscreen => _isFullscreen;
  bool get isWeb => kIsWeb;

  void init() {
    // ننشئ الـ player على جميع المنصات (WebVideoPlayer على Web، Player على native)
    _player = createNativePlayer();
    if (!kIsWeb) {
      _setupListeners();
    }
  }

  void _setupListeners() {
    if (_player == null) return;
    setupPlayerListeners(
      _player,
      (playing) {
        _isPlaying = playing;
        notifyListeners();
      },
      (buffering) {
        _isBuffering = buffering;
        notifyListeners();
      },
      (error) {
        if (error.isNotEmpty) {
          _hasError = true;
          _errorMsg = 'خطأ في تشغيل القناة';
          notifyListeners();
        }
      },
    );
  }

  Future<void> playChannel(Channel channel) async {
    _currentChannel = channel;
    _hasError = false;
    _errorMsg = '';
    _isBuffering = !kIsWeb; // على الويب لا نعرض مؤشر التحميل
    notifyListeners();

    try {
      await openMedia(_player, channel.url);
      await StorageService.addRecentChannel(channel.id);
      if (kIsWeb) {
        // على الويب نحدّث الحالة يدوياً
        _isPlaying = true;
        _isBuffering = false;
        notifyListeners();
      }
    } catch (e) {
      _hasError = true;
      _errorMsg = 'تعذّر تشغيل القناة';
      _isBuffering = false;
      notifyListeners();
    }
  }

  Future<void> togglePlay() async {
    if (kIsWeb) {
      _isPlaying = !_isPlaying;
      notifyListeners();
      await playerTogglePlay(_player);
    } else if (_player != null) {
      await playerTogglePlay(_player);
      // الحالة تُحدَّث عبر stream listener
    }
  }

  Future<void> setVolume(double vol) async {
    _volume = vol.clamp(0.0, 1.0);
    _isMuted = _volume == 0;
    await playerSetVolume(_player, _volume * 100);
    notifyListeners();
  }

  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    await playerSetVolume(_player, _isMuted ? 0 : _volume * 100);
    notifyListeners();
  }

  void toggleFullscreen() {
    _isFullscreen = !_isFullscreen;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_player != null) {
      disposePlayer(_player);
    }
    super.dispose();
  }
}
