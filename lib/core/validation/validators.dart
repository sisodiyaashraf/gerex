class Validators {
  // Email check regex
  static final RegExp _emailRegExp = RegExp(
    r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$',
  );

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required.';
    }
    if (value.length > 255) {
      return 'Email address is too long (max 255 characters).';
    }
    if (!_emailRegExp.hasMatch(value.trim())) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long.';
    }
    if (value.length > 72) {
      return 'Password must not exceed 72 characters.';
    }
    return null;
  }

  static String? validateWorkoutName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Workout template name is required.';
    }
    if (value.trim().length > 50) {
      return 'Workout name cannot exceed 50 characters.';
    }
    return null;
  }

  static String? validateExerciseName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Exercise name is required.';
    }
    if (value.trim().length > 50) {
      return 'Exercise name cannot exceed 50 characters.';
    }
    return null;
  }

  static String? validateMuscleGroup(String? value) {
    if (value == null || value.trim().isEmpty || value.trim() == 'All') {
      return 'Please select a valid target muscle group.';
    }
    if (value.trim().length > 30) {
      return 'Muscle group cannot exceed 30 characters.';
    }
    return null;
  }

  static String? validateEquipment(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please select or enter the required equipment.';
    }
    if (value.trim().length > 30) {
      return 'Equipment name cannot exceed 30 characters.';
    }
    return null;
  }

  static String? validateReps(String? value) {
    if (value == null || value.isEmpty) {
      return 'Required.';
    }
    final parsed = int.tryParse(value);
    if (parsed == null || parsed <= 0) {
      return 'Must be positive.';
    }
    if (parsed > 200) {
      return 'Max 200.';
    }
    return null;
  }

  static String? validateSetsCount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Required.';
    }
    final parsed = int.tryParse(value);
    if (parsed == null || parsed <= 0) {
      return 'Must be positive.';
    }
    if (parsed > 50) {
      return 'Max 50.';
    }
    return null;
  }

  static String? validateWeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Required.';
    }
    final parsed = double.tryParse(value);
    if (parsed == null || parsed < 0) {
      return 'Invalid weight.';
    }
    if (parsed > 1000.0) {
      return 'Max 1000 kg/lb.';
    }
    return null;
  }

  static String? validateBodyWeightLog(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your current body weight.';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed <= 20.0 || parsed >= 350.0) {
      return 'Weight must be a valid number between 20.0 kg and 350.0 kg.';
    }
    return null;
  }

  static String? validateAiChatInput(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Message cannot be empty.';
    }
    if (value.trim().length > 500) {
      return 'Message cannot exceed 500 characters.';
    }
    return null;
  }
}
