import 'package:flutter/material.dart';
import 'package:gerex/core/presentation/widgets/gerex_app_bar.dart';

/// Legacy export wrapper forwarding to the unified GerexAppBar system.
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
  final List<Widget>? customActions;

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
    this.customActions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56.0);

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
    final displayTitle = showGreeting ? _getFirstName() : (title ?? 'Dashboard');
    final displaySubtitle = showGreeting ? _getGreetingText() : null;

    return GerexAppBar.standard(
      title: displayTitle,
      subtitle: displaySubtitle,
      showBackButton: false,
      leading: GerexAvatarAction(
        photoUrl: userPhotoUrl,
        displayName: userDisplayName,
        onTap: onProfileTap,
      ),
      actions: [
        if (customActions != null) ...customActions!,
        GerexStreakAction(
          streakCount: streakCount,
          isTodayLogged: isTodayLogged,
          onTap: onStreakTap,
        ),
        GerexNotificationAction(onTap: onNotificationTap),
      ],
    );
  }
}

/// Legacy Sliver export wrapper forwarding to SliverGerexAppBar.
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
  final List<Widget>? customActions;

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
    this.pinned = true,
    this.customActions,
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
    final displayTitle = showGreeting ? _getFirstName() : (title ?? 'Dashboard');
    final displaySubtitle = showGreeting ? _getGreetingText() : null;

    return SliverGerexAppBar(
      title: displayTitle,
      subtitle: displaySubtitle,
      pinned: pinned,
      floating: floating,
      leading: GerexAvatarAction(
        photoUrl: userPhotoUrl,
        displayName: userDisplayName,
        onTap: onProfileTap,
      ),
      actions: [
        if (customActions != null) ...customActions!,
        GerexStreakAction(
          streakCount: streakCount,
          isTodayLogged: isTodayLogged,
          onTap: onStreakTap,
        ),
        GerexNotificationAction(onTap: onNotificationTap),
      ],
    );
  }
}
