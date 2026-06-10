import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/channels_provider.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _epgController = TextEditingController();
  final _m3uController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _epgController.text = StorageService.epgUrl;
  }

  @override
  void dispose() {
    _epgController.dispose();
    _m3uController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('الإعدادات'),
        backgroundColor: AppTheme.secondary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader('المصادر والقنوات'),
          _buildRefreshCard(),
          const SizedBox(height: 8),
          _buildPlaylistsCard(),
          const SizedBox(height: 24),
          _sectionHeader('دليل البرامج (EPG)'),
          _buildEpgCard(),
          const SizedBox(height: 24),
          _sectionHeader('حول التطبيق'),
          _buildAboutCard(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.accent,
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ── Refresh / Reset ─────────────────────────────────────────────────────────

  Widget _buildRefreshCard() {
    return Consumer<ChannelsProvider>(
      builder: (_, provider, __) => _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.refresh_rounded,
                    color: AppTheme.accent, size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('تحديث القنوات الافتراضية',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                      SizedBox(height: 2),
                      Text('يُعيد تحميل جميع قوائم القنوات من المصادر',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                if (provider.isLoading)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.accent),
                  )
                else
                  ElevatedButton(
                    onPressed: () => provider.resetToDefaults(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                    child: const Text('تحديث'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tv_rounded,
                      color: AppTheme.accent, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${provider.allChannels.length} قناة  •  ${provider.playlists.length} قائمة',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  if (provider.loadingLabel.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        provider.loadingLabel,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Playlists ───────────────────────────────────────────────────────────────

  Widget _buildPlaylistsCard() {
    return Consumer<ChannelsProvider>(
      builder: (_, provider, __) => _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.playlist_play_rounded,
                    color: AppTheme.accent, size: 22),
                SizedBox(width: 10),
                Text('القوائم المضافة',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
              ],
            ),
            const SizedBox(height: 12),
            // Existing playlists
            ...provider.playlists.map((p) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: AppTheme.cardBorder, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.link_rounded,
                          color: AppTheme.textSecondary, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500)),
                            Text('${p.channelCount} قناة',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded,
                            color: AppTheme.textSecondary, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => provider.loadPlaylist(p.url),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 4),
            // Add M3U field
            TextField(
              controller: _m3uController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'https://example.com/list.m3u',
                labelText: 'أضف رابط M3U',
                prefixIcon: Icon(Icons.add_link_rounded,
                    color: AppTheme.textSecondary, size: 20),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('تحميل'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 14),
                ),
                onPressed: () {
                  final url = _m3uController.text.trim();
                  if (url.isNotEmpty) {
                    provider.loadPlaylist(url);
                    _m3uController.clear();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── EPG ─────────────────────────────────────────────────────────────────────

  Widget _buildEpgCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  color: AppTheme.accent, size: 20),
              SizedBox(width: 10),
              Text('دليل البرامج XMLTV',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _epgController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'https://example.com/epg.xml',
              labelText: 'رابط EPG',
              prefixIcon: Icon(Icons.rss_feed_rounded,
                  color: AppTheme.textSecondary, size: 20),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await StorageService.setEpgUrl(_epgController.text.trim());
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('تم حفظ رابط EPG'),
                      backgroundColor: AppTheme.accent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(fontSize: 14),
              ),
              child: const Text('حفظ'),
            ),
          ),
        ],
      ),
    );
  }

  // ── About ────────────────────────────────────────────────────────────────────

  Widget _buildAboutCard() {
    return _Card(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9B72F8), Color(0xFF5B3FD4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'T',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('T-TV',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  Text('الإصدار 1.1.0',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          _InfoRow(icon: Icons.live_tv_rounded, text: 'مشغّل IPTV متعدد المنصات'),
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.playlist_play_rounded, text: 'يدعم M3U وXtream Codes وEPG'),
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.block_rounded, text: 'بدون إعلانات تماماً'),
        ],
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder, width: 0.5),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.accent, size: 18),
        const SizedBox(width: 10),
        Text(text,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 13)),
      ],
    );
  }
}
