import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/player_provider.dart';
import '../services/epg_service.dart';
import '../theme/app_theme.dart';

// Conditional import: stub for Web, native (media_kit_video) for Android/Windows
import '../widgets/platform_video_stub.dart'
    if (dart.library.io) '../widgets/platform_video_native.dart';

class PlayerScreen extends StatefulWidget {
  final bool inline;
  const PlayerScreen({super.key, this.inline = false});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  NativeVideoController? _controller;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    final player = context.read<PlayerProvider>().player;
    if (player != null) {
      _controller = createVideoController(player);
    }
    _hideControlsAfterDelay();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _hideControlsAfterDelay() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _hideControlsAfterDelay();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (_, playerP, __) {
        return GestureDetector(
          onTap: _toggleControls,
          child: Container(
            color: Colors.black,
            child: Stack(
              children: [
                // ── Video ──────────────────────────────────────────────────
                Center(
                  child: _controller != null
                      ? NativeVideo(
                          controller: _controller!,
                          fit: BoxFit.contain,
                        )
                      : const SizedBox.shrink(),
                ),

                // ── Buffering ──────────────────────────────────────────────
                if (playerP.isBuffering && !playerP.hasError)
                  const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.accent,
                      strokeWidth: 3,
                    ),
                  ),

                // ── Error Overlay (black + retry) ──────────────────────────
                if (playerP.hasError) _buildErrorOverlay(playerP),

                // ── Controls ───────────────────────────────────────────────
                if (_showControls && !playerP.hasError)
                  AnimatedOpacity(
                    opacity: _showControls ? 1 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: _buildControls(playerP),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Error Overlay ─────────────────────────────────────────────────────────

  Widget _buildErrorOverlay(PlayerProvider playerP) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(36),
              ),
              child: const Icon(Icons.signal_wifi_statusbar_connected_no_internet_4_rounded,
                  color: Colors.white54, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'تعذّر تشغيل القناة',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              playerP.errorMsg,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => playerP.playChannel(playerP.currentChannel!),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Controls Overlay ──────────────────────────────────────────────────────

  Widget _buildControls(PlayerProvider playerP) {
    final channel = playerP.currentChannel;
    final epg = channel?.tvgId != null
        ? EpgService.getCurrentProgram(channel!.tvgId!)
        : null;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xCC000000),
            Colors.transparent,
            Colors.transparent,
            Color(0xCC000000),
          ],
          stops: [0, 0.25, 0.7, 1],
        ),
      ),
      child: Column(
        children: [
          // ── Top bar ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                if (!widget.inline)
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        channel?.name ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (epg != null)
                        Text(
                          '${epg.title} • ${epg.timeRange}',
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 11),
                        ),
                    ],
                  ),
                ),
                // LIVE badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.circular(5),
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
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // ── Bottom controls ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              children: [
                // Play / Pause
                IconButton(
                  icon: Icon(
                    playerP.isPlaying
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_filled_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                  onPressed: playerP.togglePlay,
                ),

                // Volume (native only)
                if (!kIsWeb) ...[
                  IconButton(
                    icon: Icon(
                      playerP.isMuted
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: playerP.toggleMute,
                  ),
                  SizedBox(
                    width: 90,
                    child: SliderTheme(
                      data: SliderThemeData(
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 12),
                        trackHeight: 3,
                        activeTrackColor: AppTheme.accent,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: Colors.white,
                        overlayColor: AppTheme.accent.withOpacity(0.2),
                      ),
                      child: Slider(
                        value: playerP.isMuted ? 0 : playerP.volume,
                        onChanged: playerP.setVolume,
                      ),
                    ),
                  ),
                ],

                const Spacer(),

                // Fullscreen
                IconButton(
                  icon: Icon(
                    playerP.isFullscreen
                        ? Icons.fullscreen_exit_rounded
                        : Icons.fullscreen_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                  onPressed: playerP.toggleFullscreen,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
