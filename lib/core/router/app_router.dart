import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/exercise/presentation/providers/exercise_provider.dart';
import '../../features/workout/presentation/providers/workout_provider.dart';
import '../../features/nutrition/presentation/providers/meal_provider.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/challenges/presentation/screens/select_challenge_screen.dart';
import '../../features/challenges/presentation/screens/challenge_detail_screen.dart';
import '../../features/challenges/domain/entities/challenge.dart';
import '../../features/profile/presentation/screens/select_plan_screen.dart';
import '../../features/metrics/presentation/screens/metrics_dashboard_screen.dart';
import '../../features/workout/presentation/screens/live_session_screen.dart';
import '../../features/workout/presentation/screens/workout_builder_screen.dart';
import '../../features/workout/presentation/screens/workouts_tab.dart';
import '../../features/ai/presentation/screens/ai_coach_chat_screen.dart';
import '../../features/ai/presentation/screens/ai_plan_generator_screen.dart';
import '../../features/ai/presentation/screens/pose_feedback_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/workout/presentation/screens/workout_tracker_screen.dart';
import '../../features/workout/domain/entities/workout_entities.dart';
import '../../features/workout/presentation/screens/workout_details_screen.dart';
import '../../features/metrics/presentation/screens/activity_tracker_screen.dart';
import '../../features/profile/presentation/screens/notification_screen.dart';
import '../../features/profile/presentation/screens/progress_photos_screen.dart';
import '../../features/metrics/presentation/screens/sleep_tracker_screen.dart';
import '../../features/metrics/presentation/screens/sleep_schedule_screen.dart';
import '../../features/metrics/presentation/screens/add_alarm_screen.dart';
import '../../features/nutrition/presentation/screens/meal_planner_screen.dart';
import '../../features/nutrition/presentation/screens/meal_details_screen.dart';
import '../../features/nutrition/domain/entities/meal_entities.dart';
import '../../features/exercise/presentation/screens/exercise_detail_screen.dart';
import '../../features/exercise/presentation/screens/exercise_browse_screen.dart';
import '../../features/exercise/domain/entities/exercise.dart';
import '../../features/nutrition/presentation/screens/meal_schedule_screen.dart';
import '../../features/nutrition/presentation/screens/meal_browse_screen.dart';
import '../../features/nutrition/presentation/screens/meal_barcode_scanner_screen.dart';
import '../../features/profile/presentation/screens/guided_photo_capture_screen.dart';
import '../../features/metrics/presentation/screens/heart_rate_connection_screen.dart';
import '../../features/profile/presentation/screens/progress_comparison_screen.dart';
import '../../features/workout/presentation/screens/quick_workout_screen.dart';
import '../../features/exercise/presentation/screens/add_exercise_screen.dart';
import '../../features/exercise/presentation/screens/create_exercise_screen.dart';
import '../di/injection_container.dart';
import '../presentation/widgets/liquid_glass_nav_bar.dart';


