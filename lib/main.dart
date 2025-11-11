import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth/auth_wrapper.dart';
import 'utils/constants.dart';
import 'utils/routes.dart';
import 'utils/theme_manager.dart';
import 'providers/auth_provider.dart';
import 'providers/workout_provider.dart';
import 'services/database_service.dart';
import 'package:logger/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final logger = Logger();

  // Initialize Firebase with platform-specific options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize sample data for testing
    await DatabaseService.initializeSampleData();
  } catch (e) {
    logger.e('Firebase initialization error: $e');
    // For now, continue without Firebase to test the app structure
  }

  // Initialize theme manager
  final themeManager = ThemeManager();
  await themeManager.initializeTheme();

  runApp(WorkoutApp(themeManager: themeManager));
}

class WorkoutApp extends StatelessWidget {
  final ThemeManager themeManager;

  const WorkoutApp({super.key, required this.themeManager});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeManager>.value(value: themeManager),
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<WorkoutProvider>(
          create: (_) => WorkoutProvider(),
        ),
      ],
      child: Consumer<ThemeManager>(
        builder: (context, themeManager, child) {
          return MaterialApp(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: ThemeManager.lightTheme,
            darkTheme: ThemeManager.darkTheme,
            themeMode: themeManager.themeMode,
            initialRoute: AppRoutes.home,
            onGenerateRoute: AppRoutes.generateRoute,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}
