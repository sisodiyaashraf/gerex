enum NotificationCategory { workouts, meals, sleep, hydration, progress, aiCoach, general }

enum NotificationRepeatRule { none, daily, weekly }

class NotificationPayload {
  const NotificationPayload({
    required this.title,
    required this.body,
    required this.category,
    required this.scheduledTime,
    this.id,
    this.imagePath,
    this.icon,
    this.deepLink = '/notifications',
    this.repeatRule = NotificationRepeatRule.none,
    this.actionData,
  });

  final String? id;
  final String title;
  final String body;
  final String? imagePath;
  final String? icon;
  final String deepLink;
  final NotificationCategory category;
  final DateTime scheduledTime;
  final NotificationRepeatRule repeatRule;
  final Map<String, String>? actionData;

  Map<String, dynamic> toJson() => {
        'route': deepLink,
        'category': category.name,
        'action': actionData,
      };
}

