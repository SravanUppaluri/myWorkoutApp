import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../models/workout.dart';
import '../models/exercise.dart';

class WorkoutEditingService {
  late final FirebaseFunctions _functions;

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
      print('DEBUG: Replacing exercise: $exerciseToReplace');

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
      print('ERROR: Failed to replace exercise: $error');
      rethrow;
    }
  }

  /// Get similar exercises from the database
  Future<SimilarExercisesResult?> getSimilarExercises({
    List<String>? targetMuscleGroups,
    required List<String> availableEquipment,
    String? exerciseType,
    List<String>? excludeExercises,
  }) async {
    try {
      // Ensure we always have valid muscle groups
      final validMuscleGroups = targetMuscleGroups?.isNotEmpty == true
          ? targetMuscleGroups!
          : ['Upper Body', 'Lower Body']; // Default fallback

      print('DEBUG: Getting similar exercises for: $validMuscleGroups');

      final requestData = {
        'targetMuscleGroups': validMuscleGroups,
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
      print('ERROR: Failed to get similar exercises: $error');
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

  /// Helper method to infer muscle groups from exercise name
  List<String> inferMuscleGroupsFromExercise(String exerciseName) {
    final name = exerciseName.toLowerCase();
    List<String> muscleGroups = [];

    // Upper body patterns
    if (name.contains('push') ||
        name.contains('press') ||
        name.contains('chest')) {
      muscleGroups.addAll(['Chest', 'Triceps', 'Shoulders']);
    } else if (name.contains('pull') ||
        name.contains('row') ||
        name.contains('back')) {
      muscleGroups.addAll(['Back', 'Biceps']);
    } else if (name.contains('shoulder') || name.contains('raise')) {
      muscleGroups.add('Shoulders');
    } else if (name.contains('bicep') || name.contains('curl')) {
      muscleGroups.add('Biceps');
    } else if (name.contains('tricep') || name.contains('dip')) {
      muscleGroups.add('Triceps');
    }
    // Lower body patterns
    else if (name.contains('squat') ||
        name.contains('lunge') ||
        name.contains('leg')) {
      muscleGroups.addAll(['Legs', 'Glutes']);
    } else if (name.contains('deadlift') || name.contains('hamstring')) {
      muscleGroups.addAll(['Hamstrings', 'Glutes']);
    } else if (name.contains('calf')) {
      muscleGroups.add('Calves');
    }
    // Core patterns
    else if (name.contains('plank') ||
        name.contains('crunch') ||
        name.contains('abs') ||
        name.contains('core')) {
      muscleGroups.add('Core');
    }
    // Full body patterns
    else if (name.contains('burpee') ||
        name.contains('mountain') ||
        name.contains('jumping')) {
      muscleGroups.add('Full Body');
    }

    // If no specific pattern found, default to Upper Body
    return muscleGroups.isEmpty ? ['Upper Body'] : muscleGroups;
  }

  /// Convenience method to get similar exercises for a specific exercise
  Future<SimilarExercisesResult?> getSimilarExercisesForExercise({
    required String exerciseName,
    required List<String> availableEquipment,
    String? exerciseType,
    List<String>? excludeExercises,
  }) async {
    final inferredMuscleGroups = inferMuscleGroupsFromExercise(exerciseName);

    return getSimilarExercises(
      targetMuscleGroups: inferredMuscleGroups,
      availableEquipment: availableEquipment,
      exerciseType: exerciseType,
      excludeExercises: excludeExercises,
    );
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
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Exercise',
      type:
          json['type']?.toString() ??
          json['category']?.toString() ??
          'Strength',
      equipment: json['equipment'] != null
          ? List<String>.from(json['equipment'] as List)
          : ['Bodyweight'],
      muscleGroups: json['muscleGroups'] != null
          ? List<String>.from(json['muscleGroups'] as List)
          : (json['target_region'] != null
                ? List<String>.from(json['target_region'] as List)
                : ['Full Body']),
      difficulty: json['difficulty']?.toString() ?? 'Beginner',
      instructions: json['instructions']?.toString() ?? '',
      sets: json['sets'] != null
          ? (json['sets'] as List<dynamic>)
                .map((set) => ExerciseSet.fromJson(set as Map<String, dynamic>))
                .toList()
          : [ExerciseSet(reps: 12, weight: 0)],
      restTime: json['restTime'] as int? ?? 60,
      notes: json['notes']?.toString() ?? '',
      similarity: json['similarity']?.toString() ?? 'Alternative exercise',
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
