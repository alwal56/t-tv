import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// جلب نص عبر سلسلة بروكسيات CORS مع تجاوز الفشل تلقائياً.
/// (corsproxy.io توقّف، لذا نجرّب عدة بدائل بالترتيب حتى ينجح أحدها.)
class CorsProxy {
  static Future<String?> fetch(
    String url, {
    Duration timeout = const Duration(seconds: 18),
    bool Function(String body)? isValid,
  }) async {
    final candidates = kIsWeb ? _proxied(url) : <String>[url];
    for (final c in candidates) {
      try {
        final res = await http.get(Uri.parse(c)).timeout(timeout);
        if (res.statusCode == 200 && res.body.trim().isNotEmpty) {
          final body = res.body;
          if (isValid == null || isValid(body)) return body;
        }
      } catch (_) {
        // جرّب البروكسي التالي
      }
    }
    return null;
  }

  static List<String> _proxied(String url) {
    final enc = Uri.encodeComponent(url);
    return [
      'https://api.allorigins.win/raw?url=$enc',
      'https://api.codetabs.com/v1/proxy/?quest=$enc',
      'https://corsproxy.io/?url=$enc',
      'https://thingproxy.freeboard.io/fetch/$url',
    ];
  }
}
