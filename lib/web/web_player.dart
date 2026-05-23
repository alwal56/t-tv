/// حالة مشغّل الويب — Pure Dart بدون أي import خاص بالمنصة.
/// يُستخدم فقط عبر player_native_stub.dart و platform_video_stub.dart على Web.
class WebVideoPlayer {
  String? url;

  /// يُستدعى عند تغيّر رابط القناة (openMedia)
  void Function(String url)? onPlay;

  /// يُستدعى عند طلب إيقاف/تشغيل
  void Function()? onTogglePlay;

  /// يُستدعى عند تغيّر الصوت
  void Function(double volume)? onSetVolume;
}
