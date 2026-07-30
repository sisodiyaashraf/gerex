import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:gerex/core/utils/logger.dart';
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
    try {
      tz.initializeTimeZones();
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
      SecureLogger.logInfo('NotificationService: Timezone successfully set to ${zone.identifier}');
    } catch (e) {
      SecureLogger.logError('NotificationService: Timezone initialization failed', e);
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {}
    }

    const android = AndroidInitializationSettings('@drawable/ic_stat_gerex');
    final ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
      defaultPresentBanner: true,
      defaultPresentList: true,
      notificationCategories: [
        DarwinNotificationCategory(
          'workout',
          actions: [
            DarwinNotificationAction.plain('done', 'Mark Done'),
            DarwinNotificationAction.plain('snooze', 'Snooze'),
          ],
        ),
        DarwinNotificationCategory(
          'hydration',
          actions: [
            DarwinNotificationAction.plain('log_water', 'Log Water'),
          ],
        ),
      ],
    );

    await _plugin.initialize(
      settings: InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onResponse,
    );
    _initialized = true;
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      _handlePayload(launch!.notificationResponse?.payload);
    }
  }

  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    
    final androidGranted = await android?.requestNotificationsPermission() ?? false;
    final iosGranted = await ios?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    
    SecureLogger.logInfo('NotificationService: Request Notification Permission. Android=$androidGranted, iOS=$iosGranted');
    
    bool exactAlarmGranted = true;
    if (Platform.isAndroid) {
      try {
        final result = await android?.requestExactAlarmsPermission();
        SecureLogger.logInfo('NotificationService: Exact alarm permission request completed with result: $result');
        exactAlarmGranted = result ?? true;
      } catch (e) {
        SecureLogger.logError('NotificationService: Error requesting exact alarm permission', e);
      }
    }
    
    return androidGranted && iosGranted && exactAlarmGranted;
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

  Future<String?> _downloadImageIfNeeded(String? pathOrUrl, String filename) async {
    if (pathOrUrl == null || pathOrUrl.isEmpty) return null;
    if (!pathOrUrl.startsWith('http://') && !pathOrUrl.startsWith('https://')) {
      if (File(pathOrUrl).existsSync()) {
        return pathOrUrl;
      }
      return null;
    }
    try {
      SecureLogger.logInfo('NotificationService: Downloading image from URL: $pathOrUrl');
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(pathOrUrl));
      final response = await request.close();
      if (response.statusCode == 200) {
        final bytes = await response.fold<List<int>>([], (list, element) => list..addAll(element));
        final tempDir = Directory.systemTemp;
        final file = File('${tempDir.path}/$filename');
        await file.writeAsBytes(bytes);
        SecureLogger.logInfo('NotificationService: Downloaded image saved to: ${file.path}');
        return file.path;
      } else {
        SecureLogger.logInfo('NotificationService: Failed to download image. Status: ${response.statusCode}');
      }
    } catch (e) {
      SecureLogger.logError('NotificationService: Error downloading image', e);
    }
    return null;
  }

  static const Map<NotificationCategory, String> _defaultCategoryBanners = {
    NotificationCategory.workouts: 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?q=80&w=600',
    NotificationCategory.meals: 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?q=80&w=600',
    NotificationCategory.sleep: 'https://images.unsplash.com/photo-1511295742364-92767fa62d9f?q=80&w=600',
    NotificationCategory.hydration: 'https://images.unsplash.com/photo-1548839140-29a888455e9e?q=80&w=600',
    NotificationCategory.progress: 'https://images.unsplash.com/photo-1476480862126-209bfaa8edc8?q=80&w=600',
    NotificationCategory.aiCoach: 'https://images.unsplash.com/photo-1677442136019-21780efad99a?q=80&w=600',
    NotificationCategory.general: 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?q=80&w=600',
  };

  Future<void> scheduleNotification(NotificationPayload payload) async {
    try {
      if (!_initialized) {
        SecureLogger.logInfo('NotificationService: NOT initialized. Cannot schedule: ${payload.title}');
        return;
      }
      if (!(_prefs.getBool('notifications_enabled') ?? true)) {
        SecureLogger.logInfo('NotificationService: Notifications are disabled in settings');
        return;
      }
      if (!_withinDailyCap(payload.scheduledTime)) {
        SecureLogger.logInfo('NotificationService: Notification daily cap exceeded for ${payload.scheduledTime}');
        return;
      }
      if (await _isDuplicate(payload)) {
        SecureLogger.logInfo('NotificationService: Duplicate notification ID detected. Skipping scheduling for: ${payload.title}');
        return;
      }

      final id = _id(payload.id ?? '${payload.category.name}:${payload.scheduledTime.toIso8601String()}');
      
      // Resolve image url with fallback illustration if none is specified or invalid
      String? image = payload.imagePath;
      if (image == null || image.isEmpty || !File(image).existsSync()) {
        final defaultUrl = _defaultCategoryBanners[payload.category] ?? _defaultCategoryBanners[NotificationCategory.general]!;
        image = await _downloadImageIfNeeded(defaultUrl, 'default_${payload.category.name}.jpg');
      }

      SecureLogger.logInfo('NotificationService: Scheduling notification ID: $id (payload.id: ${payload.id}) "${payload.title}" at ${payload.scheduledTime}');

      final androidDetails = AndroidNotificationDetails(
        _channelId(payload.category),
        _channelName(payload.category),
        channelDescription: 'Gerex ${_channelName(payload.category)} reminders',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@drawable/ic_stat_gerex',
        color: const Color(0xFF0D807B), // Brand theme accent color
        category: payload.category == NotificationCategory.workouts ? AndroidNotificationCategory.workout : null,
        groupKey: 'gerex_${payload.category.name}',
        styleInformation: image != null && File(image).existsSync()
            ? BigPictureStyleInformation(
                FilePathAndroidBitmap(image),
                hideExpandedLargeIcon: true,
                contentTitle: payload.title,
                summaryText: payload.body,
              )
            : null,
        actions: _androidActions(payload.category),
        showWhen: true,
      );

      final iosDetails = DarwinNotificationDetails(
        categoryIdentifier: payload.category == NotificationCategory.workouts 
            ? 'workout' 
            : payload.category == NotificationCategory.hydration 
                ? 'hydration' 
                : null,
        threadIdentifier: payload.category.name,
        attachments: image != null && File(image).existsSync() ? [DarwinNotificationAttachment(image)] : null,
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        presentBanner: true,
        presentList: true,
        subtitle: payload.body,
      );

      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
      final date = _toZone(payload.scheduledTime);

      final now = DateTime.now();
      if (payload.scheduledTime.isBefore(now) && payload.repeatRule == NotificationRepeatRule.none) {
        SecureLogger.logInfo('NotificationService: Cannot schedule in the past. ScheduledTime: ${payload.scheduledTime}, Now: $now');
        return;
      }

      await _plugin.zonedSchedule(
        id: id,
        title: payload.title,
        body: payload.body,
        scheduledDate: date,
        notificationDetails: details,
        payload: jsonEncode(payload.toJson()),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: payload.repeatRule == NotificationRepeatRule.daily
            ? DateTimeComponents.time
            : payload.repeatRule == NotificationRepeatRule.weekly
                ? DateTimeComponents.dayOfWeekAndTime
                : null,
      );
      _record(payload.scheduledTime);
      SecureLogger.logInfo('NotificationService: Successfully scheduled notification ID $id');
    } catch (e, stack) {
      SecureLogger.logError('NotificationService ERROR: Failed to schedule notification', e, stack);
    }
  }

  Future<void> showNow(NotificationPayload payload) async {
    if (!_initialized) return;
    
    String? image = payload.imagePath;
    if (image == null || image.isEmpty || !File(image).existsSync()) {
      final defaultUrl = _defaultCategoryBanners[payload.category] ?? _defaultCategoryBanners[NotificationCategory.general]!;
      image = await _downloadImageIfNeeded(defaultUrl, 'default_${payload.category.name}.jpg');
    }

    final androidDetails = AndroidNotificationDetails(
      _channelId(payload.category),
      _channelName(payload.category),
      icon: '@drawable/ic_stat_gerex',
      importance: Importance.high,
      priority: Priority.high,
      color: const Color(0xFF0D807B),
      styleInformation: image != null && File(image).existsSync()
          ? BigPictureStyleInformation(
              FilePathAndroidBitmap(image),
              hideExpandedLargeIcon: true,
              contentTitle: payload.title,
              summaryText: payload.body,
            )
          : null,
      actions: _androidActions(payload.category),
      showWhen: true,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
      presentList: true,
      attachments: image != null && File(image).existsSync() ? [DarwinNotificationAttachment(image)] : null,
      subtitle: payload.body,
    );

    await _plugin.show(
      id: _id(payload.id ?? DateTime.now().microsecondsSinceEpoch.toString()),
      title: payload.title,
      body: payload.body,
      notificationDetails: NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: jsonEncode(payload.toJson()),
    );
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

  Future<void> scheduleMealReminder({
    required String entryId,
    required String recipeId,
    required String mealName,
    required String mealType,
    required DateTime day,
    double? calories,
  }) {
    final hour = mealReminderHours[mealType] ?? 13;
    var scheduledTime = DateTime(day.year, day.month, day.day, hour);
    if (scheduledTime.isBefore(DateTime.now())) {
      scheduledTime = DateTime.now().add(const Duration(minutes: 2));
    }
    final calorieText = calories != null ? ' (~${calories.toInt()} kcal)' : '';
    final title = 'Time for $mealType';
    final body = 'Enjoy your $mealName$calorieText. Tap to view recipe details!';
    return scheduleNotification(NotificationPayload(
      id: 'meal-$entryId',
      title: title,
      body: body,
      category: NotificationCategory.meals,
      deepLink: '/meal-details?id=$recipeId',
      scheduledTime: scheduledTime,
    ));
  }

  Future<void> scheduleWorkoutReminder({
    required String workoutId,
    required String workoutName,
    required DateTime startsAt,
    required int exercisesCount,
    String? imageUrl,
  }) async {
    final durationMin = exercisesCount * 7;
    final title = 'Time for $workoutName';
    final body = '$exercisesCount exercises, ~$durationMin min';
    
    final localImagePath = await _downloadImageIfNeeded(imageUrl, 'workout_$workoutId.jpg');
    
    final scheduledTime = startsAt.subtract(workoutReminderLead);
    final finalScheduledTime = scheduledTime.isAfter(DateTime.now()) ? scheduledTime : startsAt;
    
    await scheduleNotification(NotificationPayload(
      id: 'workout-$workoutId',
      title: title,
      body: body,
      category: NotificationCategory.workouts,
      deepLink: '/workout-details?id=$workoutId',
      scheduledTime: finalScheduledTime,
      imagePath: localImagePath,
    ));
  }

  Future<void> scheduleExerciseReminder({
    required String exerciseId,
    required String exerciseName,
    required DateTime startsAt,
    String? imageUrl,
    required int instructionsCount,
  }) async {
    final title = 'Practice $exerciseName';
    final body = '$instructionsCount steps instruction. Let\'s practice!';
    
    final localImagePath = await _downloadImageIfNeeded(imageUrl, 'exercise_$exerciseId.jpg');
    
    await scheduleNotification(NotificationPayload(
      id: 'exercise-$exerciseId',
      title: title,
      body: body,
      category: NotificationCategory.workouts,
      deepLink: '/exercise-detail?id=$exerciseId',
      scheduledTime: startsAt,
      imagePath: localImagePath,
    ));
  }

  Future<void> scheduleProgressPhotoReminder(DateTime when) => scheduleNotification(NotificationPayload(id: 'progress-photo-${when.toIso8601String()}', title: 'Progress check-in', body: contentPack.message(NotificationCategory.progress), category: NotificationCategory.progress, deepLink: '/progress-photos', scheduledTime: when, repeatRule: NotificationRepeatRule.weekly));

  Future<void> scheduleAiInsight(DateTime when) => scheduleNotification(NotificationPayload(id: 'ai-insight-${when.toIso8601String()}', title: 'Gerex AI insight ready', body: contentPack.message(NotificationCategory.aiCoach), category: NotificationCategory.aiCoach, deepLink: '/coach', scheduledTime: when));

  Future<bool> _isDuplicate(NotificationPayload payload) async {
    final id = _id(payload.id ?? '${payload.category.name}:${payload.scheduledTime.toIso8601String()}');
    final pending = await _plugin.pendingNotificationRequests();
    return pending.any((n) => n.id == id);
  }

  Future<List<int>> getPendingNotificationIds() async {
    try {
      final pending = await _plugin.pendingNotificationRequests();
      return pending.map((n) => n.id).toList();
    } catch (e) {
      SecureLogger.logError('NotificationService: Error getting pending notification IDs', e);
      return [];
    }
  }

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
