import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart' as app_user;

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Convert Firebase User to our app User model
  app_user.User? _userFromFirebaseUser(User? user) {
    if (user == null) return null;
    return app_user.User(
      id: user.uid,
      displayName: user.displayName ?? 'User',
      email: user.email ?? '',
      photoUrl: user.photoURL,
      createdAt: DateTime.now(), // Will be updated from Firestore if available
    );
  }

  // Get user document from Firestore
  Future<app_user.User?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return app_user.User(
          id: uid,
          displayName: data['displayName'] ?? 'User',
          email: data['email'] ?? '',
          photoUrl: data['photoUrl'],
          age: data['age'] ?? 0,
          weight: data['weight']?.toDouble() ?? 0.0,
          height: data['height']?.toDouble() ?? 0.0,
          fitnessLevel: data['fitnessLevel'] ?? 'Beginner',
          goals: List<String>.from(data['goals'] ?? []),
          createdAt: data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
          hasCompletedOnboarding: data['hasCompletedOnboarding'] ?? false,
          goalData: data['goalData'] != null
              ? Map<String, dynamic>.from(data['goalData'])
              : null,
          motivation: data['motivation'],
        );
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(User user, String displayName) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'displayName': displayName,
        'email': user.email,
        'photoUrl': user.photoURL,
        'age': 0,
        'weight': 0.0,
        'height': 0.0,
        'fitnessLevel': 'Beginner',
        'goals': [],
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating user document: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<app_user.User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential result = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last login time
      if (result.user != null) {
        await _firestore.collection('users').doc(result.user!.uid).update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
      }

      return _userFromFirebaseUser(result.user);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw 'No user found with this email address.';
        case 'wrong-password':
          throw 'Incorrect password.';
        case 'invalid-email':
          throw 'Invalid email address.';
        case 'user-disabled':
          throw 'This user account has been disabled.';
        case 'too-many-requests':
          throw 'Too many failed login attempts. Please try again later.';
        default:
          throw 'Login failed. Please try again.';
      }
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Register with email and password
  Future<app_user.User?> registerWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      UserCredential result = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (result.user != null) {
        // Update display name
        await result.user!.updateDisplayName(displayName);

        // Create user document in Firestore
        await _createUserDocument(result.user!, displayName);

        return _userFromFirebaseUser(result.user);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          throw 'The password provided is too weak.';
        case 'email-already-in-use':
          throw 'An account already exists with this email address.';
        case 'invalid-email':
          throw 'Invalid email address.';
        case 'operation-not-allowed':
          throw 'Email/password accounts are not enabled.';
        default:
          throw 'Registration failed. Please try again.';
      }
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      throw 'Failed to sign out. Please try again.';
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw 'No user found with this email address.';
        case 'invalid-email':
          throw 'Invalid email address.';
        default:
          throw 'Failed to send password reset email. Please try again.';
      }
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user != null) {
        if (displayName != null) {
          await user.updateDisplayName(displayName);
        }
        if (photoURL != null) {
          await user.updatePhotoURL(photoURL);
        }

        // Update Firestore document
        Map<String, dynamic> updates = {};
        if (displayName != null) updates['displayName'] = displayName;
        if (photoURL != null) updates['photoUrl'] = photoURL;

        if (updates.isNotEmpty) {
          await _firestore.collection('users').doc(user.uid).update(updates);
        }
      }
    } catch (e) {
      print('Error updating profile: $e');
      throw 'Failed to update profile. Please try again.';
    }
  }

  // Update complete user data in Firestore
  Future<void> updateUserData(app_user.User user) async {
    try {
      await _firestore.collection('users').doc(user.id).update({
        'displayName': user.displayName,
        'age': user.age,
        'weight': user.weight,
        'height': user.height,
        'fitnessLevel': user.fitnessLevel,
        'goals': user.goals,
        'hasCompletedOnboarding': user.hasCompletedOnboarding,
        'goalData': user.goalData,
        'motivation': user.motivation,
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating user data: $e');
      throw 'Failed to update user data. Please try again.';
    }
  }

  // Migrate existing user data to include new fields
  Future<void> migrateUserData(String userId) async {
    try {
      DocumentReference userDoc = _firestore.collection('users').doc(userId);
      DocumentSnapshot snapshot = await userDoc.get();

      if (snapshot.exists) {
        Map<String, dynamic> userData = snapshot.data() as Map<String, dynamic>;

        // Check if new fields are missing and add them with default values
        Map<String, dynamic> updates = {};

        if (!userData.containsKey('hasCompletedOnboarding')) {
          updates['hasCompletedOnboarding'] = userData['goalData'] != null;
        }

        if (!userData.containsKey('goalData')) {
          updates['goalData'] = null;
        }

        if (!userData.containsKey('motivation')) {
          updates['motivation'] = null;
        }

        // Only update if there are missing fields
        if (updates.isNotEmpty) {
          updates['lastUpdatedAt'] = FieldValue.serverTimestamp();
          await userDoc.update(updates);
          print('User data migrated successfully for user: $userId');
        }
      }
    } catch (e) {
      print('Error migrating user data: $e');
      // Don't throw here as this is a background migration
    }
  }

  // Delete user account
  Future<void> deleteAccount() async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user != null) {
        // Delete user document from Firestore
        await _firestore.collection('users').doc(user.uid).delete();

        // Delete Firebase Auth user
        await user.delete();
      }
    } catch (e) {
      print('Error deleting account: $e');
      throw 'Failed to delete account. Please try again.';
    }
  }

  // Check if email exists
  Future<bool> checkEmailExists(String email) async {
    try {
      List<String> methods = await _firebaseAuth.fetchSignInMethodsForEmail(
        email,
      );
      return methods.isNotEmpty;
    } catch (e) {
      print('Error checking email: $e');
      return false;
    }
  }
}
