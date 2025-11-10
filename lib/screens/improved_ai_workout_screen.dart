import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../models/workout_template.dart';
import '../providers/workout_provider.dart';
import '../providers/auth_provider.dart';
import '../services/ai_workout_service.dart';
import '../services/template_ui_service.dart';
import 'workout_session_screen.dart';
import 'workout_detail_screen.dart';

class ImprovedAIWorkoutScreen extends StatefulWidget {
  const ImprovedAIWorkoutScreen({super.key});

  @override
  State<ImprovedAIWorkoutScreen> createState() =>
      _ImprovedAIWorkoutScreenState();
}

class _ImprovedAIWorkoutScreenState extends State<ImprovedAIWorkoutScreen> {
  bool _isGenerating = false;
  String _selectedMode = 'quick'; // quick, template, favorites

  // Template service instance
  final TemplateUIService _templateService = TemplateUIService();

  // Perfect Workout Generation options
  int _selectedDuration = 45; // Default duration
  final TextEditingController _keywordController = TextEditingController();
  final List<int> _durationOptions = [30, 45, 60];
  final List<String> _quickKeywords = [
    'Lower Back',
    'Core',
    'Chest',
    'Arms',
    'Legs',
    'Upper Body',
  ];

  @override
  void initState() {
    super.initState();
    _initializeTemplateService();
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  /// Initialize template service with data
  Future<void> _initializeTemplateService() async {
    await _templateService.loadTemplates(context, _selectedDuration);
    await _templateService.loadAIPreference();
    setState(() {});
  }

  /// Callback for when template state changes
  void _onTemplateStateChanged() {
    setState(() {});
  }

  /// Generate workout from template
  void _generateFromTemplate() {
    final selectedTemplate = _templateService.selectedTemplate;
    final selectedCategory = _templateService.selectedTemplateCategory;

    if (selectedTemplate != null) {
      // Generate from specific template
      _templateService.generateFromTemplate(
        context,
        selectedTemplate,
        (bool isGenerating) => setState(() => _isGenerating = isGenerating),
        _showErrorSnackBar,
      );
    } else if (selectedCategory != null &&
        _templateService.isWorkoutSplit(selectedCategory.name)) {
      // Create a default template for workout split generation
      final defaultTemplate = WorkoutTemplate(
        id: 'split_${selectedCategory.name}_${DateTime.now().millisecondsSinceEpoch}',
        name: selectedCategory.displayName,
        description: selectedCategory.description,
        category: selectedCategory.name,
        params: {
          'workoutType': selectedCategory.name,
          'duration': 60,
          'muscleGroups': ['Full Body'],
        },
        createdAt: DateTime.now(),
      );

      _templateService.generateFromTemplate(
        context,
        defaultTemplate,
        (bool isGenerating) => setState(() => _isGenerating = isGenerating),
        _showErrorSnackBar,
      );
    } else {
      _showErrorSnackBar('Please select a template or workout split first');
    }
  }

  /// Show error snack bar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('AI Workout Generator'),
          ],
        ),
        backgroundColor: isDarkMode ? AppColors.darkSurface : null,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isGenerating)
            LinearProgressIndicator(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),

          // Mode selector
          Container(
            color: isDarkMode ? AppColors.darkSurface : AppColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              child: _buildModeSelector(),
            ),
          ),

          Expanded(child: _buildModeContent()),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildModeButton(
            mode: 'quick',
            icon: Icons.flash_on,
            label: 'Quick Workout',
          ),
        ),
        const SizedBox(width: AppDimensions.marginSmall),
        Expanded(
          child: _buildModeButton(
            mode: 'template',
            icon: Icons.fitness_center,
            label: 'Template Mode',
          ),
        ),
        const SizedBox(width: AppDimensions.marginSmall),
        Expanded(
          child: _buildModeButton(
            mode: 'favorites',
            icon: Icons.favorite,
            label: 'Favorites',
          ),
        ),
      ],
    );
  }

  Widget _buildModeButton({
    required String mode,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedMode == mode;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMode = mode;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.paddingSmall,
          horizontal: AppDimensions.paddingMedium,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDarkMode
                    ? AppColors.darkBackground.withValues(alpha: 0.5)
                    : AppColors.background.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : (isDarkMode
                        ? AppColors.darkOnSurface
                        : AppColors.onSurface),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected
                    ? Colors.white
                    : (isDarkMode
                          ? AppColors.darkOnSurface
                          : AppColors.onSurface),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeContent() {
    switch (_selectedMode) {
      case 'quick':
        return _buildQuickGeneration();
      case 'template':
        return _buildTemplateGeneration();
      case 'favorites':
        return _buildFavoritesMode();
      default:
        return _buildQuickGeneration();
    }
  }

  Widget _buildQuickGeneration() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Quick AI Workout',
            style: AppTextStyles.headline2.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkOnSurface
                  : AppColors.onSurface,
            ),
          ),
          const SizedBox(height: AppDimensions.marginSmall),
          Text(
            'Generate a personalized workout in seconds. Just select your preferences and let AI create the perfect workout for you.',
            style: AppTextStyles.bodyText2.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkOnSurface.withValues(alpha: 0.8)
                  : AppColors.onSurface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppDimensions.marginLarge),

          // Duration selector
          _buildDurationSelector(),
          const SizedBox(height: AppDimensions.marginLarge),

          // Keyword input
          _buildKeywordInput(),
          const SizedBox(height: AppDimensions.marginLarge),

          // Quick keywords
          _buildQuickKeywords(),
          const SizedBox(height: AppDimensions.marginLarge),

          // Generate button
          _buildOneClickButton(),
        ],
      ),
    );
  }

  Widget _buildTemplateGeneration() {
    return _templateService.buildTemplateGeneration(
      context,
      _onTemplateStateChanged,
      onGenerate: _generateFromTemplate,
    );
  }

  Widget _buildFavoritesMode() {
    return const Center(child: Text('Favorites mode - Coming soon!'));
  }

  Widget _buildDurationSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Workout Duration',
              style: AppTextStyles.headline3.copyWith(
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: AppDimensions.marginMedium),
            Row(
              children: _durationOptions.map((duration) {
                final isSelected = _selectedDuration == duration;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDuration = duration;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusSmall,
                          ),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '$duration min',
                          style: AppTextStyles.bodyText1.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeywordInput() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Focus Area (Optional)',
              style: AppTextStyles.headline3.copyWith(
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: AppDimensions.marginMedium),
            TextField(
              controller: _keywordController,
              decoration: InputDecoration(
                hintText: 'e.g., Lower Back, Core, Chest...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusSmall,
                  ),
                ),
                prefixIcon: Icon(Icons.search, color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickKeywords() {
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Focus Areas',
                style: AppTextStyles.headline3.copyWith(
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: AppDimensions.marginMedium),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickKeywords.map((keyword) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _keywordController.text = keyword;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingMedium,
                        vertical: AppDimensions.paddingSmall,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMedium,
                        ),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        keyword,
                        style: AppTextStyles.bodyText2.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOneClickButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isGenerating ? null : _generateOneClickWorkout,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.paddingMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
        ),
        child: _isGenerating
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.marginMedium),
                  Text(
                    'Generating...',
                    style: AppTextStyles.bodyText1.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white),
                  const SizedBox(width: AppDimensions.marginSmall),
                  Text(
                    'Generate Quick Workout',
                    style: AppTextStyles.bodyText1.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _generateOneClickWorkout() async {
    setState(() => _isGenerating = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.user;

      if (currentUser == null) {
        throw Exception('Please log in to generate workouts');
      }

      // Create workout request
      final focusArea = _keywordController.text.trim();
      final workoutRequest = {
        'userId': currentUser.id,
        'fitnessLevel': currentUser.fitnessLevel,
        'duration': _selectedDuration,
        'focusArea': focusArea,
        'primaryMuscles': [focusArea], // Add primary muscles array
        'goal': focusArea.isNotEmpty
            ? '${focusArea}-focused workout'
            : 'General fitness workout',
        'workoutType': focusArea.isNotEmpty
            ? '${focusArea} Training'
            : 'General Fitness',
        'equipment': ['all equipment'], // Default equipment
        'sessionId': 'quick_${DateTime.now().millisecondsSinceEpoch}',
        'useAI': _templateService.useAIGeneration,
        'instructions': focusArea.isNotEmpty
            ? 'Focus on $focusArea exercises and movements. Ensure most exercises target the $focusArea muscle group.'
            : 'Create a balanced full-body workout.',
      };

      late Workout workout;

      // Debug: Print the workout request details
      print('🎯 WORKOUT REQUEST DEBUG:');
      print('Focus Area: ${workoutRequest['focusArea']}');
      print('Primary Muscles: ${workoutRequest['primaryMuscles']}');
      print('Goal: ${workoutRequest['goal']}');
      print('Instructions: ${workoutRequest['instructions']}');
      print('Full Request: $workoutRequest');

      if (_templateService.useAIGeneration) {
        print('🤖 Using AI generation...');
        // Generate with AI
        final aiService = AIWorkoutService();
        workout = await aiService.generateWorkout(workoutRequest) as Workout;

        // Debug: Check the generated workout
        print('🏋️ AI GENERATED WORKOUT:');
        print('Name: ${workout.name}');
        print('Description: ${workout.description}');
        print('Exercises:');
        for (int i = 0; i < workout.exercises.length; i++) {
          final exercise = workout.exercises[i];
          print(
            '  ${i + 1}. ${exercise.exercise.name} - ${exercise.exercise.primaryMuscles.join(", ")}',
          );
        }
      } else {
        print('🎭 Using mock generation...');
        // Create simple mock workout
        workout = _createMockQuickWorkout(
          _selectedDuration,
          _keywordController.text.trim(),
        );
      }

      // Show workout preview popup instead of directly starting
      if (context.mounted) {
        _showWorkoutPreviewDialog(workout, currentUser);
      }
    } catch (e) {
      _showErrorSnackBar('Error generating workout: $e');
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Workout _createMockQuickWorkout(int duration, String focusArea) {
    final exercises = <WorkoutExercise>[];
    final exerciseCount = (duration / 10).round().clamp(3, 8);

    // Create specific exercises based on focus area
    List<Map<String, String>> exerciseTemplates = [];

    if (focusArea.toLowerCase() == 'arms') {
      exerciseTemplates = [
        {'name': 'Push-ups', 'muscle': 'Arms', 'type': 'Push'},
        {'name': 'Tricep Dips', 'muscle': 'Triceps', 'type': 'Push'},
        {'name': 'Bicep Curls', 'muscle': 'Biceps', 'type': 'Pull'},
        {'name': 'Overhead Press', 'muscle': 'Shoulders', 'type': 'Push'},
        {'name': 'Hammer Curls', 'muscle': 'Forearms', 'type': 'Pull'},
        {'name': 'Close-Grip Push-ups', 'muscle': 'Triceps', 'type': 'Push'},
        {'name': 'Lateral Raises', 'muscle': 'Shoulders', 'type': 'Pull'},
        {'name': 'Diamond Push-ups', 'muscle': 'Triceps', 'type': 'Push'},
      ];
    } else if (focusArea.toLowerCase() == 'chest') {
      exerciseTemplates = [
        {'name': 'Push-ups', 'muscle': 'Chest', 'type': 'Push'},
        {'name': 'Chest Press', 'muscle': 'Chest', 'type': 'Push'},
        {'name': 'Chest Flyes', 'muscle': 'Chest', 'type': 'Push'},
        {'name': 'Incline Push-ups', 'muscle': 'Upper Chest', 'type': 'Push'},
        {'name': 'Decline Push-ups', 'muscle': 'Lower Chest', 'type': 'Push'},
        {'name': 'Wide-Grip Push-ups', 'muscle': 'Chest', 'type': 'Push'},
      ];
    } else if (focusArea.toLowerCase() == 'legs') {
      exerciseTemplates = [
        {'name': 'Squats', 'muscle': 'Quadriceps', 'type': 'Push'},
        {'name': 'Lunges', 'muscle': 'Quadriceps', 'type': 'Push'},
        {'name': 'Calf Raises', 'muscle': 'Calves', 'type': 'Push'},
        {'name': 'Romanian Deadlifts', 'muscle': 'Hamstrings', 'type': 'Pull'},
        {'name': 'Wall Sit', 'muscle': 'Quadriceps', 'type': 'Hold'},
        {'name': 'Single-Leg Glute Bridge', 'muscle': 'Glutes', 'type': 'Push'},
      ];
    } else if (focusArea.toLowerCase() == 'core') {
      exerciseTemplates = [
        {'name': 'Plank', 'muscle': 'Core', 'type': 'Hold'},
        {'name': 'Crunches', 'muscle': 'Abs', 'type': 'Pull'},
        {'name': 'Russian Twists', 'muscle': 'Obliques', 'type': 'Rotation'},
        {'name': 'Mountain Climbers', 'muscle': 'Core', 'type': 'Dynamic'},
        {'name': 'Dead Bug', 'muscle': 'Deep Core', 'type': 'Hold'},
        {'name': 'Bird Dog', 'muscle': 'Core Stability', 'type': 'Hold'},
      ];
    } else {
      // Default mixed workout
      exerciseTemplates = [
        {'name': 'Push-ups', 'muscle': 'Chest', 'type': 'Push'},
        {'name': 'Squats', 'muscle': 'Legs', 'type': 'Push'},
        {'name': 'Plank', 'muscle': 'Core', 'type': 'Hold'},
        {'name': 'Lunges', 'muscle': 'Legs', 'type': 'Push'},
        {'name': 'Tricep Dips', 'muscle': 'Arms', 'type': 'Push'},
        {'name': 'Crunches', 'muscle': 'Abs', 'type': 'Pull'},
      ];
    }

    for (int i = 0; i < exerciseCount; i++) {
      final template = exerciseTemplates[i % exerciseTemplates.length];
      exercises.add(
        WorkoutExercise(
          exercise: Exercise(
            id: 'mock_quick_${i}',
            name: template['name']!,
            category: template['muscle']!.toLowerCase(),
            primaryMuscles: [template['muscle']!],
            secondaryMuscles: [],
            equipment: ['Bodyweight'],
            targetRegion: [template['muscle']!],
            difficulty: 'Intermediate',
            movementType: 'Strength',
            movementPattern: template['type']!,
            gripType: 'Standard',
            rangeOfMotion: 'Full',
            tempo: 'Moderate',
            muscleGroup: template['muscle']!,
            muscleInfo: MuscleInfo(
              scientificName: '',
              commonName: template['muscle']!,
              muscleRegions: [],
              primaryFunction: 'Strength',
              location: template['muscle']!,
              muscleFiberDirection: 'Standard',
            ),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          sets: 3,
          reps: template['type'] == 'Hold' ? 1 : 12,
          weight: 0,
          restTime: 60,
        ),
      );
    }

    return Workout(
      id: 'mock_quick_${DateTime.now().millisecondsSinceEpoch}',
      name: focusArea.isNotEmpty
          ? '${focusArea} Focus Workout'
          : 'Quick Workout',
      description: focusArea.isNotEmpty
          ? 'Targeted ${duration}-minute ${focusArea.toLowerCase()} workout'
          : 'Quick ${duration}-minute workout',
      exercises: exercises,
      estimatedDuration: duration,
      difficulty: 'Intermediate',
      createdAt: DateTime.now(),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'AI Workout Generator',
            style: AppTextStyles.headline3.copyWith(
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Generate personalized workouts using AI technology:',
                style: AppTextStyles.bodyText1.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoItem(
                '⚡',
                'Quick Workout',
                'Instant AI-generated workouts',
              ),
              _buildInfoItem(
                '🎯',
                'Template Mode',
                '7-day progressive workout plans',
              ),
              _buildInfoItem(
                '❤️',
                'Favorites',
                'Save and reuse your favorite workouts',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Got it', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoItem(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyText1.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                Text(
                  description,
                  style: AppTextStyles.bodyText2.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Show workout preview dialog with save, cancel, and edit options
  void _showWorkoutPreviewDialog(Workout workout, dynamic currentUser) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Workout Generated!',
            style: AppTextStyles.headline3.copyWith(color: AppColors.primary),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workout.name,
                  style: AppTextStyles.headline3.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  workout.description,
                  style: AppTextStyles.bodyText2.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.timer,
                      size: 16,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${workout.estimatedDuration} min',
                      style: AppTextStyles.bodyText2.copyWith(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.fitness_center,
                      size: 16,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${workout.exercises.length} exercises',
                      style: AppTextStyles.bodyText2.copyWith(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Difficulty: ${workout.difficulty}',
                  style: AppTextStyles.bodyText2.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            // First row of buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: AppTextStyles.bodyText1.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _editWorkout(workout),
                  child: Text(
                    'Edit',
                    style: AppTextStyles.bodyText1.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            // Second row of buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => _saveWorkout(workout, currentUser),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      foregroundColor: AppColors.primary,
                    ),
                    child: Text(
                      'Save for Later',
                      style: AppTextStyles.bodyText1.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _saveAndStartWorkout(workout, currentUser),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      'Save & Start',
                      style: AppTextStyles.bodyText1.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Navigate to workout detail screen for editing
  void _editWorkout(Workout workout) {
    Navigator.of(context).pop(); // Close dialog
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WorkoutDetailScreen(workout: workout),
      ),
    );
  }

  /// Save workout for later use
  void _saveWorkout(Workout workout, dynamic currentUser) async {
    try {
      Navigator.of(context).pop(); // Close dialog

      // Show loading indicator
      setState(() => _isGenerating = true);

      final workoutProvider = Provider.of<WorkoutProvider>(
        context,
        listen: false,
      );
      await workoutProvider.saveWorkout(workout, currentUser.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Workout "${workout.name}" saved successfully!'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => WorkoutDetailScreen(workout: workout),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Error saving workout: $e');
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  /// Save workout and start workout session
  void _saveAndStartWorkout(Workout workout, dynamic currentUser) async {
    try {
      Navigator.of(context).pop(); // Close dialog

      // Show loading indicator
      setState(() => _isGenerating = true);

      final workoutProvider = Provider.of<WorkoutProvider>(
        context,
        listen: false,
      );
      await workoutProvider.saveWorkout(workout, currentUser.id);

      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => WorkoutSessionScreen(workout: workout),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Error saving workout: $e');
    } finally {
      setState(() => _isGenerating = false);
    }
  }
}
