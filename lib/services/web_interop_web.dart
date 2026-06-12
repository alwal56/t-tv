// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js_util' as js_util;

/// تنفيذ الويب لوظائف المتصفح (إشعارات، فتح روابط، قراءة الصور).
class WebInterop {
  static bool get notificationsSupported => html.Notification.supported;

  static String notificationPermission() =>
      html.Notification.permission ?? 'default';

  static void openUrl(String url) {
    try {
      html.window.open(url, '_blank');
    } catch (_) {}
  }

  /// يفتح منتقي الصور ويقرأ النص عبر Tesseract.js (المعرّف في index.html)
  static Future<String> pickImageText() async {
    try {
      final promise = js_util.callMethod(js_util.globalThis, 'pickAndOcr', []);
      return await js_util.promiseToFuture<String>(promise);
    } catch (_) {
      return '';
    }
  }

  static Future<bool> requestNotificationPermission() async {
    if (!html.Notification.supported) return false;
    if (html.Notification.permission == 'granted') return true;
    if (html.Notification.permission == 'denied') return false;
    final perm = await html.Notification.requestPermission();
    return perm == 'granted';
  }

  static void showNotification(String title, String body) {
    try {
      html.Notification(title, body: body, icon: 'icons/Icon-192.png');
    } catch (_) {}
  }
}
