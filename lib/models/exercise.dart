class Exercise {
  final String id;
  final String name;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final String equipment;
  final String category;
  final String level;
  final String? mechanic;
  final String? force;
  final List<String> instructions;
  final List<String> images;
  final Map<String, dynamic>? posePattern;

  const Exercise({
    required this.id,
    required this.name,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    this.equipment = 'none',
    required this.category,
    required this.level,
    this.mechanic,
    this.force,
    required this.instructions,
    required this.images,
    this.posePattern,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown Exercise',
      primaryMuscles: List<String>.from(json['primaryMuscles'] ?? []),
      secondaryMuscles: List<String>.from(json['secondaryMuscles'] ?? []),
      equipment: json['equipment'] as String? ?? 'none',
      category: json['category'] as String? ?? 'general',
      level: json['level'] as String? ?? 'beginner',
      mechanic: json['mechanic'] as String?,
      force: json['force'] as String?,
      instructions: List<String>.from(json['instructions'] ?? []),
      images: List<String>.from(json['images'] ?? []),
      posePattern: json['posePattern'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'primaryMuscles': primaryMuscles,
      'secondaryMuscles': secondaryMuscles,
      'equipment': equipment,
      'category': category,
      'level': level,
      'mechanic': mechanic,
      'force': force,
      'instructions': instructions,
      'images': images,
      'posePattern': posePattern,
    };
  }

  // Computed imageUrl getter for the CDN
  String? get imageUrl => images.isNotEmpty
      ? 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/${images.first}'
      : null;

  // Backwards compatibility properties for the rest of the application
  String get muscleGroup {
    if (primaryMuscles.isEmpty) return 'General';
    final first = primaryMuscles.first;
    if (first.isEmpty) return 'General';
    return first[0].toUpperCase() + first.substring(1);
  }

  String? get imagePath => imageUrl;
  String? get effectiveImagePath => imageUrl;
  bool get removeBackground => false;
  String? get userId => null;

  String get difficulty {
    if (level.isEmpty) return 'Beginner';
    return level[0].toUpperCase() + level.substring(1);
  }

  double get baseCalorieBurnPerRep {
    final diff = difficulty.toLowerCase();
    if (diff == 'expert' || diff == 'advanced') return 0.6;
    if (diff == 'intermediate') return 0.4;
    return 0.25;
  }
}
