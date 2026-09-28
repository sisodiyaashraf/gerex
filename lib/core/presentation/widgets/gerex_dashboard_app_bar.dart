import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gerex/core/theme/app_theme.dart';
import 'package:gerex/core/presentation/widgets/gerex_avatar.dart';
import 'package:gerex/core/presentation/widgets/animated_tappable.dart';
import 'package:gerex/core/presentation/widgets/mascot_ai_hub_sheet.dart';
import 'package:gerex/features/metrics/presentation/widgets/streak_flame_widget.dart';

/// Upgraded Gerex Dashboard AppBar with ultra-premium glassmorphism,
/// interactive custom icon actions, animated streak status, AI Coach shortcut,
/// and dynamic greeting title.
class GerexDashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? userDisplayName;
  final String? userPhotoUrl;
  final int unreadNotificationsCount;
  final int streakCount;
  final bool isTodayLogged;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAiCoachTap;
  final VoidCallback? onQuickWinTap;
  final VoidCallback? onStreakTap;
  final String? title;
  final bool showGreeting;

  const GerexDashboardAppBar({
    super.key,
    this.userDisplayName,
    this.userPhotoUrl,
    this.unreadNotificationsCount = 0,
    this.streakCount = 0,
    this.isTodayLogged = false,
    this.onProfileTap,
    this.onNotificationTap,
    this.onAiCoachTap,
    this.onQuickWinTap,
    this.onStreakTap,
    this.title,
    this.showGreeting = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(68.0);

  @override
  Widget build(BuildContext context) {
    return _GerexAppBarContent(
      userDisplayName: userDisplayName,
      userPhotoUrl: userPhotoUrl,
      unreadNotificationsCount: unreadNotificationsCount,
      streakCount: streakCount,
      isTodayLogged: isTodayLogged,
      onProfileTap: onProfileTap,
      onNotificationTap: onNotificationTap,
      onAiCoachTap: onAiCoachTap,
      onQuickWinTap: onQuickWinTap,
      onStreakTap: onStreakTap,
      title: title,
      showGreeting: showGreeting,
    );
  }
}

/// Sliver version of the upgraded Gerex Dashboard AppBar for CustomScrollView
class SliverGerexDashboardAppBar extends StatelessWidget {
  final String? userDisplayName;
  final String? userPhotoUrl;
  final int unreadNotificationsCount;
  final int streakCount;
  final bool isTodayLogged;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAiCoachTap;
  final VoidCallback? onQuickWinTap;
  final VoidCallback? onStreakTap;
  final String? title;
  final bool showGreeting;
  final bool floating;
  final bool pinned;

  const SliverGerexDashboardAppBar({
    super.key,
    this.userDisplayName,
    this.userPhotoUrl,
    this.unreadNotificationsCount = 0,
    this.streakCount = 0,
    this.isTodayLogged = false,
    this.onProfileTap,
    this.onNotificationTap,
    this.onAiCoachTap,
    this.onQuickWinTap,
    this.onStreakTap,
    this.title,
    this.showGreeting = true,
    this.floating = true,
    this.pinned = false,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return SliverPersistentHeader(
      floating: floating,
      pinned: pinned,
      delegate: _SliverAppBarDelegate(
        minHeight: 68.0 + topPadding,
        maxHeight: 68.0 + topPadding,
        child: Padding(
          padding: EdgeInsets.only(top: topPadding),
          child: _GerexAppBarContent(
            userDisplayName: userDisplayName,
            userPhotoUrl: userPhotoUrl,
            unreadNotificationsCount: unreadNotificationsCount,
            streakCount: streakCount,
            isTodayLogged: isTodayLogged,
            onProfileTap: onProfileTap,
            onNotificationTap: onNotificationTap,
            onAiCoachTap: onAiCoachTap,
            onQuickWinTap: onQuickWinTap,
            onStreakTap: onStreakTap,
            title: title,
            showGreeting: showGreeting,
          ),
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}

class _GerexAppBarContent extends StatelessWidget {
  final String? userDisplayName;
  final String? userPhotoUrl;
  final int unreadNotificationsCount;
  final int streakCount;
  final bool isTodayLogged;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAiCoachTap;
  final VoidCallback? onQuickWinTap;
  final VoidCallback? onStreakTap;
  final String? title;
  final bool showGreeting;

  const _GerexAppBarContent({
    this.userDisplayName,
    this.userPhotoUrl,
    this.unreadNotificationsCount = 0,
    this.streakCount = 0,
    this.isTodayLogged = false,
    this.onProfileTap,
    this.onNotificationTap,
    this.onAiCoachTap,
    this.onQuickWinTap,
    this.onStreakTap,
    this.title,
    this.showGreeting = true,
  });

  String _getGreetingText() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 17) return 'Good Afternoon 🌤️';
    return 'Good Evening 🌙';
  }

  String _getFirstName() {
    if (userDisplayName == null || userDisplayName!.trim().isEmpty) {
      return 'Athlete';
    }
    return userDisplayName!.trim().split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final initials = _getFirstName().isNotEmpty ? _getFirstName()[0].toUpperCase() : 'G';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        const Color(0xFF181E29).withValues(alpha: 0.85),
                        const Color(0xFF0F141C).withValues(alpha: 0.90),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.88),
                        const Color(0xFFF1F5F9).withValues(alpha: 0.92),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(
                color: isDark
                    ? AppColors.accentEmeraldLight.withValues(alpha: 0.25)
                    : AppColors.accentEmeraldLight.withValues(alpha: 0.35),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                // 1. Profile Avatar Action Button with Halo Ring
                AnimatedTappable(
                  onTap: onProfileTap ?? () => context.push('/profile'),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.accentEmeraldLight,
                              Color(0xFF3B82F6),
                              Color(0xFF8B5CF6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentEmeraldLight.withValues(alpha: 0.35),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: GerexAvatar(
                          imageUrl: userPhotoUrl,
                          initials: initials,
                          size: 40,
                          hasNotification: unreadNotificationsCount > 0,
                          onTap: onProfileTap ?? () => context.push('/profile'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // 2. Title & Dynamic Greeting
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              showGreeting ? _getGreetingText() : (title ?? 'Gerex Dashboard'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.accentEmeraldLight.withValues(alpha: 0.2),
                                  const Color(0xFF10B981).withValues(alpha: 0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.accentEmeraldLight.withValues(alpha: 0.4),
                                width: 0.6,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: AppColors.accentEmeraldLight,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'PRO',
                                  style: GoogleFonts.outfit(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.accentEmeraldLight,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        showGreeting ? _getFirstName() : (title ?? 'Dashboard'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Action Icons Bar
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // A. Streak Pill Action Button (if streak > 0)
                    if (streakCount > 0) ...[
                      AnimatedTappable(
                        onTap: onStreakTap ?? () => context.push('/metrics'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF261D15).withValues(alpha: 0.8)
                                : const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFF97316).withValues(alpha: 0.4),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF97316).withValues(alpha: 0.2),
                                blurRadius: 6,
                              ),
                            ],
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
                                '${streakCount}d',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFF97316),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],

                    // B. Quick Action Lightning Icon Button
                    _GlassIconButton(
                      icon: FontAwesomeIcons.boltLightning,
                      iconSize: 14,
                      iconColor: const Color(0xFFEAB308),
                      glowColor: const Color(0xFFEAB308),
                      tooltip: 'Quick Workout',
                      onTap: onQuickWinTap ?? () => context.push('/quick-win'),
                    ),
                    const SizedBox(width: 6),

                    // C. AI Coach Mascot Magic Sparkles Icon Button
                    _GlassIconButton(
                      icon: FontAwesomeIcons.wandMagicSparkles,
                      iconSize: 14,
                      iconColor: const Color(0xFFA855F7),
                      glowColor: const Color(0xFFA855F7),
                      isGradient: true,
                      tooltip: 'AI Coach Hub',
                      onTap: onAiCoachTap ?? () => MascotAiHubBottomSheet.show(context),
                    ),
                    const SizedBox(width: 6),

                    // D. Notifications Bell Icon Button with Live Pulse & Count Badge
                    _GlassIconButton(
                      icon: FontAwesomeIcons.solidBell,
                      iconSize: 14,
                      iconColor: theme.colorScheme.onSurface,
                      glowColor: AppColors.accentEmeraldLight,
                      badgeCount: unreadNotificationsCount,
                      tooltip: 'Notifications',
                      onTap: onNotificationTap ?? () => context.push('/notifications'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Upgraded Frosted Glass Icon Button with dynamic glow, gradient option, & notification badge
class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final Color iconColor;
  final Color glowColor;
  final bool isGradient;
  final int badgeCount;
  final String tooltip;
  final VoidCallback onTap;

  const _GlassIconButton({
    required this.icon,
    this.iconSize = 14,
    required this.iconColor,
    required this.glowColor,
    this.isGradient = false,
    this.badgeCount = 0,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Tooltip(
      message: tooltip,
      child: AnimatedTappable(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isGradient
                    ? LinearGradient(
                        colors: [
                          glowColor.withValues(alpha: 0.35),
                          const Color(0xFF6366F1).withValues(alpha: 0.25),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: !isGradient
                    ? (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.04))
                    : null,
                border: Border.all(
                  color: glowColor.withValues(alpha: isGradient ? 0.6 : 0.25),
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withValues(alpha: isGradient ? 0.3 : 0.1),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Center(
                child: FaIcon(
                  icon,
                  size: iconSize,
                  color: isGradient ? Colors.white : iconColor,
                ),
              ),
            ),

            // Notification Badge Bubble with Pulse Red Glow
            if (badgeCount > 0)
              Positioned(
                top: -2,
                right: -2,
                child: _PulsingBadge(count: badgeCount),
              ),
          ],
        ),
      ),
    );
  }
}

class _PulsingBadge extends StatefulWidget {
  final int count;

  const _PulsingBadge({required this.count});

  @override
  State<_PulsingBadge> createState() => _PulsingBadgeState();
}

class _PulsingBadgeState extends State<_PulsingBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final countText = widget.count > 99 ? '99+' : widget.count.toString();

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
        decoration: BoxDecoration(
          color: AppColors.destructiveRed,
          shape: widget.count < 10 ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: widget.count >= 10 ? BorderRadius.circular(10) : null,
          border: Border.all(
            color: const Color(0xFF0F141C),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.destructiveRed.withValues(alpha: 0.7),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Text(
            countText,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
