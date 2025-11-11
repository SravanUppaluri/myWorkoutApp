import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../models/workout_session.dart';
import '../services/database_service.dart';
import 'package:logger/logger.dart';

class WorkoutProvider extends ChangeNotifier {
  List<Workout> _workouts = [];
  List<WorkoutSession> _workoutSessions = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Workout> get workouts => _workouts;
  List<WorkoutSession> get workoutSessions => _workoutSessions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final logger = Logger();

  /// Load user's workout sessions from Firestore
  Future<void> loadUserWorkoutSessions(String userId) async {
    try {
      // Subscribe to real-time updates for workout sessions
      DatabaseService.getUserWorkoutHistory(userId).listen(
        (snapshot) {
          try {
            _workoutSessions = snapshot.docs
                .map((doc) {
                  try {
                    return WorkoutSession.fromMap(
                      doc.id,
                      doc.data() as Map<String, dynamic>,
                    );
                  } catch (e) {
                    logger.e('Error converting workout session data: $e');
                    return null;
                  }
                })
                .whereType<WorkoutSession>()
                .toList();

            // Sort by completion date (most recent first) on client side
            _workoutSessions.sort(
              (a, b) => b.completedAt.compareTo(a.completedAt),
            );

            logger.e(
              'DEBUG: Loaded ${_workoutSessions.length} workout sessions',
            );
            notifyListeners();
          } catch (e) {
            logger.e('Error processing workout sessions: $e');
          }
        },
        onError: (error) {
          logger.e('Workout sessions stream error: $error');
        },
      );
    } catch (e) {
      logger.e('Failed to load workout sessions: $e');
    }
  }

  /// Check if user has workout on specific date
  bool hasWorkoutOnDate(DateTime date) {
    if (_workoutSessions.isEmpty) {
      return false;
    }

    // Convert the target date to local timezone for comparison
    final targetDate = DateTime(date.year, date.month, date.day);

    final hasWorkout = _workoutSessions.any((session) {
      final sessionDate = session.completedAt.toLocal();
      final normalizedSessionDate = DateTime(
        sessionDate.year,
        sessionDate.month,
        sessionDate.day,
      );

      return normalizedSessionDate.isAtSameMomentAs(targetDate);
    });

    return hasWorkout;
  }

  /// Get workout sessions for a specific date
  List<WorkoutSession> getWorkoutSessionsForDate(DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);

