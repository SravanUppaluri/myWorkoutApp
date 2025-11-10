import 'exercise.dart';

class WorkoutExercise {
  final Exercise exercise;
  final int sets;
  final int reps;
  final double weight;
  final int restTime; // in seconds
  final String notes;

  // Superset properties
  final String? supersetId; // Groups exercises in the same superset
  final int? supersetIndex; // Order within the superset (0, 1, 2...)
  final String? supersetLabel; // Display label like "A1", "A2", "B1", "B2"
  final bool isSupersetPrimary; // First exercise in superset (for UI purposes)

  // Template properties
  final bool
  isCurrentExercise; // For templates: marks which exercise is currently active

  WorkoutExercise({
    required this.exercise,
    required this.sets,
    required this.reps,
    this.weight = 0.0,
    this.restTime = 60,
    this.notes = '',
    this.supersetId,
    this.supersetIndex,
    this.supersetLabel,
    this.isSupersetPrimary = false,
    this.isCurrentExercise = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'exercise': exercise.toJson(),
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'restTime': restTime,
      'notes': notes,
      'supersetId': supersetId,
      'supersetIndex': supersetIndex,
      'supersetLabel': supersetLabel,
      'isSupersetPrimary': isSupersetPrimary,
      'isCurrentExercise': isCurrentExercise,
    };
  }

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutExercise(
      exercise: Exercise.fromJson(
        json['exercise'] as Map<String, dynamic>? ?? {},
      ),
      sets: json['sets'] as int? ?? 1,
      reps: json['reps'] as int? ?? 1,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      restTime: json['restTime'] as int? ?? 60,
      notes: json['notes']?.toString() ?? '',
      supersetId: json['supersetId'] as String?,
      supersetIndex: json['supersetIndex'] as int?,
      supersetLabel: json['supersetLabel'] as String?,
      isSupersetPrimary: json['isSupersetPrimary'] as bool? ?? false,
      isCurrentExercise: json['isCurrentExercise'] as bool? ?? false,
    );
  }

  // Helper methods for superset functionality
  bool get isInSuperset => supersetId != null;

  bool get isFirstInSuperset => isSupersetPrimary;

  String get displayLabel =>
      supersetLabel ?? (supersetIndex != null ? '${supersetIndex! + 1}' : '');

  // copyWith method for creating modified copies
  WorkoutExercise copyWith({
    Exercise? exercise,
    int? sets,
    int? reps,
    double? weight,
    int? restTime,
    String? notes,
    String? supersetId,
    int? supersetIndex,
    String? supersetLabel,
    bool? isSupersetPrimary,
    bool? isCurrentExercise,
  }) {
    return WorkoutExercise(
      exercise: exercise ?? this.exercise,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      restTime: restTime ?? this.restTime,
      notes: notes ?? this.notes,
      supersetId: supersetId ?? this.supersetId,
      supersetIndex: supersetIndex ?? this.supersetIndex,
      supersetLabel: supersetLabel ?? this.supersetLabel,
      isSupersetPrimary: isSupersetPrimary ?? this.isSupersetPrimary,
      isCurrentExercise: isCurrentExercise ?? this.isCurrentExercise,
    );
  }
}

class Workout {
  final String id;
  final String name;
  final String description;
  final List<WorkoutExercise> exercises;
  final int estimatedDuration; // in minutes
  final String difficulty; // Beginner, Intermediate, Advanced
  final DateTime createdAt;
  final bool isTemplate; // Template flag for progressive exercise system

