import 'dart:convert';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'content_packs.dart';
import 'notification_models.dart';

/// The one platform notification gateway used by every Gerex reminder.
class NotificationService {
  NotificationService(this._prefs);
  final SharedPreferences _prefs;
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  GoRouter? _router;
  bool _initialized = false;
  Future<void> Function(String actionId)? _actionHandler;
  static const maxNotificationsPerDay = 6;
  static const hydrationCheckHour = 15;
  static const streakRiskHour = 19;
  static const mealReminderHours = {'Breakfast': 8, 'Lunch': 13, 'Dinner': 20, 'Snack': 16};
  static const workoutReminderLead = Duration(minutes: 30);

  Future<void> initialize(GoRouter router) async {
    _router = router;
    tz.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
    const android = AndroidInitializationSettings('@drawable/ic_stat_gerex');
    final ios = DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false,
      notificationCategories: [DarwinNotificationCategory('workout', actions: [DarwinNotificationAction.plain('done', 'Mark Done'), DarwinNotificationAction.plain('snooze', 'Snooze')]), DarwinNotificationCategory('hydration', actions: [DarwinNotificationAction.plain('log_water', 'Log Water')])]);
    await _plugin.initialize(settings: InitializationSettings(android: android, iOS: ios), onDidReceiveNotificationResponse: _onResponse);
    _initialized = true;
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) _handlePayload(launch!.notificationResponse?.payload);
  }

  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final androidGranted = await android?.requestNotificationsPermission() ?? true;
    final iosGranted = await ios?.requestPermissions(alert: true, badge: true, sound: true) ?? true;
    return androidGranted && iosGranted;
  }
  void setActionHandler(Future<void> Function(String actionId) handler) => _actionHandler = handler;

  ContentPack get contentPack {
    final override = _prefs.getString('notification_content_pack');
    if (override != null) return NotificationContentPacks.byId(override);
    final profileCountry = _prefs.getString('profile_country') ?? _prefs.getString('profile_locale');
    return (profileCountry?.toLowerCase().contains('india') ?? false) || Platform.localeName.toLowerCase().startsWith('en_in')
        ? NotificationContentPacks.india : NotificationContentPacks.global;
  }
  Future<void> setContentPack(String? id) => id == null ? _prefs.remove('notification_content_pack') : _prefs.setString('notification_content_pack', id);

  Future<void> scheduleNotification(NotificationPayload payload) async {
    if (!_initialized) return;
    if (!(_prefs.getBool('notifications_enabled') ?? true)) return;
    if (!_withinDailyCap(payload.scheduledTime) || await _isDuplicate(payload)) return;
    final id = _id(payload.id ?? '${payload.category.name}:${payload.scheduledTime.toIso8601String()}');
    final image = payload.imagePath;
    final androidDetails = AndroidNotificationDetails(_channelId(payload.category), _channelName(payload.category), channelDescription: 'Gerex ${_channelName(payload.category)} reminders', importance: Importance.high, priority: Priority.high, icon: '@drawable/ic_stat_gerex', category: payload.category == NotificationCategory.workouts ? AndroidNotificationCategory.workout : null, groupKey: 'gerex_${payload.category.name}', styleInformation: image != null && File(image).existsSync() ? BigPictureStyleInformation(FilePathAndroidBitmap(image), hideExpandedLargeIcon: true) : null, actions: _androidActions(payload.category));
    final iosDetails = DarwinNotificationDetails(categoryIdentifier: payload.category == NotificationCategory.workouts ? 'workout' : payload.category == NotificationCategory.hydration ? 'hydration' : null, threadIdentifier: payload.category.name, attachments: image != null && File(image).existsSync() ? [DarwinNotificationAttachment(image)] : null);
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    final date = _toZone(payload.scheduledTime);
    if (payload.scheduledTime.isBefore(DateTime.now()) && payload.repeatRule == NotificationRepeatRule.none) return;
    await _plugin.zonedSchedule(id: id, title: payload.title, body: payload.body, scheduledDate: date, notificationDetails: details, payload: jsonEncode(payload.toJson()), androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle, matchDateTimeComponents: payload.repeatRule == NotificationRepeatRule.daily ? DateTimeComponents.time : payload.repeatRule == NotificationRepeatRule.weekly ? DateTimeComponents.dayOfWeekAndTime : null);
    _record(payload.scheduledTime);
  }

  Future<void> showNow(NotificationPayload payload) async {
    if (!_initialized) return;
    await _plugin.show(id: _id(payload.id ?? DateTime.now().microsecondsSinceEpoch.toString()), title: payload.title, body: payload.body, notificationDetails: NotificationDetails(android: AndroidNotificationDetails(_channelId(payload.category), _channelName(payload.category), icon: '@drawable/ic_stat_gerex', importance: Importance.high, priority: Priority.high), iOS: const DarwinNotificationDetails()), payload: jsonEncode(payload.toJson()));
  }
  Future<void> cancelNotification(String id) => _plugin.cancel(id: _id(id));
  Future<void> scheduleHydrationIfBehind({required int intakeMl, required int targetMl, DateTime? now}) async {
    final moment = now ?? DateTime.now();
    if (moment.hour < hydrationCheckHour || intakeMl >= targetMl * (moment.hour / 24)) return;
    await scheduleNotification(NotificationPayload(id: 'hydration-${moment.year}-${moment.month}-${moment.day}', title: 'Hydration check', body: contentPack.message(NotificationCategory.hydration), category: NotificationCategory.hydration, deepLink: '/activity-tracker', scheduledTime: moment.add(const Duration(minutes: 5)), actionData: {'action': 'log_water'}));
  }
  Future<void> scheduleStreakRisk({required bool loggedWorkoutToday, DateTime? now}) async {
    final moment = now ?? DateTime.now();
    if (loggedWorkoutToday || moment.hour >= 22) return;
    final fire = DateTime(moment.year, moment.month, moment.day, streakRiskHour);
    await scheduleNotification(NotificationPayload(id: 'streak-${moment.year}-${moment.month}-${moment.day}', title: 'Keep your streak alive', body: contentPack.message(NotificationCategory.general), category: NotificationCategory.progress, deepLink: '/workout-tracker', scheduledTime: fire.isAfter(moment) ? fire : moment.add(const Duration(minutes: 5))));
  }
  Future<void> scheduleMealReminder({required String entryId, required String mealName, required String mealType, required DateTime day}) {
    final hour = mealReminderHours[mealType] ?? 13;
    return scheduleNotification(NotificationPayload(id: 'meal-$entryId', title: '$mealType reminder', body: '$mealName is on your plan. ${contentPack.message(NotificationCategory.meals)}', category: NotificationCategory.meals, deepLink: '/meal-planner', scheduledTime: DateTime(day.year, day.month, day.day, hour)));
  }
  Future<void> scheduleWorkoutReminder({required String workoutId, required String workoutName, required DateTime startsAt}) => scheduleNotification(NotificationPayload(id: 'workout-$workoutId', title: 'Workout coming up', body: '$workoutName — ${contentPack.message(NotificationCategory.workouts)}', category: NotificationCategory.workouts, deepLink: '/session', scheduledTime: startsAt.subtract(workoutReminderLead)));
  Future<void> scheduleProgressPhotoReminder(DateTime when) => scheduleNotification(NotificationPayload(id: 'progress-photo-${when.toIso8601String()}', title: 'Progress check-in', body: contentPack.message(NotificationCategory.progress), category: NotificationCategory.progress, deepLink: '/progress-photos', scheduledTime: when, repeatRule: NotificationRepeatRule.weekly));
  Future<void> scheduleAiInsight(DateTime when) => scheduleNotification(NotificationPayload(id: 'ai-insight-${when.toIso8601String()}', title: 'Gerex AI insight ready', body: contentPack.message(NotificationCategory.aiCoach), category: NotificationCategory.aiCoach, deepLink: '/coach', scheduledTime: when));
  Future<bool> _isDuplicate(NotificationPayload payload) async => (await _plugin.pendingNotificationRequests()).any((n) => n.title == payload.title && n.body == payload.body);
  bool _withinDailyCap(DateTime date) { final key = 'notification_cap_${date.year}-${date.month}-${date.day}'; return (_prefs.getInt(key) ?? 0) < maxNotificationsPerDay; }
  Future<void> _record(DateTime date) async { final key = 'notification_cap_${date.year}-${date.month}-${date.day}'; await _prefs.setInt(key, (_prefs.getInt(key) ?? 0) + 1); }
  tz.TZDateTime _toZone(DateTime value) { final pack = contentPack; final loc = pack.timeZone == null ? tz.local : tz.getLocation(pack.timeZone!); return tz.TZDateTime.from(value, loc); }
  int _id(String value) => value.hashCode & 0x7fffffff;
  String _channelId(NotificationCategory c) => 'gerex_${c.name}';
  String _channelName(NotificationCategory c) => '${c.name[0].toUpperCase()}${c.name.substring(1)}';
  List<AndroidNotificationAction> _androidActions(NotificationCategory c) => c == NotificationCategory.workouts ? const [AndroidNotificationAction('done', 'Mark Done', cancelNotification: true), AndroidNotificationAction('snooze', 'Snooze')] : c == NotificationCategory.hydration ? const [AndroidNotificationAction('log_water', 'Log Water', cancelNotification: true)] : const [];
  void _onResponse(NotificationResponse response) { if (response.actionId != null) { _actionHandler?.call(response.actionId!); } _handlePayload(response.payload); }
  void _handlePayload(String? payload) { if (payload == null) return; try { final data = jsonDecode(payload) as Map<String, dynamic>; _router?.go(data['route'] as String? ?? '/notifications'); } catch (_) { _router?.go('/notifications'); } }
}
