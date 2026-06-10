import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/match.dart';

class MatchesService {
  static const _sofaBase = 'https://api.sofascore.com/api/v1';
  // CORS proxy — wraps the SofaScore URL to allow browser fetches
  static const _proxy = 'https://corsproxy.io/?';

  static String _url(String path) {
    final raw = '$_sofaBase$path';
    return kIsWeb ? '$_proxy${Uri.encodeComponent(raw)}' : raw;
  }

  static Future<List<Match>> getLiveMatches() async {
    return _fetch('/sport/football/events/live');
  }

  static Future<List<Match>> getTodayMatches() async {
    final date = _todayStr();
    return _fetch('/sport/football/scheduled-events/$date');
  }

  static Future<List<Match>> _fetch(String path) async {
    try {
      final res = await http
          .get(Uri.parse(_url(path)))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final body = kIsWeb
            ? res.body
            : utf8.decode(res.bodyBytes);
        final data = json.decode(body) as Map<String, dynamic>;
        final events = (data['events'] as List<dynamic>? ?? []);
        return events
            .cast<Map<String, dynamic>>()
            .map(Match.fromSofaScore)
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
