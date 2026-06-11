import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/channels_provider.dart';
import '../theme/app_theme.dart';
import 'channels_screen.dart';
import 'matches_screen.dart';
import 'news_screen.dart';
import 'settings_screen.dart';

/// الشاشة الرئيسية بنمط مرتضى TV — بطاقات أقسام كبيرة بخلفيات.
class MortadaHome extends StatelessWidget {
  const MortadaHome({super.key});

  // كلمات تصنيف القنوات الرياضية
  static const _sportFilters = [
    'رياض', 'الكأس', 'كأس', 'sport', 'bein', 'ssc', 'ريد', 'بحرين', 'عُمان',
  ];

  void _open(BuildContext ctx, Widget screen) {
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── مباريات اليوم ──
                  _BigCard(
                    title: 'مباريات اليوم',
                    subtitle: 'النتائج المباشرة والجداول',
                    icon: Icons.sports_soccer_rounded,
                    accent: AppTheme.sportGreen,
                    bg: 'img/bg_matches.jpg',
                    height: 150,
                    onTap: () => _open(
                      context,
                      const Scaffold(
                        backgroundColor: Colors.black,
                        body: MatchesScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // ── القنوات الرياضية ──
                  _BigCard(
                    title: 'القنوات الرياضية',
                    subtitle: 'الكأس • دبي • beIN Xtra • ريد بُل',
                    icon: Icons.live_tv_rounded,
                    accent: AppTheme.sportOrange,
                    bg: 'img/bg_sports.jpg',
                    height: 150,
                    onTap: () => _open(
                      context,
                      const ChannelsScreen(
                        title: 'القنوات الرياضية',
                        accent: AppTheme.sportOrange,
                        groupFilters: _sportFilters,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // ── القنوات المتنوعة ──
                  _BigCard(
                    title: 'قنوات متنوعة',
                    subtitle: 'أفلام • مسلسلات • أخبار • MBC • موسيقى',
                    icon: Icons.movie_filter_rounded,
                    accent: AppTheme.sportPurple,
                    bg: 'img/bg_variety.jpg',
                    height: 150,
                    onTap: () => _open(
                      context,
                      const ChannelsScreen(
                        title: 'قنوات متنوعة',
                        accent: AppTheme.sportPurple,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // ── صف الأخبار + الانتقالات ──
                  Row(
                    children: [
                      Expanded(
                        child: _SmallCard(
                          title: 'الأخبار الرياضية',
                          icon: Icons.article_rounded,
                          accent: AppTheme.gold,
                          onTap: () => _open(
                            context,
                            const Scaffold(
                              backgroundColor: Colors.black,
                              body: NewsScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _SmallCard(
                          title: 'الانتقالات',
                          icon: Icons.swap_horiz_rounded,
                          accent: AppTheme.sportGreen,
                          onTap: () => _open(
                            context,
                            const Scaffold(
                              backgroundColor: Colors.black,
                              body: NewsScreen(initialTab: 1),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 10),
      child: Row(
        children: [
          // شعار ذهبي على نمط البطولة
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.gold, Color(0xFFFF9500)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.emoji_events_rounded,
                color: Colors.black87, size: 24),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('T-TV',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
              Text('بث رياضي مباشر',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            ],
          ),
          const Spacer(),
          Consumer<ChannelsProvider>(
            builder: (_, p, __) => p.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.gold),
                  )
                : const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded,
                color: AppTheme.textSecondary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Big category card with full-bleed background ────────────────────────────

class _BigCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final String bg;
  final double height;
  final VoidCallback onTap;

  const _BigCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.bg,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // الخلفية
              Image.network(
                bg,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: accent.withOpacity(0.3)),
              ),
              // تدرّج للقراءة
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      Colors.black.withOpacity(0.82),
                      Colors.black.withOpacity(0.35),
                      accent.withOpacity(0.25),
                    ],
                  ),
                ),
              ),
              // المحتوى
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withOpacity(0.5),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(color: Colors.black, blurRadius: 8),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white.withOpacity(0.85), size: 18),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Small card (news / transfers) ───────────────────────────────────────────

class _SmallCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _SmallCard({
    required this.title,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withOpacity(0.22),
              const Color(0xFF161618),
            ],
          ),
          border: Border.all(color: accent.withOpacity(0.4)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: accent, size: 30),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
