// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html show window;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/news_article.dart';
import '../services/news_service.dart';
import '../theme/app_theme.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  late Future<List<NewsArticle>> _future;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _future = NewsService.getAll();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _openUrl(String url) {
    if (kIsWeb) {
      try {
        html.window.open(url, '_blank');
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(child: _buildTabBarView()),
        ],
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 10),
      child: Row(
        children: [
          const Icon(Icons.article_rounded, color: AppTheme.accent, size: 22),
          const SizedBox(width: 10),
          const Text(
            'أخبار كرة القدم',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppTheme.textSecondary, size: 22),
            onPressed: () => setState(() {
              _future = NewsService.getAll();
            }),
            tooltip: 'تحديث',
          ),
        ],
      ),
    );
  }

  // ─── Tab Bar ───────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.secondary,
      child: TabBar(
        controller: _tabs,
        indicatorColor: AppTheme.accent,
        indicatorWeight: 2.5,
        labelColor: AppTheme.accent,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 13),
        tabs: const [
          Tab(text: '📰 آخر الأخبار'),
          Tab(text: '🔄 الانتقالات'),
        ],
      ),
    );
  }

  // ─── Tab Views ─────────────────────────────────────────────────────────────

  Widget _buildTabBarView() {
    return FutureBuilder<List<NewsArticle>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.accent));
        }

        final all = snap.data ?? [];
        final news = all.where((a) => !a.isTransfer).toList();
        final transfers = all.where((a) => a.isTransfer).toList();

        return TabBarView(
          controller: _tabs,
          children: [
            _buildNewsList(news, icon: Icons.newspaper_rounded,
                emptyMsg: 'لا توجد أخبار حالياً'),
            _buildNewsList(transfers, icon: Icons.swap_horiz_rounded,
                emptyMsg: 'لا توجد أخبار انتقالات حالياً'),
          ],
        );
      },
    );
  }

  Widget _buildNewsList(
    List<NewsArticle> articles, {
    required IconData icon,
    required String emptyMsg,
  }) {
    if (articles.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 64, color: AppTheme.textSecondary.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(emptyMsg,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 14)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.accent,
      onRefresh: () async {
        setState(() => _future = NewsService.getAll());
      },
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: articles.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: Color(0xFF1F1F1F)),
        itemBuilder: (_, i) => _ArticleCard(
          article: articles[i],
          onTap: () => _openUrl(articles[i].url),
        ),
      ),
    );
  }
}

// ─── Article Card ────────────────────────────────────────────────────────────────

class _ArticleCard extends StatelessWidget {
  final NewsArticle article;
  final VoidCallback onTap;

  const _ArticleCard({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: AppTheme.accent.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            if (article.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: article.imageUrl!,
                  width: 80,
                  height: 60,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _placeholderImg(),
                  placeholder: (_, __) => _placeholderImg(),
                ),
              )
            else
              _placeholderImg(),
            const SizedBox(width: 12),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // Transfer badge
                      if (article.isTransfer) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'انتقال',
                            style: TextStyle(
                              color: AppTheme.accent,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      // Source badge
                      Text(
                        article.source,
                        style: const TextStyle(
                          color: AppTheme.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (article.pubDate != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          _timeAgo(article.pubDate!),
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                      const Spacer(),
                      const Icon(Icons.open_in_new_rounded,
                          size: 13, color: AppTheme.textSecondary),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImg() {
    return Container(
      width: 80,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.sports_soccer_rounded,
        color: AppTheme.accent.withOpacity(0.35),
        size: 28,
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    return 'منذ ${diff.inDays} ي';
  }
}
