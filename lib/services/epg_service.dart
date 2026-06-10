import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/epg_program.dart';

class EpgService {
  static final Map<String, List<EpgProgram>> _cache = {};

  static Future<Map<String, List<EpgProgram>>> loadEpg(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'T-TV/1.0'},
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) return {};

      final content = utf8.decode(response.bodyBytes);
      return _parseXmltv(content);
    } catch (e) {
      return {};
    }
  }

  static Map<String, List<EpgProgram>> _parseXmltv(String xmlContent) {
    final result = <String, List<EpgProgram>>{};

    try {
      final document = XmlDocument.parse(xmlContent);
      final programmes = document.findAllElements('programme');

      for (final prog in programmes) {
        final channelId = prog.getAttribute('channel') ?? '';
        final start = _parseDate(prog.getAttribute('start') ?? '');
        final stop = _parseDate(prog.getAttribute('stop') ?? '');
        final title = prog.findElements('title').firstOrNull?.innerText ?? '';
        final desc =
            prog.findElements('desc').firstOrNull?.innerText;
        final category =
            prog.findElements('category').firstOrNull?.innerText;

        if (channelId.isEmpty || start == null || stop == null) continue;

        result.putIfAbsent(channelId, () => []);
        result[channelId]!.add(EpgProgram(
          channelId: channelId,
          title: title,
          description: desc,
          start: start,
          end: stop,
          category: category,
        ));
      }

      // Sort by start time
      for (final key in result.keys) {
        result[key]!.sort((a, b) => a.start.compareTo(b.start));
      }

      _cache.addAll(result);
    } catch (_) {}

    return result;
  }

  static DateTime? _parseDate(String dateStr) {
    try {
      // Format: 20240521143000 +0300
      final cleanStr = dateStr.replaceAll(' ', '');
      if (cleanStr.length < 14) return null;

      final year = int.parse(cleanStr.substring(0, 4));
      final month = int.parse(cleanStr.substring(4, 6));
      final day = int.parse(cleanStr.substring(6, 8));
      final hour = int.parse(cleanStr.substring(8, 10));
      final minute = int.parse(cleanStr.substring(10, 12));
      final second = int.parse(cleanStr.substring(12, 14));

      int offsetHours = 0;
      if (cleanStr.length >= 19) {
        final offsetStr = cleanStr.substring(14);
        final sign = offsetStr.startsWith('-') ? -1 : 1;
        final offsetNum = int.tryParse(offsetStr.replaceAll('+', '').replaceAll('-', '')) ?? 0;
        offsetHours = sign * (offsetNum ~/ 100);
      }

      return DateTime.utc(year, month, day, hour - offsetHours, minute, second)
          .toLocal();
    } catch (_) {
      return null;
    }
  }

  static List<EpgProgram> getProgramsForChannel(String channelId) {
    return _cache[channelId] ?? [];
  }

  static EpgProgram? getCurrentProgram(String channelId) {
    final programs = getProgramsForChannel(channelId);
    final now = DateTime.now();
    try {
      return programs.firstWhere(
        (p) => now.isAfter(p.start) && now.isBefore(p.end),
      );
    } catch (_) {
      return null;
    }
  }
}
