import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/match.dart';
import '../services/matches_service.dart';
import '../theme/app_theme.dart';

enum MatchFilter { all, live, today }

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  MatchFilter _filter = MatchFilter.live;
  late Future<List<Match>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = switch (_filter) {
      MatchFilter.live  => MatchesService.getLiveMatches(),
      MatchFilter.today => MatchesService.getTodayMatches(),
      MatchFilter.all   => MatchesService.getTodayMatches(),
    };
  }

  void _refresh() => setState(_load);

  void _setFilter(MatchFilter f) {
    if (_filter == f) return;
    setState(() {
      _filter = f;
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          _buildFilterRow(),
          const Divider(height: 1, color: Color(0xFF2A2A2A)),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
      child: Row(
        children: [
          const Icon(Icons.sports_soccer_rounded,
              color: AppTheme.accent, size: 22),
          const SizedBox(width: 10),
          const Text(
            'المباريات',
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
            onPressed: _refresh,
            tooltip: 'تحديث',
          ),
        ],
      ),
    );
  }

  // ─── Filter Row ──────────────────────────────────────────────────────────────

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _FilterChip(
            label: 'مباشر',
            icon: Icons.circle,
            iconColor: Colors.red,
            selected: _filter == MatchFilter.live,
            onTap: () => _setFilter(MatchFilter.live),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'اليوم',
            icon: Icons.today_rounded,
            selected: _filter == MatchFilter.today,
            onTap: () => _setFilter(MatchFilter.today),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'الكل',
            icon: Icons.grid_view_rounded,
            selected: _filter == MatchFilter.all,
            onTap: () => _setFilter(MatchFilter.all),
          ),
        ],
      ),
    );
  }

  // ─── Body ─────────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    return FutureBuilder<List<Match>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.accent),
          );
        }
        if (snap.hasError || !snap.hasData || snap.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sports_soccer_rounded,
                    size: 64,
                    color: AppTheme.textSecondary.withOpacity(0.3)),
                const SizedBox(height: 16),
                Text(
                  _filter == MatchFilter.live
                      ? 'لا توجد مباريات مباشرة الآن'
                      : 'لا توجد مباريات',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 15),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('إعادة المحاولة'),
                  onPressed: _refresh,
                ),
              ],
            ),
          );
        }

        final matches = snap.data!;
        // Filter live if needed
        final filtered = _filter == MatchFilter.live
            ? matches.where((m) => m.isLive).toList()
            : matches;

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sports_soccer_rounded,
                    size: 64,
                    color: AppTheme.textSecondary.withOpacity(0.3)),
                const SizedBox(height: 16),
                const Text('لا توجد مباريات مباشرة الآن',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 15)),
              ],
            ),
          );
        }

        // Group by tournament
        final groups = <String, List<Match>>{};
        for (final m in filtered) {
          groups.putIfAbsent(m.tournament, () => []).add(m);
        }

        return RefreshIndicator(
          color: AppTheme.accent,
          onRefresh: () async => _refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: groups.length,
            itemBuilder: (_, i) {
              final entry = groups.entries.elementAt(i);
              return _TournamentSection(
                tournament: entry.key,
                matches: entry.value,
              );
            },
          ),
        );
      },
    );
  }
}

// ─── Filter Chip ────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? iconColor;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    this.iconColor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.accent.withOpacity(0.18)
              : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.accent : const Color(0xFF333333),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: iconColor ??
                  (selected ? AppTheme.accent : AppTheme.textSecondary),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppTheme.accent : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tournament Section ──────────────────────────────────────────────────────────

class _TournamentSection extends StatelessWidget {
  final String tournament;
  final List<Match> matches;

  const _TournamentSection({
    required this.tournament,
    required this.matches,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // League header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: const Color(0xFF111111),
          child: Row(
            children: [
              const Icon(Icons.emoji_events_rounded,
                  color: Color(0xFFFFD700), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tournament,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${matches.length} مباراة',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
        // Match rows
        ...matches.map(_MatchRow.new),
      ],
    );
  }
}

// ─── Match Row ───────────────────────────────────────────────────────────────────

class _MatchRow extends StatelessWidget {
  final Match match;
  const _MatchRow(this.match);

  @override
  Widget build(BuildContext context) {
    final isLive = match.isLive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isLive
            ? Colors.red.withOpacity(0.04)
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(
              color: const Color(0xFF1F1F1F), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Home team
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _TeamLogo(match.homeLogo),
                const SizedBox(height: 4),
                Text(
                  match.homeTeam,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Score / time
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _ScoreBox(match),
          ),
          // Away team
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TeamLogo(match.awayLogo),
                const SizedBox(height: 4),
                Text(
                  match.awayTeam,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Team Logo ────────────────────────────────────────────────────────────────────

class _TeamLogo extends StatelessWidget {
  final String url;
  const _TeamLogo(this.url);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 36,
        height: 36,
        child: CachedNetworkImage(
          imageUrl: url,
          errorWidget: (_, __, ___) => const Icon(
            Icons.sports_soccer_rounded,
            color: AppTheme.textSecondary,
            size: 24,
          ),
          placeholder: (_, __) => const SizedBox(),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

// ─── Score Box ────────────────────────────────────────────────────────────────────

class _ScoreBox extends StatelessWidget {
  final Match match;
  const _ScoreBox(this.match);

  @override
  Widget build(BuildContext context) {
    if (match.isUpcoming) {
      // Show time
      final h = match.startTime.toLocal().hour.toString().padLeft(2, '0');
      final m = match.startTime.toLocal().minute.toString().padLeft(2, '0');
      return Column(
        children: [
          Text('$h:$m',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          const Text('قادمة',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 9)),
        ],
      );
    }

    final hs = match.homeScore ?? 0;
    final as_ = match.awayScore ?? 0;

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$hs',
                style: TextStyle(
                  color: hs > as_ ? Colors.white : AppTheme.textSecondary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                )),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '-',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                ),
              ),
            ),
            Text('$as_',
                style: TextStyle(
                  color: as_ > hs ? Colors.white : AppTheme.textSecondary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                )),
          ],
        ),
        const SizedBox(height: 3),
        if (match.isLive)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.circle, color: Colors.white, size: 5),
                const SizedBox(width: 3),
                Text(
                  match.statusText.isNotEmpty ? match.statusText : 'LIVE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        else
          Text(
            'انتهت',
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 10),
          ),
      ],
    );
  }
}
