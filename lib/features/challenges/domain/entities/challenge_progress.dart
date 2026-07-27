class ChallengeProgress {
  final String id;
  final String challengeId;
  final String userId;
  final int progressMinutes;
  final String status; // "joined", "completed"
  final DateTime joinedAt;

  const ChallengeProgress({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.progressMinutes,
    required this.status,
    required this.joinedAt,
  });

  factory ChallengeProgress.fromJson(Map<String, dynamic> json) {
    return ChallengeProgress(
      id: json['id'] as String,
      challengeId: json['challenge_id'] as String,
      userId: json['user_id'] as String? ?? '',
      progressMinutes: (json['progress_minutes'] as num? ?? 0).toInt(),
      status: json['status'] as String? ?? 'joined',
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'challenge_id': challengeId,
      'user_id': userId,
      'progress_minutes': progressMinutes,
      'status': status,
      'joined_at': joinedAt.toIso8601String(),
    };
  }

  ChallengeProgress copyWith({
    String? id,
    String? challengeId,
    String? userId,
    int? progressMinutes,
    String? status,
    DateTime? joinedAt,
  }) {
    return ChallengeProgress(
      id: id ?? this.id,
      challengeId: challengeId ?? this.challengeId,
      userId: userId ?? this.userId,
      progressMinutes: progressMinutes ?? this.progressMinutes,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}
