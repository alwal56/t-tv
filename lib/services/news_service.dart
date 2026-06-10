import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/news_article.dart';

class _RssSource {
  final String name;
  final String url;
  const _RssSource(this.name, this.url);
}

class NewsService {
  static const _proxy = 'https://corsproxy.io/?';

  /// Confirmed working Arabic + English football RSS feeds
  static const _sources = [
    _RssSource('BBC عربي', 'https://feeds.bbci.co.uk/arabic/sport/rss.xml'),
    _RssSource('فرانس 24', 'https://www.france24.com/ar/sport/rss'),
    _RssSource('Sky Sports', 'https://www.skysports.com/rss/12040'),
  ];

  static String _proxyUrl(String url) =>
      kIsWeb ? '$_proxy${Uri.encodeComponent(url)}' : url;

  static Future<List<NewsArticle>> getAll() async {
    final results = <NewsArticle>[];
    for (final src in _sources) {
      try {
        final articles = await _fetchFeed(src);
        results.addAll(articles);
      } catch (_) {
        // skip failed source
      }
    }
    // Sort newest first
    results.sort((a, b) {
      if (a.pubDate == null && b.pubDate == null) return 0;
      if (a.pubDate == null) return 1;
      if (b.pubDate == null) return -1;
      return b.pubDate!.compareTo(a.pubDate!);
    });
    return results;
  }

  static Future<List<NewsArticle>> _fetchFeed(_RssSource src) async {
    final res = await http
        .get(Uri.parse(_proxyUrl(src.url)))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) return [];

    final body = res.body;
    final doc = XmlDocument.parse(body);
    final items = doc.findAllElements('item');

    return items.map((item) {
      final title = _text(item, 'title');
      final link  = _text(item, 'link');
      final desc  = _text(item, 'description');
      final date  = _parseDate(_text(item, 'pubDate'));
      final img   = _extractImage(item);

      return NewsArticle.fromRssItem(
        title: title,
        description: desc.isNotEmpty ? desc : null,
        link: link,
        imageUrl: img,
        source: src.name,
        pubDate: date,
      );
    }).where((a) => a.title.isNotEmpty && a.url.isNotEmpty).toList();
  }

  static String _text(XmlElement item, String tag) {
    try {
      return item.findElements(tag).first.innerText.trim();
    } catch (_) {
      return '';
    }
  }

  /// Extracts image from <enclosure>, <media:thumbnail>, or <media:content>
  static String? _extractImage(XmlElement item) {
    // <enclosure url="..." type="image/..."/>
    for (final enc in item.findElements('enclosure')) {
      final type = enc.getAttribute('type') ?? '';
      if (type.startsWith('image')) {
        return enc.getAttribute('url');
      }
    }
    // <media:thumbnail url="..."/>
    for (final el in item.findAllElements('thumbnail')) {
      final url = el.getAttribute('url');
      if (url != null) return url;
    }
    // <media:content url="..." medium="image"/>
    for (final el in item.findAllElements('content')) {
      final url = el.getAttribute('url');
      final medium = el.getAttribute('medium') ?? '';
      if (url != null && (medium == 'image' || medium.isEmpty)) return url;
    }
    return null;
  }

  static DateTime? _parseDate(String s) {
    if (s.isEmpty) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {}
    // RFC 822 fallback  e.g. "Wed, 10 Jun 2026 14:00:00 GMT"
    try {
      return _parseRfc822(s);
    } catch (_) {
      return null;
    }
  }

  static DateTime _parseRfc822(String s) {
    const months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };
    final parts = s.replaceAll(',', '').trim().split(RegExp(r'\s+'));
    // e.g. [Wed, 10, Jun, 2026, 14:00:00, GMT]
    if (parts.length < 5) throw FormatException('bad date');
    final day   = int.parse(parts[1]);
    final month = months[parts[2]] ?? 1;
    final year  = int.parse(parts[3]);
    final time  = parts[4].split(':');
    final h     = int.parse(time[0]);
    final m     = int.parse(time[1]);
    final sec   = time.length > 2 ? int.parse(time[2]) : 0;
    return DateTime.utc(year, month, day, h, m, sec);
  }
}
