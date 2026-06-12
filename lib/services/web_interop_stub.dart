/// تنفيذ بديل (أندرويد/سطح المكتب) — الإشعارات والـOCR ميزات ويب فقط حالياً.
class WebInterop {
  static bool get notificationsSupported => false;

  static String notificationPermission() => 'default';

  static void openUrl(String url) {}

  static Future<String> pickImageText() async => '';

  static Future<bool> requestNotificationPermission() async => false;

  static void showNotification(String title, String body) {}
}