class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: sl<AuthProvider>(),
    redirect: (context, state) {
      final authProvider = sl<AuthProvider>();
      final isAuthenticated = authProvider.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login';
      final isSplashing = state.matchedLocation == '/splash';
      final isOnboarding = state.matchedLocation == '/onboarding';

      if (!authProvider.isInitialized) {
        return '/splash';
      }

      if (!authProvider.onboardingCompleted) {
        if (isOnboarding) return null;
        return '/onboarding';
      }

      if (!isAuthenticated) {
        if (isLoggingIn) return null;
        return '/login';
      }

      if (isAuthenticated && (isLoggingIn || isSplashing || isOnboarding)) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/',
        builder: (context, state) => const _MainNavigationShell(),
      ),
      GoRoute(
        path: '/builder',
        builder: (context, state) => const WorkoutBuilderScreen(),
      ),
      GoRoute(
        path: '/session',
        builder: (context, state) => const LiveSessionScreen(),
      ),
      GoRoute(
        path: '/coach',
        builder: (context, state) => const AICoachChatScreen(),
      ),
      GoRoute(
        path: '/ai-plan',
        builder: (context, state) => const AIPlanGeneratorScreen(),
      ),
      GoRoute(
        path: '/pose-feedback',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return PoseFeedbackScreen(
            targetExercise: extra?['targetExercise'] as String?,
            customPattern: extra?['customPattern'] as Map<String, dynamic>?,
          );
        },
      ),
      GoRoute(
        path: '/quick-workout',
        builder: (context, state) => const QuickWorkoutScreen(),
      ),
      GoRoute(
        path: '/add-exercise',
        builder: (context, state) {
          final ids = (state.extra as List<String>?) ?? const [];
          return AddExerciseScreen(initiallySelectedIds: ids);
        },
      ),
      GoRoute(
        path: '/create-exercise',
        builder: (context, state) => const CreateExerciseScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/workout-tracker',
        builder: (context, state) => const WorkoutTrackerScreen(),
      ),
      GoRoute(
        path: '/workout-details',
        builder: (context, state) {
          Workout? workout;
          if (state.extra is Workout) {
            workout = state.extra as Workout;
          } else {
            final id = state.uri.queryParameters['id'];
            if (id != null) {
              try {
                final wp = Provider.of<WorkoutProvider>(context, listen: false);
                workout = wp.workouts.firstWhere((w) => w.id == id);
              } catch (_) {}
            }
          }
          if (workout != null) {
            return WorkoutDetailsScreen(workout: workout);
          }
          return const Scaffold(
            body: Center(
              child: Text('Workout not found'),
            ),
          );
        },
      ),
      GoRoute(
        path: '/activity-tracker',
        builder: (context, state) => const ActivityTrackerScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationScreen(),
      ),
      GoRoute(
        path: '/progress-photos',
        builder: (context, state) => const ProgressPhotosScreen(),
      ),
      GoRoute(
        path: '/heart-rate-connect',
        builder: (context, state) => const HeartRateConnectionScreen(),
      ),
      GoRoute(
        path: '/sleep-tracker',
        builder: (context, state) => const SleepTrackerScreen(),
      ),
      GoRoute(
        path: '/sleep-schedule',
        builder: (context, state) => const SleepScheduleScreen(),
      ),
      GoRoute(
        path: '/add-alarm',
        builder: (context, state) => const AddAlarmScreen(),
      ),
      GoRoute(
        path: '/meal-planner',
        builder: (context, state) => const MealPlannerScreen(),
      ),
      GoRoute(
        path: '/meal-details',
        builder: (context, state) {
          Recipe? recipe;
          if (state.extra is Recipe) {
            recipe = state.extra as Recipe;
          } else {
            final id = state.uri.queryParameters['id'];
            if (id != null) {
              try {
                final mp = Provider.of<MealProvider>(context, listen: false);
                recipe = mp.recipes.firstWhere((r) => r.id == id);
              } catch (_) {}
            }
          }
          if (recipe != null) {
            return MealDetailsScreen(recipe: recipe);
          }
          return const Scaffold(
            body: Center(
              child: Text('Recipe not found'),
            ),
          );
        },
      ),
      GoRoute(
        path: '/exercise-library',
        builder: (context, state) => const ExerciseBrowseScreen(),
      ),
      GoRoute(
        path: '/exercise-detail',
        builder: (context, state) {
          Exercise? exercise;
          bool isPicker = false;
          if (state.extra is Map<String, dynamic>) {
            final extra = state.extra as Map<String, dynamic>;
            exercise = extra['exercise'] as Exercise?;
            isPicker = extra['isPicker'] as bool? ?? false;
          } else {
            final id = state.uri.queryParameters['id'];
            if (id != null) {
              try {
                final ep = Provider.of<ExerciseProvider>(context, listen: false);
                exercise = ep.allRawExercises.firstWhere((e) => e.id == id);
              } catch (_) {
                try {
                  final ep = Provider.of<ExerciseProvider>(context, listen: false);
                  exercise = ep.exercises.firstWhere((e) => e.id == id);
                } catch (_) {}
              }
            }
          }
          if (exercise != null) {
            return ExerciseDetailScreen(
              exercise: exercise,
              isPicker: isPicker,
            );
          }
          return const Scaffold(
            body: Center(
              child: Text('Exercise not found'),
            ),
          );
        },
      ),
      GoRoute(
        path: '/meal-schedule',
        builder: (context, state) => const MealScheduleScreen(),
      ),
      GoRoute(
        path: '/meal-browse',
        builder: (context, state) => const MealBrowseScreen(),
      ),
      GoRoute(
        path: '/meal-barcode-scanner',
        builder: (context, state) => const MealBarcodeScannerScreen(),
      ),
      GoRoute(
        path: '/analytics',
        builder: (context, state) => const MetricsDashboardScreen(),
      ),
      GoRoute(
        path: '/guided-capture',
        builder: (context, state) => const GuidedPhotoCaptureScreen(),
      ),
      GoRoute(
        path: '/progress-compare',
        builder: (context, state) => const ProgressComparisonScreen(),
      ),
      GoRoute(
        path: '/challenge-detail',
        builder: (context, state) =>
            ChallengeDetailScreen(challenge: state.extra as Challenge),
      ),
      GoRoute(
        path: '/select-plan',
        builder: (context, state) => const SelectPlanScreen(),
      ),
    ],
  );
}

class _MainNavigationShell extends StatefulWidget {
  const _MainNavigationShell();

  @override
  State<_MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<_MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    WorkoutsTab(),
    SelectChallengeScreen(),
    MealPlannerScreen(),
    MetricsDashboardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allows body stack to bleed behind navigation overlay
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(index: _currentIndex, children: _tabs),
          ),

          Positioned(
            left: 24,
            right: 24,
            bottom: 12 + MediaQuery.of(context).padding.bottom,
            child: LiquidGlassNavBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              items: const [
                LiquidGlassNavBarItem(
                  icon: 'assets/svg icons/barbel.svg',
                  label: 'Workouts',
                ),
                LiquidGlassNavBarItem(
                  icon: 'assets/images/explore_icon.png',
                  label: 'Explore',
                ),
                LiquidGlassNavBarItem(
                  icon: 'assets/images/meal_icon.png',
                  label: 'Meals',
                ),
                LiquidGlassNavBarItem(
                  icon: 'assets/images/analytics_icon.png',
                  label: 'Analytics',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
