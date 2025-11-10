import 'package:flutter/foundation.dart';
import 'dart:math';
import '../models/workout.dart';
import '../models/workout_template.dart';
import '../models/exercise.dart';
import '../services/ai_workout_service.dart';
import '../services/ai_preferences_service.dart';

/// Controller responsible for all AI workout generation logic
/// Extracted from ImprovedAIWorkoutScreen for better maintainability
class WorkoutGenerationController extends ChangeNotifier {
  final AIWorkoutService _aiWorkoutService = AIWorkoutService();

  bool _isGenerating = false;
  String? _generationError;

  bool get isGenerating => _isGenerating;
  String? get generationError => _generationError;

  /// Generate a one-click workout with smart defaults
  Future<Workout?> generateOneClickWorkout({
    required String userId,
    required String fitnessLevel,
    required int duration,
    String? keyword,
  }) async {
    _setGenerating(true);
    _generationError = null;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = Random();

      final workoutRequest = {
        'userId': userId,
        'goal': 'General fitness and strength improvement',
        'fitnessLevel': fitnessLevel,
        'workoutType': _determineWorkoutType(),
        'duration': duration,
        'muscleGroups': _determineOptimalMuscleGroups(),
        'equipment': [],
        'additionalNotes':
            'Generated using AI smart defaults based on user profile and workout history. DO NOT include warm-up exercises or warm-up sections in the workout.',
        'randomSeed': random.nextInt(10000),
        'timestamp': timestamp,
        'sessionId': 'oneclick_${timestamp}_${random.nextInt(1000)}',
        'workoutVariety': [
          'standard',
          'challenging',
          'innovative',
        ][random.nextInt(3)],
        'excludeWarmup': true,
        'workoutStructure': 'main_exercises_only',
      };

      // Add keyword focus if provided
      if (keyword != null && keyword.isNotEmpty) {
        final currentGoal = workoutRequest['goal'] as String;
        workoutRequest['goal'] = '$currentGoal with focus on $keyword';

        final currentNotes = workoutRequest['additionalNotes'] as String;
        workoutRequest['additionalNotes'] =
            '$currentNotes. Focus on exercises targeting: $keyword';

        // Try to match keyword to muscle groups
        final keywordLower = keyword.toLowerCase();
        final muscleGroupMap = {
          'chest': 'Chest',
          'back': 'Back',
          'lower back': 'Back',
          'upper back': 'Back',
          'shoulders': 'Shoulders',
          'arms': 'Arms',
          'legs': 'Legs',
          'glutes': 'Glutes',
          'core': 'Core',
          'abs': 'Core',
          'cardio': 'Cardio',
          'hiit': 'HIIT',
        };

        if (muscleGroupMap.containsKey(keywordLower)) {
          final currentMuscleGroups = List<String>.from(
            workoutRequest['muscleGroups'] as List,
          );
          if (!currentMuscleGroups.contains(muscleGroupMap[keywordLower])) {
            currentMuscleGroups.add(muscleGroupMap[keywordLower]!);
            workoutRequest['muscleGroups'] = currentMuscleGroups;
          }
        }
      }

      // Track generation analytics
      await AIPreferencesService.trackGeneration('quick', workoutRequest);
      await AIPreferencesService.saveLastGenerationParams(workoutRequest);

      final generatedWorkout = await _generateWorkoutWithTimeout(
        workoutRequest,
      );

      if (generatedWorkout != null) {
        // Note: Workout generated with type: ${workoutRequest['workoutType']},
        // duration: ${workoutRequest['duration']}, level: ${workoutRequest['fitnessLevel']}
        return generatedWorkout;
      } else {
        throw Exception('Failed to generate workout');
      }
    } catch (e) {
      _generationError = e.toString();
      debugPrint('Error in generateOneClickWorkout: $e');
      return null;
    } finally {
      _setGenerating(false);
    }
  }

  /// Generate workout from a template with AI enhancement
  Future<Workout?> generateFromTemplate({
    required String userId,
    required String fitnessLevel,
    required WorkoutTemplate template,
  }) async {
    _setGenerating(true);
    _generationError = null;

    try {
      // Get data in parallel for better performance
      final results = await Future.wait([
        _getUserProfile(userId),
        _getRecentWorkoutHistory(userId),
        _getUserEquipment(userId),
      ]);

      // User profile data available in results[0] if needed
      final recentWorkouts = results[1] as List<Map<String, dynamic>>? ?? [];
      final userEquipment = results[2] as List<String>? ?? ['Bodyweight'];

      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Optimized AI workout request
      final workoutRequest = {
        'userId': userId,
        'templateId': template.id,
        'templateName': template.name,
        'templateCategory': template.category,
        'workoutType': template.params['workoutType'],
        'duration': template.params['duration'],
        'fitnessLevel': fitnessLevel,
        'muscleGroups': template.params['muscleGroups'] ?? [],

        // Minimal user context
        if (recentWorkouts.isNotEmpty)
          'recentWorkoutSummary': {
            'lastWorkoutDate': recentWorkouts.first['date'],
            'lastWorkoutType': recentWorkouts.first['type'],
            'recentMuscleGroups': recentWorkouts
                .map((w) => w['muscleGroups'])
                .expand((x) => x as List)
                .toSet()
                .toList(),
          },

        // Equipment (only if user has more than bodyweight)
        if (userEquipment.length > 1)
          'userEquipment': userEquipment.take(3).toList(),

        'personalizationLevel': 'standard',
        'requestTimeout': 30,
        'sessionId': 'fast_${template.id}_${timestamp}',
        'generationType': 'optimized_template',
        'priority': 'speed',
        'excludeWarmup': true,
        'workoutStructure': 'main_exercises_only',
      };

      // Add AI instructions based on category
      workoutRequest['aiInstructions'] = _getAIInstructionsForCategory(
        template.category,
      );

      _trackGenerationAsync(workoutRequest);

      final generatedWorkout = await _generateWorkoutWithTimeout(
        workoutRequest,
      );

      if (generatedWorkout != null) {
        // Note: Generated from template ${template.name} (${template.id})
        // Category: ${template.category}, Enhanced by AI, Generated at: $timestamp
        return generatedWorkout;
      } else {
        throw Exception('Failed to generate AI-enhanced workout');
      }
    } catch (e) {
      _generationError = e.toString();
      debugPrint('Error in generateFromTemplate: $e');
      return null;
    } finally {
      _setGenerating(false);
    }
  }

  /// Generate workout with timeout and retry logic
  Future<Workout?> _generateWorkoutWithTimeout(
    Map<String, dynamic> request,
  ) async {
    const timeoutDuration = Duration(seconds: 15); // Optimized timeout
    const maxRetries = 1; // Reduced retries

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint('🚀 AI Generation attempt $attempt/$maxRetries');

        final workout = await _aiWorkoutService
            .generateWorkout(request)
            .timeout(
              timeoutDuration,
              onTimeout: () {
                throw Exception(
                  'AI generation timed out after ${timeoutDuration.inSeconds} seconds',
                );
              },
            );

        if (workout != null) {
          debugPrint('✅ AI workout generated successfully');
          return workout;
        }
      } catch (e) {
        debugPrint('⚠️ Generation attempt $attempt failed: $e');

        if (attempt == maxRetries) {
          debugPrint('🔄 All attempts failed, generating fallback workout');
          return _generateFallbackWorkout(request);
        }

        // Wait before retry
        await Future.delayed(Duration(seconds: attempt));
      }
    }

    return _generateFallbackWorkout(request);
  }

  /// Generate a fallback workout when AI generation fails
  Workout _generateFallbackWorkout(Map<String, dynamic> request) {
    debugPrint('🆘 Generating fallback workout');

    final workoutType = request['workoutType'] as String? ?? 'Full Body';
    final duration = request['duration'] as int? ?? 45;

    return Workout(
      id: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Quick $workoutType Workout',
      description: 'A reliable $workoutType workout generated as backup',
      exercises: _generateFallbackExercises(workoutType),
      estimatedDuration: duration,
      difficulty: request['fitnessLevel'] as String? ?? 'Intermediate',
      createdAt: DateTime.now(),
    );
  }

  /// Generate fallback exercises for offline capability
  List<WorkoutExercise> _generateFallbackExercises(String workoutType) {
    switch (workoutType.toLowerCase()) {
      case 'upper body':
        return [
          WorkoutExercise(
            exercise: _createFallbackExercise(
              'fallback_pushups',
              'Push-ups',
              'Strength',
              ['Chest'],
              ['Pectorals'],
              ['Triceps', 'Shoulders'],
            ),
            sets: 3,
            reps: 15,
            restTime: 60,
          ),
          WorkoutExercise(
            exercise: _createFallbackExercise(
              'fallback_rows',
              'Bodyweight Rows',
              'Strength',
              ['Back'],
              ['Latissimus Dorsi', 'Rhomboids'],
              ['Biceps', 'Rear Deltoids'],
            ),
            sets: 3,
            reps: 12,
            restTime: 60,
          ),
        ];
      case 'lower body':
        return [
          WorkoutExercise(
            exercise: _createFallbackExercise(
              'fallback_squats',
              'Bodyweight Squats',
              'Strength',
              ['Legs'],
              ['Quadriceps', 'Glutes'],
              ['Hamstrings', 'Calves'],
            ),
            sets: 3,
            reps: 20,
            restTime: 45,
          ),
          WorkoutExercise(
            exercise: _createFallbackExercise(
              'fallback_lunges',
              'Lunges',
              'Strength',
              ['Legs'],
              ['Quadriceps', 'Glutes'],
              ['Hamstrings', 'Calves'],
            ),
            sets: 3,
            reps: 12,
            restTime: 45,
          ),
        ];
      default:
        return [
          WorkoutExercise(
            exercise: _createFallbackExercise(
              'fallback_burpees',
              'Burpees',
              'HIIT',
              ['Full Body'],
              ['Chest', 'Legs', 'Core'],
              ['Arms', 'Shoulders'],
            ),
            sets: 3,
            reps: 10,
            restTime: 90,
          ),
          WorkoutExercise(
            exercise: _createFallbackExercise(
              'fallback_mountain_climbers',
              'Mountain Climbers',
              'Cardio',
              ['Core'],
              ['Abdominals', 'Hip Flexors'],
              ['Shoulders', 'Legs'],
            ),
            sets: 3,
            reps: 30,
            restTime: 60,
          ),
        ];
    }
  }

  /// Create a fallback exercise with complete Exercise model data
  Exercise _createFallbackExercise(
    String id,
    String name,
    String category,
    List<String> targetRegion,
    List<String> primaryMuscles,
    List<String> secondaryMuscles,
  ) {
    return Exercise(
      id: id,
      name: name,
      category: category,
      equipment: ['Bodyweight'],
      targetRegion: targetRegion,
      primaryMuscles: primaryMuscles,
      secondaryMuscles: secondaryMuscles,
      difficulty: 'Beginner',
      movementType: 'Compound',
      movementPattern: 'Functional',
      gripType: 'None',
      rangeOfMotion: 'Full',
      tempo: 'Controlled',
      muscleGroup: targetRegion.first,
      muscleInfo: MuscleInfo(
        scientificName: primaryMuscles.first,
        commonName: targetRegion.first,
        muscleRegions: [
          MuscleRegion(
            region: targetRegion.first,
            anatomicalName: primaryMuscles.first,
            description: 'Primary target muscle',
          ),
        ],
        primaryFunction: 'Movement',
        location: 'Body',
        muscleFiberDirection: 'Multi-directional',
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Helper methods
  void _setGenerating(bool value) {
    _isGenerating = value;
    notifyListeners();
  }

  void _trackGenerationAsync(Map<String, dynamic> workoutRequest) {
    // Fire analytics in background (non-blocking)
    Future.microtask(() async {
      try {
        await AIPreferencesService.trackGeneration('template', workoutRequest);
        await AIPreferencesService.saveLastGenerationParams(workoutRequest);
      } catch (e) {
        debugPrint('Analytics tracking failed (non-critical): $e');
      }
    });
  }

  String _determineWorkoutType() {
    final workoutTypes = ['Upper Body', 'Lower Body', 'Full Body', 'Cardio'];
    return workoutTypes[Random().nextInt(workoutTypes.length)];
  }

  List<String> _determineOptimalMuscleGroups() {
    final muscleGroups = [
      ['Chest', 'Triceps'],
      ['Back', 'Biceps'],
      ['Legs', 'Glutes'],
      ['Shoulders', 'Core'],
    ];
    return muscleGroups[Random().nextInt(muscleGroups.length)];
  }

  String _getAIInstructionsForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'strength':
        return 'Focus on progressive overload, compound movements, and proper rest periods. Adjust weight recommendations based on user fitness level.';
      case 'cardio':
        return 'Personalize intensity zones based on user fitness level. Include variety in cardio exercises to prevent boredom.';
      case 'hiit':
        return 'Adjust work-to-rest ratios based on user fitness level. DO NOT include warm-up exercises - focus only on the main HIIT workout exercises.';
      case 'flexibility':
        return 'Customize stretches based on user mobility needs. Include both static and dynamic stretching.';
      case 'sports':
        return 'Focus on sport-specific movements and skills. Adjust intensity based on user sport experience.';
      case 'rehabilitation':
        return 'Prioritize safety and proper form. Progress slowly and include mobility work.';
      case 'functional':
        return 'Focus on real-world movement patterns. Adjust complexity based on user fitness level.';
      default:
        return 'Personalize exercises, sets, reps, and rest periods based on user fitness level and goals. DO NOT include warm-up exercises in the workout - focus only on main exercises.';
    }
  }

  // Placeholder methods for external data (to be implemented)
  Future<Map<String, dynamic>?> _getUserProfile(String userId) async {
    // TODO: Implement user profile fetching
    return {};
  }

  Future<List<Map<String, dynamic>>> _getRecentWorkoutHistory(
    String userId,
  ) async {
    // TODO: Implement workout history fetching
    return [];
  }

  Future<List<String>> _getUserEquipment(String userId) async {
    // TODO: Implement user equipment fetching
    return ['Bodyweight'];
  }

  @override
  void dispose() {
    super.dispose();
  }
}
