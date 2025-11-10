import 'package:flutter/foundation.dart';
import '../services/ai_preferences_service.dart';

/// Service responsible for managing user workout preferences
/// Handles recent preferences, smart recommendations, and user settings
class WorkoutPreferencesService extends ChangeNotifier {
  // State
  List<Map<String, dynamic>> _recentPreferences = [];
  Map<String, dynamic> _smartRecommendations = {};
  bool _isLoadingPreferences = true;
  Map<String, dynamic>? _userPreferences;

  // Getters
  List<Map<String, dynamic>> get recentPreferences => _recentPreferences;
  Map<String, dynamic> get smartRecommendations => _smartRecommendations;
  bool get isLoadingPreferences => _isLoadingPreferences;
  Map<String, dynamic>? get userPreferences => _userPreferences;

  /// Load user preferences and recommendations
  Future<void> loadUserPreferences() async {
    _isLoadingPreferences = true;
    notifyListeners();

    try {
      // Load recent generation parameters
      final recentParams = await AIPreferencesService.getRecentPreferences();
      _recentPreferences = recentParams;

      // Load smart recommendations
      final recommendations =
          await AIPreferencesService.getSmartRecommendations();
      _smartRecommendations = recommendations;
    } catch (e) {
      debugPrint('Error loading user preferences: $e');
    } finally {
      _isLoadingPreferences = false;
      notifyListeners();
    }
  }

  /// Generate a user-friendly title from preferences
  String generatePreferenceTitle(Map<String, dynamic> pref) {
    final workoutType = pref['workoutType'] as String? ?? 'Workout';
    final duration = pref['duration'] as int? ?? 45;
    final muscleGroups = pref['muscleGroups'] as List<dynamic>? ?? [];

    if (muscleGroups.isNotEmpty) {
      final firstGroup = muscleGroups.first.toString();
      return '$firstGroup $workoutType ($duration min)';
    }

    return '$workoutType ($duration min)';
  }

  /// Get user's most frequent workout preferences
  Map<String, dynamic> getMostFrequentPreferences() {
    if (_recentPreferences.isEmpty) {
      return _getDefaultPreferences();
    }

    // Count frequency of each parameter
    final workoutTypeCounts = <String, int>{};
    final durationCounts = <int, int>{};
    final muscleGroupCounts = <String, int>{};
    final fitnessLevelCounts = <String, int>{};

    for (final pref in _recentPreferences) {
      // Count workout types
      final workoutType = pref['workoutType'] as String?;
      if (workoutType != null) {
        workoutTypeCounts[workoutType] =
            (workoutTypeCounts[workoutType] ?? 0) + 1;
      }

      // Count durations
      final duration = pref['duration'] as int?;
      if (duration != null) {
        durationCounts[duration] = (durationCounts[duration] ?? 0) + 1;
      }

      // Count muscle groups
      final muscleGroups = pref['muscleGroups'] as List<dynamic>?;
      if (muscleGroups != null) {
        for (final group in muscleGroups) {
          final groupStr = group.toString();
          muscleGroupCounts[groupStr] = (muscleGroupCounts[groupStr] ?? 0) + 1;
        }
      }

      // Count fitness levels
      final fitnessLevel = pref['fitnessLevel'] as String?;
      if (fitnessLevel != null) {
        fitnessLevelCounts[fitnessLevel] =
            (fitnessLevelCounts[fitnessLevel] ?? 0) + 1;
      }
    }

    // Find most frequent values
    final mostFrequentWorkoutType = _getMostFrequent(workoutTypeCounts);
    final mostFrequentDuration = _getMostFrequent(durationCounts);
    final mostFrequentFitnessLevel = _getMostFrequent(fitnessLevelCounts);

    // Get top muscle groups
    final topMuscleGroups = muscleGroupCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final frequentMuscleGroups = topMuscleGroups
        .take(3)
        .map((e) => e.key)
        .toList();

    return {
      'workoutType': mostFrequentWorkoutType ?? 'Full Body',
      'duration': mostFrequentDuration ?? 45,
      'muscleGroups': frequentMuscleGroups.isNotEmpty
          ? frequentMuscleGroups
          : ['Full Body'],
      'fitnessLevel': mostFrequentFitnessLevel ?? 'Intermediate',
      'confidence': _calculateConfidence(),
    };
  }

