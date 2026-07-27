class SleepLog {
  final String id;
  final DateTime date;
  final double hours;
  final double quality; // sleep quality from 0.0 to 100.0

  const SleepLog({
    required this.id,
    required this.date,
    required this.hours,
    required this.quality,
  });

  factory SleepLog.fromJson(Map<String, dynamic> json) {
    return SleepLog(
      id: json['id'] as String,
      date: json['date'] != null ? DateTime.parse(json['date'] as String) : DateTime.now(),
      hours: (json['hours'] as num).toDouble(),
      quality: (json['quality'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'hours': hours,
      'quality': quality,
    };
  }
}

class SleepAlarm {
  final String id;
  final String bedtimeHour; // e.g. "22:30"
  final String wakeHour; // e.g. "06:30"
  final List<int> repeatDays; // Monday=1, Sunday=7
  final bool isEnabled;
  final bool vibrate;

  const SleepAlarm({
    required this.id,
    required this.bedtimeHour,
    required this.wakeHour,
    required this.repeatDays,
    required this.isEnabled,
    required this.vibrate,
  });

  factory SleepAlarm.fromJson(Map<String, dynamic> json) {
    return SleepAlarm(
      id: json['id'] as String,
      bedtimeHour: json['bedtime_hour'] as String,
      wakeHour: json['wake_hour'] as String,
      repeatDays: List<int>.from(json['repeat_days'] ?? []),
      isEnabled: json['is_enabled'] as bool? ?? true,
      vibrate: json['vibrate'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bedtime_hour': bedtimeHour,
      'wake_hour': wakeHour,
      'repeat_days': repeatDays,
      'is_enabled': isEnabled,
      'vibrate': vibrate,
    };
  }
}
