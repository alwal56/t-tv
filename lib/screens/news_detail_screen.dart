// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html show window;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/news_article.dart';
import '../theme/app_theme.dart';

/// قارئ المقال داخل التطبيق — يعرض الصورة والعنوان والنص بدون مغادرة التطبيق.
class NewsDetailScreen extends StatelessWidget {
  final NewsArticle article;
  const NewsDetailScreen({super.key, required this.article});

  void _openSource() {
    if (kIsWeb) {
      try {
        html.window.open(article.url, '_blank');
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _htmlToText(article.bodyHtml);
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          // ── صورة علوية مع زر رجوع ──
          SliverAppBar(
            expandedHeight: article.imageUrl != null ? 240 : 0,
            pinned: true,
            backgroundColor: AppTheme.secondary,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: article.imageUrl != null
                ? FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: article.imageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              Container(color: AppTheme.cardBg),
                          placeholder: (_, __) =>
                              Container(color: AppTheme.cardBg),
                        ),
                        // تدرّج سفلي
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Color(0xCC0E0E0E)],
                              stops: [0.55, 1],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
          ),

          // ── محتوى المقال ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // المصدر + الوقت + شارة انتقال
                  Row(
                    children: [
                      if (article.isTransfer) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.sportGreen.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('انتقال',
                              style: TextStyle(
                                  color: AppTheme.sportGreen,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(article.source,
                            style: const TextStyle(
                                color: AppTheme.accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                      const Spacer(),
                      if (article.pubDate != null)
                        Text(_timeAgo(article.pubDate!),
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // العنوان
                  Text(
                    article.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFF222222), height: 1),
                  const SizedBox(height: 16),
                  // النص
                  if (body.isNotEmpty)
                    Text(
                      body,
                      style: const TextStyle(
                        color: Color(0xFFD8D8D8),
                        fontSize: 15,
                        height: 1.9,
                      ),
                    )
                  else
                    const Text(
                      'لا يتوفّر نص كامل لهذا الخبر من المصدر.',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 14),
                    ),
                  const SizedBox(height: 28),
                  // رابط المصدر الأصلي (اختياري)
                  Center(
                    child: TextButton.icon(
                      onPressed: _openSource,
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text('فتح الخبر في المصدر الأصلي'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                      ),
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

  // ─── HTML → نص نظيف ───────────────────────────────────────────────────────

  static String _htmlToText(String html) {
    if (html.isEmpty) return '';
    var s = html;
    // إزالة سكربت وستايل
    s = s.replaceAll(
        RegExp(r'<(script|style)[^>]*>.*?</\1>',
            caseSensitive: false, dotAll: true),
        '');
    // تحويل الفواصل الكتلية إلى أسطر
    s = s.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    s = s.replaceAll(
        RegExp(r'</(p|div|li|h[1-6])>', caseSensitive: false), '\n\n');
    // إزالة بقية الوسوم
    s = s.replaceAll(RegExp(r'<[^>]+>'), '');
    // فك ترميز الكيانات الشائعة
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
    // تنظيف الأسطر الزائدة
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
