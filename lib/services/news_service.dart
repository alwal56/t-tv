import 'package:xml/xml.dart';
import '../models/news_article.dart';
import 'cors_proxy.dart';

class _RssSource {
  final String name;
  final String url;
  const _RssSource(this.name, this.url);
}

class NewsService {
  /// مصادر أخبار رياضية عربية متعددة (متحقق من عملها)
  static const _sources = [
    _RssSource('BBC عربي',     'https://feeds.bbci.co.uk/arabic/sport/rss.xml'),
    _RssSource('فرانس 24',     'https://www.france24.com/ar/sport/rss'),
    _RssSource('CNN عربية',    'https://arabic.cnn.com/api/v1/rss/sport/rss.xml'),
    _RssSource('اليوم السابع', 'https://www.youm7.com/rss/SectionRss?SectionID=298'),
    _RssSource('الجزيرة',      'https://www.aljazeera.net/aljazeerarss/a7c186be-1baa-4bd4-9d80-a84db769f779/73d0e1b4-532f-45ef-b135-bfdff8b8cc54'),
    _RssSource('RT عربي',      'https://arabic.rt.com/rss/'),
  ];

  /// كلمات رياضية لتصفية الأخبار غير الرياضية (للمصادر العامة)
  static const _sportsKeywords = [
    'كرة', 'مباراة', 'مباريات', 'دوري', 'هدف', 'أهداف', 'لاعب', 'لاعبين',
    'فريق', 'مدرب', 'بطولة', 'كأس', 'منتخب', 'ملعب', 'تهديف', 'انتقال',
    'ضم', 'صفقة', 'ريال', 'برشلونة', 'ليفربول', 'النصر', 'الهلال', 'الاتحاد',
    'الأهلي', 'الزمالك', 'مونديال', 'رياضة', 'رياضي',
    'football', 'soccer', 'goal', 'match', 'league', 'transfer',
  ];

  /// المصادر الرياضية المتخصّصة لا تحتاج تصفية
  static const _sportsOnlySources = {
    'BBC عربي', 'فرانس 24', 'CNN عربية', 'اليوم السابع',
  };

  static bool _isSports(String title, String description) {
    final text = '${title.toLowerCase()} ${description.toLowerCase()}';
    return _sportsKeywords.any((k) => text.contains(k.toLowerCase()));
  }

  static Future<List<NewsArticle>> getAll() async {
    // جلب كل المصادر بالتوازي لسرعة أكبر
    final lists = await Future.wait(
      _sources.map((s) async {
        try {
          return await _fetchFeed(s);
        } catch (_) {
          return <NewsArticle>[];
        }
      }),
    );

    final results = lists.expand((l) => l).toList();

    // إزالة التكرار حسب الرابط
    final seen = <String>{};
    final unique = results.where((a) => seen.add(a.url)).toList();

    // الأحدث أولاً
    unique.sort((a, b) {
      if (a.pubDate == null && b.pubDate == null) return 0;
      if (a.pubDate == null) return 1;
      if (b.pubDate == null) return -1;
      return b.pubDate!.compareTo(a.pubDate!);
    });
    return unique;
  }

  static Future<List<NewsArticle>> _fetchFeed(_RssSource src) async {
    final body = await CorsProxy.fetch(
      src.url,
      isValid: (b) => b.contains('<item') || b.contains('<entry'),
    );
    if (body == null) return [];

    final doc = XmlDocument.parse(body);
    final items = doc.findAllElements('item');
    final sportsOnly = _sportsOnlySources.contains(src.name);

    return items
        .map((item) {
          final title = _text(item, 'title');
          final link  = _text(item, 'link');
          final desc  = _text(item, 'description');
          final full  = _text(item, 'encoded'); // content:encoded
          final date  = _parseDate(_text(item, 'pubDate'));
          final img   = _extractImage(item);

          return NewsArticle.fromRssItem(
            title: title,
            description: desc.isNotEmpty ? desc : null,
            content: full.isNotEmpty ? full : null,
            link: link,
            imageUrl: img,
            source: src.name,
            pubDate: date,
          );
        })
        .where((a) =>
            a.title.isNotEmpty &&
            a.url.isNotEmpty &&
            // المصادر الرياضية المتخصّصة تُقبل كاملة؛ العامة تُصفّى
            (sportsOnly || _isSports(a.title, a.description ?? '')))
        .toList();
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
