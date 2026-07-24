import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gerex/features/profile/presentation/providers/profile_provider.dart';

void main() {
  group('ProfileProvider Tests', () {
    late SharedPreferences prefs;
    late ProfileProvider profileProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'units_preference': 'kg',
        'notifications_enabled': true,
        'theme_mode': 'system',
      });
      prefs = await SharedPreferences.getInstance();
      profileProvider = ProfileProvider(prefs);
    });

    test('Initial preferences are loaded correctly', () {
      expect(profileProvider.units, 'kg');
      expect(profileProvider.notificationsEnabled, true);
      expect(profileProvider.themeMode, 'system');
    });

    test('setUnits updates preference and persists', () async {
      await profileProvider.setUnits('lb');
      expect(profileProvider.units, 'lb');
      expect(prefs.getString('units_preference'), 'lb');
    });

    test('toggleNotifications updates preference and persists', () async {
      await profileProvider.toggleNotifications(false);
      expect(profileProvider.notificationsEnabled, false);
      expect(prefs.getBool('notifications_enabled'), false);
    });

    test('setThemeMode updates preference and persists', () async {
      await profileProvider.setThemeMode('dark');
      expect(profileProvider.themeMode, 'dark');
      expect(prefs.getString('theme_mode'), 'dark');
    });
  });
}
