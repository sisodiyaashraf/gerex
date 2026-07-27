import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gerex/features/profile/presentation/providers/progress_photos_provider.dart';
import 'package:gerex/core/providers/notification_provider.dart';

class MockSupabaseClient extends Fake implements SupabaseClient {
  final MockGoTrueClient _auth = MockGoTrueClient();
  @override
  GoTrueClient get auth => _auth;
}

class MockGoTrueClient extends Fake implements GoTrueClient {
  @override
  User? get currentUser => const User(
        id: 'user_123',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '',
      );
}

class MockNotificationProvider extends Fake implements NotificationProvider {
  bool sendNotificationCalled = false;
  @override
  Future<void> sendNotification(String title, String description) async {
    sendNotificationCalled = true;
  }
}

void main() {
  group('ProgressPhotosProvider Tests', () {
    late SharedPreferences prefs;
    late MockSupabaseClient mockSupabase;
    late MockNotificationProvider mockNotifications;
    late ProgressPhotosProvider provider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'cached_progress_photos': [
          'photo_1:::user_123:::path_1:::signed_url_1:::2026-07-24T10:00:00Z',
        ],
        'progress_reminders_enabled': true,
        'progress_reminder_cadence': 'monthly',
      });
      prefs = await SharedPreferences.getInstance();
      mockSupabase = MockSupabaseClient();
      mockNotifications = MockNotificationProvider();
      provider = ProgressPhotosProvider(mockSupabase, prefs, mockNotifications);
    });

    test('Initial progress photos and settings load correctly', () {
      expect(provider.photos.length, 1);
      expect(provider.photos.first.id, 'photo_1');
      expect(provider.remindersEnabled, true);
      expect(provider.reminderCadence, 'monthly');
      expect(provider.nextReminderDate, isNotNull);
    });

    test('setRemindersEnabled updates setting and saves', () async {
      await provider.setRemindersEnabled(false);
      expect(provider.remindersEnabled, false);
      expect(prefs.getBool('progress_reminders_enabled'), false);
    });

    test('setReminderCadence updates setting and saves', () async {
      await provider.setReminderCadence('weekly');
      expect(provider.reminderCadence, 'weekly');
      expect(prefs.getString('progress_reminder_cadence'), 'weekly');
    });

    test('deletePhoto removes photo from gallery list', () async {
      final photo = provider.photos.first;
      await provider.deletePhoto(photo);
      expect(provider.photos.isEmpty, true);
    });
  });
}
