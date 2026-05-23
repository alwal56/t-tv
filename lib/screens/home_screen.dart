import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../providers/channels_provider.dart';
import '../providers/player_provider.dart';
import '../models/channel.dart';
import '../services/epg_service.dart';
import '../theme/app_theme.dart';
import '../widgets/channel_tile.dart';
import 'player_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  int _currentTab = 0; // 0=Home, 1=Search, 2=Favorites, 3=Settings

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChannelsProvider>().init();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;
    return isWide ? _buildWideLayout() : _buildMobileLayout();
  }

  // ─── Wide Layout (Desktop / Web) ────────────────────────────────────────────

  Widget _buildWideLayout() {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Row(
        children: [
          _buildSidebar(),
          SizedBox(width: 320, child: _buildChannelPanel()),
          Expanded(child: _buildPlayerArea()),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Consumer<ChannelsProvider>(
      builder: (_, provider, __) => Container(
        width: 200,
        color: AppTheme.secondary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: _buildLogoRow(),
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: provider.categories.map((cat) {
                  final isSelected = provider.selectedCategory == cat;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.accent.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      leading: Icon(
                        _categoryIcon(cat),
                        color: isSelected
                            ? AppTheme.accent
                            : AppTheme.textSecondary,
                        size: 18,
                      ),
                      title: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected
                              ? AppTheme.accent
                              : AppTheme.textPrimary,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                      onTap: () => provider.setCategory(cat),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.settings_rounded,
                  color: AppTheme.textSecondary, size: 20),
              title: const Text('الإعدادات',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('إضافة مصدر'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: const TextStyle(fontSize: 13),
                ),
                onPressed: _showAddSourceSheet,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelPanel() {
    return Container(
      color: AppTheme.secondary,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: _buildSearchField(),
          ),
          Consumer<ChannelsProvider>(
            builder: (_, provider, __) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    '${provider.channels.length} قناة',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  if (provider.isLoading) ...[
                    const SizedBox(width: 8),
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.accent),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Expanded(child: _buildWideChannelList()),
        ],
      ),
    );
  }

  Widget _buildWideChannelList() {
    return Consumer2<ChannelsProvider, PlayerProvider>(
      builder: (_, channelsP, playerP, __) {
        if (channelsP.state == LoadingState.loading &&
            channelsP.channels.isEmpty) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.accent));
        }
        if (channelsP.channels.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.tv_off_rounded,
                    size: 48, color: AppTheme.textSecondary),
                const SizedBox(height: 12),
                const Text('لا توجد قنوات',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ],
            ),
          );
        }

        // ── Grouped by sub-category when a parent is selected (no search) ──
        final cat = channelsP.selectedCategory;
        final useGroups = cat != 'الكل' &&
            cat != 'المفضلة' &&
            _searchController.text.isEmpty;

        if (useGroups) {
          final groups = _buildGroups(channelsP.channels);
          final items = <Widget>[];
          for (final entry in groups) {
            final subName = entry.key.contains(' | ')
                ? entry.key.split(' | ').last
                : entry.key;
            items.add(_buildWidePanelSubHeader(subName, entry.value.length));
            for (final ch in entry.value) {
              items.add(ChannelTile(
                channel: ch,
                isSelected: playerP.currentChannel?.id == ch.id,
                onTap: () => _playChannel(ch, playerP),
                onFavoriteToggle: () => channelsP.toggleFavorite(ch),
              ));
            }
          }
          return ListView(
            padding: const EdgeInsets.only(top: 6, bottom: 16),
            children: items,
          );
        }

        // ── Flat list for "الكل", "المفضلة", or active search ──────────────
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: channelsP.channels.length,
          itemBuilder: (_, i) {
            final ch = channelsP.channels[i];
            return ChannelTile(
              channel: ch,
              isSelected: playerP.currentChannel?.id == ch.id,
              onTap: () => _playChannel(ch, playerP),
              onFavoriteToggle: () => channelsP.toggleFavorite(ch),
            );
          },
        );
      },
    );
  }

  /// Sub-category folder header inside the wide channel panel.
  Widget _buildWidePanelSubHeader(String name, int count) {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 2),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      decoration: BoxDecoration(
        color: AppTheme.accent.withOpacity(0.07),
        border: Border(
          left: BorderSide(color: AppTheme.accent.withOpacity(0.6), width: 3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.folder_rounded,
              color: AppTheme.accent.withOpacity(0.8), size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: AppTheme.accent,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerArea() {
    return Consumer<PlayerProvider>(
      builder: (_, player, __) {
        if (player.currentChannel == null) {
          return Container(
            color: AppTheme.surface,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.live_tv_rounded,
                        size: 40, color: AppTheme.accent),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'اختر قناة للمشاهدة',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('أضف قائمة M3U أو Xtream'),
                    onPressed: _showAddSourceSheet,
                  ),
                ],
              ),
            ),
          );
        }
        return const PlayerScreen(inline: true);
      },
    );
  }

  // ─── Mobile Layout (Netflix / Buz TV style) ─────────────────────────────────

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: IndexedStack(
        index: _currentTab,
        children: [
          _buildHomeTab(),
          _buildSearchTab(),
          _buildFavoritesTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        border:
            Border(top: BorderSide(color: Color(0xFF2A2A2A), width: 0.5)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentTab,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppTheme.accent,
        unselectedItemColor: const Color(0xFF666666),
        selectedLabelStyle:
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        onTap: (i) {
          if (i == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
            return;
          }
          setState(() => _currentTab = i);
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded), label: 'الرئيسية'),
          BottomNavigationBarItem(
              icon: Icon(Icons.search_rounded), label: 'البحث'),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite_rounded), label: 'المفضلة'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded), label: 'الإعدادات'),
        ],
      ),
    );
  }

  // ─── Home Tab ────────────────────────────────────────────────────────────────

  Widget _buildHomeTab() {
    return Consumer2<ChannelsProvider, PlayerProvider>(
      builder: (_, channelsP, playerP, __) {
        // Full-screen loading
        if (channelsP.state == LoadingState.loading &&
            channelsP.allChannels.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppTheme.accent),
                const SizedBox(height: 16),
                Text(
                  channelsP.loadingLabel.isNotEmpty
                      ? channelsP.loadingLabel
                      : 'جاري تحميل القنوات...',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          );
        }

        // Build category groups from all channels
        final grouped = _buildGroups(channelsP.allChannels);

        // Build a flat widget list: section headers + sub-category rows
        final List<Widget> homeRows = [];
        String? lastParent;
        for (final entry in grouped) {
          final fullGroup = entry.key;
          final hasPipe   = fullGroup.contains(' | ');
          final parent    = hasPipe ? fullGroup.split(' | ').first : null;
          final subName   = hasPipe ? fullGroup.split(' | ').last  : fullGroup;
          if (parent != null && parent != lastParent) {
            homeRows.add(_buildSectionHeader(parent));
            lastParent = parent;
          }
          homeRows.add(_buildCategoryRow(subName, entry.value, playerP, channelsP));
        }

        return CustomScrollView(
          slivers: [
            // ── App bar overlaid on hero ──────────────────────────────────
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  // Hero section
                  _buildHeroSection(playerP, channelsP),
                  // App bar (transparent, overlaid)
                  _buildNetflixAppBar(),
                ],
              ),
            ),

            // ── Loading progress bar ──────────────────────────────────────
            if (channelsP.isLoading && channelsP.allChannels.isNotEmpty)
              SliverToBoxAdapter(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.accent),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          channelsP.loadingLabel,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Category rows or empty state ──────────────────────────────
            if (homeRows.isEmpty && !channelsP.isLoading)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => homeRows[i],
                  childCount: homeRows.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        );
      },
    );
  }

  /// Groups channels by their full group-title, sorted by parent → sub order.
  List<MapEntry<String, List<Channel>>> _buildGroups(List<Channel> channels) {
    final map = <String, List<Channel>>{};
    for (final ch in channels) {
      final g = ch.group ?? 'عام';
      map.putIfAbsent(g, () => []).add(ch);
    }

    const parentOrder = ['رياضة', 'أخبار', 'عربية', 'ترفيه'];
    final subOrder = <String, List<String>>{
      'رياضة': ['الكأس', 'ثمانية', 'شاهد', 'سعودية', 'إماراتية', 'كويتية', 'خليجية', 'دولية'],
      'أخبار': ['الجزيرة', 'العربية', 'أخرى', 'دولية'],
      'عربية': ['MBC', 'سعودية', 'قطرية', 'كويتية', 'دولية'],
      'ترفيه': ['beIN', 'أفلام', 'مسلسلات', 'موسيقى'],
    };

    final entries = map.entries.toList();
    entries.sort((a, b) {
      final aParent = a.key.contains(' | ') ? a.key.split(' | ').first : a.key;
      final bParent = b.key.contains(' | ') ? b.key.split(' | ').first : b.key;
      final aSub    = a.key.contains(' | ') ? a.key.split(' | ').last  : '';
      final bSub    = b.key.contains(' | ') ? b.key.split(' | ').last  : '';

      final aParentIdx = parentOrder.indexOf(aParent);
      final bParentIdx = parentOrder.indexOf(bParent);
      if (aParentIdx != bParentIdx) {
        if (aParentIdx == -1) return 1;
        if (bParentIdx == -1) return -1;
        return aParentIdx.compareTo(bParentIdx);
      }

      final subs = subOrder[aParent] ?? <String>[];
      final aSubIdx = subs.indexOf(aSub);
      final bSubIdx = subs.indexOf(bSub);
      if (aSubIdx != bSubIdx) {
        if (aSubIdx == -1) return 1;
        if (bSubIdx == -1) return -1;
        return aSubIdx.compareTo(bSubIdx);
      }
      return a.key.compareTo(b.key);
    });

    return entries;
  }

  /// Section header widget shown before each new parent category.
  Widget _buildSectionHeader(String parent) {
    IconData icon;
    Color color;
    if (parent == 'رياضة') {
      icon  = Icons.sports_soccer_rounded;
      color = const Color(0xFF4CAF50);
    } else if (parent == 'أخبار') {
      icon  = Icons.newspaper_rounded;
      color = const Color(0xFF2196F3);
    } else if (parent == 'عربية') {
      icon  = Icons.tv_rounded;
      color = AppTheme.accent;
    } else if (parent == 'ترفيه') {
      icon  = Icons.movie_rounded;
      color = const Color(0xFFFF9800);
    } else {
      icon  = Icons.folder_rounded;
      color = AppTheme.accent;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 6),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            parent,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.5), Colors.transparent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetflixAppBar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xDD000000), Colors.transparent],
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 6,
        left: 16,
        right: 16,
        bottom: 14,
      ),
      child: Row(
        children: [
          _buildLogoRow(),
          const Spacer(),
          // Search icon → go to search tab
          GestureDetector(
            onTap: () => setState(() => _currentTab = 1),
            child: const Icon(Icons.search_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          // Add source
          GestureDetector(
            onTap: _showAddSourceSheet,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(Icons.add_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Hero Section ──────────────────────────────────────────────────────────

  Widget _buildHeroSection(
      PlayerProvider playerP, ChannelsProvider channelsP) {
    final channels = channelsP.allChannels;
    // Show currently playing channel, or first channel
    final featured =
        playerP.currentChannel ?? (channels.isNotEmpty ? channels.first : null);

    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          // ── Background ─────────────────────────────────────────────────
          Positioned.fill(child: _buildHeroBackground(featured)),

          // ── Bottom gradient overlay ────────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x44000000),
                    Colors.transparent,
                    Color(0xEE000000),
                  ],
                  stops: [0, 0.35, 1],
                ),
              ),
            ),
          ),

          // ── Content (bottom) ───────────────────────────────────────────
          if (featured != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // LIVE badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: Colors.white, size: 6),
                        SizedBox(width: 4),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Channel name
                  Text(
                    featured.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(color: Colors.black54, blurRadius: 12)
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // EPG program
                  if (featured.tvgId != null)
                    Builder(builder: (_) {
                      final epg =
                          EpgService.getCurrentProgram(featured.tvgId!);
                      if (epg == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${epg.title}  •  ${epg.timeRange}',
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 12),
                        ),
                      );
                    }),
                  const SizedBox(height: 14),
                  // Action buttons
                  Row(
                    children: [
                      // ▶ Watch now
                      ElevatedButton.icon(
                        icon: const Icon(Icons.play_arrow_rounded, size: 22),
                        label: Text(
                          playerP.currentChannel?.id == featured.id
                              ? 'جارٍ التشغيل'
                              : 'شاهد الآن',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          textStyle: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          playerP.playChannel(featured);
                          if (!kIsWeb) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const PlayerScreen()),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 10),
                      // ♥ Favorite
                      Consumer<ChannelsProvider>(
                        builder: (_, cp, __) => OutlinedButton.icon(
                          icon: Icon(
                            featured.isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 18,
                            color: featured.isFavorite
                                ? Colors.red
                                : Colors.white,
                          ),
                          label: Text(featured.isFavorite
                              ? 'في المفضلة'
                              : 'المفضلة'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side:
                                const BorderSide(color: Colors.white54),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            textStyle: const TextStyle(fontSize: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => cp.toggleFavorite(featured),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroBackground(Channel? featured) {
    if (featured?.logo != null && featured!.logo!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: featured.logo!,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _heroGradientBox(),
        placeholder: (_, __) => _heroGradientBox(),
      );
    }
    return _heroGradientBox();
  }

  Widget _heroGradientBox() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1040),
            AppTheme.accent.withOpacity(0.4),
            Colors.black,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.live_tv_rounded,
          size: 90,
          color: AppTheme.accent.withOpacity(0.25),
        ),
      ),
    );
  }

  // ─── Category Row ──────────────────────────────────────────────────────────

  Widget _buildCategoryRow(
    String category,
    List<Channel> channels,
    PlayerProvider playerP,
    ChannelsProvider channelsP,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${channels.length} قناة',
                  style: TextStyle(
                    color: AppTheme.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Horizontal cards
          SizedBox(
            height: 155,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 16, right: 8),
              itemCount: channels.length,
              itemBuilder: (_, i) {
                final ch = channels[i];
                return _ChannelPosterCard(
                  channel: ch,
                  isSelected: playerP.currentChannel?.id == ch.id,
                  onTap: () => _playChannel(ch, playerP),
                  onFavoriteToggle: () => channelsP.toggleFavorite(ch),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.live_tv_rounded,
              size: 72,
              color: AppTheme.accent.withOpacity(0.25)),
          const SizedBox(height: 20),
          const Text(
            'لا توجد قنوات بعد',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'أضف مصدر M3U أو Xtream Codes\nللبدء في المشاهدة',
            textAlign: TextAlign.center,
            style:
                TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_rounded),
            label: const Text('إضافة مصدر'),
            onPressed: _showAddSourceSheet,
          ),
        ],
      ),
    );
  }

  // ─── Search Tab ────────────────────────────────────────────────────────────

  Widget _buildSearchTab() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: const Text(
              'البحث',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: _buildSearchField(),
          ),
          Expanded(
            child: Consumer2<ChannelsProvider, PlayerProvider>(
              builder: (_, channelsP, playerP, __) {
                final query = _searchController.text.trim();
                if (query.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_rounded,
                            size: 72,
                            color: AppTheme.textSecondary.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        const Text(
                          'ابحث عن قناة',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }
                final results = channelsP.allChannels
                    .where((ch) => ch.name
                        .toLowerCase()
                        .contains(query.toLowerCase()))
                    .toList();
                if (results.isEmpty) {
                  return Center(
                    child: Text(
                      'لا توجد نتائج لـ "$query"',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: results.length,
                  itemBuilder: (_, i) => ChannelTile(
                    channel: results[i],
                    isSelected: playerP.currentChannel?.id == results[i].id,
                    onTap: () => _playChannel(results[i], playerP),
                    onFavoriteToggle: () =>
                        channelsP.toggleFavorite(results[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Favorites Tab ─────────────────────────────────────────────────────────

  Widget _buildFavoritesTab() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Row(
              children: [
                const Text(
                  'المفضلة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Icon(Icons.favorite_rounded,
                    color: AppTheme.accent, size: 22),
              ],
            ),
          ),
          Expanded(
            child: Consumer2<ChannelsProvider, PlayerProvider>(
              builder: (_, channelsP, playerP, __) {
                final favs =
                    channelsP.allChannels.where((c) => c.isFavorite).toList();
                if (favs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite_border_rounded,
                            size: 72,
                            color: AppTheme.textSecondary.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        const Text(
                          'لا توجد قنوات مفضلة',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'اضغط ❤ على أي قناة لإضافتها',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: favs.length,
                  itemBuilder: (_, i) => _ChannelPosterCard(
                    channel: favs[i],
                    isSelected: playerP.currentChannel?.id == favs[i].id,
                    onTap: () => _playChannel(favs[i], playerP),
                    onFavoriteToggle: () => channelsP.toggleFavorite(favs[i]),
                    compact: true,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shared Widgets ────────────────────────────────────────────────────────

  Widget _buildLogoRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF9B72F8), Color(0xFF5B3FD4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Center(
            child: Text(
              'T',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'T-TV',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (v) {
        context.read<ChannelsProvider>().search(v);
        setState(() {});
      },
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'ابحث عن قناة...',
        prefixIcon: const Icon(Icons.search_rounded,
            color: AppTheme.textSecondary, size: 20),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded,
                    color: AppTheme.textSecondary, size: 18),
                onPressed: () {
                  _searchController.clear();
                  context.read<ChannelsProvider>().search('');
                  setState(() {});
                },
              )
            : null,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  // ─── Channel Playback ──────────────────────────────────────────────────────

  void _playChannel(Channel ch, PlayerProvider playerP) {
    playerP.playChannel(ch);
    if (!kIsWeb && MediaQuery.of(context).size.width <= 800) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PlayerScreen()),
      );
    }
  }

  // ─── Add Source Bottom Sheet ───────────────────────────────────────────────

  void _showAddSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (_) => _AddSourceSheet(
        onM3uLoad: (url) =>
            context.read<ChannelsProvider>().loadPlaylist(url),
        onXtreamLoad: (server, user, pass) =>
            context.read<ChannelsProvider>().loadXtream(
                  server: server,
                  username: user,
                  password: pass,
                ),
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  IconData _categoryIcon(String cat) {
    if (cat == 'الكل')     return Icons.grid_view_rounded;
    if (cat == 'المفضلة')  return Icons.star_rounded;
    if (cat == 'رياضة')    return Icons.sports_soccer_rounded;
    if (cat == 'أخبار')    return Icons.newspaper_rounded;
    if (cat == 'عربية')    return Icons.tv_rounded;
    if (cat == 'ترفيه')    return Icons.movie_rounded;
    // fallback for legacy groups
    if (cat.contains('رياض') || cat.contains('Sport')) return Icons.sports_soccer_rounded;
    if (cat.contains('فلم')  || cat.contains('Movie')) return Icons.movie_rounded;
    if (cat.contains('خبر')  || cat.contains('News'))  return Icons.newspaper_rounded;
    if (cat.contains('موسيق')|| cat.contains('Music')) return Icons.music_note_rounded;
    return Icons.tv_rounded;
  }
}

// ─── Channel Poster Card (Netflix-style) ──────────────────────────────────────

class _ChannelPosterCard extends StatelessWidget {
  final Channel channel;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final bool compact; // true → used in grid (no fixed width)

  const _ChannelPosterCard({
    required this.channel,
    required this.isSelected,
    required this.onTap,
    required this.onFavoriteToggle,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Poster image ──────────────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.accent.withOpacity(0.18)
                        : const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.accent
                          : Colors.transparent,
                      width: isSelected ? 2 : 0,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _buildPosterImage(),
                ),
                // LIVE badge
                if (isSelected)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                // Favorite button
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: onFavoriteToggle,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        channel.isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: channel.isFavorite
                            ? Colors.red
                            : Colors.white70,
                        size: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── Channel name ───────────────────────────────────────────────
          const SizedBox(height: 6),
          Text(
            channel.name,
            style: TextStyle(
              color: isSelected ? AppTheme.accent : Colors.white,
              fontSize: 11,
              fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    if (compact) return card;

    // In horizontal list, give fixed width
    return SizedBox(
      width: 110,
      child: Padding(
        padding: const EdgeInsets.only(right: 10),
        child: card,
      ),
    );
  }

  Widget _buildPosterImage() {
    if (channel.logo != null && channel.logo!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: channel.logo!,
        fit: BoxFit.contain,
        errorWidget: (_, __, ___) => _defaultIcon(),
        placeholder: (_, __) => _defaultIcon(),
      );
    }
    return _defaultIcon();
  }

  Widget _defaultIcon() {
    return Center(
      child: Icon(
        Icons.tv_rounded,
        color: AppTheme.accent.withOpacity(0.45),
        size: 36,
      ),
    );
  }
}

// ─── Add Source Bottom Sheet ─────────────────────────────────────────────────

class _AddSourceSheet extends StatefulWidget {
  final void Function(String url) onM3uLoad;
  final void Function(String server, String user, String pass) onXtreamLoad;

  const _AddSourceSheet({
    required this.onM3uLoad,
    required this.onXtreamLoad,
  });

  @override
  State<_AddSourceSheet> createState() => _AddSourceSheetState();
}

class _AddSourceSheetState extends State<_AddSourceSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _m3uController = TextEditingController();
  final _serverController = TextEditingController();
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _passObscure = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _m3uController.dispose();
    _serverController.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.add_circle_outline_rounded,
                    color: AppTheme.accent, size: 22),
                SizedBox(width: 10),
                Text(
                  'إضافة مصدر',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppTheme.secondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabCtrl,
              indicator: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'رابط M3U'),
                Tab(text: 'Xtream Codes'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildM3uTab(),
                _buildXtreamTab(),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildM3uTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          TextField(
            controller: _m3uController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'https://example.com/playlist.m3u',
              labelText: 'رابط M3U',
              prefixIcon: Icon(Icons.link_rounded,
                  color: AppTheme.textSecondary, size: 20),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.download_rounded),
              label: const Text('تحميل القائمة'),
              onPressed: () {
                final url = _m3uController.text.trim();
                if (url.isNotEmpty) {
                  Navigator.pop(context);
                  widget.onM3uLoad(url);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXtreamTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          TextField(
            controller: _serverController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'http://server.example.com:8080',
              labelText: 'رابط الخادم',
              prefixIcon: Icon(Icons.dns_rounded,
                  color: AppTheme.textSecondary, size: 20),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _userController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'username',
                    labelText: 'اسم المستخدم',
                    prefixIcon: Icon(Icons.person_rounded,
                        color: AppTheme.textSecondary, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _passController,
                  obscureText: _passObscure,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'password',
                    labelText: 'كلمة المرور',
                    prefixIcon: const Icon(Icons.lock_rounded,
                        color: AppTheme.textSecondary, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passObscure
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: AppTheme.textSecondary,
                        size: 18,
                      ),
                      onPressed: () =>
                          setState(() => _passObscure = !_passObscure),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.login_rounded),
              label: const Text('تسجيل الدخول'),
              onPressed: () {
                final s = _serverController.text.trim();
                final u = _userController.text.trim();
                final p = _passController.text.trim();
                if (s.isNotEmpty && u.isNotEmpty && p.isNotEmpty) {
                  Navigator.pop(context);
                  widget.onXtreamLoad(s, u, p);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
