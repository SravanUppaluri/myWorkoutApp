import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../controllers/workout_generation_controller.dart';
import '../services/template_management_service.dart';
import '../services/workout_preferences_service.dart';
import '../widgets/ai_workout/header_card.dart';
import '../widgets/ai_workout/mode_selector.dart';
import '../widgets/ai_workout/quick_generation_widget.dart';
import '../widgets/ai_workout/template_generation_widget.dart';

/// Refactored AI Workout Screen with improved architecture
/// Separated into multiple services and widgets for better maintainability
class AIWorkoutScreen extends StatefulWidget {
  const AIWorkoutScreen({super.key});

  @override
  State<AIWorkoutScreen> createState() => _AIWorkoutScreenState();
}

class _AIWorkoutScreenState extends State<AIWorkoutScreen> {
  // Controllers and Services
  late final WorkoutGenerationController _generationController;
  late final TemplateManagementService _templateService;
  late final WorkoutPreferencesService _preferencesService;

  // State
  String _selectedMode = 'quick'; // quick, template, favorites

  @override
  void initState() {
    super.initState();

    // Initialize controllers and services
    _generationController = WorkoutGenerationController();
    _templateService = TemplateManagementService();
    _preferencesService = WorkoutPreferencesService();

    // Load initial data
    _loadInitialData();
  }

  @override
  void dispose() {
    _generationController.dispose();
    _templateService.dispose();
    _preferencesService.dispose();
    super.dispose();
  }

  /// Load initial data for the screen
  Future<void> _loadInitialData() async {
    await Future.wait([
      _preferencesService.loadUserPreferences(),
      _templateService.loadTemplates(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _generationController),
        ChangeNotifierProvider.value(value: _templateService),
        ChangeNotifierProvider.value(value: _preferencesService),
      ],
      child: Scaffold(
        backgroundColor: isDarkMode
            ? AppColors.darkBackground
            : AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // Header Card
              const AIWorkoutHeaderCard(),

              // Mode Selector
              WorkoutModeSelector(
                selectedMode: _selectedMode,
                onModeChanged: (mode) {
                  setState(() {
                    _selectedMode = mode;
                  });
                },
              ),

              // Main Content
              Expanded(child: _buildMainContent()),
            ],
          ),
        ),
      ),
    );
  }

  /// Build main content based on selected mode
  Widget _buildMainContent() {
    switch (_selectedMode) {
      case 'quick':
        return QuickGenerationWidget(
          onWorkoutGenerated: () => _handleWorkoutGenerated(),
        );
      case 'template':
        return TemplateGenerationWidget(
          onWorkoutGenerated: () => _handleWorkoutGenerated(),
        );
      case 'favorites':
        return TemplateGenerationWidget(
          onWorkoutGenerated: () => _handleWorkoutGenerated(),
        );
      default:
        return QuickGenerationWidget(
          onWorkoutGenerated: () => _handleWorkoutGenerated(),
        );
    }
  }

  /// Handle when a workout is generated
  void _handleWorkoutGenerated() {
    // Workout generation handled by widgets themselves
    debugPrint('Workout generated successfully');
  }

  // Workout preview dialog removed for simplicity
}
