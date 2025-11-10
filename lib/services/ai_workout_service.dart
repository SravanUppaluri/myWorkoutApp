import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/workout.dart';
import '../models/exercise.dart';

class AIWorkoutService {
  late final FirebaseFunctions _functions;

  // Toggle between local backend and Firebase Functions
  static const bool _useLocalBackend =
      false; // Set to false to use Firebase Functions
  static const String _localBaseUrl = 'http://localhost:3000/api';

  AIWorkoutService() {
    _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

    // For development on web, use the emulator
    if (kDebugMode && kIsWeb && !_useLocalBackend) {
      // Uncomment this line if you want to use the local emulator during development
      // _functions.useFunctionsEmulator('localhost', 5001);
    }
  }

  String get _apiBaseUrl {
    if (_useLocalBackend) {
      return _localBaseUrl;
    }
    return 'https://us-central1-exerciselist-da299.cloudfunctions.net';
  }

  bool get _isUsingLocalBackend => _useLocalBackend && kDebugMode;

  /// Generate a complete workout using AI based on user preferences
  Future<Workout?> generateWorkout(Map<String, dynamic> workoutRequest) async {
    try {
      // Flatten the request for better token efficiency
      final flattenedRequest = flattenWorkoutRequest(workoutRequest);

      // Add timestamp and random elements to ensure unique requests
      flattenedRequest['requestTimestamp'] = DateTime.now().toIso8601String();
      flattenedRequest['requestId'] =
          'req_${DateTime.now().millisecondsSinceEpoch}';

      print(
        'DEBUG: AIWorkoutService.generateWorkout called with flattened request: $flattenedRequest',
      );
      print('DEBUG: Goal parameter: ${flattenedRequest['goal']}');
      print(
        'DEBUG: Using ${_isUsingLocalBackend ? 'LOCAL BACKEND' : 'FIREBASE FUNCTIONS'}',
      );

      if (_isUsingLocalBackend) {
        return await _generateWorkoutLocal(flattenedRequest);
      } else {
        return await _generateWorkoutFirebase(flattenedRequest);
      }
    } catch (e) {
      print('Error generating workout with AI: $e');
      rethrow;
    }
  }

  /// Generate workout using local backend
  Future<Workout?> _generateWorkoutLocal(
    Map<String, dynamic> workoutRequest,
  ) async {
    try {
      print('🚀 Calling local backend: $_apiBaseUrl/workout/generate');

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/workout/generate'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'WorkoutApp/1.0',
        },
        body: jsonEncode(workoutRequest),
      );

