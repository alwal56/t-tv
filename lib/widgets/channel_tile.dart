import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/channel.dart';
import '../services/epg_service.dart';
import '../theme/app_theme.dart';

class ChannelTile extends StatelessWidget {
  final Channel channel;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const ChannelTile({
    super.key,
    required this.channel,
    required this.isSelected,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final epg = channel.tvgId != null
        ? EpgService.getCurrentProgram(channel.tvgId!)
        : null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accent.withOpacity(0.18)
              : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.accent : AppTheme.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Logo
            Padding(
              padding: const EdgeInsets.all(10),
              child: _buildLogo(),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      channel.name,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppTheme.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    if (epg != null) ...[
                      Text(
                        epg.title,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: epg.progress,
                          backgroundColor: Colors.white10,
                          valueColor: const AlwaysStoppedAnimation(
                              AppTheme.accent),
                          minHeight: 2,
                        ),
                      ),
                    ] else
                      Text(
                        channel.group ?? 'عام',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 11),
                      ),
                  ],
                ),
              ),
            ),
            // Live indicator + Favorite
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4, left: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    channel.isFavorite
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: channel.isFavorite
                        ? Colors.amber
                        : AppTheme.textSecondary,
                    size: 20,
                  ),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  onPressed: onFavoriteToggle,
                ),
              ],
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.accent.withOpacity(0.2)
            : AppTheme.cardBorder.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: channel.logo != null && channel.logo!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: channel.logo!,
                fit: BoxFit.contain,
                errorWidget: (_, __, ___) => _defaultIcon(),
                placeholder: (_, __) => _defaultIcon(),
              ),
            )
          : _defaultIcon(),
    );
  }

  Widget _defaultIcon() {
    return Icon(
      Icons.tv_rounded,
      color: isSelected ? AppTheme.accent : AppTheme.textSecondary,
      size: 24,
    );
  }
}
