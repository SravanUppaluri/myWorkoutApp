import 'package:flutter/material.dart';
import '../screens/workouts_screen.dart';
import '../screens/exercise_selection_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/auth_wrapper.dart';

class AppRoutes {
  static const String home = '/';
  static const String workouts = '/workouts';
  static const String exercises = '/exercises';
  static const String profile = '/profile';
  static const String createWorkout = '/create-workout';
  static const String workoutDetails = '/workout-details';
  static const String exerciseDetails = '/exercise-details';
  static const String settings = '/settings';
  static const String login = '/login';
  static const String signup = '/signup';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(
          builder: (context) => const AuthWrapper(),
          settings: settings,
        );

      case login:
        return MaterialPageRoute(
          builder: (context) => const LoginScreen(),
          settings: settings,
        );

      case signup:
        return MaterialPageRoute(
          builder: (context) => const SignUpScreen(),
          settings: settings,
        );

      case workouts:
        return MaterialPageRoute(
          builder: (context) => const WorkoutsScreen(),
          settings: settings,
        );

      case exercises:
        return MaterialPageRoute(
          builder: (context) => const ExerciseSelectionScreen(),
          settings: settings,
        );

      case profile:
        return MaterialPageRoute(
          builder: (context) => const ProfileScreen(),
          settings: settings,
        );

      // Add more routes as needed
      default:
        return MaterialPageRoute(
          builder: (context) => const NotFoundScreen(),
          settings: settings,
        );
    }
  }
}

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '404 - Page Not Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'The page you are looking for does not exist.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
