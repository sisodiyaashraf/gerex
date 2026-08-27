import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gerex/features/metrics/presentation/providers/sleep_provider.dart';
import 'package:gerex/core/providers/notification_provider.dart';

class MockNotificationProvider extends Fake implements NotificationProvider {
  bool sendNotificationCalled = false;
  @override
  Future<void> sendNotification(String title, String description) async {
    sendNotificationCalled = true;
  }

  @override
  Future<void> scheduleNotification(int id, String title, String body, DateTime scheduledTime, {String? route}) async {}

  @override
  Future<void> cancelNotification(int id) async {}
}

void main() {
  group('SleepProvider Tests', () {
    late SharedPreferences prefs;
    late MockNotificationProvider mockNotifications;
    late SleepProvider provider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'cached_sleep_alarms': [
          'alarm_1:::22:00:::06:00:::1,2,3:::1:::1',
        ],
      });
      prefs = await SharedPreferences.getInstance();
      mockNotifications = MockNotificationProvider();
      provider = SleepProvider(prefs, mockNotifications);
    });

    test('Initial alarms and mock logs load correctly', () {
      expect(provider.alarms.length, 1);
      expect(provider.alarms.first.id, 'alarm_1');
      expect(provider.sleepLogs.isNotEmpty, true);
    });

    test('calculateDuration computes hours correctly', () {
      final hoursCrossMidnight = provider.calculateDuration('22:00', '06:00');
      expect(hoursCrossMidnight, 8.0);

      final hoursSameDay = provider.calculateDuration('08:00', '16:30');
      expect(hoursSameDay, 8.5);
    });

    test('addAlarm validates sleep duration bounds', () async {
      // 0 hours sleep error
      final errShort = await provider.addAlarm(
        bedtime: '06:00',
        wake: '07:00',
        repeatDays: [1],
        vibrate: true,
      );
      expect(errShort, 'Projected sleep duration must be between 2 and 16 hours.');

      // 18 hours sleep error
      final errLong = await provider.addAlarm(
        bedtime: '12:00',
        wake: '06:00',
        repeatDays: [1],
        vibrate: true,
      );
      expect(errLong, 'Projected sleep duration must be between 2 and 16 hours.');
    });

    test('toggleAlarm works correctly', () async {
      await provider.toggleAlarm('alarm_1', false);
      expect(provider.alarms.first.isEnabled, false);
    });

    test('deleteAlarm removes entry from list', () async {
      await provider.deleteAlarm('alarm_1');
      expect(provider.alarms.isEmpty, true);
    });
  });
}