  Workout({
    required this.id,
    required this.name,
    required this.description,
    required this.exercises,
    required this.estimatedDuration,
    required this.difficulty,
    required this.createdAt,
    this.isTemplate = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'estimatedDuration': estimatedDuration,
      'difficulty': difficulty,
      'createdAt': createdAt.toIso8601String(),
      'isTemplate': isTemplate,
    };
  }

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Untitled Workout',
      description: json['description']?.toString() ?? '',
      exercises:
          (json['exercises'] as List?)
              ?.map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      estimatedDuration: json['estimatedDuration'] as int? ?? 30,
      difficulty: json['difficulty']?.toString() ?? 'Beginner',
      createdAt: _parseDateTime(json['createdAt']),
      isTemplate: json['isTemplate'] as bool? ?? false,
    );
  }

  // Add copyWith method for creating modified copies
  Workout copyWith({
    String? id,
    String? name,
    String? description,
    List<WorkoutExercise>? exercises,
    int? estimatedDuration,
    String? difficulty,
    DateTime? createdAt,
    bool? isTemplate,
  }) {
    return Workout(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      exercises: exercises ?? this.exercises,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      difficulty: difficulty ?? this.difficulty,
      createdAt: createdAt ?? this.createdAt,
      isTemplate: isTemplate ?? this.isTemplate,
    );
  }

  // Helper method to parse various date formats from Firestore
  static DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) {
      return DateTime.now();
    }

    if (dateValue is DateTime) {
      return dateValue;
    }

    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        return DateTime.now();
      }
    }

    // Handle Firestore Timestamp (check for toDate method)
    try {
      if (dateValue.runtimeType.toString() == 'Timestamp' ||
          dateValue.toString().contains('Timestamp')) {
        // Use reflection-like approach to call toDate()
        return dateValue.toDate() as DateTime;
      }
    } catch (e) {
      // If toDate() fails, try other approaches
    }

    // Try to convert any object that might have seconds/nanoseconds
    try {
      if (dateValue is Map && dateValue.containsKey('_seconds')) {
        final seconds = dateValue['_seconds'] as int;
        return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      }
    } catch (e) {
      // Ignore and fall back
    }

    return DateTime.now();
  }

  // Template helper methods
  WorkoutExercise? get currentExercise {
    if (!isTemplate) return null;
    try {
      return exercises.firstWhere((exercise) => exercise.isCurrentExercise);
    } catch (e) {
      return exercises.isNotEmpty ? exercises.first : null;
    }
  }

  int get currentExerciseIndex {
    if (!isTemplate) return -1;
    final current = currentExercise;
    if (current == null) return 0;
    return exercises.indexOf(current);
  }

  int get completedExercisesCount {
    if (!isTemplate) return 0;
    final currentIndex = currentExerciseIndex;
    return currentIndex == -1
        ? exercises.length
        : currentIndex; // If no current exercise, all are completed
  }

  int get remainingExercisesCount {
    if (!isTemplate) return exercises.length;
    final currentIndex = currentExerciseIndex;
    if (currentIndex == -1) return 0; // All completed
    return exercises.length - currentIndex - 1; // Remaining after current
  }

  bool get isCompleted {
    if (!isTemplate) return false;
    return currentExerciseIndex >= exercises.length - 1 &&
        currentExercise == null;
  }

  // Creates a template with the first exercise as current
  Workout asTemplate({String? templateId}) {
    // Don't modify exercises - keep all exercises but mark first as current
    final templateExercises = exercises.map((exercise) {
      final isFirst = exercises.indexOf(exercise) == 0;
      return exercise.copyWith(isCurrentExercise: isFirst);
    }).toList();

    return copyWith(
      id: templateId ?? id,
      exercises: templateExercises,
      isTemplate: true,
    );
  }

  // Marks current exercise as completed and moves to next
  Workout completeCurrentExercise() {
    if (!isTemplate) return this;

    final currentIndex = currentExerciseIndex;
    if (currentIndex == -1) return this;

    // If this is the last exercise, mark template as completed
    if (currentIndex >= exercises.length - 1) {
      // Template is completed, remove all exercises to signal completion
      return copyWith(exercises: []);
    }

    // Mark current exercise as completed and move to next exercise
    final updatedExercises = exercises.map((exercise) {
      final index = exercises.indexOf(exercise);
      if (index == currentIndex) {
        // Mark current exercise as no longer current
        return exercise.copyWith(isCurrentExercise: false);
      } else if (index == currentIndex + 1) {
        // Mark next exercise as current
        return exercise.copyWith(isCurrentExercise: true);
      } else {
        // Keep other exercises unchanged
        return exercise;
      }
    }).toList();

    return copyWith(exercises: updatedExercises);
  }
}
