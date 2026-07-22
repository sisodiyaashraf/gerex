class BodyMetric {
  final String id;
  final String? userId;
  final String metricType;
  final double value;
  final DateTime loggedAt;

  const BodyMetric({
    required this.id,
    this.userId,
    required this.metricType,
    required this.value,
    required this.loggedAt,
  });

  factory BodyMetric.fromJson(Map<String, dynamic> json) {
    return BodyMetric(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      metricType: json['metric_type'] as String,
      value: (json['value'] as num).toDouble(),
      loggedAt: DateTime.parse(json['logged_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (userId != null) 'user_id': userId,
      'metric_type': metricType,
      'value': value,
      'logged_at':
          '${loggedAt.year}-${loggedAt.month.toString().padLeft(2, '0')}-${loggedAt.day.toString().padLeft(2, '0')}',
    };
  }
}

class ProgressDataPoint {
  final DateTime date;
  final double value;

  const ProgressDataPoint({
    required this.date,
    required this.value,
  });
}
