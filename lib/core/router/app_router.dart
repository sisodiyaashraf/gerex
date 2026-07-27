import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
import '../../features/exercise/domain/entities/exercise.dart';
import '../../features/nutrition/presentation/screens/meal_schedule_screen.dart';
import '../../features/nutrition/presentation/screens/meal_browse_screen.dart';
import '../../features/profile/presentation/screens/guided_photo_capture_screen.dart';
import '../../features/profile/presentation/screens/progress_comparison_screen.dart';
import '../di/injection_container.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../presentation/widgets/glass_container.dart';
import '../theme/app_theme.dart';

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
        if (isLoggingIn || isOnboarding) return null;
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
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
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
        builder: (context, state) => const PoseFeedbackScreen(),
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
        builder: (context, state) => WorkoutDetailsScreen(
          workout: state.extra as Workout,
        ),
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
        builder: (context, state) => MealDetailsScreen(
          recipe: state.extra as Recipe,
        ),
      ),
      GoRoute(
        path: '/exercise-detail',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return ExerciseDetailScreen(
            exercise: extra['exercise'] as Exercise,
            isPicker: extra['isPicker'] as bool? ?? false,
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
        path: '/guided-capture',
        builder: (context, state) => const GuidedPhotoCaptureScreen(),
      ),
      GoRoute(
        path: '/progress-compare',
        builder: (context, state) => const ProgressComparisonScreen(),
      ),
      GoRoute(
        path: '/challenge-detail',
        builder: (context, state) => ChallengeDetailScreen(
          challenge: state.extra as Challenge,
        ),
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
    final theme = Theme.of(context);

    return Scaffold(
      extendBody: true, // Allows body stack to bleed behind navigation overlay
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex,
              children: _tabs,
            ),
          ),
          
          Positioned(
            left: 24,
            right: 24,
            bottom: 12 + MediaQuery.of(context).padding.bottom,
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              borderRadius: 28,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, FontAwesomeIcons.dumbbell, 'Workouts', theme),
                  _buildNavItem(1, FontAwesomeIcons.compass, 'Explore', theme),
                  _buildNavItem(2, FontAwesomeIcons.bowlFood, 'Meals', theme),
                  _buildNavItem(3, FontAwesomeIcons.chartSimple, 'Analytics', theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, dynamic icon, String label, ThemeData theme) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isActive ? GerexGradients.primaryCTA : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              icon,
              size: isActive ? 18.0 : 16.0,
              color: isActive ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
