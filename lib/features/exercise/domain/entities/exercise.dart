class Exercise {
  final String id;
  final String name;
  final String muscleGroup;
  final String equipment;
  final List<String> instructions;
  final String? userId;

  const Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.equipment,
    required this.instructions,
    this.userId,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      muscleGroup: json['muscle_group'] as String,
      equipment: json['equipment'] as String,
      instructions: List<String>.from(json['instructions'] ?? []),
      userId: json['user_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'muscle_group': muscleGroup,
      'equipment': equipment,
      'instructions': instructions,
      if (userId != null) 'user_id': userId,
    };
  }
}
