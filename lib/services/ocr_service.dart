// ignore: avoid_web_libraries_in_flutter
import 'dart:js_util' as js_util;

import 'package:flutter/foundation.dart';

/// نتيجة قراءة الصورة وتحليلها
class OcrResult {
  final String rawText;
  final String? m3uUrl;
  final String? server;
  final String? username;
  final String? password;

  const OcrResult({
    required this.rawText,
    this.m3uUrl,
    this.server,
    this.username,
    this.password,
  });

  bool get hasXtream =>
      (server != null && server!.isNotEmpty) ||
      (username != null && username!.isNotEmpty) ||
      (password != null && password!.isNotEmpty);
}

class OcrService {
  /// يفتح منتقي الصور (ويب فقط) ويقرأ النص ثم يحلّله لاستخراج بيانات المصدر.
  static Future<OcrResult?> pickAndRead() async {
    if (!kIsWeb) return null;
    try {
      final promise = js_util.callMethod(js_util.globalThis, 'pickAndOcr', []);
      final text = await js_util.promiseToFuture<String>(promise);
      if (text.trim().isEmpty) return const OcrResult(rawText: '');
      return _parse(text);
    } catch (_) {
      return null;
    }
  }

  static OcrResult _parse(String text) {
    // تنظيف بسيط — OCR أحياناً يضع مسافات داخل الروابط
    final clean = text.replaceAll(' ', ' ');

    // كل الروابط
    final urls = RegExp(r'https?:\/\/[^\s"؀-ۿ]+')
        .allMatches(clean)
        .map((m) => m.group(0)!.trim().replaceAll(RegExp(r'[.,;]+$'), ''))
        .toList();

    // رابط M3U: يحتوي m3u أو get.php
    String? m3u;
    for (final u in urls) {
      final lu = u.toLowerCase();
      if (lu.contains('.m3u') || lu.contains('get.php') || lu.contains('type=m3u')) {
        m3u = u;
        break;
      }
    }

    // خادم Xtream: scheme://host[:port] بدون مسار
    String? server;
    for (final u in urls) {
      final uri = Uri.tryParse(u);
      if (uri != null && uri.host.isNotEmpty) {
        final port = uri.hasPort ? ':${uri.port}' : '';
        server = '${uri.scheme}://${uri.host}$port';
        break;
      }
    }

    // إذا كان رابط get.php فيه user/pass كباراميتر
    if (m3u != null) {
      final uri = Uri.tryParse(m3u);
      final qp = uri?.queryParameters ?? const {};
      final u = qp['username'];
      final p = qp['password'];
      if (u != null || p != null) {
        return OcrResult(
          rawText: text,
          m3uUrl: m3u,
          server: server,
          username: u,
          password: p,
        );
      }
    }

    final username = _field(clean, [
      'username', 'user name', 'user', 'login',
      'اسم المستخدم', 'المستخدم', 'يوزر',
    ]);
    final password = _field(clean, [
      'password', 'pass', 'pwd',
      'كلمة المرور', 'كلمة السر', 'الباسورد', 'باسورد',
    ]);

    return OcrResult(
      rawText: text,
      m3uUrl: m3u,
      server: server,
      username: username,
      password: password,
    );
  }

  /// يبحث عن "مفتاح: قيمة" أو "مفتاح = قيمة" لأي من المرادفات
  static String? _field(String text, List<String> keys) {
    for (final k in keys) {
      final re = RegExp(
        RegExp.escape(k) + r'\s*[:=\-]?\s*([^\s\n\r]+)',
        caseSensitive: false,
      );
      final m = re.firstMatch(text);
      if (m != null) {
        final v = _sanitize(m.group(1));
        if (v != null) return v;
      }
    }
    return null;
  }

  /// ينظّف القيمة ويرفض النصوص النائبة (placeholders)
  static String? _sanitize(String? raw) {
    if (raw == null) return null;
    // إزالة الأقواس وعلامات القوالب من الأطراف
    var v = raw.trim().replaceAll(RegExp(r'^[\[\]<>{}():"ّ\-]+|[\[\]<>{}():"\-]+$'), '');
    v = v.trim();
    if (v.length < 3) return null;
    if (v.contains('://')) return null;
    // رفض القيم النائبة الشائعة
    const placeholders = [
      'name', 'username', 'user', 'password', 'pass', 'pwd',
      'xxxx', 'yourusername', 'yourpassword', 'example',
    ];
    final lv = v.toLowerCase();
    if (placeholders.contains(lv)) return null;
    if (v.contains('[') || v.contains(']') || v.contains('{') || v.contains('}')) {
      return null;
    }
    return v;
  }
}
