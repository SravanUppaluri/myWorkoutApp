import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutSession {
  final String id;
  final String userId;
  final String workoutId;
  final int duration; // in seconds
  final List<CompletedExercise> completedExercises;
  final String? notes;
  final DateTime completedAt;

  WorkoutSession({
    required this.id,
    required this.userId,
    required this.workoutId,
    required this.duration,
    required this.completedExercises,
    this.notes,
    required this.completedAt,
  });

  factory WorkoutSession.fromMap(String id, Map<String, dynamic> data) {
    return WorkoutSession(
      id: id,
      userId: data['userId'] ?? '',
      workoutId: data['workoutId'] ?? '',
      duration: data['duration'] ?? 0,
      completedExercises:
          (data['completedExercises'] as List<dynamic>?)
              ?.map((e) => CompletedExercise.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      notes: data['notes'],
      completedAt:
          (data['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'workoutId': workoutId,
      'duration': duration,
      'completedExercises': completedExercises.map((e) => e.toMap()).toList(),
      'notes': notes,
    };
  }

  // Helper methods
  String get formattedDuration {
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    final seconds = duration % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  int get totalSets =>
      completedExercises.fold(0, (sum, exercise) => sum + exercise.sets.length);

  double? get totalVolume {
    double volume = 0;
    for (final exercise in completedExercises) {
      for (final set in exercise.sets) {
        if (set.weight != null && set.reps != null) {
          volume += set.weight! * set.reps!;
        }
      }
    }
    return volume > 0 ? volume : null;
  }
}

class CompletedExercise {
  final String exerciseId;
  final String exerciseName;
  final List<CompletedSet> sets;
  final String? notes;

  CompletedExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    this.notes,
  });

  factory CompletedExercise.fromMap(Map<String, dynamic> data) {
    return CompletedExercise(
      exerciseId: data['exerciseId'] ?? '',
      // Backward compatibility: older sessions may have stored the key as 'name'
      exerciseName: (data['exerciseName'] ?? data['name'] ?? '').toString(),
      sets:
          (data['sets'] as List<dynamic>?)
              ?.map((e) => CompletedSet.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'sets': sets.map((e) => e.toMap()).toList(),
      'notes': notes,
    };
  }
}

class CompletedSet {
  final int? reps;
  final double? weight;
  final int? duration; // in seconds
  final bool completed;
  final String? notes;

  CompletedSet({
    this.reps,
    this.weight,
    this.duration,
    this.completed = true,
    this.notes,
  });

  factory CompletedSet.fromMap(Map<String, dynamic> data) {
    return CompletedSet(
      reps: data['reps'],
      weight: data['weight']?.toDouble(),
      duration: data['duration'],
      completed: data['completed'] ?? true,
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reps': reps,
      'weight': weight,
      'duration': duration,
      'completed': completed,
      'notes': notes,
    };
  }

  String get displayText {
    if (reps != null && weight != null) {
      return '${weight}kg × $reps reps';
    } else if (reps != null) {
      return '$reps reps';
    } else if (duration != null) {
      final minutes = duration! ~/ 60;
      final seconds = duration! % 60;
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    } else {
      return 'Completed';
    }
  }
}

class UserProgress {
  final String userId;
  final int totalWorkouts;
  final int totalDuration; // in seconds
  final DateTime? lastWorkout;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProgress({
    required this.userId,
    required this.totalWorkouts,
    required this.totalDuration,
    this.lastWorkout,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProgress.fromMap(String userId, Map<String, dynamic> data) {
    return UserProgress(
      userId: userId,
      totalWorkouts: data['totalWorkouts'] ?? 0,
      totalDuration: data['totalDuration'] ?? 0,
      lastWorkout: (data['lastWorkout'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalWorkouts': totalWorkouts,
      'totalDuration': totalDuration,
      'lastWorkout': lastWorkout != null
          ? Timestamp.fromDate(lastWorkout!)
          : null,
    };
  }

  // Helper methods
  String get formattedTotalDuration {
    final hours = totalDuration ~/ 3600;
    final minutes = (totalDuration % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  double get averageWorkoutDuration {
    if (totalWorkouts == 0) return 0;
    return totalDuration / totalWorkouts / 60; // in minutes
  }
}
