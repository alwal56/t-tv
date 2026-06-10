import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/channel.dart';

/// Xtream Codes API integration
class XtreamService {
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

    final headers = kIsWeb ? <String, String>{} : {'User-Agent': 'T-TV/1.0'};

    // ── Step 1: Get live categories ──────────────────────────────────────────
    final Map<String, String> catNames = {};
    try {
      final catUri = Uri.parse(
          '$base/player_api.php?username=$username&password=$password&action=get_live_categories');
      final catResp =
          await http.get(catUri, headers: headers).timeout(const Duration(seconds: 20));
      if (catResp.statusCode == 200) {
        final cats = jsonDecode(catResp.body) as List;
        for (final cat in cats) {
          catNames[cat['category_id'].toString()] =
              cat['category_name'].toString();
        }
      }
    } catch (_) {
      // Categories are optional — continue without them
    }

    // ── Step 2: Get live streams ─────────────────────────────────────────────
    final streamUri = Uri.parse(
        '$base/player_api.php?username=$username&password=$password&action=get_live_streams');
    final resp = await http
        .get(streamUri, headers: headers)
        .timeout(const Duration(seconds: 60));

    if (resp.statusCode != 200) {
      throw Exception('فشل تحميل القنوات (${resp.statusCode})');
    }

    final dynamic decoded = jsonDecode(resp.body);
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

      channels.add(Channel(
        id: 'xt_${i}_$streamId',
        name: s['name']?.toString() ?? 'قناة',
        url: '$base/$username/$password/$streamId',
        logo: logo.isEmpty ? null : logo,
        group: groupName.isEmpty ? 'عام' : groupName,
        tvgId: s['epg_channel_id']?.toString(),
        tvgName: s['name']?.toString(),
      ));
    }

    return channels;
  }
}
