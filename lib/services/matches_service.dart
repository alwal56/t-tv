import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/match.dart';

class MatchesService {
  // ESPN public soccer API — CORS-friendly (Access-Control-Allow-Origin: *)
  static const _base =
      'https://site.api.espn.com/apis/site/v2/sports/soccer';

  /// slug → Arabic league name (slugs verified against ESPN, June 2026)
  static const _leagues = [
    ['fifa.world',        'كأس العالم 2026 🏆'],
    ['uefa.champions',    'دوري أبطال أوروبا'],
    ['uefa.europa',       'الدوري الأوروبي'],
    ['ksa.1',             'دوري روشن السعودي'],
    ['eng.1',             'الدوري الإنجليزي الممتاز'],
    ['esp.1',             'الدوري الإسباني'],
    ['ger.1',             'الدوري الألماني'],
    ['ita.1',             'الدوري الإيطالي'],
    ['fra.1',             'الدوري الفرنسي'],
    ['fifa.friendly',     'مباريات ودية دولية'],
    ['club.friendly',     'مباريات ودية - أندية'],
  ];

  /// Live matches only (in-progress)
  static Future<List<Match>> getLiveMatches() async {
    final all = await getTodayMatches();
    return all.where((m) => m.isLive).toList();
  }

  /// All matches for today across all configured leagues
  static Future<List<Match>> getTodayMatches() async {
    return _fetchDate(DateTime.now());
  }

  /// Today + tomorrow (for the "الكل" filter — upcoming schedule view)
  static Future<List<Match>> getUpcomingMatches() async {
    final now = DateTime.now();
    final results = await Future.wait([
      _fetchDate(now),
      _fetchDate(now.add(const Duration(days: 1))),
    ]);
    final seen = <int>{};
    final all = <Match>[];
    for (final list in results) {
      for (final m in list) {
        if (seen.add(m.id)) all.add(m);
      }
    }
    _sort(all);
    return all;
  }

  static Future<List<Match>> _fetchDate(DateTime day) async {
    final date = _dateStr(day);
    final futures = _leagues.map((l) => _fetchLeague(l[0], l[1], date));
    final results = await Future.wait(futures);
    final all = results.expand((r) => r).toList();
    _sort(all);
    return all;
  }

  // Sort: 🔴 live first → ⏳ upcoming (by kickoff) → ✅ finished
  static void _sort(List<Match> all) {
    all.sort((a, b) {
      if (a.isLive  && !b.isLive)       return -1;
      if (!a.isLive &&  b.isLive)       return  1;
      if (a.isUpcoming && b.isFinished) return -1;
      if (a.isFinished && b.isUpcoming) return  1;
      return a.startTime.compareTo(b.startTime);
    });
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
  static String _dateStr(DateTime d) {
    return '${d.year}'
        '${d.month.toString().padLeft(2, '0')}'
        '${d.day.toString().padLeft(2, '0')}';
  }
}
