import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../models/exercise.dart';
import 'database_service.dart';

class ExerciseAIService {
  late final FirebaseFunctions _functions;

  ExerciseAIService() {
    _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

    // For development on web, use the emulator
    if (kDebugMode && kIsWeb) {
      // Uncomment this line if you want to use the local emulator during development
      // _functions.useFunctionsEmulator('localhost', 5001);
    }
  }

  /// Validate if the input looks like a legitimate exercise search term
  bool _isValidExerciseQuery(String query) {
    // Basic validation rules
    final trimmed = query.trim();

    // Must be at least 2 characters
    if (trimmed.length < 2) return false;

    // Cannot be all numbers
    if (RegExp(r'^\d+$').hasMatch(trimmed)) return false;

    // Cannot be all special characters
    if (RegExp(r'^[^a-zA-Z\s]+$').hasMatch(trimmed)) return false;

    // Cannot be all the same character repeated
    if (RegExp(r'^(.)\1{2,}$').hasMatch(trimmed)) return false;

    // Must contain at least one letter
    if (!RegExp(r'[a-zA-Z]').hasMatch(trimmed)) return false;

    // Common gibberish patterns
    final gibberishPatterns = [
      r'^[qwerty]+$', // keyboard mashing
      r'^[asdf]+$', // keyboard mashing
      r'^[zxcv]+$', // keyboard mashing
      r'^(test|testing|abc|xyz|demo)$', // common test strings
      r'^[a-z]{1,2}$', // single/double letters
      r'^\w{1,2}\d+$', // single letter + numbers
    ];

    for (final pattern in gibberishPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(trimmed)) {
        return false;
      }
    }

    return true;
  }

  /// Search for an exercise using AI when not found in local database
  Future<Exercise?> searchExerciseWithAI(String exerciseName) async {
    try {
      // Validate input before sending to AI
      if (!_isValidExerciseQuery(exerciseName)) {
        logger.e('Invalid exercise query detected: $exerciseName');
        return null;
      }

      final callable = _functions.httpsCallable('searchExerciseWithAI');
      final result = await callable.call({'exerciseName': exerciseName});

      if (result.data != null) {
        // Check if AI returned an error response
        if (result.data is Map<String, dynamic> &&
            result.data['error'] == 'not_found') {
          logger.e('AI rejected query as invalid: ${result.data['message']}');
          return null;
        }

        // Convert the AI response to Exercise model
        final exercise = Exercise.fromAIResponse(result.data);

        // Save the AI-generated exercise to the database for future use
        try {
          final savedId = await DatabaseService.saveAIExercise(result.data);
          logger.e('Successfully saved AI exercise to database: $savedId');
        } catch (saveError) {
          // Log the error but don't fail the main operation
          logger.e(
            'Warning: Could not save AI exercise to database: $saveError',
          );
        }

        return exercise;
      }
      return null;
    } catch (e) {
      logger.e('Error searching exercise with AI: $e');
      rethrow;
    }
  }

  /// Get exercise variations using AI
  Future<List<Exercise>> getExerciseVariations(
    String baseExercise, {
    int count = 3,
  }) async {
    try {
      final callable = _functions.httpsCallable('getExerciseVariations');
      final result = await callable.call({
        'baseExercise': baseExercise,
        'count': count,
      });

      if (result.data != null && result.data is List) {
        return (result.data as List)
            .map((exerciseData) => Exercise.fromAIResponse(exerciseData))
            .toList();
      }
      return [];
    } catch (e) {
      logger.e('Error getting exercise variations: $e');
      rethrow;
    }
  }
}
