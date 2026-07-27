import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class GerexAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? initials;
  final double size;
  final bool hasNotification;
  final VoidCallback? onTap;

  const GerexAvatar({
    super.key,
    this.imageUrl,
    this.initials = 'GX',
    this.size = 44.0,
    this.hasNotification = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(size * 0.3); // Rounded-square frame

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: GerexGradients.darkGlassCard,
              borderRadius: borderRadius,
              border: Border.all(
                color: AppColors.accentEmeraldLight.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: borderRadius,
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildFallbackInitials(),
                    )
                  : _buildFallbackInitials(),
            ),
          ),
          if (hasNotification)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.destructiveRed,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.bgDarkPrimary,
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.destructiveRed.withValues(alpha: 0.6),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFallbackInitials() {
    return Container(
      color: AppColors.cardDarkGlass,
      child: Center(
        child: Text(
          initials ?? 'GX',
          style: TextStyle(
            color: AppColors.accentEmeraldLight,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.38,
          ),
        ),
      ),
    );
  }
}