    return _workoutSessions.where((session) {
      final sessionDate = session.completedAt.toLocal();
      final normalizedSessionDate = DateTime(
        sessionDate.year,
        sessionDate.month,
        sessionDate.day,
      );

      return normalizedSessionDate.isAtSameMomentAs(targetDate);
    }).toList();
  }

  /// Debug method to print all workout sessions
  void debugPrintWorkoutSessions() {
    logger.e('=== DEBUG: All Workout Sessions ===');
    for (int i = 0; i < _workoutSessions.length; i++) {
      final session = _workoutSessions[i];
      final sessionDate = session.completedAt;
      logger.e('Session ${i + 1}:');
      logger.e('  ID: ${session.id}');
      logger.e('  UTC Time: ${sessionDate.toUtc()}');
      logger.e('  Local Time: ${sessionDate.toLocal()}');
      logger.e(
        '  Date Only: ${sessionDate.toLocal().year}-${sessionDate.toLocal().month}-${sessionDate.toLocal().day}',
      );
      logger.e('  Duration: ${session.formattedDuration}');
      logger.e('  Exercises: ${session.completedExercises.length}');
      logger.e('---');
    }
    logger.e('=== END DEBUG ===');
  }

  Future<void> loadUserWorkouts(String userId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // Subscribe to real-time updates
      DatabaseService.getUserWorkouts(userId).listen(
        (workoutMapList) {
          try {
            _workouts = workoutMapList
                .map((workoutMap) {
                  try {
                    return Workout.fromJson(workoutMap);
                  } catch (e) {
                    logger.e('Error converting workout data: $e');
                    logger.e('Workout data that failed: $workoutMap');
                    return null;
                  }
                })
                .whereType<Workout>()
                .toList();
            _setLoading(false);
            _errorMessage = null;
          } catch (e) {
            logger.e('Error processing workout list: $e');
            _errorMessage = 'Error loading workouts: $e';
            _setLoading(false);
          }
          notifyListeners();
        },
        onError: (error) {
          logger.e('Firestore stream error: $error');
          _errorMessage =
              'Failed to load workouts. Please check your connection.';
          _setLoading(false);
          notifyListeners();
        },
      );
    } catch (e) {
      _errorMessage = 'Failed to connect to database: $e';
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Save a new workout
  Future<String?> saveWorkout(Workout workout, String userId) async {
    try {
      logger.e('DEBUG: WorkoutProvider.saveWorkout called for user: $userId');
      logger.e('DEBUG: Workout name: ${workout.name}');
      logger.e('DEBUG: Workout exercises: ${workout.exercises.length}');

      _setLoading(true);

      // Convert Workout object to Map for the database
      final workoutMap = workout.toJson();
      logger.e('DEBUG: Workout converted to JSON: $workoutMap');

      final workoutId = await DatabaseService.saveWorkout(workoutMap, userId);
      logger.e('DEBUG: DatabaseService.saveWorkout returned: $workoutId');

      // The stream will automatically update the list
      _setLoading(false);
      return workoutId;
    } catch (e) {
      logger.e('DEBUG: Error in WorkoutProvider.saveWorkout: $e');
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateWorkout(Workout workout) async {
    try {
      logger.e(
        'DEBUG: WorkoutProvider.updateWorkout called for workout: ${workout.id}',
      );
      logger.e('DEBUG: Workout name: ${workout.name}');
      logger.e('DEBUG: Workout exercises: ${workout.exercises.length}');

      _setLoading(true);

      // Convert Workout object to Map for the database
      final workoutMap = workout.toJson();
      logger.e('DEBUG: Workout converted to JSON: $workoutMap');

      await DatabaseService.updateWorkout(
        workoutId: workout.id,
        updates: workoutMap,
      );
      logger.e('DEBUG: DatabaseService.updateWorkout completed successfully');

      // The stream will automatically update the list
      _setLoading(false);
      return true;
    } catch (e) {
      logger.e('DEBUG: Error in WorkoutProvider.updateWorkout: $e');
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Delete a workout
  Future<bool> deleteWorkout(String workoutId) async {
    try {
      logger.e(
        'DEBUG: WorkoutProvider.deleteWorkout called for ID: $workoutId',
      );
      _setLoading(true);

      await DatabaseService.deleteWorkout(workoutId);
      logger.e(
        'DEBUG: WorkoutProvider.deleteWorkout succeeded for ID: $workoutId',
      );

      // The stream will automatically update the list
      _setLoading(false);
      _errorMessage = null;
      return true;
    } catch (e) {
      logger.e('DEBUG: WorkoutProvider.deleteWorkout failed: $e');
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Delete a workout session (completed workout)
  Future<bool> deleteWorkoutSession(String sessionId) async {
    try {
      logger.e(
        'DEBUG: WorkoutProvider.deleteWorkoutSession called for ID: $sessionId',
      );
      _setLoading(true);

      await DatabaseService.deleteWorkoutSession(sessionId);
      logger.e(
        'DEBUG: WorkoutProvider.deleteWorkoutSession succeeded for ID: $sessionId',
      );

      // Remove from local list and notify listeners
      _workoutSessions.removeWhere((session) => session.id == sessionId);
      _setLoading(false);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      logger.e('DEBUG: WorkoutProvider.deleteWorkoutSession failed: $e');
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Get a specific workout with full details
  Future<Workout?> getWorkoutDetails(String workoutId) async {
    try {
      final workoutData = await DatabaseService.getWorkout(workoutId);
      if (workoutData != null) {
        return Workout.fromJson(workoutData);
      }
      return null;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Test Firebase connection
  Future<bool> testConnection() async {
    try {
      return await DatabaseService.testConnection();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
