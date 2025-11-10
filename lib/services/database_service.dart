import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references - using your existing Firebase project structure
  static CollectionReference get users => _firestore.collection('users');
  static CollectionReference get workouts =>
      _firestore.collection('workouts'); // NEW collection for user workouts
  static CollectionReference get exercises =>
      _firestore.collection('exercises'); // Your existing exercise collection
  static CollectionReference get workoutSessions =>
      _firestore.collection('workout_sessions'); // NEW collection
  static CollectionReference get userProgress =>
      _firestore.collection('user_progress'); // NEW collection

  // ==================== USERS ====================

  /// Create or update user profile
  static Future<void> createUserProfile({
    required String userId,
    required String displayName,
    required String email,
    String? photoUrl,
  }) async {
    await users.doc(userId).set({
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Get user profile
  static Future<DocumentSnapshot> getUserProfile(String userId) async {
    return await users.doc(userId).get();
  }

  /// Get user workouts as a stream for real-time updates
  static Stream<List<Map<String, dynamic>>> getUserWorkouts(String userId) {
    return workouts
        .where('userId', isEqualTo: userId)
        // Note: orderBy requires a Firestore index. Removed temporarily.
        // To add ordering back, create an index in Firebase Console:
        // Collection: workouts, Fields: userId (Ascending), createdAt (Descending)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return <String, dynamic>{'id': doc.id, ...data};
          }).toList();

          // Sort manually by createdAt if present
          docs.sort((a, b) {
            try {
              final aTime = a['createdAt'] as Timestamp?;
              final bTime = b['createdAt'] as Timestamp?;
              if (aTime == null || bTime == null) return 0;
              return bTime.compareTo(aTime); // Descending order
            } catch (e) {
              return 0;
            }
          });

          return docs;
        });
  }

  /// Save workout (create or update)
  static Future<String> saveWorkout(
    Map<String, dynamic> workout,
    String userId,
  ) async {
    try {
      print('DEBUG: DatabaseService.saveWorkout called for user: $userId');
      print('DEBUG: Workout data: $workout');

      // Add userId and timestamp
      final workoutData = {
        ...workout,
        'userId': userId,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Check if this is an update (existing document) or create (new document)
      final workoutId = workout['id'];
      print('DEBUG: Workout ID: $workoutId');

      if (workoutId != null &&
          workoutId.toString().isNotEmpty &&
          workoutId.toString() != '') {
        print('DEBUG: Updating existing workout');
        // Try to check if document exists before updating
        try {
          final docSnapshot = await workouts.doc(workoutId).get();
          if (docSnapshot.exists) {
            // Document exists, update it
            await workouts.doc(workoutId).update(workoutData);
            print('DEBUG: Updated existing workout with ID: $workoutId');
            return workoutId;
          } else {
            // Document doesn't exist, create new one
            workoutData['createdAt'] = FieldValue.serverTimestamp();
            workoutData.remove('id'); // Remove the old ID
            final docRef = await workouts.add(workoutData);
            print('DEBUG: Created new workout with ID: ${docRef.id}');
            return docRef.id;
          }
        } catch (e) {
          // If there's an error checking existence, create new document
          print('Error checking document existence, creating new: $e');
          workoutData['createdAt'] = FieldValue.serverTimestamp();
          workoutData.remove('id'); // Remove the old ID
          final docRef = await workouts.add(workoutData);
          print('DEBUG: Created new workout after error with ID: ${docRef.id}');
          return docRef.id;
        }
      } else {
        print('DEBUG: Creating new workout');
        // No ID provided, create new workout
        workoutData['createdAt'] = FieldValue.serverTimestamp();
        workoutData.remove('id'); // Remove any null/empty ID
        final docRef = await workouts.add(workoutData);
        print('DEBUG: Created new workout with ID: ${docRef.id}');
        return docRef.id;
      }
    } catch (e) {
      print('DEBUG: Error in DatabaseService.saveWorkout: $e');
      throw Exception('Failed to save workout: $e');
    }
  }

  /// Get single workout
  static Future<Map<String, dynamic>?> getWorkout(String workoutId) async {
    try {
      final doc = await workouts.doc(workoutId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return <String, dynamic>{'id': doc.id, ...data};
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get workout: $e');
    }
  }

  // ==================== WORKOUTS ====================

  /// Create a new workout
  static Future<String> createWorkout({
    required String userId,
    required String name,
    required String description,
    required List<Map<String, dynamic>> exercises,
    String? category,
  }) async {
    final docRef = await workouts.add({
      'userId': userId,
      'name': name,
      'description': description,
      'exercises': exercises,
      'category': category,
      'isTemplate': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// Update workout
  static Future<void> updateWorkout({
    required String workoutId,
    required Map<String, dynamic> updates,
  }) async {
    await workouts.doc(workoutId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete workout
  static Future<void> deleteWorkout(String workoutId) async {
    try {
      print('DEBUG: Attempting to delete workout with ID: $workoutId');
      await workouts.doc(workoutId).delete();
      print('DEBUG: Successfully deleted workout with ID: $workoutId');
    } catch (e) {
      print('DEBUG: Error deleting workout: $e');
      throw Exception('Failed to delete workout: $e');
    }
  }

  /// Delete workout session (completed workout)
  static Future<void> deleteWorkoutSession(String sessionId) async {
    try {
      print('DEBUG: Attempting to delete workout session with ID: $sessionId');
      await workoutSessions.doc(sessionId).delete();
      print('DEBUG: Successfully deleted workout session with ID: $sessionId');
    } catch (e) {
      print('DEBUG: Error deleting workout session: $e');
      throw Exception('Failed to delete workout session: $e');
    }
  }

  // ==================== EXERCISES ====================

  /// Create exercise template
  static Future<String> createExercise({
    required String name,
    required String category,
    required List<String> muscleGroups,
    String? instructions,
    String? imageUrl,
    Map<String, dynamic>? metadata,
  }) async {
    final docRef = await exercises.add({
      'name': name,
      'category': category,
      'muscleGroups': muscleGroups,
      'instructions': instructions,
      'imageUrl': imageUrl,
      'metadata': metadata,
      'isPublic': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// Save AI-generated exercise to the database
  static Future<String> saveAIExercise(
    Map<String, dynamic> exerciseData,
  ) async {
    try {
      // Check if exercise already exists by name
      final existingQuery = await exercises
          .where('name', isEqualTo: exerciseData['name'])
          .limit(1)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        // Exercise already exists, return existing ID
        return existingQuery.docs.first.id;
      }

      // Add the exercise to the database
      final docRef = await exercises.add({
        ...exerciseData,
        'isPublic': true,
        'source': exerciseData['source'] ?? 'ai_generated',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print(
        'Saved AI exercise to database: ${exerciseData['name']} (ID: ${docRef.id})',
      );
      return docRef.id;
    } catch (e) {
      print('Error saving AI exercise to database: $e');
      rethrow;
    }
  }

  /// Get exercises by category
  static Stream<QuerySnapshot> getExercisesByCategory(String category) {
    return exercises
        .where('category', isEqualTo: category)
        .where('isPublic', isEqualTo: true)
        .orderBy('name')
        .snapshots();
  }

  /// Search exercises
  static Stream<QuerySnapshot> searchExercises(String searchTerm) {
    return exercises
        .where('name', isGreaterThanOrEqualTo: searchTerm)
        .where('name', isLessThanOrEqualTo: '$searchTerm\uf8ff')
        .where('isPublic', isEqualTo: true)
        .snapshots();
  }

  // ==================== WORKOUT SESSIONS ====================

  /// Record completed workout session
  static Future<String> recordWorkoutSession({
    required String userId,
    required String workoutId,
    required int duration, // in seconds
    required List<Map<String, dynamic>> completedExercises,
    String? notes,
  }) async {
    final docRef = await workoutSessions.add({
      'userId': userId,
      'workoutId': workoutId,
      'duration': duration,
      'completedExercises': completedExercises,
      'notes': notes,
      'completedAt': FieldValue.serverTimestamp(),
    });

    // Update user progress
    await _updateUserProgress(userId, duration);

    return docRef.id;
  }

  /// Get user's workout history
  static Stream<QuerySnapshot> getUserWorkoutHistory(String userId) {
    // Temporary fix: Remove orderBy to avoid index requirement
    // We'll sort on the client side instead
    return workoutSessions.where('userId', isEqualTo: userId).snapshots();
  }

  /// Get workout session details
  static Future<DocumentSnapshot> getWorkoutSession(String sessionId) async {
    return await workoutSessions.doc(sessionId).get();
  }

  // ==================== USER PROGRESS ====================

  /// Update user progress statistics
  static Future<void> _updateUserProgress(
    String userId,
    int sessionDuration,
  ) async {
    final progressDoc = userProgress.doc(userId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(progressDoc);

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        transaction.update(progressDoc, {
          'totalWorkouts': (data['totalWorkouts'] ?? 0) + 1,
          'totalDuration': (data['totalDuration'] ?? 0) + sessionDuration,
          'lastWorkout': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        transaction.set(progressDoc, {
          'totalWorkouts': 1,
          'totalDuration': sessionDuration,
          'lastWorkout': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Get user progress
  static Future<DocumentSnapshot> getUserProgress(String userId) async {
    return await userProgress.doc(userId).get();
  }

  /// Get user statistics
  static Stream<DocumentSnapshot> getUserProgressStream(String userId) {
    return userProgress.doc(userId).snapshots();
  }

  // ==================== UTILITY METHODS ====================

  /// Get workout with exercises populated
  static Future<Map<String, dynamic>?> getWorkoutWithExercises(
    String workoutId,
  ) async {
    final workoutDoc = await workouts.doc(workoutId).get();

    if (!workoutDoc.exists) return null;

    final workoutData = workoutDoc.data() as Map<String, dynamic>;
    final exerciseIds = (workoutData['exercises'] as List)
        .map((e) => e['exerciseId'] as String)
        .toList();

    // Fetch exercise details
    final exerciseDetails = <Map<String, dynamic>>[];
    for (final exerciseId in exerciseIds) {
      final exerciseDoc = await exercises.doc(exerciseId).get();
      if (exerciseDoc.exists) {
        exerciseDetails.add({
          'id': exerciseId,
          ...exerciseDoc.data() as Map<String, dynamic>,
        });
      }
    }

    return {
      'id': workoutId,
      ...workoutData,
      'exerciseDetails': exerciseDetails,
    };
  }

  /// Batch operations for better performance
  static WriteBatch getBatch() => _firestore.batch();

  /// Execute batch operations
  static Future<void> commitBatch(WriteBatch batch) => batch.commit();

  /// Test Firebase connection
  static Future<bool> testConnection() async {
    try {
      await _firestore.collection('test').add({
        'timestamp': FieldValue.serverTimestamp(),
        'message': 'Connection test successful from Flutter app',
      });
      print('✅ Firebase Firestore connected successfully!');
      return true;
    } catch (e) {
      print('❌ Firebase connection failed: $e');
      return false;
    }
  }

  /// Initialize sample data for testing
  static Future<void> initializeSampleData() async {
    try {
      // Check if exercises already exist
      final exercisesSnapshot = await exercises.limit(1).get();

      if (exercisesSnapshot.docs.isEmpty) {
        print('📝 Adding sample exercises to database...');

        // Add sample exercises
        final sampleExercises = [
          {
            'name': 'Push-ups',
            'description':
                'A basic upper body exercise targeting chest, shoulders, and triceps',
            'muscleGroups': ['Chest', 'Shoulders', 'Triceps'],
            'equipment': 'None',
            'difficulty': 'Beginner',
            'instructions': [
              'Start in a plank position with hands slightly wider than shoulders',
              'Lower your body until chest nearly touches the floor',
              'Push back up to starting position',
              'Keep your body in a straight line throughout',
            ],
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Squats',
            'description':
                'A fundamental lower body exercise targeting legs and glutes',
            'muscleGroups': ['Quadriceps', 'Glutes', 'Hamstrings'],
            'equipment': 'None',
            'difficulty': 'Beginner',
            'instructions': [
              'Stand with feet shoulder-width apart',
              'Lower your body as if sitting back into a chair',
              'Keep your chest up and knees behind toes',
              'Return to starting position',
            ],
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Plank',
            'description': 'Core strengthening exercise',
            'muscleGroups': ['Core', 'Shoulders'],
            'equipment': 'None',
            'difficulty': 'Beginner',
            'instructions': [
              'Start in a push-up position',
              'Lower to forearms',
              'Keep body in straight line',
              'Hold position',
            ],
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Burpees',
            'description':
                'Full body exercise combining squat, plank, and jump',
            'muscleGroups': ['Full Body'],
            'equipment': 'None',
            'difficulty': 'Advanced',
            'instructions': [
              'Start standing',
              'Squat down and place hands on floor',
              'Jump feet back to plank',
              'Do a push-up',
              'Jump feet back to squat',
              'Jump up with arms overhead',
            ],
            'createdAt': FieldValue.serverTimestamp(),
          },
        ];

        final batch = _firestore.batch();
        for (final exercise in sampleExercises) {
          final docRef = exercises.doc();
          batch.set(docRef, exercise);
        }
        await batch.commit();

        print('✅ Sample exercises added successfully!');
      } else {
        print('✅ Exercise library already has data');
      }
    } catch (e) {
      print('❌ Failed to initialize sample data: $e');
    }
  }
}
