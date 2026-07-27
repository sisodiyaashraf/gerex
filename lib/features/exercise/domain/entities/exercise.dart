class Exercise {
  final String id;
  final String name;
  final String muscleGroup;
  final String equipment;
  final List<String> instructions;
  final String? imagePath;
  final bool removeBackground;
  final String? userId;

  const Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.equipment,
    required this.instructions,
    this.imagePath,
    this.removeBackground = false,
    this.userId,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      muscleGroup: json['muscle_group'] as String,
      equipment: json['equipment'] as String,
      instructions: List<String>.from(json['instructions'] ?? []),
      imagePath: json['image_path'] as String?,
      removeBackground: json['remove_background'] as bool? ?? false,
      userId: json['user_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'muscle_group': muscleGroup,
      'equipment': equipment,
      'instructions': instructions,
      if (imagePath != null) 'image_path': imagePath,
      'remove_background': removeBackground,
      if (userId != null) 'user_id': userId,
    };
  }
}

extension ExerciseExtensions on Exercise {
  String get difficulty {
    if (name.contains('Squat') || name.contains('Deadlift')) return 'Advanced';
    if (name.contains('Push') || name.contains('Pull') || name.contains('Row') || name.contains('Press')) return 'Intermediate';
    return 'Beginner';
  }

  double get baseCalorieBurnPerRep {
    if (difficulty == 'Advanced') return 0.6;
    if (difficulty == 'Intermediate') return 0.4;
    return 0.25;
  }

  String? get effectiveImagePath {
    if (imagePath != null && imagePath!.isNotEmpty) {
      return imagePath;
    }
    final nameLower = name.toLowerCase();
    if (nameLower.contains('burpee')) return 'assets/exercise/burpee.png';
    if (nameLower.contains('jumping jack')) return 'assets/exercise/jumping jack.png';
    if (nameLower.contains('lunge')) return 'assets/exercise/lunges.png';
    if (nameLower.contains('mountain climber')) return 'assets/exercise/mountain climber.png';
    if (nameLower.contains('row')) return 'assets/exercise/rowing machine.png';
    if (nameLower.contains('squat')) return 'assets/exercise/cycling.png';
    if (nameLower.contains('deadlift')) return 'assets/exercise/kettlebell swing.png';
    if (nameLower.contains('curl') || nameLower.contains('press')) return 'assets/exercise/pushap.png';
    return null;
  }
}