  /// Get default preferences for new users
  Map<String, dynamic> _getDefaultPreferences() {
    return {
      'workoutType': 'Full Body',
      'duration': 45,
      'muscleGroups': ['Full Body'],
      'fitnessLevel': 'Beginner',
      'confidence': 0.0,
    };
  }

  /// Get the most frequent value from a count map
  T? _getMostFrequent<T>(Map<T, int> counts) {
    if (counts.isEmpty) return null;

    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Calculate confidence score based on data consistency
  double _calculateConfidence() {
    if (_recentPreferences.length < 3) {
      return 0.3; // Low confidence with little data
    }

    // Calculate consistency across recent preferences
    final workoutTypes = <String>{};
    final durations = <int>{};
    final fitnessLevels = <String>{};

    for (final pref in _recentPreferences.take(5)) {
      if (pref['workoutType'] != null) {
        workoutTypes.add(pref['workoutType']);
      }
      if (pref['duration'] != null) {
        durations.add(pref['duration']);
      }
      if (pref['fitnessLevel'] != null) {
        fitnessLevels.add(pref['fitnessLevel']);
      }
    }

    // Higher consistency = higher confidence
    final typeConsistency = 1.0 - (workoutTypes.length / 5.0);
    final durationConsistency = 1.0 - (durations.length / 5.0);
    final levelConsistency = 1.0 - (fitnessLevels.length / 5.0);

    final averageConsistency =
        (typeConsistency + durationConsistency + levelConsistency) / 3.0;

    // Scale to 0.3 - 1.0 range
    return 0.3 + (averageConsistency * 0.7);
  }

  /// Get personalized workout recommendations
  List<Map<String, dynamic>> getPersonalizedRecommendations() {
    final frequent = getMostFrequentPreferences();
    final recommendations = <Map<String, dynamic>>[];

    // Recommendation 1: User's most frequent preference
    recommendations.add({
      'title': 'Your Favorite',
      'subtitle': 'Based on your workout history',
      'workoutType': frequent['workoutType'],
      'duration': frequent['duration'],
      'muscleGroups': frequent['muscleGroups'],
      'fitnessLevel': frequent['fitnessLevel'],
      'confidence': frequent['confidence'],
      'reason': 'Most frequently chosen',
    });

    // Recommendation 2: Complementary workout
    final complementary = _getComplementaryWorkout(frequent);
    recommendations.add({
      'title': 'Balance Your Training',
      'subtitle': 'Complement your usual routine',
      ...complementary,
      'reason': 'Muscle balance optimization',
    });

    // Recommendation 3: Challenge workout
    final challenge = _getChallengeWorkout(frequent);
    recommendations.add({
      'title': 'Step It Up',
      'subtitle': 'Ready for a challenge?',
      ...challenge,
      'reason': 'Progressive overload',
    });

    // Recommendation 4: Quick workout
    recommendations.add({
      'title': 'Quick Session',
      'subtitle': 'Perfect for busy days',
      'workoutType': 'HIIT',
      'duration': 20,
      'muscleGroups': ['Full Body'],
      'fitnessLevel': frequent['fitnessLevel'],
      'confidence': 0.8,
      'reason': 'Time-efficient option',
    });

    return recommendations;
  }

  /// Get a complementary workout to balance training
  Map<String, dynamic> _getComplementaryWorkout(Map<String, dynamic> frequent) {
    final frequentMuscleGroups = frequent['muscleGroups'] as List<dynamic>;
    final frequentWorkoutType = frequent['workoutType'] as String;

    // Complementary muscle groups
    final complementaryGroups = <String>[];

    if (frequentMuscleGroups.contains('Chest') ||
        frequentMuscleGroups.contains('Arms')) {
      complementaryGroups.addAll(['Back', 'Legs']);
    } else if (frequentMuscleGroups.contains('Back')) {
      complementaryGroups.addAll(['Chest', 'Shoulders']);
    } else if (frequentMuscleGroups.contains('Legs')) {
      complementaryGroups.addAll(['Upper Body', 'Core']);
    } else {
      complementaryGroups.addAll(['Full Body']);
    }

    // Complementary workout type
    String complementaryType;
    if (frequentWorkoutType == 'Strength') {
      complementaryType = 'Cardio';
    } else if (frequentWorkoutType == 'Cardio') {
      complementaryType = 'Strength';
    } else {
      complementaryType = 'Flexibility';
    }

    return {
      'workoutType': complementaryType,
      'duration': frequent['duration'] as int,
      'muscleGroups': complementaryGroups,
      'fitnessLevel': frequent['fitnessLevel'],
      'confidence': 0.7,
    };
  }

  /// Get a challenging workout progression
  Map<String, dynamic> _getChallengeWorkout(Map<String, dynamic> frequent) {
    final currentLevel = frequent['fitnessLevel'] as String;
    final currentDuration = frequent['duration'] as int;

    // Progress fitness level
    String challengeLevel;
    switch (currentLevel.toLowerCase()) {
      case 'beginner':
        challengeLevel = 'Intermediate';
        break;
      case 'intermediate':
        challengeLevel = 'Advanced';
        break;
      default:
        challengeLevel = 'Expert';
    }

    return {
      'workoutType': 'HIIT',
      'duration': (currentDuration + 15).clamp(30, 90),
      'muscleGroups': frequent['muscleGroups'],
      'fitnessLevel': challengeLevel,
      'confidence': 0.6,
    };
  }

  /// Save user preference
  Future<void> savePreference(Map<String, dynamic> preference) async {
    try {
      await AIPreferencesService.saveLastGenerationParams(preference);
      await loadUserPreferences(); // Reload to get updated data
    } catch (e) {
      debugPrint('Error saving preference: $e');
    }
  }

  /// Clear all preferences
  Future<void> clearPreferences() async {
    try {
      // Clear stored preferences
      _recentPreferences.clear();
      _smartRecommendations.clear();
      notifyListeners();

      // Note: AIPreferencesService might need a clearAll method
      debugPrint('Preferences cleared locally');
    } catch (e) {
      debugPrint('Error clearing preferences: $e');
    }
  }

  /// Get workout insights based on history
  Map<String, dynamic> getWorkoutInsights() {
    if (_recentPreferences.isEmpty) {
      return {
        'totalWorkouts': 0,
        'averageDuration': 0,
        'favoriteWorkoutType': 'Unknown',
        'consistencyScore': 0.0,
        'recommendations': [],
      };
    }

    final totalWorkouts = _recentPreferences.length;
    final durations = _recentPreferences
        .map((p) => p['duration'] as int? ?? 0)
        .where((d) => d > 0);

    final averageDuration = durations.isNotEmpty
        ? durations.reduce((a, b) => a + b) / durations.length
        : 0;

    final frequent = getMostFrequentPreferences();

    return {
      'totalWorkouts': totalWorkouts,
      'averageDuration': averageDuration.round(),
      'favoriteWorkoutType': frequent['workoutType'],
      'favoriteBodyPart': frequent['muscleGroups'].isNotEmpty
          ? frequent['muscleGroups'][0]
          : 'Full Body',
      'consistencyScore': frequent['confidence'],
      'recommendations': getPersonalizedRecommendations(),
    };
  }

  @override
  void dispose() {
    super.dispose();
  }
}
