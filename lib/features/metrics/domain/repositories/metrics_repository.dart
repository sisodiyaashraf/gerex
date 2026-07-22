import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../entities/metrics_entities.dart';

abstract class MetricsRepository {
  Future<Result<List<BodyMetric>, Failure>> getMetrics(String metricType);
  Future<Result<BodyMetric, Failure>> logMetric(BodyMetric metric);
  Future<Result<List<ProgressDataPoint>, Failure>> getVolumeProgression(
    String exerciseId,
  );
}
