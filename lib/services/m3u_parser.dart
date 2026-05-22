import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/channel.dart';

class M3uParser {
  /// حد أقصى للقنوات عند التحميل التلقائي (لتجنب تجميد الواجهة على Web)
  static const int defaultMaxChannels = 300;

  static Future<List<Channel>> parseFromUrl(
    String url, {
    int? maxChannels,
  }) async {
    try {
      // Web browsers block custom User-Agent headers (CORS restriction)
      final response = await http.get(
        Uri.parse(url),
        headers: kIsWeb ? {} : {'User-Agent': 'T-TV/1.0'},
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final content = utf8.decode(response.bodyBytes);
        return await _parseAsync(content, maxChannels: maxChannels);
      }
      throw Exception('فشل تحميل القائمة: ${response.statusCode}');
    } catch (e) {
      throw Exception('خطأ في تحميل القائمة: $e');
    }
  }

  static List<Channel> parseFromString(String content) =>
      _parseSync(content, maxChannels: null);

  /// Async parser — يُخلي مجال الـ event loop كل 200 سطر
  /// لتجنب تجميد الـ UI thread على Web
  static Future<List<Channel>> _parseAsync(
    String content, {
    int? maxChannels,
  }) async {
    final lines = content.split('\n');
    final channels = <Channel>[];

    if (lines.isEmpty || !lines.first.trim().startsWith('#EXTM3U')) {
      throw Exception('صيغة M3U غير صحيحة');
    }

    String? currentName;
    String? currentLogo;
    String? currentGroup;
    String? currentTvgId;
    String? currentTvgName;
    int idCounter = 0;
    int linesSinceYield = 0;

    for (var i = 1; i < lines.length; i++) {
      // توقف مبكر عند الوصول للحد الأقصى
      if (maxChannels != null && channels.length >= maxChannels) break;

      final line = lines[i].trim();

      if (line.startsWith('#EXTINF:')) {
        currentName = _extractName(line);
        currentLogo = _extractAttr(line, 'tvg-logo');
        currentGroup = _extractAttr(line, 'group-title');
        currentTvgId = _extractAttr(line, 'tvg-id');
        currentTvgName = _extractAttr(line, 'tvg-name');
      } else if (line.isNotEmpty && !line.startsWith('#') && currentName != null) {
        channels.add(Channel(
          id: 'ch_${idCounter++}',
          name: currentName,
          url: line,
          logo: currentLogo,
          group: currentGroup?.isEmpty ?? true ? 'عام' : currentGroup,
          tvgId: currentTvgId,
          tvgName: currentTvgName,
        ));
        currentName = null;
        currentLogo = null;
        currentGroup = null;
        currentTvgId = null;
        currentTvgName = null;
      }

      // أطلق الـ event loop كل 200 سطر لتجنب تجميد الواجهة
      linesSinceYield++;
      if (linesSinceYield >= 200) {
        linesSinceYield = 0;
        await Future.delayed(Duration.zero);
      }
    }

    return channels;
  }

  static List<Channel> _parseSync(String content, {int? maxChannels}) {
    final lines = content.split('\n');
    final channels = <Channel>[];

    if (lines.isEmpty || !lines.first.trim().startsWith('#EXTM3U')) {
      throw Exception('صيغة M3U غير صحيحة');
    }

    String? currentName;
    String? currentLogo;
    String? currentGroup;
    String? currentTvgId;
    String? currentTvgName;
    int idCounter = 0;

    for (var i = 1; i < lines.length; i++) {
      if (maxChannels != null && channels.length >= maxChannels) break;
      final line = lines[i].trim();

      if (line.startsWith('#EXTINF:')) {
        currentName = _extractName(line);
        currentLogo = _extractAttr(line, 'tvg-logo');
        currentGroup = _extractAttr(line, 'group-title');
        currentTvgId = _extractAttr(line, 'tvg-id');
        currentTvgName = _extractAttr(line, 'tvg-name');
      } else if (line.isNotEmpty && !line.startsWith('#') && currentName != null) {
        channels.add(Channel(
          id: 'ch_${idCounter++}',
          name: currentName,
          url: line,
          logo: currentLogo,
          group: currentGroup?.isEmpty ?? true ? 'عام' : currentGroup,
          tvgId: currentTvgId,
          tvgName: currentTvgName,
        ));
        currentName = null;
        currentLogo = null;
        currentGroup = null;
        currentTvgId = null;
        currentTvgName = null;
      }
    }

    return channels;
  }

  static String? _extractAttr(String line, String attr) {
    final regex = RegExp('$attr="([^"]*)"', caseSensitive: false);
    final match = regex.firstMatch(line);
    return match?.group(1);
  }

  static String _extractName(String line) {
    final commaIndex = line.lastIndexOf(',');
    if (commaIndex != -1 && commaIndex < line.length - 1) {
      return line.substring(commaIndex + 1).trim();
    }
    return 'قناة بدون اسم';
  }
}
