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

class CustomNotificationTemplate {
  const CustomNotificationTemplate({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    this.imagePath,
    this.deepLink = '/notifications',
  });

  final String id;
  final String title;
  final String body;
  final NotificationCategory category;
  final String? imagePath;
  final String deepLink;

  String serialize() => [id, title, body, category.name, imagePath ?? '', deepLink].join(':::');
  factory CustomNotificationTemplate.deserialize(String value) {
    final p = value.split(':::');
    return CustomNotificationTemplate(id: p[0], title: p[1], body: p[2], category: NotificationCategory.values.byName(p[3]), imagePath: p[4].isEmpty ? null : p[4], deepLink: p.length > 5 ? p[5] : '/notifications');
  }
}
