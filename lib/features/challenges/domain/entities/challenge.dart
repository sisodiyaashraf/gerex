import 'package:flutter/material.dart';

class Challenge {
  final String id;
  final String title;
  final String difficulty; // "easy" (or "beginner"), "hard", "very hard"
  final String type; // e.g. "Daily challenge"
  final String badgeIcon; // icon name or emoji representation
  final String description;
  final int totalMinutesGoal;
  final int usersJoined;

  const Challenge({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.type,
    required this.badgeIcon,
    required this.description,
    required this.totalMinutesGoal,
    required this.usersJoined,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as String,
      title: json['title'] as String,
      difficulty: (json['difficulty'] as String? ?? 'easy').toLowerCase(),
      type: json['type'] as String? ?? 'Daily challenge',
      badgeIcon: json['badge_icon'] as String? ?? 'award',
      description: json['description'] as String? ?? '',
      totalMinutesGoal: (json['total_minutes_goal'] as num? ?? 60).toInt(),
      usersJoined: (json['users_joined'] as num? ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'difficulty': difficulty,
      'type': type,
      'badge_icon': badgeIcon,
      'description': description,
      'total_minutes_goal': totalMinutesGoal,
      'users_joined': usersJoined,
    };
  }
}

extension ChallengeDifficultyExtension on Challenge {
  Color getDifficultyColor(BuildContext context) {
    switch (difficulty) {
      case 'easy':
      case 'beginner':
      case 'beginner-friendly':
        return const Color(0xFF10B981); // Emerald Green
      case 'hard':
      case 'medium':
      case 'intermediate':
        return Colors.amber; // Amber
      case 'very hard':
      case 'advanced':
      case 'expert':
        return const Color(0xFFEF4444); // Red/Coral (from new destructive token)
      default:
        return const Color(0xFF10B981);
    }
  }

  String get difficultyLabel {
    switch (difficulty) {
      case 'easy':
      case 'beginner':
      case 'beginner-friendly':
        return 'Easy';
      case 'hard':
      case 'medium':
      case 'intermediate':
        return 'Hard';
      case 'very hard':
      case 'advanced':
        return 'Very Hard';
      default:
        return difficulty;
    }
  }
}
