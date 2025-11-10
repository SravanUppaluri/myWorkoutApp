import 'package:flutter/material.dart';

class AppColors {
  // Light Theme Colors
  static const Color primary = Color(0xFF6200EE);
  static const Color primaryVariant = Color(0xFF3700B3);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color secondaryVariant = Color(0xFF018786);

  // Light Background Colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFB00020);

  // Light Text Colors
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFF000000);
  static const Color onBackground = Color(0xFF000000);
  static const Color onSurface = Color(0xFF000000);
  static const Color onError = Color(0xFFFFFFFF);

  // Dark Theme Colors (Updated for better visibility)
  static const Color darkPrimary = Color(0xFF9C88FF); // Brighter purple
  static const Color darkPrimaryVariant = Color(0xFF7C4DFF);
  static const Color darkSecondary = Color(0xFF4FDDC6); // Brighter teal
  static const Color darkSecondaryVariant = Color(0xFF1DE9B6);

  // Dark Background Colors (Lighter for better contrast)
  static const Color darkBackground = Color(
    0xFF1A1A1A,
  ); // Lighter than pure black
  static const Color darkSurface = Color(0xFF2D2D2D); // Much lighter surface
  static const Color darkError = Color(0xFFFF6B6B);

  // Dark Text Colors (Better contrast)
  static const Color darkOnPrimary = Color(0xFF000000);
  static const Color darkOnSecondary = Color(0xFF000000);
  static const Color darkOnBackground = Color(0xFFE0E0E0); // Lighter text
  static const Color darkOnSurface = Color(0xFFE0E0E0); // Lighter text
  static const Color darkOnError = Color(0xFF000000);

  // Custom Colors for Workout App (Updated for dark mode)
  static const Color cardinalRed = Color(0xFFFF5252); // Brighter red
  static const Color forestGreen = Color(0xFF66BB6A); // Brighter green
  static const Color steelBlue = Color(0xFF42A5F5); // Brighter blue
  static const Color orange = Color(0xFFFF9800); // Orange for calories
  static const Color purple = Color(0xFF9C27B0); // Purple for week stats
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color darkGray = Color(0xFF757575); // Lighter gray
  static const Color success = Color(0xFF4CAF50); // Success green

  // Additional Dark Mode Colors (Much improved)
  static const Color darkLightGray = Color(
    0xFF404040,
  ); // Lighter gray for dark mode
  static const Color darkCard = Color(
    0xFF2D2D2D,
  ); // Same as surface for consistency
}

class AppStrings {
  // App Info
  static const String appName = 'Workout Tracker';
  static const String appVersion = '1.0.0';

  // Navigation
  static const String home = 'Home';
  static const String workouts = 'Workouts';
  static const String exercises = 'Exercises';
  static const String profile = 'Profile';
  static const String settings = 'Settings';

  // Authentication
  static const String signIn = 'Sign In';
  static const String signUp = 'Sign Up';
  static const String signOut = 'Sign Out';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String forgotPassword = 'Forgot Password?';

  // Workout Related
  static const String createWorkout = 'Create Workout';
  static const String startWorkout = 'Start Workout';
  static const String finishWorkout = 'Finish Workout';
  static const String noWorkouts = 'No workouts found';
  static const String addExercise = 'Add Exercise';

  // Common
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String loading = 'Loading...';
  static const String error = 'Error occurred';
}

class AppTextStyles {
  static const TextStyle headline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.onBackground,
  );

  static const TextStyle headline2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.onBackground,
  );

  static const TextStyle headline3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.onBackground,
  );

  static const TextStyle bodyText1 = TextStyle(
    fontSize: 16,
    color: AppColors.onBackground,
  );

  static const TextStyle bodyText2 = TextStyle(
    fontSize: 14,
    color: AppColors.onBackground,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.darkGray,
  );
}

class AppDimensions {
  // Padding
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  // Margins
  static const double marginSmall = 8.0;
  static const double marginMedium = 16.0;
  static const double marginLarge = 24.0;
  static const double marginXLarge = 48.0;

  // Border Radius
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 16.0;

  // Icon Sizes
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
}
