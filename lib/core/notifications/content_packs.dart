import 'notification_models.dart';

class ContentPack {
  const ContentPack({required this.id, required this.label, required this.templates, this.timeZone});
  final String id;
  final String label;
  final String? timeZone;
  final Map<NotificationCategory, List<String>> templates;
  String message(NotificationCategory category, {int variant = 0}) {
    final choices = templates[category] ?? templates[NotificationCategory.general]!;
    return choices[variant % choices.length];
  }
}

class NotificationContentPacks {
  static const global = ContentPack(id: 'global', label: 'Global', templates: {
    NotificationCategory.workouts: ['Your workout is ready. Let’s get moving.'],
    NotificationCategory.meals: ['Your planned meal is coming up. Fuel your day well.'],
    NotificationCategory.sleep: ['A little wind-down now supports tomorrow’s recovery.'],
    NotificationCategory.hydration: ['You are behind your water pace. A glass now helps.'],
    NotificationCategory.progress: ['A quick progress photo helps you see the change.'],
    NotificationCategory.aiCoach: ['Your daily Gerex AI insight is ready.'],
    NotificationCategory.general: ['A small healthy action can make today count.'],
  });
  static const india = ContentPack(id: 'india', label: 'India', timeZone: 'Asia/Kolkata', templates: {
    NotificationCategory.workouts: ['Workout ka time — let’s make today count!'],
    NotificationCategory.meals: ['Meal time aa gaya — fuel up, feel strong.'],
    NotificationCategory.sleep: ['Wind down karein — kal ke liye recovery zaroori hai.'],
    NotificationCategory.hydration: ['Paani break? You’re a little behind your goal.'],
    NotificationCategory.progress: ['Aaj ki progress photo, kal ka motivation.'],
    NotificationCategory.aiCoach: ['Aaj ka Gerex AI tip ready hai.'],
    NotificationCategory.general: ['Chhota step, strong progress — keep going!'],
  });
  static const all = [global, india];
  static ContentPack byId(String id) => all.firstWhere((pack) => pack.id == id, orElse: () => global);
}
