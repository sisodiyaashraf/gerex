import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:gerex/core/theme/app_theme.dart';
import 'package:gerex/core/providers/notification_provider.dart';
import 'package:gerex/core/presentation/widgets/gerex_avatar.dart';
import 'package:gerex/features/metrics/presentation/widgets/streak_flame_widget.dart';

/// Unified Modern App Bar System for Gerex.
/// Supports Standard Mode (Fixed height PreferredSizeWidget) and Large-Title Mode (Collapsible Sliver).
class GerexAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final bool isTransparent;
  final double height;

  const GerexAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.showBackButton = true,
    this.onBack,
    this.actions,
    this.isTransparent = false,
    this.height = 56.0,
  });

  /// Standard Compact Mode Constructor
  const GerexAppBar.standard({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.showBackButton = true,
    this.onBack,
    this.actions,
    this.isTransparent = false,
    this.height = 56.0,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final shouldShowBack = showBackButton && (canPop || onBack != null);

    final textColorPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textColorSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    final backgroundColor = isTransparent
        ? Colors.transparent
        : (isDark
            ? const Color(0xFF0F141C).withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.88));

    return Container(
      height: height + topPadding,
      padding: EdgeInsets.only(top: topPadding),
      decoration: BoxDecoration(
        color: isTransparent ? Colors.transparent : Colors.black.withValues(alpha: 0.01),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: isTransparent
              ? ImageFilter.blur(sigmaX: 0, sigmaY: 0)
              : ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  color: backgroundColor,
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Leading Widget or Back Button
                      if (leading != null) ...[
                        leading!,
                        const SizedBox(width: 12),
                      ] else if (shouldShowBack) ...[
                        GerexAppBarBackButton(onPressed: onBack),
                        const SizedBox(width: 12),
                      ],

                      // Title & Optional Subtitle / Breadcrumb
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                              Text(
                                subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: textColorSecondary,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 1),
                            ],
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: subtitle != null ? 17.0 : 18.5,
                                fontWeight: FontWeight.w700,
                                color: textColorPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Custom Actions or Default Actions
                      if (actions != null && actions!.isNotEmpty) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: actions!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Signature Thin Shimmer Gradient Bottom Border
              if (!isTransparent) const GerexShimmerGradientBorder(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Collapsible Large-Title Mode Sliver App Bar Widget
class SliverGerexAppBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final double expandedHeight;
  final bool pinned;
  final bool floating;
  final Widget? flexibleBackground;

  const SliverGerexAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.showBackButton = false,
    this.onBack,
    this.actions,
    this.expandedHeight = 96.0,
    this.pinned = true,
    this.floating = false,
    this.flexibleBackground,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final minHeight = kToolbarHeight + topPadding;
    final maxHeight = expandedHeight + topPadding;

    return SliverPersistentHeader(
      pinned: pinned,
      floating: floating,
      delegate: _SliverGerexAppBarDelegate(
        minHeight: minHeight,
        maxHeight: maxHeight,
        title: title,
        subtitle: subtitle,
        leading: leading,
        showBackButton: showBackButton,
        onBack: onBack,
        actions: actions,
        flexibleBackground: flexibleBackground,
      ),
    );
  }
}

class _SliverGerexAppBarDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final String title;
  final String? subtitle;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final Widget? flexibleBackground;

  _SliverGerexAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.title,
    this.subtitle,
    this.leading,
    this.showBackButton = false,
    this.onBack,
    this.actions,
    this.flexibleBackground,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final topPadding = MediaQuery.of(context).padding.top;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final shouldShowBack = showBackButton && (canPop || onBack != null);

    // Calculate collapse progress: 0.0 = fully expanded, 1.0 = fully collapsed
    final delta = maxHeight - minHeight;
    final collapseRatio = delta > 0 ? (shrinkOffset / delta).clamp(0.0, 1.0) : 1.0;

    final textColorPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textColorSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    final glassAlpha = (0.15 + (collapseRatio * 0.73)).clamp(0.0, 0.90);
    final glassColor = isDark
        ? const Color(0xFF0F141C).withValues(alpha: glassAlpha)
        : Colors.white.withValues(alpha: glassAlpha);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 10.0 * collapseRatio,
          sigmaY: 10.0 * collapseRatio,
        ),
        child: Container(
          color: glassColor,
          child: Stack(
            children: [
              // Optional Custom Flexible Background
              if (flexibleBackground != null)
                Opacity(
                  opacity: (1.0 - collapseRatio).clamp(0.0, 1.0),
                  child: flexibleBackground!,
                ),

              // Main Header Layout containing Avatar, Greeting & Name, Actions
              Positioned(
                top: topPadding,
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // Top Right Action Buttons (Always Pinned in Header)
                      if (actions != null && actions!.isNotEmpty)
                        Positioned(
                          top: (kToolbarHeight - 38) / 2,
                          right: 0,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: actions!,
                          ),
                        ),

                      // Avatar + Greeting Subtitle & Name Title Column
                      Positioned(
                        top: Tween<double>(
                          begin: ((maxHeight - topPadding) - 44) / 2,
                          end: (kToolbarHeight - 42) / 2,
                        ).transform(collapseRatio),
                        left: 0,
                        right: actions != null && actions!.isNotEmpty ? 115.0 : 0.0,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Leading / Avatar / Back Button
                            if (leading != null) ...[
                              leading!,
                              const SizedBox(width: 10),
                            ] else if (shouldShowBack) ...[
                              GerexAppBarBackButton(onPressed: onBack),
                              const SizedBox(width: 10),
                            ],

                            // Subtitle (e.g. "Good Afternoon 🌤️") & Title (e.g. "Ashraf")
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                                    Text(
                                      subtitle!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: Tween<double>(begin: 12.0, end: 10.5).transform(collapseRatio),
                                        fontWeight: FontWeight.w600,
                                        color: textColorSecondary,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                  ],
                                  Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      fontSize: Tween<double>(begin: 20.0, end: 17.0).transform(collapseRatio),
                                      fontWeight: FontWeight.w800,
                                      color: textColorPrimary,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Signature Thin Shimmer Gradient Bottom Border
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: GerexShimmerGradientBorder(opacity: collapseRatio),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverGerexAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        title != oldDelegate.title ||
        subtitle != oldDelegate.subtitle ||
        actions != oldDelegate.actions;
  }
}

/// Sleek Back Button with generous tap target and subtle haptic feedback.
class GerexAppBarBackButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const GerexAppBarBackButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          if (onPressed != null) {
            onPressed!();
          } else {
            context.pop();
          }
        },
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.08),
              width: 1.0,
            ),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 17,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

