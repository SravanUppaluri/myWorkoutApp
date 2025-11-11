import 'package:flutter/material.dart';
import 'dart:async';
import '../models/user.dart';
import '../services/auth_service.dart';
import 'package:logger/logger.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;
  StreamSubscription? _authSubscription;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  final logger = Logger();

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    _setStatus(AuthStatus.loading);

    // Listen to auth state changes
    _authSubscription = _authService.authStateChanges.listen((
      firebaseUser,
    ) async {
      if (firebaseUser != null) {
        // User is signed in, get complete user data from Firestore
        try {
          // Migrate user data to include new fields if needed
          await _authService.migrateUserData(firebaseUser.uid);

          User? appUser = await _authService.getUserData(firebaseUser.uid);
          if (appUser != null) {
            _user = appUser;
            _setStatus(AuthStatus.authenticated);
          } else {
            // Fallback to Firebase user data if Firestore data not available
            _user = User(
              id: firebaseUser.uid,
              displayName: firebaseUser.displayName ?? 'User',
              email: firebaseUser.email ?? '',
              photoUrl: firebaseUser.photoURL,
              createdAt: DateTime.now(),
            );
            _setStatus(AuthStatus.authenticated);
          }
        } catch (e) {
          logger.e('Error getting user data: $e');
          _setStatus(AuthStatus.unauthenticated);
        }
      } else {
        // User is signed out
        _user = null;
        _setStatus(AuthStatus.unauthenticated);
      }
    });
  }

  // Login with email and password
  Future<void> login(String email, String password) async {
    _setStatus(AuthStatus.loading);
    _errorMessage = null;

    try {
      User? user = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );
      if (user != null) {
        logger.e('Login successful, user: ${user.email}');

        // Migrate user data to include new fields if needed
        await _authService.migrateUserData(user.id);

        // Get complete user data from Firestore
        User? appUser = await _authService.getUserData(user.id);
        if (appUser != null) {
          _user = appUser;
        } else {
          _user = user; // Fallback to basic user data
        }
        _setStatus(AuthStatus.authenticated);
        logger.e('Auth status set to authenticated');
      }
    } catch (e) {
      logger.e('Login error: $e');
      _errorMessage = e.toString();
      _setStatus(AuthStatus.unauthenticated);
      rethrow;
    }
  }

  // Register with email and password
  Future<void> register(
    String displayName,
    String email,
    String password,
  ) async {
    _setStatus(AuthStatus.loading);
    _errorMessage = null;

    try {
      User? user = await _authService.registerWithEmailAndPassword(
        email,
        password,
        displayName,
      );
      if (user != null) {
        logger.e('Registration successful, user: ${user.email}');
        // Get complete user data from Firestore
        User? appUser = await _authService.getUserData(user.id);
        if (appUser != null) {
          _user = appUser;
        } else {
          _user = user; // Fallback to basic user data
        }
        _setStatus(AuthStatus.authenticated);
        logger.e('Auth status set to authenticated after registration');
      }
    } catch (e) {
      logger.e('Registration error: $e');
      _errorMessage = e.toString();
      _setStatus(AuthStatus.unauthenticated);
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    _setStatus(AuthStatus.loading);

    try {
      await _authService.signOut();
      // The auth state listener will handle clearing the user and setting status
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Logout error: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _authService.resetPassword(email);
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      await _authService.updateUserProfile(
        displayName: displayName,
        photoURL: photoURL,
      );

      // Refresh user data
      if (_user != null) {
        User? updatedUser = await _authService.getUserData(_user!.id);
        if (updatedUser != null) {
          _user = updatedUser;
          notifyListeners();
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    }
  }

  // Update complete user profile with all fields
  Future<void> updateUserProfile(User updatedUser) async {
    try {
      await _authService.updateUserData(updatedUser);
      _user = updatedUser;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      await _authService.deleteAccount();
      // The auth state listener will handle clearing the user and setting status
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    }
  }

  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
