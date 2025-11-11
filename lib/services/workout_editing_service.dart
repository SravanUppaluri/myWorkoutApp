import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import 'package:logger/logger.dart';

class WorkoutEditingService {
  late final FirebaseFunctions _functions;
  final logger = Logger();

  WorkoutEditingService() {
    _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

    // For development on web, use the emulator
    if (kDebugMode && kIsWeb) {
      // Uncomment this line if you want to use the local emulator during development
      // _functions.useFunctionsEmulator('localhost', 5001);
    }
  }

  /// Replace a specific exercise with AI-generated alternatives
  Future<ExerciseReplacementResult?> replaceExerciseWithAI({
    required String exerciseToReplace,
    required List<String> targetMuscleGroups,
    required List<String> availableEquipment,
    required String fitnessLevel,
    required String workoutType,
    String? reason,
  }) async {
    try {
      logger.e('DEBUG: Replacing exercise: $exerciseToReplace');

      final requestData = {
        'exerciseToReplace': exerciseToReplace,
        'targetMuscleGroups': targetMuscleGroups,
        'availableEquipment': availableEquipment,
        'fitnessLevel': fitnessLevel,
        'workoutType': workoutType,
        if (reason != null) 'reason': reason,
      };

      final callable = _functions.httpsCallable('replaceExerciseWithAI');
      final result = await callable.call(requestData);

      if (result.data != null) {
        return ExerciseReplacementResult.fromJson(
          result.data as Map<String, dynamic>,
        );
      }

      return null;
    } catch (error) {
      logger.e('ERROR: Failed to replace exercise: $error');
      rethrow;
    }
  }

  /// Get similar exercises from the database
  Future<SimilarExercisesResult?> getSimilarExercises({
    required List<String> targetMuscleGroups,
    required List<String> availableEquipment,
    String? exerciseType,
    List<String>? excludeExercises,
  }) async {
    try {
      logger.e('DEBUG: Getting similar exercises for: $targetMuscleGroups');

      final requestData = {
        'targetMuscleGroups': targetMuscleGroups,
        'availableEquipment': availableEquipment,
        if (exerciseType != null) 'exerciseType': exerciseType,
        if (excludeExercises != null) 'excludeExercises': excludeExercises,
      };

      final callable = _functions.httpsCallable('getSimilarExercises');
      final result = await callable.call(requestData);

      if (result.data != null) {
        return SimilarExercisesResult.fromJson(
          result.data as Map<String, dynamic>,
        );
      }

      return null;
    } catch (error) {
      logger.e('ERROR: Failed to get similar exercises: $error');
      rethrow;
    }
  }

