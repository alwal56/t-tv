import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/channel.dart';
import '../providers/channels_provider.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';
import 'player_screen.dart';

/// شاشة تصفّح القنوات بنمط مرتضى — خلفية ملوّنة + شبكة بطاقات.
/// [groupFilters] قائمة كلمات؛ تُعرض القنوات التي تحتوي مجموعتها أياً منها.
/// إذا كانت فارغة تُعرض كل القنوات.
class ChannelsScreen extends StatefulWidget {
  final String title;
  final Color accent;
  final String? bgImage;
  final List<String> groupFilters;

  const ChannelsScreen({
    super.key,
    required this.title,
    required this.accent,
    this.bgImage,
    this.groupFilters = const [],
  });

  @override
  State<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends State<ChannelsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _matchesGroup(Channel ch) {
    if (widget.groupFilters.isEmpty) return true;
    final g = (ch.group ?? '').toLowerCase();
    return widget.groupFilters.any((f) => g.contains(f.toLowerCase()));
  }

  void _play(Channel ch, PlayerProvider playerP) {
    playerP.playChannel(ch);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PlayerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          // خلفية ملوّنة خافتة
          Positioned.fill(child: _buildBackdrop()),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildSearch(),
                Expanded(child: _buildGrid()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackdrop() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            widget.accent.withOpacity(0.22),
            AppTheme.surface,
            AppTheme.surface,
          ],
          stops: const [0, 0.4, 1],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Container(
            width: 6,
            height: 26,
            decoration: BoxDecoration(
              color: widget.accent,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            widget.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'ابحث في ${widget.title}...',
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppTheme.textSecondary, size: 20),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      color: AppTheme.textSecondary, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return Consumer2<ChannelsProvider, PlayerProvider>(
      builder: (_, channelsP, playerP, __) {
        if (channelsP.state == LoadingState.loading &&
            channelsP.allChannels.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppTheme.accent),
                const SizedBox(height: 14),
                Text(
                  channelsP.loadingLabel.isNotEmpty
                      ? channelsP.loadingLabel
                      : 'جاري التحميل...',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          );
        }

        var list = channelsP.allChannels.where(_matchesGroup).toList();
        if (_query.isNotEmpty) {
          list = list
              .where((c) => c.name.toLowerCase().contains(_query))
              .toList();
        }

        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tv_off_rounded,
                    size: 60, color: AppTheme.textSecondary.withOpacity(0.4)),
                const SizedBox(height: 12),
                const Text('لا توجد قنوات',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ],
            ),
          );
        }

        final width = MediaQuery.of(context).size.width;
        final cols = width > 1100
            ? 6
            : width > 800
                ? 5
                : width > 500
                    ? 4
                    : 3;

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.78,
          ),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final ch = list[i];
            return _ChannelCard(
              channel: ch,
              accent: widget.accent,
              isPlaying: playerP.currentChannel?.id == ch.id,
              onTap: () => _play(ch, playerP),
              onFav: () => channelsP.toggleFavorite(ch),
            );
          },
        );
      },
    );
  }
}

class _ChannelCard extends StatelessWidget {
  final Channel channel;
  final Color accent;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onFav;

  const _ChannelCard({
    required this.channel,
    required this.accent,
    required this.isPlaying,
    required this.onTap,
    required this.onFav,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1C),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isPlaying ? accent : Colors.white10,
                      width: isPlaying ? 2 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: (channel.logo != null && channel.logo!.isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl: channel.logo!,
                            fit: BoxFit.contain,
                            errorWidget: (_, __, ___) => _fallback(),
                            placeholder: (_, __) => _fallback(),
                          )
                        : _fallback(),
                  ),
                ),
                if (isPlaying)
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
                      child: const Text('LIVE',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: onFav,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        channel.isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 13,
                        color:
                            channel.isFavorite ? Colors.red : Colors.white70,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            channel.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isPlaying ? accent : Colors.white,
              fontSize: 11,
              fontWeight: isPlaying ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback() => Center(
        child: Icon(Icons.live_tv_rounded,
            color: accent.withOpacity(0.5), size: 34),
      );
}
