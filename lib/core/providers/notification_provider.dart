import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  NotificationProvider(this._prefs) {
    _loadNotifications();
  }

  List<UserNotification> _notifications = [];

  List<UserNotification> get notifications => _notifications;
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
