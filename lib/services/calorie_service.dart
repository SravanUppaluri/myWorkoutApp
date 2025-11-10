import '../models/workout_session.dart';

class CalorieService {
  // METs values for different exercise types and intensities
  static const Map<String, Map<String, double>> exerciseMETsValues = {
    // Strength Training
    'strength': {
      'light': 3.0, // Light effort
      'moderate': 4.5, // Moderate effort
      'vigorous': 6.0, // Vigorous effort
    },

    // Cardiovascular
    'cardio': {
      'light': 4.0, // Walking, light pace
      'moderate': 6.5, // Jogging, moderate pace
      'vigorous': 9.0, // Running, vigorous pace
    },

    // Specific Exercise Types
    'push_ups': {'light': 3.8, 'moderate': 4.5, 'vigorous': 5.5},

    'pull_ups': {'light': 4.0, 'moderate': 5.0, 'vigorous': 6.0},

    'squats': {'light': 3.5, 'moderate': 4.5, 'vigorous': 5.5},

    'deadlifts': {'light': 4.0, 'moderate': 5.0, 'vigorous': 6.5},

    'bench_press': {'light': 3.5, 'moderate': 4.5, 'vigorous': 5.5},

    'bicep_curls': {'light': 3.0, 'moderate': 3.5, 'vigorous': 4.0},

    'lunges': {'light': 3.5, 'moderate': 4.5, 'vigorous': 5.5},

    'planks': {'light': 3.0, 'moderate': 4.0, 'vigorous': 5.0},

    'burpees': {'light': 6.0, 'moderate': 8.0, 'vigorous': 10.0},

    'mountain_climbers': {'light': 5.0, 'moderate': 7.0, 'vigorous': 9.0},

    // Default fallback values
    'default': {'light': 3.0, 'moderate': 4.5, 'vigorous': 6.0},
  };

  /// Calculate calories burned for a workout session
  /// Formula: Calories = METs × weight (kg) × time (hours)
  static double calculateSessionCalories({
    required WorkoutSession session,
    required double userWeightKg,
  }) {
    double totalCalories = 0.0;

    for (final exercise in session.completedExercises) {
      final exerciseCalories = calculateExerciseCalories(
        exerciseName: exercise.exerciseName,
        sets: exercise.sets,
        userWeightKg: userWeightKg,
      );
      totalCalories += exerciseCalories;
    }

    return totalCalories;
  }

  /// Calculate calories for a specific exercise
  static double calculateExerciseCalories({
    required String exerciseName,
    required List<CompletedSet> sets,
    required double userWeightKg,
  }) {
    // Determine exercise type and intensity
    final exerciseType = _getExerciseType(exerciseName);
    final intensity = _calculateIntensity(sets);

    // Get METs value
    final metsValue = _getMETsValue(exerciseType, intensity);

    // Calculate total exercise time in hours
    final totalTimeHours = _calculateExerciseTime(sets);

    // Calculate calories: METs × weight (kg) × time (hours)
    final calories = metsValue * userWeightKg * totalTimeHours;

    return calories;
  }

  /// Get exercise type from exercise name
  static String _getExerciseType(String exerciseName) {
    final lowercaseName = exerciseName.toLowerCase();

    // Check for specific exercise types
    for (final type in exerciseMETsValues.keys) {
      if (lowercaseName.contains(type.replaceAll('_', ' ')) ||
          lowercaseName.contains(type.replaceAll('_', ''))) {
        return type;
      }
    }

    // Check for common strength training keywords
    if (lowercaseName.contains('press') ||
        lowercaseName.contains('curl') ||
        lowercaseName.contains('row') ||
        lowercaseName.contains('extension') ||
        lowercaseName.contains('raise')) {
      return 'strength';
    }

    // Check for cardio keywords
    if (lowercaseName.contains('run') ||
        lowercaseName.contains('walk') ||
        lowercaseName.contains('cycle') ||
        lowercaseName.contains('jump')) {
      return 'cardio';
    }

    return 'default';
  }

