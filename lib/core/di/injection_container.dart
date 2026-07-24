import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
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
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/profile/presentation/providers/profile_provider.dart';
import '../network/network_info.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External
  final sharedPrefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPrefs);

  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  sl.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn(
        serverClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
      ));

  // Core
  sl.registerLazySingleton<NetworkInfo>(() => const NetworkInfoImpl());

  // Features - Auth
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton<AuthProvider>(() => AuthProvider(sl()));

  // Features - Exercise
  sl.registerLazySingleton<ExerciseRepository>(
    () => ExerciseRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<ExerciseProvider>(() => ExerciseProvider(sl()));

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
  sl.registerLazySingleton<AIRepository>(
    () => AIRepositoryImpl(dotenv.get('GEMINI_API_KEY')),
  );
  sl.registerLazySingleton<AIProvider>(() => AIProvider(sl()));

  // Features - Profile Settings
  sl.registerLazySingleton<ProfileProvider>(() => ProfileProvider(sl()));
}
