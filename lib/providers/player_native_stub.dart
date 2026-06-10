// Web stub — يُستخدم بدلاً من media_kit على Web
import '../web/web_player.dart';

/// ينشئ كائن WebVideoPlayer بدلاً من media_kit Player
dynamic createNativePlayer() => WebVideoPlayer();

/// لا مستمعين على الويب (الحالة تُدار يدوياً في PlayerProvider)
void setupPlayerListeners(
  dynamic player,
  void Function(bool) onPlaying,
  void Function(bool) onBuffering,
  void Function(String) onError,
) {}

/// يحدّث الرابط ويُطلق callback التشغيل على عنصر الـ video HTML
Future<void> openMedia(dynamic player, String url) async {
  if (player is WebVideoPlayer) {
    player.url = url;
    player.onPlay?.call(url);
  }
}

/// إيقاف/تشغيل عبر callback يُسجّله NativeVideoController
Future<void> playerTogglePlay(dynamic player) async {
  if (player is WebVideoPlayer) {
    player.onTogglePlay?.call();
  }
}

/// ضبط الصوت عبر callback
Future<void> playerSetVolume(dynamic player, double volume) async {
  if (player is WebVideoPlayer) {
    player.onSetVolume?.call(volume);
  }
}

/// تنظيف callbacks عند الإغلاق
void disposePlayer(dynamic player) {
  if (player is WebVideoPlayer) {
    player.onPlay = null;
    player.onTogglePlay = null;
    player.onSetVolume = null;
  }
}
