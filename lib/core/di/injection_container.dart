import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../services/exercise_service.dart';
import '../../features/exercise/data/repositories/exercise_repository_impl.dart';
import '../../features/exercise/domain/repositories/exercise_repository.dart';
import '../../features/exercise/presentation/providers/exercise_provider.dart';
import '../../features/metrics/data/repositories/metrics_repository_impl.dart';
import '../../features/metrics/domain/repositories/metrics_repository.dart';
import '../../features/metrics/presentation/providers/metrics_provider.dart';
import '../../features/workout/data/repositories/workout_repository_impl.dart';
import '../../features/workout/domain/repositories/workout_repository.dart';
import '../../features/workout/presentation/providers/workout_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../features/ai/data/repositories/ai_repository_impl.dart';
import '../../features/ai/domain/repositories/ai_repository.dart';
import '../../features/ai/presentation/providers/ai_provider.dart';
import '../../features/ai/data/services/offline_ai_service.dart';
import '../../features/ai/data/services/gemini_ai_service.dart';
import '../../features/ai/data/services/ai_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/profile/presentation/providers/profile_provider.dart';
import '../../features/profile/presentation/providers/progress_photos_provider.dart';
import '../../features/metrics/presentation/providers/sleep_provider.dart';
import '../../features/nutrition/presentation/providers/meal_provider.dart';
import '../../features/nutrition/domain/repositories/food_scanner_repository.dart';
import '../../features/nutrition/data/repositories/food_scanner_repository_impl.dart';
import '../../features/nutrition/domain/usecases/analyze_food_image_usecase.dart';
import '../../features/nutrition/presentation/providers/scanner_provider.dart';
import '../network/network_info.dart';
import '../../features/metrics/presentation/providers/heart_rate_provider.dart';
import '../providers/activity_provider.dart';
import '../providers/notification_provider.dart';
import '../../features/challenges/domain/repositories/challenge_repository.dart';
import '../../features/challenges/data/repositories/challenge_repository_impl.dart';
import '../../features/challenges/presentation/providers/challenge_provider.dart';
import 'package:gerex/core/services/voice_coach_service.dart';
import 'package:gerex/core/services/voice_engine.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External
  final sharedPrefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPrefs);

  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  sl.registerLazySingleton<GoogleSignIn>(() {
    if (kIsWeb) {
      return GoogleSignIn(
        clientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
      );
    } else {
      return GoogleSignIn(
        serverClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
      );
    }
  });

  // Core
  sl.registerLazySingleton<NetworkInfo>(() => const NetworkInfoImpl());

  // Features - Auth
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton<AuthProvider>(() => AuthProvider(sl()));

  // Features - Exercise
  sl.registerLazySingleton<ExerciseService>(() => ExerciseService());
  sl.registerLazySingleton<ExerciseRepository>(
    () => ExerciseRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<ExerciseProvider>(() => ExerciseProvider(sl<ExerciseService>()));

  // Features - Workout
  sl.registerLazySingleton<WorkoutRepository>(
    () => WorkoutRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<WorkoutProvider>(() => WorkoutProvider(sl()));

  // Features - Metrics & Tracking
  sl.registerLazySingleton<MetricsRepository>(
    () => MetricsRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<MetricsProvider>(() => MetricsProvider(sl()));

  // Features - AI
  sl.registerLazySingleton<OfflineAIService>(() => OfflineAIService());
  sl.registerLazySingleton<GeminiAIService>(
    () => GeminiAIService(dotenv.get('GEMINI_API_KEY', fallback: '')),
  );
  sl.registerLazySingleton<AIRouter>(
    () => AIRouter(sl<OfflineAIService>(), sl<GeminiAIService>()),
  );
  sl.registerLazySingleton<AIRepository>(
    () => AIRepositoryImpl(sl<AIRouter>()),
  );
  sl.registerLazySingleton<AIProvider>(() => AIProvider(sl()));

  // Features - Profile Settings
  sl.registerLazySingleton<ProfileProvider>(() => ProfileProvider(sl()));
  sl.registerLazySingleton<ProgressPhotosProvider>(() => ProgressPhotosProvider(sl(), sl(), sl()));

  // Features - Challenges
  sl.registerLazySingleton<ChallengeRepository>(
    () => ChallengeRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<ChallengeProvider>(() => ChallengeProvider(sl()));

  // Features - Sleep & Nutrition Metrics
  sl.registerLazySingleton<SleepProvider>(() => SleepProvider(sl(), sl()));
  sl.registerLazySingleton<MealProvider>(() => MealProvider(sl()));

  // AI Food Scanner
  sl.registerLazySingleton<FoodScannerRepository>(() => FoodScannerRepositoryImpl());
  sl.registerLazySingleton<AnalyzeFoodImageUseCase>(() => AnalyzeFoodImageUseCase(sl()));
  sl.registerLazySingleton<ScannerProvider>(() => ScannerProvider(sl()));

  // Core tracking & notifications
  sl.registerLazySingleton<VoiceEngine>(() => OnDeviceVoiceEngine());
  sl.registerLazySingleton<VoiceCoachService>(() => VoiceCoachService(sl()));
  sl.registerLazySingleton<ActivityProvider>(() => ActivityProvider(sl()));
  sl.registerLazySingleton<NotificationProvider>(() => NotificationProvider(sl()));
  sl.registerLazySingleton<HeartRateProvider>(() => HeartRateProvider(sl(), sl()));
}
