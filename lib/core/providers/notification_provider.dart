import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../notifications/notification_models.dart';
import '../notifications/notification_service.dart';

class UserNotification {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  bool isRead;

  UserNotification({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    this.isRead = false,
  });

  String toSerializedString() {
    return '$id:::$title:::$description:::${timestamp.toIso8601String()}:::${isRead ? '1' : '0'}';
  }

  factory UserNotification.fromSerializedString(String str) {
    final parts = str.split(':::');
    return UserNotification(
      id: parts[0],
      title: parts[1],
      description: parts[2],
      timestamp: DateTime.tryParse(parts[3]) ?? DateTime.now(),
      isRead: parts[4] == '1',
    );
  }
}

class NotificationProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  late final NotificationService service;

  NotificationProvider(this._prefs) {
    service = NotificationService(_prefs);
    _loadNotifications();
  }

  List<UserNotification> _notifications = [];
  List<CustomNotificationTemplate> _templates = [];

  List<UserNotification> get notifications => _notifications;
  List<CustomNotificationTemplate> get templates => List.unmodifiable(_templates);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void _loadNotifications() {
    final list = _prefs.getStringList('user_notifications_list') ?? [];
    try {
      _notifications = list.map((item) => UserNotification.fromSerializedString(item)).toList();
    } catch (_) {
      _notifications = [];
    }
    // Sort descending by timestamp
    _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    _templates = (_prefs.getStringList('custom_notification_templates') ?? [])
        .map((value) { try { return CustomNotificationTemplate.deserialize(value); } catch (_) { return null; } })
        .whereType<CustomNotificationTemplate>().toList();
    notifyListeners();
  }

  Future<void> _saveNotifications() async {
    final list = _notifications.map((n) => n.toSerializedString()).toList();
    await _prefs.setStringList('user_notifications_list', list);
  }

  Future<void> sendNotification(String title, String description) async {
    final enabled = _prefs.getBool('notifications_enabled') ?? true;
    if (!enabled) return;

    final notif = UserNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      timestamp: DateTime.now(),
    );

    _notifications.insert(0, notif);
    if (_notifications.length > 50) _notifications.removeLast();
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> initialize(GoRouter router) => service.initialize(router);
  Future<bool> requestSystemPermission() => service.requestPermission();
  Future<void> scheduleNotification(NotificationPayload payload) => service.scheduleNotification(payload);
  Future<void> cancelNotification(String id) => service.cancelNotification(id);
  void setActionHandler(Future<void> Function(String actionId) handler) => service.setActionHandler(handler);
  Future<void> setContentPack(String? id) async { await service.setContentPack(id); notifyListeners(); }
  Future<void> scheduleHydrationIfBehind({required int intakeMl, required int targetMl}) => service.scheduleHydrationIfBehind(intakeMl: intakeMl, targetMl: targetMl);
  Future<void> scheduleStreakRisk({required bool loggedWorkoutToday}) => service.scheduleStreakRisk(loggedWorkoutToday: loggedWorkoutToday);
  Future<void> scheduleMealReminder({
    required String entryId,
    required String recipeId,
    required String mealName,
    required String mealType,
    required DateTime day,
    double? calories,
  }) => service.scheduleMealReminder(
    entryId: entryId,
    recipeId: recipeId,
    mealName: mealName,
    mealType: mealType,
    day: day,
    calories: calories,
  );
  Future<void> scheduleWorkoutReminder({
    required String workoutId,
    required String workoutName,
    required DateTime startsAt,
    required int exercisesCount,
    String? imageUrl,
  }) => service.scheduleWorkoutReminder(
    workoutId: workoutId,
    workoutName: workoutName,
    startsAt: startsAt,
    exercisesCount: exercisesCount,
    imageUrl: imageUrl,
  );

  Future<void> scheduleExerciseReminder({
    required String exerciseId,
    required String exerciseName,
    required DateTime startsAt,
    String? imageUrl,
    required int instructionsCount,
  }) => service.scheduleExerciseReminder(
    exerciseId: exerciseId,
    exerciseName: exerciseName,
    startsAt: startsAt,
    imageUrl: imageUrl,
    instructionsCount: instructionsCount,
  );

  Future<List<int>> getPendingNotificationIds() => service.getPendingNotificationIds();

  Future<void> showCustomNotification(NotificationPayload payload) async {
    await sendNotification(payload.title, payload.body);
    await service.showNow(payload);
  }
  Future<void> saveTemplate(CustomNotificationTemplate template) async {
    _templates.removeWhere((item) => item.id == template.id);
    _templates.add(template);
    await _prefs.setStringList('custom_notification_templates', _templates.map((item) => item.serialize()).toList());
    notifyListeners();
  }
  Future<void> deleteTemplate(String id) async {
    _templates.removeWhere((item) => item.id == id);
    await _prefs.setStringList('custom_notification_templates', _templates.map((item) => item.serialize()).toList());
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx].isRead = true;
      await _saveNotifications();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    for (final n in _notifications) {
      n.isRead = true;
    }
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _notifications.clear();
    await _saveNotifications();
    notifyListeners();
  }
}