  /// Create a new WorkoutExercise from an alternative exercise
  WorkoutExercise createWorkoutExerciseFromAlternative(
    AlternativeExercise altExercise, {
    int? customSets,
    int? customReps,
    double? customWeight,
  }) {
    // Create Exercise object from alternative
    final exercise = Exercise(
      id: altExercise.id,
      name: altExercise.name,
      category: altExercise.type,
      equipment: altExercise.equipment,
      targetRegion: _getTargetRegionFromMuscles(altExercise.muscleGroups),
      primaryMuscles: altExercise.muscleGroups,
      secondaryMuscles: [],
      difficulty: altExercise.difficulty,
      movementType: 'Compound', // Default
      movementPattern: _inferMovementPattern(altExercise.muscleGroups),
      gripType: 'Standard', // Default
      rangeOfMotion: 'Full', // Default
      tempo: 'Moderate', // Default
      muscleGroup: altExercise.muscleGroups.isNotEmpty
          ? altExercise.muscleGroups.first
          : 'Full Body',
      muscleInfo: MuscleInfo(
        scientificName: '',
        commonName: altExercise.muscleGroups.join(', '),
        muscleRegions:
            [], // Fixed: Empty list instead of altExercise.muscleGroups
        primaryFunction: '',
        location: '',
        muscleFiberDirection: '',
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Use custom values or defaults from the alternative exercise
    final sets = customSets ?? altExercise.sets.length;
    final reps =
        customReps ??
        (altExercise.sets.isNotEmpty ? altExercise.sets.first.reps : 12);
    final weight =
        customWeight ??
        (altExercise.sets.isNotEmpty ? altExercise.sets.first.weight : 0.0);

    return WorkoutExercise(
      exercise: exercise,
      sets: sets,
      reps: reps,
      weight: weight,
      restTime: altExercise.restTime,
      notes: altExercise.notes,
    );
  }

  /// Helper method to get target region from muscle groups
  List<String> _getTargetRegionFromMuscles(List<String> muscles) {
    final muscleSet = muscles.map((m) => m.toLowerCase()).toSet();
    List<String> regions = [];

    if (muscleSet.any(
      (m) => ['chest', 'shoulders', 'arms', 'triceps', 'biceps'].contains(m),
    )) {
      regions.add('Upper Body');
    }
    if (muscleSet.any(
      (m) =>
          ['legs', 'glutes', 'quadriceps', 'hamstrings', 'calves'].contains(m),
    )) {
      regions.add('Lower Body');
    }
    if (muscleSet.any((m) => ['core', 'abs', 'abdominals'].contains(m))) {
      regions.add('Core');
    }
    if (muscleSet.any((m) => ['back', 'lats'].contains(m))) {
      regions.add('Upper Body'); // Back is part of upper body
    }

    return regions.isEmpty ? ['Full Body'] : regions;
  }

  /// Helper method to infer movement pattern from muscle groups
  String _inferMovementPattern(List<String> muscles) {
    final muscleSet = muscles.map((m) => m.toLowerCase()).toSet();

    if (muscleSet.any((m) => ['chest', 'triceps', 'shoulders'].contains(m))) {
      return 'Push';
    } else if (muscleSet.any((m) => ['back', 'biceps', 'lats'].contains(m))) {
      return 'Pull';
    } else if (muscleSet.any(
      (m) => ['legs', 'glutes', 'quadriceps', 'hamstrings'].contains(m),
    )) {
      return 'Squat';
    }

    return 'Push'; // Default
  }
}

/// Result of exercise replacement request
class ExerciseReplacementResult {
  final String originalExercise;
  final List<AlternativeExercise> alternatives;
  final String? replacementReason;
  final DateTime timestamp;

  ExerciseReplacementResult({
    required this.originalExercise,
    required this.alternatives,
    this.replacementReason,
    required this.timestamp,
  });

  factory ExerciseReplacementResult.fromJson(Map<String, dynamic> json) {
    return ExerciseReplacementResult(
      originalExercise: json['originalExercise'] as String,
      alternatives: (json['alternatives'] as List<dynamic>)
          .map(
            (alt) => AlternativeExercise.fromJson(alt as Map<String, dynamic>),
          )
          .toList(),
      replacementReason: json['replacementReason'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// Alternative exercise option
class AlternativeExercise {
  final String id;
  final String name;
  final String type;
  final List<String> equipment;
  final List<String> muscleGroups;
  final String difficulty;
  final String instructions;
  final List<ExerciseSet> sets;
  final int restTime;
  final String notes;
  final String similarity;

  AlternativeExercise({
    required this.id,
    required this.name,
    required this.type,
    required this.equipment,
    required this.muscleGroups,
    required this.difficulty,
    required this.instructions,
    required this.sets,
    required this.restTime,
    required this.notes,
    required this.similarity,
  });

  factory AlternativeExercise.fromJson(Map<String, dynamic> json) {
    return AlternativeExercise(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      equipment: List<String>.from(json['equipment'] as List),
      muscleGroups: List<String>.from(json['muscleGroups'] as List),
      difficulty: json['difficulty'] as String,
      instructions: json['instructions'] as String,
      sets: (json['sets'] as List<dynamic>)
          .map((set) => ExerciseSet.fromJson(set as Map<String, dynamic>))
          .toList(),
      restTime: json['restTime'] as int,
      notes: json['notes'] as String,
      similarity: json['similarity'] as String,
    );
  }
}

/// Exercise set data
class ExerciseSet {
  final int reps;
  final double weight;

  ExerciseSet({required this.reps, required this.weight});

  factory ExerciseSet.fromJson(Map<String, dynamic> json) {
    return ExerciseSet(
      reps: json['reps'] as int,
      weight: (json['weight'] as num).toDouble(),
    );
  }
}

/// Result of similar exercises query
class SimilarExercisesResult {
  final List<Exercise> exercises;
  final int totalFound;
  final Map<String, dynamic> searchCriteria;
  final DateTime timestamp;

  SimilarExercisesResult({
    required this.exercises,
    required this.totalFound,
    required this.searchCriteria,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory SimilarExercisesResult.fromJson(Map<String, dynamic> json) {
    return SimilarExercisesResult(
      exercises: (json['exercises'] as List<dynamic>)
          .map((ex) => Exercise.fromJson(ex as Map<String, dynamic>))
          .toList(),
      totalFound: json['totalFound'] as int? ?? 0,
      searchCriteria: json['searchCriteria'] as Map<String, dynamic>? ?? {},
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }
}
