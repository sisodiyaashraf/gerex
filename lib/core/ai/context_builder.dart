import '../../core/di/injection_container.dart' as di;
import '../../features/workout/presentation/providers/workout_provider.dart';
import '../../features/metrics/presentation/providers/metrics_provider.dart';
import '../../core/providers/activity_provider.dart';
import '../../features/nutrition/presentation/providers/meal_provider.dart';
import '../../features/exercise/presentation/providers/exercise_provider.dart';

class ContextBuilder {
  ContextBuilder._();

  /// Compiles a short, relevant context snapshot of the user's fitness state and app data.
  static String buildContext() {
    try {
      final workoutProvider = di.sl<WorkoutProvider>();
      final metricsProvider = di.sl<MetricsProvider>();
      final activityProvider = di.sl<ActivityProvider>();
      final mealProvider = di.sl<MealProvider>();
      final exerciseProvider = di.sl<ExerciseProvider>();

      // 1. Static features summary
      const featuresSummary = 
          'Gerex Capabilities Guide & Scope Constraints:\n'
          '- Workout Tracker: log sets/reps/weights, live duration, rest timers.\n'
          '- Exercises library: browse muscle group categories.\n'
          '- Meal Planner: track calorie intake (breakfast/lunch/dinner).\n'
          '- Sleep Tracker: sleep alarms & recovery quality percentages.\n'
          '- Progress Gallery: front/side/back photo comparisons.\n'
          '- Challenges: join workouts & cardio/strength challenges.\n'
          'CRITICAL SCOPE RULE: You are ONLY allowed to answer questions regarding workouts, exercises, meal planning, nutrition, sleep logs, activity/hydration stats, BMI, progress photos, or app navigation. If the user\'s query falls outside these fitness-focused domains, you MUST state that you are the Gerex AI Coach and refuse to answer the out-of-scope question, redirecting the user back to fitness/nutrition/sleep domains.\n';

      // 2. User current state snapshot
      final streak = metricsProvider.currentStreak;
      final totalWorkouts = workoutProvider.sessions.length;
      final lastWorkout = workoutProvider.sessions.isNotEmpty 
          ? workoutProvider.sessions.first.name 
          : 'None logged yet';

      // Today's metrics from ActivityProvider
      final steps = activityProvider.stepsCount;
      final stepsTarget = activityProvider.stepsTarget;
      final water = activityProvider.waterIntake;
      final waterTarget = activityProvider.waterTarget;
      final sleep = activityProvider.sleepHours;
      final caloriesBurn = activityProvider.calories; // active calorie estimate
      final caloriesTarget = activityProvider.caloriesTarget;

      // Calories consumed today from MealProvider
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final todayMeals = mealProvider.mealPlan.where((m) {
        return m.date.toIso8601String().startsWith(todayStr);
      });
      double consumedKcal = 0;
      double consumedProt = 0;
      double consumedCarb = 0;
      double consumedFat = 0;
      for (var entry in todayMeals) {
        consumedKcal += entry.calories;
        consumedProt += entry.protein;
        consumedCarb += entry.carbs;
        consumedFat += entry.fat;
      }

      final userState = 
          'User Fitness Stats Snapshot:\n'
          '- Current Streak: $streak days\n'
          '- Total Workouts: $totalWorkouts completed\n'
          '- Last Workout: "$lastWorkout"\n'
          '- Today\'s Activity: $steps / $stepsTarget steps, $caloriesBurn / $caloriesTarget kcal burned\n'
          '- Today\'s Nutrition: ${consumedKcal.toInt()} kcal consumed (P: ${consumedProt.toInt()}g, C: ${consumedCarb.toInt()}g, F: ${consumedFat.toInt()}g)\n'
          '- Today\'s Hydration: $water / $waterTarget ml water\n'
          '- Sleep logged: $sleep hours\n';

      // 3. Database samples (cap to 5 items to keep it light)
      final exerciseSamples = exerciseProvider.exercises.take(5).map((e) => e.name).join(', ');
      final mealSamples = mealProvider.recipes.take(5).map((r) => r.name).join(', ');

      final dbSummary = 
          'Database Categories:\n'
          '- Exercises available: $exerciseSamples\n'
          '- Recipes available: $mealSamples\n';

      return '$featuresSummary\n$userState\n$dbSummary';
    } catch (_) {
      return 'Gerex App Assistant Guide: Workout tracking, Exercise library, Meal planner, Sleep tracking, Challenges, and Progress galleries are active.';
    }
  }
}
