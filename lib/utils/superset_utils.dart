import '../models/workout.dart';

class SupersetUtils {
  // Generate superset labels (A1, A2, B1, B2, etc.)
  static String generateSupersetLabel(int supersetIndex, int exerciseIndex) {
    final letter = String.fromCharCode(65 + supersetIndex); // A, B, C, etc.
    return '$letter${exerciseIndex + 1}';
  }

  // Group exercises by superset
  static Map<String, List<WorkoutExercise>> groupBySupersets(
    List<WorkoutExercise> exercises,
  ) {
    final Map<String, List<WorkoutExercise>> supersets = {};

    for (final exercise in exercises) {
      if (exercise.isInSuperset) {
        final key = exercise.supersetId!;
        if (!supersets.containsKey(key)) {
          supersets[key] = [];
        }
        supersets[key]!.add(exercise);
      }
    }

    // Sort exercises within each superset by their index
    for (final exercises in supersets.values) {
      exercises.sort(
        (a, b) => (a.supersetIndex ?? 0).compareTo(b.supersetIndex ?? 0),
      );
    }

    return supersets;
  }

  // Get all non-superset exercises
  static List<WorkoutExercise> getNonSupersetExercises(
    List<WorkoutExercise> exercises,
  ) {
    return exercises.where((exercise) => !exercise.isInSuperset).toList();
  }

  // Create a superset from selected exercises
  static List<WorkoutExercise> createSuperset(
    List<WorkoutExercise> exercises,
    String supersetId,
    int supersetIndex,
  ) {
    final List<WorkoutExercise> supersetExercises = [];

    for (int i = 0; i < exercises.length; i++) {
      final exercise = exercises[i];
      final label = generateSupersetLabel(supersetIndex, i);

      supersetExercises.add(
        exercise.copyWith(
          supersetId: supersetId,
          supersetIndex: i,
          supersetLabel: label,
          isSupersetPrimary: i == 0,
        ),
      );
    }

    return supersetExercises;
  }

  // Remove exercises from superset (make them regular exercises)
  static List<WorkoutExercise> removeFromSuperset(
    List<WorkoutExercise> exercises,
  ) {
    return exercises
        .map(
          (exercise) => exercise.copyWith(
            supersetId: null,
            supersetIndex: null,
            supersetLabel: null,
            isSupersetPrimary: false,
          ),
        )
        .toList();
  }

  // Check if exercises can form a superset (different muscle groups recommended)
  static bool canFormSuperset(List<WorkoutExercise> exercises) {
    if (exercises.length < 2) return false;

    // Get all primary muscles from all exercises
    final Set<String> allMuscles = {};
    for (final exercise in exercises) {
      allMuscles.addAll(exercise.exercise.primaryMuscles);
    }

    // Ideally, superset exercises should target different muscle groups
    // But we'll allow it regardless and let the user decide
    return true;
  }

  // Get recommended rest time for superset
  static int getRecommendedSupersetRest(List<WorkoutExercise> exercises) {
    // For supersets, rest time is typically longer than individual exercises
    // as you're doing multiple exercises back-to-back
    final maxRest = exercises
        .map((e) => e.restTime)
        .reduce((a, b) => a > b ? a : b);
    return (maxRest * 1.5).round(); // 50% longer rest
  }

  // Validate superset configuration
  static List<String> validateSuperset(List<WorkoutExercise> exercises) {
    final List<String> warnings = [];

    if (exercises.length < 2) {
      warnings.add('Superset must contain at least 2 exercises');
    }

    if (exercises.length > 4) {
      warnings.add(
        'Supersets with more than 4 exercises can be very challenging',
      );
    }

    // Check for same muscle groups
    final muscleGroups = exercises
        .expand((e) => e.exercise.primaryMuscles)
        .toSet();
    final uniqueMuscleGroups = muscleGroups.length;

    if (uniqueMuscleGroups == 1) {
      warnings.add(
        'All exercises target the same muscle group - consider varying for better recovery',
      );
    }

    return warnings;
  }

  // Get the next superset index for a workout
  static int getNextSupersetIndex(List<WorkoutExercise> exercises) {
    final supersets = groupBySupersets(exercises);
    return supersets.length;
  }

  // Get superset summary for display
  static String getSupersetSummary(List<WorkoutExercise> exercises) {
    if (exercises.isEmpty) return '';

    final exerciseNames = exercises.map((e) => e.exercise.name).join(' + ');
    final totalSets =
        exercises.first.sets; // Assuming all exercises have same sets

    return '$exerciseNames ($totalSets sets)';
  }
}
