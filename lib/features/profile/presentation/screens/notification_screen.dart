import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gerex/core/providers/notification_provider.dart';
import 'package:gerex/core/utils/relative_time.dart';
import 'package:gerex/core/presentation/widgets/pastel_gradient_card.dart';
import 'package:gerex/core/presentation/widgets/gerex_scaffold.dart';
import 'package:gerex/core/theme/app_theme.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<NotificationProvider>(context);

    final now = DateTime.now();
    final todayNotifications = provider.notifications.where((n) {
      return n.timestamp.year == now.year &&
          n.timestamp.month == now.month &&
          n.timestamp.day == now.day;
    }).toList();

    final olderNotifications = provider.notifications.where((n) {
      return !(n.timestamp.year == now.year &&
          n.timestamp.month == now.month &&
          n.timestamp.day == now.day);
    }).toList();

    return GerexScaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textDarkHeading,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: () => provider.markAllAsRead(),
              child: const Text('Mark all read', style: TextStyle(color: AppColors.accentEmeraldLight)),
            ),
        ],
      ),
      body: provider.notifications.isEmpty
          ? _buildEmptyState(theme)
          : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                children: [
                  if (todayNotifications.isNotEmpty) ...[
                    _buildSectionHeader(theme, 'Today'),
                    const SizedBox(height: 8),
                    ...todayNotifications.map((n) => _buildNotificationCard(context, theme, n, provider)),
                    const SizedBox(height: 24),
                  ],
                  if (olderNotifications.isNotEmpty) ...[
                    _buildSectionHeader(theme, 'Older Alerts'),
                    const SizedBox(height: 8),
                    ...olderNotifications.map((n) => _buildNotificationCard(context, theme, n, provider)),
                  ],
                ],
              ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    ThemeData theme,
    UserNotification notification,
    NotificationProvider provider,
  ) {
    final titleLower = notification.title.toLowerCase();
    final PastelCardType cardType = titleLower.contains('workout')
        ? PastelCardType.indigo
        : (titleLower.contains('streak')
            ? PastelCardType.sunset
            : (titleLower.contains('ai') || titleLower.contains('coach') ? PastelCardType.mint : PastelCardType.slate));

    return PastelGradientCard(
      type: cardType,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: Icon(
              _getIconForNotification(notification.title),
              color: theme.colorScheme.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      RelativeTimeFormatter.format(notification.timestamp),
                      style: TextStyle(
                        fontSize: 10,
                        color: const Color(0xFF14181F).withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF14181F).withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              color: const Color(0xFF14181F).withValues(alpha: 0.4),
              size: 18,
            ),
            padding: EdgeInsets.zero,
            onSelected: (val) {
              if (val == 'read') {
                provider.markAsRead(notification.id);
              } else if (val == 'delete') {
                provider.deleteNotification(notification.id);
              }
            },
            itemBuilder: (c) => [
              if (!notification.isRead)
                const PopupMenuItem(
                  value: 'read',
                  child: Text('Mark as Read', style: TextStyle(fontSize: 13)),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete Notification', style: TextStyle(fontSize: 13, color: Colors.redAccent)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getIconForNotification(String title) {
    final t = title.toLowerCase();
    if (t.contains('workout') || t.contains('completed')) {
      return Icons.fitness_center_rounded;
    } else if (t.contains('streak') || t.contains('milestone')) {
      return Icons.local_fire_department_rounded;
    } else if (t.contains('ai') || t.contains('coach') || t.contains('insight')) {
      return Icons.psychology_rounded;
    } else {
      return Icons.notifications_rounded;
    }
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: Icon(
              Icons.notifications_active_rounded,
              size: 32,
              color: theme.colorScheme.primary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'All Caught Up!',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No notifications to review at the moment.',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
