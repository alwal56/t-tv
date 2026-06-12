import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/news_article.dart';
import '../services/cors_proxy.dart';
import '../services/web_interop.dart';
import '../theme/app_theme.dart';

/// قارئ المقال داخل التطبيق — يعرض النص كاملاً بدون مغادرة التطبيق.
class NewsDetailScreen extends StatefulWidget {
  final NewsArticle article;
  const NewsDetailScreen({super.key, required this.article});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  late String _body;          // النص المعروض حالياً
  bool _loadingFull = false;  // جاري جلب النص الكامل

  @override
  void initState() {
    super.initState();
    _body = _htmlToText(widget.article.bodyHtml);
    // إذا كان النص قصيراً (ملخّص فقط) نحاول جلب المقال الكامل
    if (_body.length < 600) {
      _fetchFull();
    }
  }

  Future<void> _fetchFull() async {
    setState(() => _loadingFull = true);
    try {
      final html = await CorsProxy.fetch(
        widget.article.url,
        isValid: (b) => b.length > 500,
      );
      if (html != null) {
        final extracted = _extractArticle(html);
        if (extracted.length > _body.length) {
          if (!mounted) return;
          setState(() => _body = extracted);
        }
      }
    } catch (_) {
      // نبقي على الملخّص إذا فشل الجلب
    } finally {
      if (mounted) setState(() => _loadingFull = false);
    }
  }

  void _openSource() {
    WebInterop.openUrl(widget.article.url);
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.article;
    final hasImg = a.imageUrl != null && a.imageUrl!.isNotEmpty;
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          // ── شريط علوي ثابت مع زر رجوع واضح ──
          SliverAppBar(
            expandedHeight: hasImg ? 240 : 0,
            collapsedHeight: 56,
            pinned: true,
            backgroundColor: AppTheme.secondary,
            elevation: 2,
            automaticallyImplyLeading: false,
            titleSpacing: 0,
            title: Row(
              children: [
                _BackButton(onTap: () => Navigator.pop(context)),
                Expanded(
                  child: Text(
                    a.source,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: 'فتح في المصدر',
                  icon: const Icon(Icons.open_in_new_rounded,
                      color: AppTheme.textSecondary, size: 20),
                  onPressed: _openSource,
                ),
              ],
            ),
            flexibleSpace: hasImg
                ? FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: a.imageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              Container(color: AppTheme.cardBg),
                          placeholder: (_, __) =>
                              Container(color: AppTheme.cardBg),
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Color(0xEE141414)],
                              stops: [0.5, 1],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
          ),

          // ── المحتوى ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (a.isTransfer) ...[
                        _badge('انتقال', AppTheme.sportGreen),
                        const SizedBox(width: 8),
                      ],
                      _badge(a.source, AppTheme.accent),
                      const Spacer(),
                      if (a.pubDate != null)
                        Text(_timeAgo(a.pubDate!),
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    a.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFF222222), height: 1),
                  const SizedBox(height: 16),
                  if (_body.isNotEmpty)
                    Text(
                      _body,
                      style: const TextStyle(
                        color: Color(0xFFD8D8D8),
                        fontSize: 15.5,
                        height: 2.0,
                      ),
                    ),
                  if (_loadingFull) ...[
                    const SizedBox(height: 20),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppTheme.accent),
                        ),
                        SizedBox(width: 10),
                        Text('جاري تحميل بقية الخبر...',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ],
                  if (_body.isEmpty && !_loadingFull)
                    const Text('لا يتوفّر نص لهذا الخبر.',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 14)),
                  const SizedBox(height: 28),
                  Center(
                    child: TextButton.icon(
                      onPressed: _openSource,
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text('فتح الخبر في المصدر الأصلي'),
                      style: TextButton.styleFrom(
                          foregroundColor: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.16),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      );

  // ─── استخراج نص المقال من صفحة HTML ───────────────────────────────────────

  static String _extractArticle(String htmlDoc) {
    var src = htmlDoc;
    // أزل العناصر غير النصية أولاً (سكربت/ستايل/SVG/رؤوس)
    src = src.replaceAll(
        RegExp(r'<(script|style|svg|noscript|head|nav|footer|aside)[^>]*>.*?</\1>',
            caseSensitive: false, dotAll: true),
        ' ');

    // اقتصر على <article> إن وُجدت
    final art = RegExp(r'<article[^>]*>(.*?)</article>',
            caseSensitive: false, dotAll: true)
        .firstMatch(src);
    if (art != null) src = art.group(1) ?? src;

    // اجمع فقرات <p>
    final ps = RegExp(r'<p[^>]*>(.*?)</p>',
            caseSensitive: false, dotAll: true)
        .allMatches(src);
    final buf = StringBuffer();
    final seen = <String>{};
    for (final m in ps) {
      final txt = _htmlToText(m.group(1) ?? '');
      if (txt.length < 40) continue;          // تجاهل القصير
      if (_looksLikeCode(txt)) continue;        // تجاهل CSS/JS
      if (!seen.add(txt)) continue;             // تجاهل التكرار
      buf.writeln('$txt\n');
    }
    return buf.toString().trim();
  }

  /// يكتشف ما إذا كانت الفقرة كوداً (CSS/JS) لا نصاً
  static bool _looksLikeCode(String t) {
    if (t.contains('{') && t.contains('}')) return true;
    if (t.contains('px;') || t.contains('url(') || t.contains('@media')) {
      return true;
    }
    if (t.contains('background:') || t.contains('function(') ||
        t.contains('display:') || t.contains('width:')) {
      return true;
    }
    // كثافة رموز غير حرفية عالية = كود غالباً
    final symbols = RegExp(r'[{}();:=<>/\\]').allMatches(t).length;
    if (symbols > t.length * 0.12) return true;
    return false;
  }

  static String _htmlToText(String html) {
    if (html.isEmpty) return '';
    var s = html;
    s = s.replaceAll(
        RegExp(r'<(script|style)[^>]*>.*?</\1>',
            caseSensitive: false, dotAll: true),
        '');
    s = s.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    s = s.replaceAll(
        RegExp(r'</(p|div|li|h[1-6])>', caseSensitive: false), '\n\n');
    s = s.replaceAll(RegExp(r'<[^>]+>'), '');
    s = s
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&#34;', '"')
        .replaceAll('&hellip;', '…')
        .replaceAll('&laquo;', '«')
        .replaceAll('&raquo;', '»');
    s = s.replaceAll(RegExp(r'[ \t]+'), ' ');
    s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return s.trim();
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    return 'منذ ${diff.inDays} ي';
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppTheme.accent.withOpacity(0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.accent.withOpacity(0.5)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
              SizedBox(width: 5),
              Text('رجوع',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
