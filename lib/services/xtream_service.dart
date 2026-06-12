import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/channel.dart';
import 'cors_proxy.dart';

/// Xtream Codes API integration
class XtreamService {
  /// يجلب JSON من player_api — عبر بروكسي CORS على الويب (الخوادم غالباً تحجب المتصفح)
  static Future<String?> _fetchApi(String url) async {
    if (kIsWeb) {
      return CorsProxy.fetch(
        url,
        timeout: const Duration(seconds: 30),
        isValid: (b) {
          final t = b.trimLeft();
          return t.startsWith('[') || t.startsWith('{');
        },
      );
    }
    try {
      final resp = await http
          .get(Uri.parse(url), headers: {'User-Agent': 'T-TV/1.0'})
          .timeout(const Duration(seconds: 60));
      return resp.statusCode == 200 ? resp.body : null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<Channel>> loadChannels({
    required String server,
    required String username,
    required String password,
    int? maxChannels,
  }) async {
    // Normalize server URL
    String base = server.trim();
    if (!base.startsWith('http://') && !base.startsWith('https://')) {
      base = 'http://$base';
    }
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);

    // ── Step 1: Get live categories ──────────────────────────────────────────
    final Map<String, String> catNames = {};
    try {
      final catBody = await _fetchApi(
          '$base/player_api.php?username=$username&password=$password&action=get_live_categories');
      if (catBody != null) {
        final cats = jsonDecode(catBody) as List;
        for (final cat in cats) {
          catNames[cat['category_id'].toString()] =
              cat['category_name'].toString();
        }
      }
    } catch (_) {
      // Categories are optional — continue without them
    }

    // ── Step 2: Get live streams ─────────────────────────────────────────────
    final body = await _fetchApi(
        '$base/player_api.php?username=$username&password=$password&action=get_live_streams');

    if (body == null) {
      throw Exception(
          'تعذّر الوصول للخادم — قد يحجب المتصفح. جرّب تطبيق أندرويد');
    }

    final dynamic decoded = jsonDecode(body);
    if (decoded is! List) {
      throw Exception('استجابة غير صحيحة من الخادم');
    }

    final List streams = decoded;
    final channels = <Channel>[];

    for (int i = 0; i < streams.length; i++) {
      if (maxChannels != null && channels.length >= maxChannels) break;

      final s = streams[i];
      final streamId = s['stream_id']?.toString() ?? i.toString();
      final catId = s['category_id']?.toString() ?? '';
      final groupName = catNames[catId] ??
          s['category_name']?.toString() ??
          'عام';
      final logo = s['stream_icon']?.toString() ?? '';

      // المتصفح يحتاج HLS (m3u8)؛ التطبيقات الأصلية تشغّل TS مباشرة
      final streamUrl = kIsWeb
          ? '$base/live/$username/$password/$streamId.m3u8'
          : '$base/$username/$password/$streamId';

      channels.add(Channel(
        id: 'xt_${i}_$streamId',
        name: s['name']?.toString() ?? 'قناة',
        url: streamUrl,
        logo: logo.isEmpty ? null : logo,
        group: groupName.isEmpty ? 'عام' : groupName,
        tvgId: s['epg_channel_id']?.toString(),
        tvgName: s['name']?.toString(),
      ));
    }

    return channels;
  }
}