      print('📡 Local backend response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          print(
            '✅ Local backend success - MCP Enhanced: ${responseData['meta']?['mcpEnhanced'] ?? false}',
          );
          return _parseAIWorkoutResponse(responseData['data'], workoutRequest);
        } else {
          throw Exception('Invalid response format from local backend');
        }
      } else if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded. Please try again later.');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['error']?['message'] ?? 'Failed to generate workout',
        );
      }
    } catch (e) {
      if (e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        print(
          '⚠️  Local backend not available, falling back to Firebase Functions',
        );
        return await _generateWorkoutFirebase(workoutRequest);
      }
      rethrow;
    }
  }

  /// Generate workout using Firebase Functions with enhanced MCP
  Future<Workout?> _generateWorkoutFirebase(
    Map<String, dynamic> workoutRequest,
  ) async {
    try {
      print('🔥 Using Firebase Functions with enhanced MCP');

      // Try enhanced AI workout endpoint first
      try {
        // Add cache-busting query parameter
        final uri =
            Uri.parse(
              '$_apiBaseUrl/enhancedAIWorkout/api/ai-workout/generate-workout',
            ).replace(
              queryParameters: {
                'cache_bust': DateTime.now().millisecondsSinceEpoch.toString(),
              },
            );

        print(
          '🔍 MCP Request - sending enhanced context with ${workoutRequest['workoutSessions']?.length ?? 0} recent sessions',
        );

        final response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'User-Agent': 'WorkoutApp/1.0',
            'Accept': 'application/json',
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
            'Expires': '0',
            'X-MCP-Context': 'enhanced',
            'X-User-ID': workoutRequest['userId']?.toString() ?? '',
            'Access-Control-Request-Method': 'POST',
            'Access-Control-Request-Headers':
                'Content-Type, X-MCP-Context, X-User-ID',
          },
          body: jsonEncode(workoutRequest),
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);

          if (responseData['success'] == true &&
              responseData['workout'] != null) {
            print('✅ Firebase MCP enhanced workout generated successfully');
            return _parseAIWorkoutResponse(
              responseData['workout'],
              workoutRequest,
            );
          }
        }
      } catch (enhancedError) {
        print(
          '⚠️ Enhanced endpoint failed, falling back to basic: $enhancedError',
        );
      }

      // Fallback to original Firebase Functions
      final callable = _functions.httpsCallable('generateWorkoutWithAI');
      final result = await callable.call(workoutRequest);

      if (result.data != null) {
        print('DEBUG: Firebase AI workout generation successful (fallback)');

        // Parse the AI response into a Workout object
        final workoutData = result.data as Map<String, dynamic>;
        return _parseAIWorkoutResponse(workoutData, workoutRequest);
      }

      print('DEBUG: Firebase AI workout generation returned null');
      return null;
    } catch (e) {
      final errorMessage = e.toString();
      print('Error generating workout with Firebase Functions: $errorMessage');

      // Handle specific Gemini API errors
      if (errorMessage.contains('gemini-2.5-flash-latest is not found') ||
          errorMessage.contains('models/gemini-2.5-flash-latest')) {
        print(
          '🚨 GEMINI MODEL ERROR: gemini-2.5-flash-latest is not available',
        );
        print(
          '💡 Please update your Firebase Functions to use a supported model like:',
        );
        print('   - gemini-2.5-flash');
        print('   - gemini-1.5-pro');
        print('   - gemini-pro');
        throw Exception(
          'AI model unavailable. Please contact support to update the workout generation service.',
        );
      }

      // If it's any other error, try to provide a helpful fallback
      if (errorMessage.contains('Gemini API error') ||
          errorMessage.contains('generateWorkoutWithAI')) {
        print(
          '⚠️ AI service temporarily unavailable, trying local fallback...',
        );
        try {
          return await _generateWorkoutLocal(workoutRequest);
        } catch (localError) {
          print('Local fallback also failed: $localError');
          throw Exception(
            'AI workout generation is temporarily unavailable. Please try again later.',
          );
        }
      }

      rethrow;
    }
  }

  /// Parse the AI response into Workout object
  Workout _parseAIWorkoutResponse(
    Map<String, dynamic> data, [
    Map<String, dynamic>? originalRequest,
  ]) {
    try {
      print('🔄 Parsing AI workout response...');

      // Handle new nested workout_plan structure
      List<dynamic> exercisesData = [];

      if (data.containsKey('workout_plan') && data['workout_plan'] != null) {
        print(
          '📋 Found new workout_plan structure, extracting exercises from sections...',
        );
        final workoutPlan = data['workout_plan'] as Map<String, dynamic>;
        final sections = workoutPlan['sections'] as List<dynamic>? ?? [];

        // Extract exercises from all sections (Main Workout, Warm-up, Cool-down)
        for (final section in sections) {
          final sectionMap = section as Map<String, dynamic>;
          final sectionType = sectionMap['type']?.toString() ?? '';
          var sectionExercises =
              sectionMap['exercises'] as List<dynamic>? ?? [];

          print(
            '📋 Processing section: $sectionType with ${sectionExercises.length} exercises',
          );

          // Normalize string entries into maps and attach section metadata
          sectionExercises = sectionExercises.map((exercise) {
            if (exercise is String) {
              return <String, dynamic>{
                'name': exercise,
                'sectionType': sectionType,
                'sectionInfo': sectionMap,
              };
            } else if (exercise is Map<String, dynamic>) {
              exercise['sectionType'] = exercise['sectionType'] ?? sectionType;
              exercise['sectionInfo'] = exercise['sectionInfo'] ?? sectionMap;
              return exercise;
            } else {
              return <String, dynamic>{
                'name': exercise?.toString() ?? 'Unknown Exercise',
                'sectionType': sectionType,
                'sectionInfo': sectionMap,
              };
            }
          }).toList();

          exercisesData.addAll(sectionExercises);
        }

        print(
          '📋 Total exercises extracted from sections: ${exercisesData.length}',
        );
      } else {
        // Fallback to old flat structure
        var flat = data['exercises'] as List<dynamic>?;
        if (flat == null) {
          // Some backends may return exercises as top-level strings or under other keys
          // Try common fallbacks
          if (data['workout'] is Map<String, dynamic>) {
            flat =
                (data['workout'] as Map<String, dynamic>)['exercises']
                    as List<dynamic>?;
          }
        }

        exercisesData = flat ?? [];
        print(
          '📋 Using flat exercises structure: ${exercisesData.length} exercises',
        );
      }

      // Normalize exercisesData: convert string entries to maps and ensure a 'name' key exists
      exercisesData = exercisesData.map((exercise) {
        if (exercise is String) {
          return <String, dynamic>{'name': exercise};
        } else if (exercise is Map<String, dynamic>) {
          if (!exercise.containsKey('name') &&
              exercise.containsKey('exercise')) {
            exercise['name'] =
                exercise['exercise']?.toString() ?? 'Unknown Exercise';
          }
          // Ensure keys expected by parser exist (avoid null-related exceptions)
          exercise['name'] = (exercise['name'] ?? 'Unknown Exercise')
              .toString();
          exercise['equipment'] =
              exercise['equipment'] ?? exercise['equipmentList'] ?? [];
          exercise['target_muscle_groups'] =
              exercise['target_muscle_groups'] ??
              exercise['muscleGroups'] ??
              [];
          return exercise;
        } else {
          return <String, dynamic>{
            'name': exercise?.toString() ?? 'Unknown Exercise',
          };
        }
      }).toList();

      final exercises = exercisesData.map((exerciseData) {
        try {
          final exerciseMap = exerciseData as Map<String, dynamic>;
          print('🏋️ Parsing exercise: ${exerciseMap['name']}');
          print('🔍 Raw exercise data: $exerciseMap');

          // Handle section type for categorization
          final sectionType =
              exerciseMap['sectionType']?.toString() ?? 'Main Workout';

          // Create Exercise object - handle both old and new formats
          final exercise = Exercise(
            id:
                exerciseMap['id']?.toString() ??
                'ai_${DateTime.now().millisecondsSinceEpoch}',
            name: exerciseMap['name']?.toString() ?? 'Unknown Exercise',
            category: _getExerciseCategory(sectionType, exerciseMap),
            equipment: _parseStringList(
              exerciseMap['equipment'] ?? ['Bodyweight'],
            ),
            targetRegion: _parseStringList(
              exerciseMap['targetRegion'] ??
                  exerciseMap['target_muscle_groups'],
            ),
            primaryMuscles: _parseStringList(
              exerciseMap['target_muscle_groups'] ??
                  exerciseMap['muscleGroups'] ??
                  exerciseMap['primaryMuscles'] ??
                  ['Full Body'],
            ),
            secondaryMuscles: _parseStringList(
              exerciseMap['secondaryMuscles'] ?? [],
            ),
            difficulty: exerciseMap['difficulty']?.toString() ?? 'Beginner',
            movementType: exerciseMap['movementType']?.toString() ?? 'Compound',
            movementPattern:
                exerciseMap['movementPattern']?.toString() ?? 'Push',
            gripType: exerciseMap['gripType']?.toString() ?? 'Standard',
            rangeOfMotion: exerciseMap['rangeOfMotion']?.toString() ?? 'Full',
            tempo: exerciseMap['tempo']?.toString() ?? 'Moderate',
            muscleGroup: _getMuscleGroupFromTargets(exerciseMap),
            muscleInfo: MuscleInfo(
              scientificName: '',
              commonName: exerciseMap['muscleGroup']?.toString() ?? '',
              muscleRegions: [],
              primaryFunction: '',
              location: '',
              muscleFiberDirection: '',
            ),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          // Create WorkoutExercise with sets/reps/weight
          // Handle both new section-based format and old format
          int sets = 3;
          int reps = 12;
          double weight = 0.0;
          int restTime = 60;

          // Handle new section-based format
          if (exerciseMap.containsKey('duration_seconds')) {
            // New format with duration-based exercises
            final durationSeconds =
                exerciseMap['duration_seconds'] as int? ?? 30;
            final sectionInfo =
                exerciseMap['sectionInfo'] as Map<String, dynamic>?;

            if (sectionInfo != null) {
              sets = sectionInfo['sets'] as int? ?? 1;
              restTime =
                  sectionInfo['rest_between_exercises_seconds'] as int? ?? 15;
            }

            // Convert duration to reps (approximate)
            reps = durationSeconds ~/ 2; // Rough approximation

            // Handle time-based exercises differently
            if (exerciseMap['reps_sets_info']
                    ?.toString()
                    .toLowerCase()
                    .contains('continuous') ==
                true) {
              sets = 1;
              reps = durationSeconds; // Use duration as "reps"
            }
          } else if (exerciseMap['sets'] is List) {
            // Old AI array format: [{"reps": 12, "weight": 0}, ...]
            final setsArray = exerciseMap['sets'] as List;
            sets = setsArray.length;

            if (setsArray.isNotEmpty && setsArray.first is Map) {
              final firstSet = setsArray.first as Map<String, dynamic>;
              reps = _parseReps(firstSet['reps']);
              weight = _parseWeight(firstSet['weight']);
            }
          } else {
            // Fallback to old simple format
            sets = _parseSets(exerciseMap['sets']);
            reps = _parseReps(exerciseMap['reps']);
            weight = _parseWeight(exerciseMap['weight']);
            restTime = _parseRestTime(exerciseMap['restTime']);
          }

          print('✅ Created exercise: ${exercise.name} (${exercise.id})');

          return WorkoutExercise(
            exercise: exercise,
            sets: sets,
            reps: reps,
            weight: weight,
            restTime: restTime,
            notes:
                exerciseMap['instructions']?.toString() ??
                exerciseMap['notes']?.toString() ??
                '',
          );
        } catch (exerciseError) {
          final exerciseName =
              (exerciseData as Map<String, dynamic>?)?['name']?.toString() ??
              'Unknown Exercise';
          print('⚠️ Error parsing exercise $exerciseName: $exerciseError');

          // Return a default exercise to prevent the entire workout from failing
          return WorkoutExercise(
            exercise: Exercise(
              id: 'default_${DateTime.now().millisecondsSinceEpoch}',
              name: exerciseName,
              category: 'Strength',
              equipment: ['Bodyweight'],
              targetRegion: ['Full Body'],
              primaryMuscles: ['Full Body'],
              secondaryMuscles: [],
              difficulty: 'Beginner',
              movementType: 'Compound',
              movementPattern: 'Push',
              gripType: 'Standard',
              rangeOfMotion: 'Full',
              tempo: 'Moderate',
              muscleGroup: 'Full Body',
              muscleInfo: MuscleInfo(
                scientificName: '',
                commonName: 'Full Body',
                muscleRegions: [],
                primaryFunction: '',
                location: '',
                muscleFiberDirection: '',
              ),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            sets: 3,
            reps: 12,
            weight: 0.0,
            restTime: 60,
            notes: 'Exercise parsing error - please review',
          );
        }
      }).toList();

      print('✅ Successfully parsed ${exercises.length} exercises');

      // Create Workout object with meaningful name
      final workoutName = _generateMeaningfulWorkoutName(
        data,
        originalRequest,
        exercisesData,
      );

      print('🎯 Created workout: $workoutName');

      return Workout(
        id: '', // Will be set when saved to database
        name: workoutName,
        description:
            data['description']?.toString() ??
            'Personalized workout created by AI',
        exercises: exercises,
        estimatedDuration:
            originalRequest?['duration'] as int? ??
            data['estimatedDuration'] as int? ??
            45,
        difficulty: data['difficulty']?.toString() ?? 'Intermediate',
        createdAt: DateTime.now(),
      );
    } catch (e) {
      print('❌ Error parsing AI workout response: $e');
      print('Raw response data: $data');
      rethrow;
    }
  }

  /// Test backend connection and get service status
  Future<Map<String, dynamic>> getServiceStatus() async {
    if (_isUsingLocalBackend) {
      return await _getLocalBackendStatus();
    } else {
      return await _getFirebaseStatus();
    }
  }

  /// Get local backend status and capabilities
  Future<Map<String, dynamic>> _getLocalBackendStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/workout/test'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'backend': 'local',
          'status': 'connected',
          'url': _apiBaseUrl,
          'services': data['services'] ?? {},
          'mcpEnabled': data['services']?['mcp'] == 'connected',
        };
      } else {
        throw Exception('Local backend returned ${response.statusCode}');
      }
    } catch (e) {
      return {
        'backend': 'local',
        'status': 'disconnected',
        'url': _apiBaseUrl,
        'error': e.toString(),
        'mcpEnabled': false,
      };
    }
  }

  /// Get Firebase Functions status
  Future<Map<String, dynamic>> _getFirebaseStatus() async {
    try {
      // You could implement a health check function in Firebase if needed
      return {
        'backend': 'firebase',
        'status': 'connected',
        'mcpEnabled': false,
      };
    } catch (e) {
      return {
        'backend': 'firebase',
        'status': 'disconnected',
        'error': e.toString(),
        'mcpEnabled': false,
      };
    }
  }

  /// Generate smart workout based on user profile and history
  Future<Workout?> generateSmartWorkout({
    required String userId,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      print('🧠 Generating smart workout for user: $userId');

      // Flatten the request structure for better token efficiency
      final flattenedRequest = _flattenSmartWorkoutRequest(userId, preferences);
      print('🧠 Flattened smart workout request: $flattenedRequest');

      if (_isUsingLocalBackend) {
        final response = await http.post(
          Uri.parse('$_apiBaseUrl/workout/smart-generate'),
          headers: {
            'Content-Type': 'application/json',
            'User-Agent': 'WorkoutApp/1.0',
          },
          body: jsonEncode(flattenedRequest),
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);

          if (responseData['success'] == true && responseData['data'] != null) {
            print('✅ Smart workout generated (local MCP)');
            return _parseAIWorkoutResponse(
              responseData['data'],
              flattenedRequest,
            );
          }
        }
      } else {
        // Use Firebase enhanced endpoint
        final uri = Uri.parse(
          '$_apiBaseUrl/enhancedAIWorkout/api/ai-workout/smart-generate',
        );
        print('🔥 Calling Firebase smart-generate at: $uri');
        print('🔥 Request payload: ${jsonEncode(flattenedRequest)}');

        final response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'User-Agent': 'WorkoutApp/1.0',
            'Accept': 'application/json',
          },
          body: jsonEncode(flattenedRequest),
        );

        print('📡 Smart workout response status: ${response.statusCode}');
        print('📡 Smart workout response body: ${response.body}');

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);

          if (responseData['success'] == true &&
              responseData['workout'] != null) {
            print('✅ Smart workout generated (Firebase MCP)');
            return _parseAIWorkoutResponse(
              responseData['workout'],
              flattenedRequest,
            );
          } else {
            print('❌ Smart workout response missing success or workout data');
          }
        } else {
          print('❌ Smart workout failed with status: ${response.statusCode}');
          print('❌ Error response: ${response.body}');
        }
      }

      throw Exception('Failed to generate smart workout');
    } catch (e) {
      print('Error generating smart workout: $e');
      rethrow;
    }
  }

  /// Get development information
  String getBackendInfo() {
    if (_isUsingLocalBackend) {
      return 'Using LOCAL BACKEND at $_localBaseUrl (MCP Enhanced)';
    } else {
      return 'Using FIREBASE FUNCTIONS (Production)';
    }
  }

  /// Helper method to parse string lists from various formats
  List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    } else if (value is String) {
      return [value];
    }
    return [];
  }

  /// Generate workout variations based on existing workout
  Future<List<Workout>> generateWorkoutVariations(
    String baseWorkoutId,
    Map<String, dynamic> modifications,
  ) async {
    try {
      final callable = _functions.httpsCallable('generateWorkoutVariations');
      final result = await callable.call({
        'baseWorkoutId': baseWorkoutId,
        'modifications': modifications,
      });

      if (result.data != null && result.data is List) {
        return (result.data as List)
            .map(
              (workoutData) =>
                  _parseAIWorkoutResponse(workoutData as Map<String, dynamic>),
            )
            .toList();
      }
      return [];
    } catch (e) {
      print('Error generating workout variations: $e');
      rethrow;
    }
  }

  /// Get AI suggestions for workout improvements
  Future<Map<String, dynamic>?> getWorkoutSuggestions(
    String workoutId,
    Map<String, dynamic> userProgress,
  ) async {
    try {
      final callable = _functions.httpsCallable('getWorkoutSuggestions');
      final result = await callable.call({
        'workoutId': workoutId,
        'userProgress': userProgress,
      });

      return result.data as Map<String, dynamic>?;
    } catch (e) {
      print('Error getting workout suggestions: $e');
      rethrow;
    }
  }

  /// Parse reps value that might be a string like "AMRAP" or an integer
  int _parseReps(dynamic repsValue) {
    if (repsValue == null) return 12;

    if (repsValue is int) return repsValue;

    if (repsValue is String) {
      // Handle special cases
      final lowerReps = repsValue.toLowerCase();
      if (lowerReps.contains('amrap') ||
          lowerReps.contains('as many as possible') ||
          lowerReps.contains('max reps')) {
        return 0; // Use 0 to indicate AMRAP
      }

      if (lowerReps.contains('failure') || lowerReps.contains('burnout')) {
        return 0; // Use 0 to indicate to failure
      }

      // Try to extract numbers from strings like "8-12", "10-15", "12 reps"
      final numberMatch = RegExp(r'(\d+)').firstMatch(repsValue);
      if (numberMatch != null) {
        return int.tryParse(numberMatch.group(1)!) ?? 12;
      }

      // If we can't parse it, default to 12
      return 12;
    }

    // If it's a double, round it to int
    if (repsValue is double) return repsValue.round();

    // Default fallback
    return 12;
  }

  /// Parse sets value that might be a string or integer
  int _parseSets(dynamic setsValue) {
    if (setsValue == null) return 3;

    if (setsValue is int) return setsValue;

    if (setsValue is String) {
      // Try to extract number from string
      final numberMatch = RegExp(r'(\d+)').firstMatch(setsValue);
      if (numberMatch != null) {
        return int.tryParse(numberMatch.group(1)!) ?? 3;
      }
      return 3;
    }

    if (setsValue is double) return setsValue.round();

    return 3;
  }

  /// Parse weight value that might be a string or number
  double _parseWeight(dynamic weightValue) {
    if (weightValue == null) return 0.0;

    if (weightValue is double) return weightValue;
    if (weightValue is int) return weightValue.toDouble();

    if (weightValue is String) {
      // Handle bodyweight exercises
      final lowerWeight = weightValue.toLowerCase();
      if (lowerWeight.contains('bodyweight') ||
          lowerWeight.contains('body weight') ||
          lowerWeight.contains('bw') ||
          lowerWeight.contains('none')) {
        return 0.0;
      }

      // Try to extract number from strings like "45 lbs", "20kg", "15.5"
      final numberMatch = RegExp(r'(\d+\.?\d*)').firstMatch(weightValue);
      if (numberMatch != null) {
        return double.tryParse(numberMatch.group(1)!) ?? 0.0;
      }

      return 0.0;
    }

    return 0.0;
  }

  /// Parse rest time value that might be a string like "60 seconds" or integer
  int _parseRestTime(dynamic restValue) {
    if (restValue == null) return 60;

    if (restValue is int) return restValue;

    if (restValue is String) {
      // Handle time formats like "60 seconds", "1 minute", "90s", "1:30"
      final lowerRest = restValue.toLowerCase();

      // Handle minute:second format like "1:30"
      final minuteSecondMatch = RegExp(r'(\d+):(\d+)').firstMatch(lowerRest);
      if (minuteSecondMatch != null) {
        final minutes = int.tryParse(minuteSecondMatch.group(1)!) ?? 0;
        final seconds = int.tryParse(minuteSecondMatch.group(2)!) ?? 0;
        return (minutes * 60) + seconds;
      }

      // Handle minutes
      if (lowerRest.contains('minute')) {
        final numberMatch = RegExp(r'(\d+\.?\d*)').firstMatch(lowerRest);
        if (numberMatch != null) {
          final minutes = double.tryParse(numberMatch.group(1)!) ?? 1.0;
          return (minutes * 60).round();
        }
      }

      // Handle seconds
      final numberMatch = RegExp(r'(\d+)').firstMatch(lowerRest);
      if (numberMatch != null) {
        return int.tryParse(numberMatch.group(1)!) ?? 60;
      }

      return 60;
    }

    if (restValue is double) return restValue.round();

    return 60;
  }

  /// Generate a meaningful workout name based on content and context
  String _generateMeaningfulWorkoutName(
    Map<String, dynamic> data,
    Map<String, dynamic>? originalRequest,
    List<dynamic> exercisesData,
  ) {
    print('🎯 Generating meaningful workout name...');

    // First, try to extract a good name from the workout_plan if it exists
    if (data.containsKey('workout_plan')) {
      final workoutPlan = data['workout_plan'] as Map<String, dynamic>;
      final planName = workoutPlan['name']?.toString() ?? '';

      if (planName.isNotEmpty &&
          planName.length <= 30 &&
          !planName.toLowerCase().contains('achieve') &&
          !planName.toLowerCase().contains('your goal')) {
        print('✅ Using workout plan name: "$planName"');
        return planName;
      }
    }

    // Analyze the exercises to determine workout type
    final primaryMuscles = <String>{};
    bool hasCardio = false;
    bool hasStrength = false;
    bool hasStretching = false;

    for (final exercise in exercisesData) {
      if (exercise is Map<String, dynamic>) {
        final exerciseName = exercise['name']?.toString().toLowerCase() ?? '';
        final sectionType =
            exercise['sectionType']?.toString().toLowerCase() ?? '';

        // Categorize by section
        if (sectionType.contains('warm') || sectionType.contains('cool')) {
          hasStretching = true;
        } else {
          // Analyze exercise name for type
          if (exerciseName.contains('run') ||
              exerciseName.contains('jump') ||
              exerciseName.contains('cardio') ||
              exerciseName.contains('burpee')) {
            hasCardio = true;
          } else {
            hasStrength = true;
          }
        }

        // Collect target muscles
        final targetMuscles =
            exercise['target_muscle_groups'] as List<dynamic>? ?? [];
        for (final muscle in targetMuscles) {
          if (muscle.toString().toLowerCase() != 'full body') {
            primaryMuscles.add(muscle.toString());
          }
        }
      }
    }

    // Determine workout type
    String workoutType = '';
    if (hasCardio && hasStrength) {
      workoutType = 'HIIT';
    } else if (hasCardio) {
      workoutType = 'Cardio';
    } else if (hasStrength) {
      workoutType = 'Strength';
    } else {
      workoutType = 'Fitness';
    }

    // If the workout only contains warm-up / cool-down / mobility, mark as Stretching
    if (hasStretching && !hasCardio && !hasStrength) {
      workoutType = 'Stretching';
    }

    // Determine focus area
    String focusArea = '';
    if (primaryMuscles.length == 1) {
      focusArea = primaryMuscles.first;
    } else if (primaryMuscles.length == 2) {
      focusArea = primaryMuscles.join(' & ');
    } else if (primaryMuscles.contains('Chest') ||
        primaryMuscles.contains('Shoulders')) {
      focusArea = 'Upper Body';
    } else if (primaryMuscles.contains('Quads') ||
        primaryMuscles.contains('Glutes')) {
      focusArea = 'Lower Body';
    } else {
      focusArea = 'Full Body';
    }

    // Duration is available in originalRequest or response but not used directly here

    // Generate name
    String workoutName;
    if (focusArea != 'Full Body' && focusArea.isNotEmpty) {
      workoutName = '$focusArea $workoutType';
    } else {
      workoutName = '$workoutType Blast';
    }

    // Add time context for variety
    final hour = DateTime.now().hour;
    if (hour < 12) {
      workoutName = 'Morning $workoutName';
    } else if (hour < 17) {
      workoutName = 'Midday $workoutName';
    } else {
      workoutName = 'Evening $workoutName';
    }

    print('✅ Generated meaningful name: "$workoutName"');
    return workoutName;
  }

  /// Get exercise category based on section type and exercise data
  String _getExerciseCategory(
    String sectionType,
    Map<String, dynamic> exerciseMap,
  ) {
    switch (sectionType.toLowerCase()) {
      case 'warm-up':
      case 'warmup':
        return 'Warm-up';
      case 'main workout':
      case 'workout':
        // Determine based on exercise characteristics
        final exerciseName =
            exerciseMap['name']?.toString().toLowerCase() ?? '';
        if (exerciseName.contains('run') ||
            exerciseName.contains('cardio') ||
            exerciseName.contains('jump')) {
          return 'Cardio';
        }
        return 'Strength';
      default:
        return 'Strength';
    }
  }

  /// Extract muscle group from target muscle groups
  String _getMuscleGroupFromTargets(Map<String, dynamic> exerciseMap) {
    final targetMuscles = _parseStringList(
      exerciseMap['target_muscle_groups'] ??
          exerciseMap['muscleGroups'] ??
          exerciseMap['primaryMuscles'],
    );

    if (targetMuscles.isEmpty) return 'Full Body';

    // If multiple muscle groups, return the first one or "Full Body" if diverse
    if (targetMuscles.length > 3) return 'Full Body';

    return targetMuscles.first;
  }

  /// Flatten smart workout request for better token efficiency
  /// Reduces nested structure and eliminates duplicate data
  Map<String, dynamic> _flattenSmartWorkoutRequest(
    String userId,
    Map<String, dynamic>? preferences,
  ) {
    final prefs = preferences ?? {};

    // Extract nested preferences and flatten to top level
    // Accept either recentExerciseNames (preferred) or recentWorkoutNames (fallback)
    final recentExerciseNames =
        prefs['recentExerciseNames'] ?? prefs['recentWorkoutNames'] ?? [];
    final recentWorkoutNames =
        prefs['recentWorkoutNames'] ?? prefs['recentExerciseNames'] ?? [];

    final flattenedRequest = <String, dynamic>{
      'userId': userId,
      'duration': prefs['duration'] ?? 45,
      'recentExerciseNames': recentExerciseNames,
      'recentWorkoutNames': recentWorkoutNames,
      'excludeWarmup': prefs['excludeWarmup'] ?? false,
    };

    // Remove any null values to reduce payload size further
    flattenedRequest.removeWhere((key, value) => value == null);

    return flattenedRequest;
  }

  /// Flatten regular workout request for better token efficiency
  /// Removes redundant nesting and optimizes data structure
  static Map<String, dynamic> flattenWorkoutRequest(
    Map<String, dynamic> request,
  ) {
    final flattened = <String, dynamic>{};

    // Copy top-level properties directly
    for (final entry in request.entries) {
      if (entry.value is Map<String, dynamic>) {
        // Flatten nested maps
        final nestedMap = entry.value as Map<String, dynamic>;
        for (final nestedEntry in nestedMap.entries) {
          // Avoid duplicate keys by prefixing nested keys if needed
          final key = flattened.containsKey(nestedEntry.key)
              ? '${entry.key}_${nestedEntry.key}'
              : nestedEntry.key;
          flattened[key] = nestedEntry.value;
        }
      } else if (entry.value is List) {
        // Keep arrays but ensure they're not nested unnecessarily
        final list = entry.value as List;
        if (list.isNotEmpty && list.first is Map) {
          // If list contains objects, flatten each object
          flattened[entry.key] = list
              .map(
                (item) => item is Map<String, dynamic>
                    ? flattenWorkoutRequest(item)
                    : item,
              )
              .toList();
        } else {
          flattened[entry.key] = entry.value;
        }
      } else {
        // Copy primitive values directly
        flattened[entry.key] = entry.value;
      }
    }

    // Remove null values to reduce payload size
    flattened.removeWhere((key, value) => value == null);

    // Ensure goal parameter is present (add default if missing)
    if (!flattened.containsKey('goal') ||
        flattened['goal'] == null ||
        flattened['goal'].toString().isEmpty) {
      // Generate a default goal based on workoutType or other available data
      final workoutType = flattened['workoutType']?.toString() ?? 'General';
      final fitnessLevel =
          flattened['fitnessLevel']?.toString() ?? 'Intermediate';

      flattened['goal'] =
          'Build strength and improve fitness with $workoutType training suitable for $fitnessLevel level';
    }

    return flattened;
  }
}
