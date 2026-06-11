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

  /// مباريات اليوم (حسب التوقيت المحلي للمستخدم)
  static Future<List<Match>> getTodayMatches() async {
    final now = DateTime.now();
    // نجلب نطاق أمس→غد لالتقاط المباريات التي تعبر منتصف الليل بتوقيت UTC
    final all = await _fetchRange(
      now.subtract(const Duration(days: 1)),
      now.add(const Duration(days: 1)),
    );
    final today = DateTime(now.year, now.month, now.day);
    final result = all.where((m) {
      final d = m.startTime.toLocal();
      final md = DateTime(d.year, d.month, d.day);
      return md == today;
    }).toList();
    _sort(result);
    return result;
  }

  /// المباريات المباشرة الآن
  static Future<List<Match>> getLiveMatches() async {
    final now = DateTime.now();
    final all = await _fetchRange(
      now.subtract(const Duration(days: 1)),
      now.add(const Duration(days: 1)),
    );
    return all.where((m) => m.isLive).toList();
  }

  /// جدول الأيام القادمة (اليوم → +6 أيام)
  static Future<List<Match>> getUpcomingMatches() async {
    final now = DateTime.now();
    final all = await _fetchRange(now, now.add(const Duration(days: 6)));
    _sort(all);
    return all;
  }

  // ── جلب نطاق تواريخ من كل الدوريات ──
  static Future<List<Match>> _fetchRange(DateTime start, DateTime end) async {
    final range = '${_dateStr(start)}-${_dateStr(end)}';
    final futures = _leagues.map((l) => _fetchLeague(l[0], l[1], range));
    final results = await Future.wait(futures);

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

  // ترتيب: 🔴 مباشر → ⏳ قادمة (حسب الموعد) → ✅ منتهية
  static void _sort(List<Match> all) {
    all.sort((a, b) {
      if (a.isLive && !b.isLive) return -1;
      if (!a.isLive && b.isLive) return 1;
      if (a.isUpcoming && b.isFinished) return -1;
      if (a.isFinished && b.isUpcoming) return 1;
      return a.startTime.compareTo(b.startTime);
    });
  }

  static Future<List<Match>> _fetchLeague(
      String slug, String name, String dates) async {
    try {
      final url = '$_base/$slug/scoreboard?dates=$dates&limit=100';
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return [];
      final data = json.decode(res.body) as Map<String, dynamic>;
      final events = (data['events'] as List<dynamic>?) ?? [];
      return events
          .cast<Map<String, dynamic>>()
          .map((e) => Match.fromEspn(e, name))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ESPN dates param uses YYYYMMDD (no dashes within a single date)
  static String _dateStr(DateTime d) {
    return '${d.year}'
        '${d.month.toString().padLeft(2, '0')}'
        '${d.day.toString().padLeft(2, '0')}';
  }
}
