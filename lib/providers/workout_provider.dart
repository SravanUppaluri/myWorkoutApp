import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../models/workout_session.dart';
import '../services/database_service.dart';

class WorkoutProvider extends ChangeNotifier {
  List<Workout> _workouts = [];
  List<WorkoutSession> _workoutSessions = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Workout> get workouts => _workouts;
  List<WorkoutSession> get workoutSessions => _workoutSessions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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
                    print('Error converting workout session data: $e');
                    return null;
                  }
                })
                .whereType<WorkoutSession>()
                .toList();

            // Sort by completion date (most recent first) on client side
            _workoutSessions.sort(
              (a, b) => b.completedAt.compareTo(a.completedAt),
            );

            print('DEBUG: Loaded ${_workoutSessions.length} workout sessions');
            notifyListeners();
          } catch (e) {
            print('Error processing workout sessions: $e');
          }
        },
        onError: (error) {
          print('Workout sessions stream error: $error');
        },
      );
    } catch (e) {
      print('Failed to load workout sessions: $e');
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
    print('=== DEBUG: All Workout Sessions ===');
    for (int i = 0; i < _workoutSessions.length; i++) {
      final session = _workoutSessions[i];
      final sessionDate = session.completedAt;
      print('Session ${i + 1}:');
      print('  ID: ${session.id}');
      print('  UTC Time: ${sessionDate.toUtc()}');
      print('  Local Time: ${sessionDate.toLocal()}');
      print(
        '  Date Only: ${sessionDate.toLocal().year}-${sessionDate.toLocal().month}-${sessionDate.toLocal().day}',
      );
      print('  Duration: ${session.formattedDuration}');
      print('  Exercises: ${session.completedExercises.length}');
      print('---');
    }
    print('=== END DEBUG ===');
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
                    print('Error converting workout data: $e');
                    print('Workout data that failed: $workoutMap');
                    return null;
                  }
                })
                .whereType<Workout>()
                .toList();
            _setLoading(false);
            _errorMessage = null;
          } catch (e) {
            print('Error processing workout list: $e');
            _errorMessage = 'Error loading workouts: $e';
            _setLoading(false);
          }
          notifyListeners();
        },
        onError: (error) {
          print('Firestore stream error: $error');
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
      print('DEBUG: WorkoutProvider.saveWorkout called for user: $userId');
      print('DEBUG: Workout name: ${workout.name}');
      print('DEBUG: Workout exercises: ${workout.exercises.length}');

      _setLoading(true);

      // Convert Workout object to Map for the database
      final workoutMap = workout.toJson();
      print('DEBUG: Workout converted to JSON: $workoutMap');

      final workoutId = await DatabaseService.saveWorkout(workoutMap, userId);
      print('DEBUG: DatabaseService.saveWorkout returned: $workoutId');

      // The stream will automatically update the list
      _setLoading(false);
      return workoutId;
    } catch (e) {
      print('DEBUG: Error in WorkoutProvider.saveWorkout: $e');
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateWorkout(Workout workout) async {
    try {
      print(
        'DEBUG: WorkoutProvider.updateWorkout called for workout: ${workout.id}',
      );
      print('DEBUG: Workout name: ${workout.name}');
      print('DEBUG: Workout exercises: ${workout.exercises.length}');

      _setLoading(true);

      // Convert Workout object to Map for the database
      final workoutMap = workout.toJson();
      print('DEBUG: Workout converted to JSON: $workoutMap');

      await DatabaseService.updateWorkout(
        workoutId: workout.id,
        updates: workoutMap,
      );
      print('DEBUG: DatabaseService.updateWorkout completed successfully');

      // The stream will automatically update the list
      _setLoading(false);
      return true;
    } catch (e) {
      print('DEBUG: Error in WorkoutProvider.updateWorkout: $e');
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Delete a workout
  Future<bool> deleteWorkout(String workoutId) async {
    try {
      print('DEBUG: WorkoutProvider.deleteWorkout called for ID: $workoutId');
      _setLoading(true);

      await DatabaseService.deleteWorkout(workoutId);
      print(
        'DEBUG: WorkoutProvider.deleteWorkout succeeded for ID: $workoutId',
      );

      // The stream will automatically update the list
      _setLoading(false);
      _errorMessage = null;
      return true;
    } catch (e) {
      print('DEBUG: WorkoutProvider.deleteWorkout failed: $e');
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Delete a workout session (completed workout)
  Future<bool> deleteWorkoutSession(String sessionId) async {
    try {
      print(
        'DEBUG: WorkoutProvider.deleteWorkoutSession called for ID: $sessionId',
      );
      _setLoading(true);

      await DatabaseService.deleteWorkoutSession(sessionId);
      print(
        'DEBUG: WorkoutProvider.deleteWorkoutSession succeeded for ID: $sessionId',
      );

      // Remove from local list and notify listeners
      _workoutSessions.removeWhere((session) => session.id == sessionId);
      _setLoading(false);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      print('DEBUG: WorkoutProvider.deleteWorkoutSession failed: $e');
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
