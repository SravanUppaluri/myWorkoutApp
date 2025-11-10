import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

class AIPreferencesService {
  static const String _keyRecentPreferences = 'ai_recent_preferences';
  static const String _keyFavoriteTemplates = 'ai_favorite_templates';
  static const String _keyLastGenerationParams = 'ai_last_generation_params';
  static const String _keyGenerationHistory = 'ai_generation_history';

  // Save recent workout preferences
  static Future<void> saveRecentPreference(
    Map<String, dynamic> preference,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = await getRecentPreferences();

      // Add timestamp to preference
      preference['timestamp'] = DateTime.now().toIso8601String();
      preference['id'] = DateTime.now().millisecondsSinceEpoch.toString();

      // Add to beginning of list and limit to 5 recent preferences
      existing.insert(0, preference);
      if (existing.length > 5) {
        existing.removeRange(5, existing.length);
      }

      final jsonString = json.encode(existing);
      await prefs.setString(_keyRecentPreferences, jsonString);
    } catch (e) {
      print('Error saving recent preference: $e');
    }
  }

  // Get recent workout preferences
  static Future<List<Map<String, dynamic>>> getRecentPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyRecentPreferences);

      if (jsonString != null) {
        final List<dynamic> decoded = json.decode(jsonString);
        return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (e) {
      print('Error loading recent preferences: $e');
    }
    return [];
  }

  // Save favorite template
  static Future<void> addFavoriteTemplate(Map<String, dynamic> template) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = await getFavoriteTemplates();

      // Check if template already exists
      final exists = existing.any(
        (t) =>
            t['workoutType'] == template['workoutType'] &&
            t['duration'] == template['duration'],
      );

      if (!exists) {
        template['favoriteDate'] = DateTime.now().toIso8601String();
        existing.add(template);

        final jsonString = json.encode(existing);
        await prefs.setString(_keyFavoriteTemplates, jsonString);
      }
    } catch (e) {
      print('Error saving favorite template: $e');
    }
  }

  // Get favorite templates
  static Future<List<Map<String, dynamic>>> getFavoriteTemplates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyFavoriteTemplates);

      if (jsonString != null) {
        final List<dynamic> decoded = json.decode(jsonString);
        return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (e) {
      print('Error loading favorite templates: $e');
    }
    return [];
  }

  // Save last generation parameters
  static Future<void> saveLastGenerationParams(
    Map<String, dynamic> params,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      params['timestamp'] = DateTime.now().toIso8601String();

      final jsonString = json.encode(params);
      await prefs.setString(_keyLastGenerationParams, jsonString);
    } catch (e) {
      print('Error saving last generation params: $e');
    }
  }

  // Get last generation parameters
  static Future<Map<String, dynamic>?> getLastGenerationParams() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyLastGenerationParams);

      if (jsonString != null) {
        return Map<String, dynamic>.from(json.decode(jsonString));
      }
    } catch (e) {
      print('Error loading last generation params: $e');
    }
    return null;
  }

  // Track generation history for analytics
  static Future<void> trackGeneration(
    String method,
    Map<String, dynamic> params,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = await _getGenerationHistory();

      final record = {
        'method': method, // 'quick', 'template', 'custom'
        'params': params,
        'timestamp': DateTime.now().toIso8601String(),
      };

      existing.add(record);

      // Keep only last 50 records
      if (existing.length > 50) {
        existing.removeRange(0, existing.length - 50);
      }

      final jsonString = json.encode(existing);
      await prefs.setString(_keyGenerationHistory, jsonString);
    } catch (e) {
      print('Error tracking generation: $e');
    }
  }

  // Public method to get generation history
  static Future<List<Map<String, dynamic>>> getGenerationHistory() async {
    return await _getGenerationHistory();
  }

  // Save generation to history (alias for trackGeneration)
  static Future<void> saveGenerationToHistory(
    Map<String, dynamic> params,
  ) async {
    await trackGeneration('smart', params);
  }

  static Future<List<Map<String, dynamic>>> _getGenerationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyGenerationHistory);

      if (jsonString != null) {
        final List<dynamic> decoded = json.decode(jsonString);
        return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (e) {
      print('Error loading generation history: $e');
    }
    return [];
  }

  // Get smart recommendations based on history
  static Future<Map<String, dynamic>> getSmartRecommendations() async {
    try {
      final history = await _getGenerationHistory();

      // Analyze patterns in the last 10 generations
      final recentHistory = history.length > 10
          ? history.sublist(history.length - 10)
          : history;

      // Most common workout type
      final workoutTypes = <String, int>{};
      final durations = <int, int>{};
      final muscleGroups = <String, int>{};

      for (final record in recentHistory) {
        final params = record['params'] as Map<String, dynamic>;

        // Count workout types
        final workoutType = params['workoutType'] as String?;
        if (workoutType != null) {
          workoutTypes[workoutType] = (workoutTypes[workoutType] ?? 0) + 1;
        }

        // Count durations
        final duration = params['duration'] as int?;
        if (duration != null) {
          durations[duration] = (durations[duration] ?? 0) + 1;
        }

        // Count muscle groups
        final groups = params['muscleGroups'] as List<dynamic>?;
        if (groups != null) {
          for (final group in groups) {
            if (group is String) {
              muscleGroups[group] = (muscleGroups[group] ?? 0) + 1;
            }
          }
        }
      }

      // Find most common preferences
      String? preferredWorkoutType;
      int? preferredDuration;
      List<String> preferredMuscleGroups = [];

      if (workoutTypes.isNotEmpty) {
        preferredWorkoutType = workoutTypes.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
      }

      if (durations.isNotEmpty) {
        preferredDuration = durations.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
      }

      if (muscleGroups.isNotEmpty) {
        // Get top 3 muscle groups
        final sortedGroups = muscleGroups.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        preferredMuscleGroups = sortedGroups.take(3).map((e) => e.key).toList();
      }

      return {
        'preferredWorkoutType': preferredWorkoutType,
        'preferredDuration': preferredDuration,
        'preferredMuscleGroups': preferredMuscleGroups,
        'hasHistory': history.isNotEmpty,
        'totalGenerations': history.length,
      };
    } catch (e) {
      print('Error getting smart recommendations: $e');
      return {'hasHistory': false, 'totalGenerations': 0};
    }
  }

  // Clear all preferences (for reset functionality)
  static Future<void> clearAllPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyRecentPreferences);
      await prefs.remove(_keyFavoriteTemplates);
      await prefs.remove(_keyLastGenerationParams);
      await prefs.remove(_keyGenerationHistory);
    } catch (e) {
      print('Error clearing preferences: $e');
    }
  }

  // Get analytics data for user insights
  static Future<Map<String, dynamic>> getAnalytics() async {
    try {
      final history = await _getGenerationHistory();
      final favorites = await getFavoriteTemplates();

      final analytics = {
        'totalGenerations': history.length,
        'favoriteCount': favorites.length,
        'mostUsedMethod': _getMostUsedMethod(history),
        'averageWorkoutDuration': _getAverageWorkoutDuration(history),
        'preferredWorkoutTypes': _getPreferredWorkoutTypes(history),
      };

      return analytics;
    } catch (e) {
      print('Error getting analytics: $e');
      return {};
    }
  }

  static String _getMostUsedMethod(List<Map<String, dynamic>> history) {
    final methods = <String, int>{};

    for (final record in history) {
      final method = record['method'] as String;
      methods[method] = (methods[method] ?? 0) + 1;
    }

    if (methods.isEmpty) return 'quick';

    return methods.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  static double _getAverageWorkoutDuration(List<Map<String, dynamic>> history) {
    if (history.isEmpty) return 30.0;

    final durations = <int>[];

    for (final record in history) {
      final params = record['params'] as Map<String, dynamic>;
      final duration = params['duration'] as int?;
      if (duration != null) {
        durations.add(duration);
      }
    }

    if (durations.isEmpty) return 30.0;

    final sum = durations.reduce((a, b) => a + b);
    return sum / durations.length;
  }

  static List<String> _getPreferredWorkoutTypes(
    List<Map<String, dynamic>> history,
  ) {
    final types = <String, int>{};

    for (final record in history) {
      final params = record['params'] as Map<String, dynamic>;
      final workoutType = params['workoutType'] as String?;
      if (workoutType != null) {
        types[workoutType] = (types[workoutType] ?? 0) + 1;
      }
    }

    final sortedTypes = types.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedTypes.take(3).map((e) => e.key).toList();
  }

  // Generate smart workout based on recent exercise history
  static Map<String, dynamic> generateSmartWorkoutParams({
    required List<String> recentExercises,
    required List<String> recentMuscleGroups,
    required List<Map<String, dynamic>> workoutHistory,
    dynamic userProfile, // Accept user profile to get their goal
  }) {
    print(
      'DEBUG: Generating smart workout with recent exercises: $recentExercises',
    );
    print('DEBUG: Recent muscle groups: $recentMuscleGroups');

    // Determine muscle groups to avoid based on recent workouts (last 7 days)
    final recentMuscleGroupsSet = recentMuscleGroups.toSet();

    // Available muscle groups
    final allMuscleGroups = [
      'Chest',
      'Back',
      'Shoulders',
      'Arms',
      'Legs',
      'Core',
      'Glutes',
      'Full Body',
    ];

    // Find muscle groups that haven't been worked recently
    final availableMuscleGroups = allMuscleGroups
        .where((muscle) => !recentMuscleGroupsSet.contains(muscle))
        .toList();

    // If all muscle groups have been worked, prioritize the least recent ones
    String targetMuscleGroup;
    if (availableMuscleGroups.isEmpty) {
      // Count frequency of each muscle group in recent history
      final muscleGroupCounts = <String, int>{};
      for (final muscle in recentMuscleGroups) {
        muscleGroupCounts[muscle] = (muscleGroupCounts[muscle] ?? 0) + 1;
      }

      // Find the least worked muscle group
      final sortedMuscles = muscleGroupCounts.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));

      targetMuscleGroup = sortedMuscles.isEmpty
          ? 'Full Body'
          : sortedMuscles.first.key;
    } else {
      // Pick a random muscle group from those that haven't been worked recently
      try {
        if (availableMuscleGroups.isNotEmpty) {
          final random = Random();
          targetMuscleGroup =
              availableMuscleGroups[random.nextInt(
                availableMuscleGroups.length,
              )];
        } else {
          targetMuscleGroup = 'Full Body';
        }
      } catch (e) {
        print('DEBUG: Error accessing available muscle groups: $e');
        targetMuscleGroup = 'Full Body';
      }
    }

    // Determine workout type based on target muscle group
    String workoutType;
    switch (targetMuscleGroup) {
      case 'Chest':
      case 'Back':
      case 'Shoulders':
      case 'Arms':
        workoutType = 'Strength';
        break;
      case 'Legs':
      case 'Glutes':
        workoutType = 'Lower Body';
        break;
      case 'Core':
        workoutType = 'Core';
        break;
      case 'Full Body':
      default:
        workoutType = 'Full Body';
        break;
    }

    // Get user's preferred duration from history
    final avgDuration = _getAverageWorkoutDuration(workoutHistory);

    // Get fitness level from recent preferences or default to intermediate
    String fitnessLevel = 'Intermediate';
    if (workoutHistory.isNotEmpty) {
      final recentParams =
          workoutHistory.first['params'] as Map<String, dynamic>?;
      if (recentParams != null) {
        fitnessLevel = recentParams['fitnessLevel'] ?? 'Intermediate';
      }
    }

    // Use user's profile goal if available, otherwise generate based on muscle group
    String goal;
    if (userProfile != null) {
      // Try to get goal from user's profile first
      if (userProfile.goals != null &&
          userProfile.goals is List &&
          userProfile.goals.isNotEmpty) {
        try {
          // Use the first goal from the user's goals list
          goal = userProfile.goals.first.toString();
        } catch (e) {
          print('DEBUG: Error accessing user goals: $e');
          goal = _generateGoalFromMuscleGroup(targetMuscleGroup);
        }
      } else if (userProfile.goalData != null &&
          userProfile.goalData is Map &&
          userProfile.goalData['primaryGoal'] != null) {
        // Try to get primary goal from goalData
        goal = userProfile.goalData['primaryGoal'].toString();
      } else if (userProfile.motivation != null &&
          userProfile.motivation.toString().isNotEmpty) {
        // Use motivation as goal if no specific goal is set
        goal = userProfile.motivation.toString();
      } else {
        // Fall back to generated goal based on muscle group
        goal = _generateGoalFromMuscleGroup(targetMuscleGroup);
      }
    } else {
      // No user profile provided, generate goal based on muscle group
      goal = _generateGoalFromMuscleGroup(targetMuscleGroup);
    }

    // Ensure the goal is descriptive and actionable
    if (goal.length < 10) {
      goal = 'Achieve $goal through targeted $targetMuscleGroup training';
    }

    // Add randomization elements to ensure variety
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Vary the workout slightly with random elements
    final workoutVariations = [
      'strength',
      'endurance',
      'power',
      'hypertrophy',
      'circuit',
    ];

    final intensityLevels = ['moderate', 'challenging', 'intense'];

    // Build smart workout parameters with randomization
    final smartParams = {
      'workoutType': workoutType,
      'targetMuscleGroup': targetMuscleGroup,
      'goal': goal,
      'duration': avgDuration.round(),
      'fitnessLevel': fitnessLevel,
      'excludeExercises': recentExercises, // Avoid recently done exercises
      'generationType': 'smart',
      'smartReason':
          'Generated based on your recent workout history. '
          'Targeting $targetMuscleGroup to balance your training.',
      // Add randomization factors
      'workoutVariation':
          workoutVariations[random.nextInt(workoutVariations.length)],
      'intensityLevel': intensityLevels[random.nextInt(intensityLevels.length)],
      'randomSeed': random.nextInt(10000),
      'timestamp': timestamp,
      'sessionId': 'session_${timestamp}_${random.nextInt(1000)}',
    };

    print('DEBUG: Generated smart workout params: $smartParams');
    return smartParams;
  }

  // Extract exercises from recent workout sessions
  static List<String> extractRecentExercises(dynamic workoutSessions) {
    final exercises = <String>{};

    try {
      if (workoutSessions is List) {
        for (final session in workoutSessions.take(4)) {
          if (session?.completedExercises != null) {
            for (final completedExercise in session.completedExercises) {
              if (completedExercise?.exerciseName != null) {
                exercises.add(completedExercise.exerciseName.toString());
              }
            }
          }
        }
      }
    } catch (e) {
      print('DEBUG: Error extracting recent exercises: $e');
      // Return empty list if there's an error
    }

    return exercises.toList();
  }

  // Extract muscle groups from recent workout sessions
  static List<String> extractRecentMuscleGroups(dynamic workoutSessions) {
    final muscleGroups = <String>{};

    try {
      // Define muscle group mappings based on exercise names
      final muscleGroupMappings = {
        // Chest exercises
        'push up': 'Chest',
        'bench press': 'Chest',
        'chest press': 'Chest',
        'chest fly': 'Chest',
        'dips': 'Chest',

        // Back exercises
        'pull up': 'Back',
        'row': 'Back',
        'lat pulldown': 'Back',
        'deadlift': 'Back',
        'back extension': 'Back',

        // Shoulder exercises
        'shoulder press': 'Shoulders',
        'lateral raise': 'Shoulders',
        'overhead press': 'Shoulders',
        'front raise': 'Shoulders',
        'rear delt': 'Shoulders',

        // Arm exercises
        'curl': 'Arms',
        'tricep': 'Arms',
        'bicep': 'Arms',
        'arm extension': 'Arms',

        // Leg exercises
        'squat': 'Legs',
        'lunge': 'Legs',
        'leg press': 'Legs',
        'leg curl': 'Legs',
        'calf raise': 'Legs',

        // Glute exercises
        'hip thrust': 'Glutes',
        'glute bridge': 'Glutes',
        'hip abduction': 'Glutes',

        // Core exercises
        'plank': 'Core',
        'crunch': 'Core',
        'ab': 'Core',
        'core': 'Core',
        'sit up': 'Core',
      };

      if (workoutSessions is List) {
        for (final session in workoutSessions.take(4)) {
          if (session?.completedExercises != null) {
            for (final completedExercise in session.completedExercises) {
              if (completedExercise?.exerciseName != null) {
                final exerciseName = completedExercise.exerciseName
                    .toString()
                    .toLowerCase();

                // Find matching muscle group
                for (final mapping in muscleGroupMappings.entries) {
                  if (exerciseName.contains(mapping.key)) {
                    muscleGroups.add(mapping.value);
                    break;
                  }
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print('DEBUG: Error extracting recent muscle groups: $e');
      // Return empty list if there's an error
    }

    return muscleGroups.toList();
  }

  // Helper method to generate goal based on muscle group
  static String _generateGoalFromMuscleGroup(String targetMuscleGroup) {
    switch (targetMuscleGroup) {
      case 'Legs':
      case 'Glutes':
        return 'Build lower body strength and muscle definition';
      case 'Chest':
      case 'Back':
      case 'Shoulders':
        return 'Develop upper body strength and muscle growth';
      case 'Arms':
        return 'Build arm strength and muscle definition';
      case 'Core':
        return 'Strengthen core muscles and improve stability';
      case 'Full Body':
      default:
        return 'Improve overall fitness, strength, and muscle balance';
    }
  }
}