/// Lightweight Animated Shimmer Gradient Underline Signature Border
class GerexShimmerGradientBorder extends StatefulWidget {
  final double opacity;

  const GerexShimmerGradientBorder({super.key, this.opacity = 1.0});

  @override
  State<GerexShimmerGradientBorder> createState() => _GerexShimmerGradientBorderState();
}

class _GerexShimmerGradientBorderState extends State<GerexShimmerGradientBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.opacity <= 0.0) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final animVal = _controller.value;
        return Opacity(
          opacity: widget.opacity,
          child: Container(
            height: 1.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accentEmeraldLight.withValues(alpha: 0.3 + (animVal * 0.4)),
                  const Color(0xFF10B981),
                  const Color(0xFF3B82F6).withValues(alpha: 0.3 + ((1.0 - animVal) * 0.4)),
                ],
                begin: Alignment(-1.0 + (animVal * 0.5), 0),
                end: Alignment(1.0 - (animVal * 0.5), 0),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Pre-packaged Notification Bell Action with Live Unread Badge Counter
class GerexNotificationAction extends StatelessWidget {
  final VoidCallback? onTap;

  const GerexNotificationAction({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final notifications = Provider.of<NotificationProvider>(context);
    final unreadCount = notifications.unreadCount;

    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          FaIcon(
            FontAwesomeIcons.bell,
            size: 18,
            color: isDark ? Colors.white70 : const Color(0xFF334155),
          ),
          if (unreadCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(3.5),
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 15,
                  minHeight: 15,
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      onPressed: onTap ?? () => context.push('/notifications'),
    );
  }
}

/// Pre-packaged Streak Counter Action Pill
class GerexStreakAction extends StatelessWidget {
  final int streakCount;
  final bool isTodayLogged;
  final VoidCallback? onTap;

  const GerexStreakAction({
    super.key,
    required this.streakCount,
    this.isTodayLogged = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (streakCount <= 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap ?? () => context.push('/metrics'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        margin: const EdgeInsets.only(right: 6),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF261D15).withValues(alpha: 0.9)
              : const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFF97316).withValues(alpha: 0.5),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: StreakFlameWidget(
                streakCount: streakCount,
                isTodayLogged: isTodayLogged,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '$streakCount',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFF97316),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pre-packaged Profile Avatar Action
class GerexAvatarAction extends StatelessWidget {
  final String? photoUrl;
  final String? displayName;
  final VoidCallback? onTap;

  const GerexAvatarAction({
    super.key,
    this.photoUrl,
    this.displayName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = displayName ?? 'Athlete';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'G';

    return GestureDetector(
      onTap: onTap ?? () => context.push('/profile'),
      child: Container(
        margin: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.accentEmeraldLight,
                    Color(0xFF3B82F6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(2.0),
              child: GerexAvatar(
                imageUrl: photoUrl,
                initials: initials,
                size: 32,
                onTap: onTap ?? () => context.push('/profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
