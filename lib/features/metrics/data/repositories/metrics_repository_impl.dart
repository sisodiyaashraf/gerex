import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import 'package:gerex/features/metrics/domain/entities/metrics_entities.dart';
import 'package:gerex/features/metrics/domain/repositories/metrics_repository.dart';

class MetricsRepositoryImpl implements MetricsRepository {
  final SupabaseClient _supabaseClient;

  MetricsRepositoryImpl(this._supabaseClient);

  @override
  Future<Result<List<BodyMetric>, Failure>> getMetrics(
    String metricType,
  ) async {
    try {
      final response = await _supabaseClient
          .from('body_metrics')
          .select()
          .eq('metric_type', metricType)
          .order('logged_at', ascending: true);

      final list = response as List<dynamic>;
      final metrics = list
          .map((json) => BodyMetric.fromJson(json as Map<String, dynamic>))
          .toList();
      return Success(metrics);
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<BodyMetric, Failure>> logMetric(BodyMetric metric) async {
    try {
      final response = await _supabaseClient
          .from('body_metrics')
          .insert(metric.toJson())
          .select()
          .single();
      final logged = BodyMetric.fromJson(response);
      return Success(logged);
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<ProgressDataPoint>, Failure>> getVolumeProgression(
    String exerciseId,
  ) async {
    try {
      final response = await _supabaseClient
          .from('workout_sets_logged')
          .select('reps, weight, workout_sessions(completed_at)')
          .eq('exercise_id', exerciseId)
          .eq('is_completed', true);

      final list = response as List<dynamic>;
      final Map<String, double> dailyVolume = {};

      for (final item in list) {
        final reps = item['reps'] as int;
        final weight = (item['weight'] as num).toDouble();
        final session = item['workout_sessions'] as Map<String, dynamic>?;

        if (session != null && session['completed_at'] != null) {
          final dateStr = (session['completed_at'] as String).substring(0, 10);
          final volume = reps * weight;
          dailyVolume[dateStr] = (dailyVolume[dateStr] ?? 0.0) + volume;
        }
      }

      final dataPoints = dailyVolume.entries.map((e) {
        return ProgressDataPoint(
          date: DateTime.parse(e.key),
          value: e.value,
        );
      }).toList();

      dataPoints.sort((a, b) => a.date.compareTo(b.date));
      return Success(dataPoints);
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }
}
