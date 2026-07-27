import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/di/injection_container.dart' as di;
import 'core/presentation/providers/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/security/secure_local_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/exercise/presentation/providers/exercise_provider.dart';
import 'features/workout/presentation/providers/workout_provider.dart';
import 'features/metrics/presentation/providers/metrics_provider.dart';
import 'features/ai/presentation/providers/ai_provider.dart';
import 'features/profile/presentation/providers/profile_provider.dart';
import 'features/profile/presentation/providers/progress_photos_provider.dart';
import 'features/metrics/presentation/providers/sleep_provider.dart';
import 'features/nutrition/presentation/providers/meal_provider.dart';
import 'features/challenges/presentation/providers/challenge_provider.dart';
import 'core/providers/activity_provider.dart';
import 'core/providers/notification_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: 'assets/.env');

  // Initialize Supabase with custom secure storage adapter
  await Supabase.initialize(
    url: dotenv.get('SUPABASE_URL'),
    publishableKey: dotenv.get('SUPABASE_ANON_KEY'),
    authOptions: const FlutterAuthClientOptions(
      localStorage: SecureLocalStorage(),
    ),
  );

  // Initialize DI service locator
  await di.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: di.sl<AuthProvider>()),
        ChangeNotifierProvider.value(value: di.sl<ExerciseProvider>()),
        ChangeNotifierProvider.value(value: di.sl<WorkoutProvider>()),
        ChangeNotifierProvider.value(value: di.sl<MetricsProvider>()),
        ChangeNotifierProvider.value(value: di.sl<AIProvider>()),
        ChangeNotifierProvider.value(value: di.sl<ProfileProvider>()),
        ChangeNotifierProvider.value(value: di.sl<ProgressPhotosProvider>()),
        ChangeNotifierProvider.value(value: di.sl<SleepProvider>()),
        ChangeNotifierProvider.value(value: di.sl<MealProvider>()),
        ChangeNotifierProvider.value(value: di.sl<ActivityProvider>()),
        ChangeNotifierProvider.value(value: di.sl<NotificationProvider>()),
        ChangeNotifierProvider.value(value: di.sl<ChallengeProvider>()),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp.router(
      title: 'Gerex',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      routerConfig: AppRouter.router,
    );
  }
}
