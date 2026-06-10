import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/match.dart';

class MatchesService {
  // ESPN public soccer API — CORS-friendly, no API key, no proxy needed
  static const _base =
      'https://site.api.espn.com/apis/site/v2/sports/soccer';

  /// slug → Arabic league name
  static const _leagues = [
    ['uefa.champions_league',  'دوري أبطال أوروبا'],
    ['uefa.europa_league',     'الدوري الأوروبي'],
    ['eng.1',                  'الدوري الإنجليزي الممتاز'],
    ['esp.1',                  'الدوري الإسباني'],
    ['ger.1',                  'الدوري الألماني'],
    ['ita.1',                  'الدوري الإيطالي'],
    ['fra.1',                  'الدوري الفرنسي'],
    ['ksa.1',                  'دوري روشن السعودي'],
    ['uae.1',                  'دوري أدنوك للمحترفين'],
    ['qat.1',                  'دوري نجوم قطر'],
    ['fifa.worldq.afc',        'تصفيات كأس العالم - آسيا'],
    ['fifa.worldq.caf',        'تصفيات كأس العالم - أفريقيا'],
  ];

  /// Live matches only (in-progress)
  static Future<List<Match>> getLiveMatches() async {
    final all = await getTodayMatches();
    return all.where((m) => m.isLive).toList();
  }

  /// All matches for today across all configured leagues
  static Future<List<Match>> getTodayMatches() async {
    final today = _todayStr(); // YYYYMMDD
    final futures = _leagues.map((l) => _fetchLeague(l[0], l[1], today));
    final results = await Future.wait(futures);

    final all = results.expand((r) => r).toList();

    // Sort: 🔴 live first → ⏳ upcoming (by time) → ✅ finished
    all.sort((a, b) {
      if (a.isLive  && !b.isLive)      return -1;
      if (!a.isLive &&  b.isLive)      return  1;
      if (a.isUpcoming && b.isFinished) return -1;
      if (a.isFinished && b.isUpcoming) return  1;
      return a.startTime.compareTo(b.startTime);
    });

    return all;
  }

  static Future<List<Match>> _fetchLeague(
      String slug, String name, String date) async {
    try {
      final url = '$_base/$slug/scoreboard?dates=$date&limit=50';
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return [];
      final data   = json.decode(res.body) as Map<String, dynamic>;
      final events = (data['events'] as List<dynamic>?) ?? [];
      return events
          .cast<Map<String, dynamic>>()
          .map((e) => Match.fromEspn(e, name))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ESPN dates param uses YYYYMMDD (no dashes)
  static String _todayStr() {
    final n = DateTime.now();
    return '${n.year}'
        '${n.month.toString().padLeft(2, '0')}'
        '${n.day.toString().padLeft(2, '0')}';
  }
}
