enum SleepConnectionState {
  connect,
  live,
  disconnected,
}

enum SleepSource {
  none,
  health,
  manual,
}

class SyncedSleepData {
  final double totalHours;
  final double deepHours;
  final double remHours;
  final double lightHours;
  final double awakeHours;
  final bool hasStages;
  final DateTime wakeTime;

  const SyncedSleepData({
    required this.totalHours,
    required this.deepHours,
    required this.remHours,
    required this.lightHours,
    required this.awakeHours,
    required this.hasStages,
    required this.wakeTime,
  });
}

class SleepLog {
  final String id;
  final DateTime date;
  final double hours;
  final double quality; // sleep quality from 0.0 to 100.0
  final String? wakeUpMood; // e.g., 'Energized', 'Rested', 'Tired', 'Sore'

  const SleepLog({
    required this.id,
    required this.date,
    required this.hours,
    required this.quality,
    this.wakeUpMood,
  });

  factory SleepLog.fromJson(Map<String, dynamic> json) {
    return SleepLog(
      id: json['id'] as String,
      date: json['date'] != null ? DateTime.parse(json['date'] as String) : DateTime.now(),
      hours: (json['hours'] as num).toDouble(),
      quality: (json['quality'] as num).toDouble(),
      wakeUpMood: json['wake_up_mood'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'hours': hours,
      'quality': quality,
      'wake_up_mood': wakeUpMood,
    };
  }
}

class SleepAlarm {
  final String id;
  final String bedtimeHour; // e.g. "22:30"
  final String wakeHour; // e.g. "06:30" (For smart alarm, this represents the end of the wake window)
  final List<int> repeatDays; // Monday=1, Sunday=7
  final bool isEnabled;
  final bool vibrate;
  final bool isSmartAlarm;
  final String? smartAlarmWindowStart; // e.g. "06:00"

  const SleepAlarm({
    required this.id,
    required this.bedtimeHour,
    required this.wakeHour,
    required this.repeatDays,
    required this.isEnabled,
    required this.vibrate,
    this.isSmartAlarm = false,
    this.smartAlarmWindowStart,
  });

  factory SleepAlarm.fromJson(Map<String, dynamic> json) {
    return SleepAlarm(
      id: json['id'] as String,
      bedtimeHour: json['bedtime_hour'] as String,
      wakeHour: json['wake_hour'] as String,
      repeatDays: List<int>.from(json['repeat_days'] ?? []),
      isEnabled: json['is_enabled'] as bool? ?? true,
      vibrate: json['vibrate'] as bool? ?? true,
      isSmartAlarm: json['is_smart_alarm'] as bool? ?? false,
      smartAlarmWindowStart: json['smart_alarm_window_start'] as String?,
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
      'is_smart_alarm': isSmartAlarm,
      'smart_alarm_window_start': smartAlarmWindowStart,
    };
  }
}

