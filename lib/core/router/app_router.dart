import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/exercise/presentation/screens/exercise_library_screen.dart';
import '../../features/metrics/presentation/screens/metrics_dashboard_screen.dart';
import '../../features/workout/presentation/screens/live_session_screen.dart';
import '../../features/workout/presentation/screens/workout_builder_screen.dart';
import '../../features/workout/presentation/screens/workouts_tab.dart';
import '../../features/ai/presentation/screens/ai_coach_chat_screen.dart';
import '../../features/ai/presentation/screens/ai_plan_generator_screen.dart';
import '../../features/ai/presentation/screens/pose_feedback_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
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
    ExerciseLibraryScreen(),
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
                  _buildNavItem(1, FontAwesomeIcons.bookOpen, 'Exercises', theme),
                  _buildNavItem(2, FontAwesomeIcons.chartSimple, 'Analytics', theme),
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
