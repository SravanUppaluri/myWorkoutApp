import '../models/workout.dart';

class WorkoutService {
  // This will be replaced with Firebase/database implementation
  static final List<Workout> _workouts = [];

  // Get all workouts
  Future<List<Workout>> getAllWorkouts() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_workouts);
  }

  // Get workout by ID
  Future<Workout?> getWorkoutById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _workouts.firstWhere((workout) => workout.id == id);
    } catch (e) {
      return null;
    }
  }

  // Add a new workout
  Future<void> addWorkout(Workout workout) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _workouts.add(workout);
  }

  // Update an existing workout
  Future<void> updateWorkout(Workout workout) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _workouts.indexWhere((w) => w.id == workout.id);
    if (index != -1) {
      _workouts[index] = workout;
    }
  }

  // Delete a workout
  Future<void> deleteWorkout(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _workouts.removeWhere((workout) => workout.id == id);
  }

  // Get workouts by difficulty
  Future<List<Workout>> getWorkoutsByDifficulty(String difficulty) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _workouts
        .where(
          (workout) =>
              workout.difficulty.toLowerCase() == difficulty.toLowerCase(),
        )
        .toList();
  }

  // Search workouts by name
  Future<List<Workout>> searchWorkouts(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final lowercaseQuery = query.toLowerCase();
    return _workouts
        .where(
          (workout) =>
              workout.name.toLowerCase().contains(lowercaseQuery) ||
              workout.description.toLowerCase().contains(lowercaseQuery),
        )
        .toList();
  }

  // Get recent workouts (last 10)
  Future<List<Workout>> getRecentWorkouts() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final sortedWorkouts = List<Workout>.from(_workouts);
    sortedWorkouts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sortedWorkouts.take(10).toList();
  }

  // Get workouts by duration range
  Future<List<Workout>> getWorkoutsByDuration(
    int minMinutes,
    int maxMinutes,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _workouts
        .where(
          (workout) =>
              workout.estimatedDuration >= minMinutes &&
              workout.estimatedDuration <= maxMinutes,
        )
        .toList();
  }

  // Create a sample workout for demonstration
  Future<Workout> createSampleWorkout() async {
    // This is just for demo purposes
    final sampleWorkout = Workout(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Full Body Workout',
      description: 'A comprehensive full-body workout for beginners',
      exercises: [], // Will be populated with exercises
      estimatedDuration: 45,
      difficulty: 'Beginner',
      createdAt: DateTime.now(),
    );

    await addWorkout(sampleWorkout);
    return sampleWorkout;
  }
}
