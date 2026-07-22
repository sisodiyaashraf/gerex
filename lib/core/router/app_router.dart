import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/exercise/presentation/screens/exercise_library_screen.dart';
import '../../features/metrics/presentation/screens/metrics_dashboard_screen.dart';
import '../../features/workout/presentation/screens/live_session_screen.dart';
import '../../features/workout/presentation/screens/workout_builder_screen.dart';
import '../../features/workout/presentation/screens/workouts_tab.dart';
import '../../features/ai/presentation/screens/ai_coach_chat_screen.dart';
import '../../features/ai/presentation/screens/ai_plan_generator_screen.dart';
import '../../features/ai/presentation/screens/pose_feedback_screen.dart';
import '../di/injection_container.dart';

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

      if (!isAuthenticated) {
        if (isSplashing) return null;
        return '/login';
      }

      if (isAuthenticated && (isLoggingIn || isSplashing)) {
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
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) {
          setState(() {
            _currentIndex = idx;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center_rounded),
            label: 'Workouts',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            selectedIcon: Icon(Icons.library_books_rounded),
            label: 'Exercises',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics_rounded),
            label: 'Analytics',
          ),
        ],
        backgroundColor: theme.colorScheme.surface,
        indicatorColor: theme.colorScheme.primaryContainer,
      ),
    );
  }
}