  /// Calculate exercise intensity based on weight and reps
  static String _calculateIntensity(List<CompletedSet> sets) {
    if (sets.isEmpty) return 'moderate';

    // Calculate average weight and reps
    double totalWeight = 0.0;
    double totalReps = 0.0;
    int validSets = 0;

    for (final set in sets) {
      if (set.weight != null && set.reps != null && set.completed) {
        totalWeight += set.weight!;
        totalReps += set.reps!;
        validSets++;
      }
    }

    if (validSets == 0) return 'moderate';

    final avgWeight = totalWeight / validSets;
    final avgReps = totalReps / validSets;

    // Intensity heuristics
    if (avgReps > 15 || avgWeight < 20) {
      return 'light';
    } else if (avgReps < 6 || avgWeight > 80) {
      return 'vigorous';
    } else {
      return 'moderate';
    }
  }

  /// Get METs value for exercise type and intensity
  static double _getMETsValue(String exerciseType, String intensity) {
    final exerciseValues =
        exerciseMETsValues[exerciseType] ?? exerciseMETsValues['default']!;
    return exerciseValues[intensity] ?? exerciseValues['moderate']!;
  }

  /// Calculate exercise time based on sets and rest periods
  static double _calculateExerciseTime(List<CompletedSet> sets) {
    if (sets.isEmpty) return 0.0;

    // Estimate time based on number of sets
    // Assume each set takes 30-60 seconds + rest time
    final setCount = sets.length;
    final estimatedSetTime = 45; // seconds per set (average)
    final estimatedRestTime = 60; // seconds rest between sets

    final totalSeconds =
        (setCount * estimatedSetTime) + ((setCount - 1) * estimatedRestTime);

    // Convert to hours
    return totalSeconds / 3600;
  }

  /// Calculate total calories burned today
  static double calculateTodayCalories({
    required List<WorkoutSession> todaySessions,
    required double userWeightKg,
  }) {
    double totalCalories = 0.0;

    for (final session in todaySessions) {
      totalCalories += calculateSessionCalories(
        session: session,
        userWeightKg: userWeightKg,
      );
    }

    return totalCalories;
  }

  /// Calculate calories burned this week
  static double calculateWeeklyCalories({
    required List<WorkoutSession> weeklySessions,
    required double userWeightKg,
  }) {
    double totalCalories = 0.0;

    for (final session in weeklySessions) {
      totalCalories += calculateSessionCalories(
        session: session,
        userWeightKg: userWeightKg,
      );
    }

    return totalCalories;
  }

  /// Get user weight from goal data or use default
  static double getUserWeight(Map<String, dynamic>? goalData) {
    if (goalData == null) return 70.0; // Default weight in kg

    // Try to parse weight from goal data
    final weightGoal = goalData['weightGoal'] as String?;
    if (weightGoal != null) {
      // Extract number from weight goal (e.g., "Lose 5kg" -> current weight estimate)
      final RegExp regex = RegExp(r'(\d+(?:\.\d+)?)');
      final match = regex.firstMatch(weightGoal);
      if (match != null) {
        final goalWeight = double.tryParse(match.group(1)!) ?? 70.0;

        // If it's a loss goal, add some weight to estimate current weight
        if (weightGoal.toLowerCase().contains('lose')) {
          return goalWeight + 10; // Estimate current weight
        } else if (weightGoal.toLowerCase().contains('gain')) {
          return goalWeight - 5; // Estimate current weight
        }

        return goalWeight;
      }
    }

    return 70.0; // Default weight in kg
  }

  /// Format calories for display
  static String formatCalories(double calories) {
    if (calories < 10) {
      return '${calories.toStringAsFixed(1)} cal';
    } else {
      return '${calories.round()} cal';
    }
  }

  /// Get calories burned per hour rate for current workout
  static double getCalorieRate({
    required String exerciseType,
    required double userWeightKg,
    String intensity = 'moderate',
  }) {
    final metsValue = _getMETsValue(exerciseType, intensity);
    return metsValue * userWeightKg; // Calories per hour
  }
}
