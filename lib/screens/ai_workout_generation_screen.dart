import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../models/workout.dart';
import '../providers/workout_provider.dart';
import '../providers/auth_provider.dart';
import '../services/ai_workout_service.dart';
import 'workout_editor_screen.dart';

class AIWorkoutGenerationScreen extends StatefulWidget {
  const AIWorkoutGenerationScreen({super.key});

  @override
  State<AIWorkoutGenerationScreen> createState() =>
      _AIWorkoutGenerationScreenState();
}

class _AIWorkoutGenerationScreenState extends State<AIWorkoutGenerationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _goalController = TextEditingController();
  final _additionalNotesController = TextEditingController();

  String _selectedFitnessLevel = 'Beginner';
  String _selectedWorkoutType = 'Strength';
  String _selectedDuration = '30';
  String _selectedTargetFocus =
      ''; // Target focus for prioritized muscle targeting
  List<String> _selectedMuscleGroups = [];
  List<String> _selectedEquipment = [];
  bool _isGenerating = false;

  final List<String> _fitnessLevels = ['Beginner', 'Intermediate', 'Advanced'];
  final List<String> _workoutTypes = [
    'Strength',
    'Cardio',
    'Flexibility',
    'HIIT',
    'Full Body',
    'Upper Body',
    'Lower Body',
    'Core',
  ];
  final List<String> _durations = ['15', '30', '45', '60', '75', '90'];
  final List<String> _targetFocusOptions = [
    'Core',
    'Lower Back',
    'Chest',
    'Arms',
    'Legs',
    'Upper Body',
  ];
  final List<String> _muscleGroups = [
    'Chest',
    'Back',
    'Shoulders',
    'Arms',
    'Legs',
    'Core',
    'Glutes',
    'Calves',
  ];
  final List<String> _equipmentOptions = [
    'Bodyweight',
    'Dumbbells',
    'Barbells',
    'Resistance Bands',
    'Cable Machine',
    'Pull-up Bar',
    'Kettlebells',
    'Medicine Ball',
  ];

  @override
  void dispose() {
    _goalController.dispose();
    _additionalNotesController.dispose();
    super.dispose();
  }

  void _generateWorkout() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final aiWorkoutService = AIWorkoutService();

      // Get the current user
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.user;

      if (currentUser == null) {
        setState(() {
          _isGenerating = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log in to generate workouts.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final workoutRequest = {
        'userId': currentUser.id,
        'goal': _goalController.text.trim(),
        'fitnessLevel': _selectedFitnessLevel,
        'workoutType': _selectedWorkoutType,
        'duration': int.parse(_selectedDuration),
        'muscleGroups': _determinePriorityMuscleGroups(),
        'equipment': _selectedEquipment,
        'additionalNotes': _buildAdditionalNotes(),
        'excludeWarmup': true, // Structured flag to exclude warmup exercises
        'workoutStructure':
            'main_exercises_only', // Focus only on main exercises
      };

      print('DEBUG: Target Focus: $_selectedTargetFocus');
      print('DEBUG: Selected Muscle Groups: $_selectedMuscleGroups');
      print(
        'DEBUG: Priority Muscle Groups: ${_determinePriorityMuscleGroups()}',
      );
      print('DEBUG: Generating AI workout with request: $workoutRequest');

      final generatedWorkout = await aiWorkoutService.generateWorkout(
        workoutRequest,
      );

      if (generatedWorkout != null) {
        print('DEBUG: AI workout generated: ${generatedWorkout.name}');

        setState(() {
          _isGenerating = false;
        });

        // Show preview dialog
        _showWorkoutPreview(generatedWorkout);
      } else {
        setState(() {
          _isGenerating = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to generate workout. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('DEBUG: Error generating AI workout: $e');
      setState(() {
        _isGenerating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating workout: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showWorkoutPreview(Workout workout) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'AI Generated Workout',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
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
                ),
              ),
              const SizedBox(height: 8),
              Text(workout.description, style: AppTextStyles.bodyText2),
              const SizedBox(height: 16),
              Text(
                'Exercises (${workout.exercises.length}):',
                style: AppTextStyles.bodyText1.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: workout.exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = workout.exercises[index];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        exercise.exercise.name,
                        style: AppTextStyles.bodyText2.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '${exercise.sets} sets × ${exercise.reps} reps',
                        style: AppTextStyles.caption,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _editGeneratedWorkout(workout);
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit'),
            style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _saveGeneratedWorkout(workout);
            },
            icon: const Icon(Icons.save),
            label: const Text('Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _saveGeneratedWorkout(Workout workout) async {
    try {
      final workoutProvider = Provider.of<WorkoutProvider>(
        context,
        listen: false,
      );
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.user != null) {
        final userId = authProvider.user!.id;
        final savedId = await workoutProvider.saveWorkout(workout, userId);

        if (savedId != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'AI workout "${workout.name}" saved successfully! 🎉',
              ),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 3),
            ),
          );
          Navigator.of(context).pop(); // Return to previous screen
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving workout: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _editGeneratedWorkout(Workout workout) async {
    try {
      final editedWorkout = await Navigator.of(context).push<Workout>(
        MaterialPageRoute(
          builder: (context) =>
              WorkoutEditorScreen(workout: workout, isFromAI: true),
        ),
      );

      if (editedWorkout != null) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Workout "${editedWorkout.name}" saved successfully! 🎉',
            ),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop(); // Return to previous screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error editing workout: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  List<String> _determinePriorityMuscleGroups() {
    // If target focus is selected, use ONLY the target focus (not additional muscle groups)
    if (_selectedTargetFocus.isNotEmpty) {
      // Map target focus to muscle groups with comprehensive mapping
      final muscleGroupMap = {
        'Core': ['Core'],
        'Lower Back': ['Back'],
        'Chest': ['Chest'],
        'Arms': ['Arms'],
        'Legs': ['Legs'],
        'Upper Body': ['Chest', 'Back', 'Shoulders', 'Arms'],
      };

      // Return ONLY the target focus muscle groups for focused training
      final targetMuscleGroups =
          muscleGroupMap[_selectedTargetFocus] ?? [_selectedTargetFocus];
      return targetMuscleGroups;
    }

    // If no target focus, use selected muscle groups or default to Full Body
    return _selectedMuscleGroups.isNotEmpty
        ? _selectedMuscleGroups
        : ['Full Body'];
  }

  String _buildAdditionalNotes() {
    String notes = _additionalNotesController.text.trim();

    // Add target focus to notes if specified
    if (_selectedTargetFocus.isNotEmpty) {
      final focusNote = 'Focus on exercises targeting: $_selectedTargetFocus';
      notes = notes.isEmpty ? focusNote : '$notes. $focusNote';
    }

    return notes;
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
        backgroundColor: isDarkMode ? AppColors.darkSurface : AppColors.surface,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.primary.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusLarge,
                  ),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.psychology,
                          color: AppColors.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'AI-Powered Workout Creation',
                            style: AppTextStyles.headline3.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tell us your goals and preferences, and our AI will create a personalized workout plan just for you!',
                      style: AppTextStyles.bodyText2.copyWith(
                        color: isDarkMode
                            ? AppColors.darkOnSurface.withOpacity(0.8)
                            : AppColors.darkGray,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.marginLarge),

              // Goal Input
              _buildSectionTitle('What\'s your fitness goal?'),
              const SizedBox(height: AppDimensions.marginSmall),
              TextFormField(
                controller: _goalController,
                decoration: const InputDecoration(
                  hintText:
                      'e.g., Build muscle, lose weight, improve endurance...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please describe your fitness goal';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppDimensions.marginLarge),

              // Fitness Level
              _buildSectionTitle('Fitness Level'),
              const SizedBox(height: AppDimensions.marginSmall),
              _buildDropdownField(
                value: _selectedFitnessLevel,
                items: _fitnessLevels,
                onChanged: (value) =>
                    setState(() => _selectedFitnessLevel = value!),
                icon: Icons.trending_up,
              ),
              const SizedBox(height: AppDimensions.marginLarge),

              // Workout Type
              _buildSectionTitle('Workout Type'),
              const SizedBox(height: AppDimensions.marginSmall),
              _buildDropdownField(
                value: _selectedWorkoutType,
                items: _workoutTypes,
                onChanged: (value) =>
                    setState(() => _selectedWorkoutType = value!),
                icon: Icons.fitness_center,
              ),
              const SizedBox(height: AppDimensions.marginLarge),

              // Duration
              _buildSectionTitle('Workout Duration (minutes)'),
              const SizedBox(height: AppDimensions.marginSmall),
              _buildDropdownField(
                value: _selectedDuration,
                items: _durations,
                onChanged: (value) =>
                    setState(() => _selectedDuration = value!),
                icon: Icons.timer,
              ),
              const SizedBox(height: AppDimensions.marginLarge),

              // Target Focus
              _buildSectionTitle('Target Focus (optional)'),
              const SizedBox(height: AppDimensions.marginSmall),
              _buildTargetFocusSelector(),
              const SizedBox(height: AppDimensions.marginLarge),

              // Muscle Groups
              _buildSectionTitle('Target Muscle Groups (optional)'),
              const SizedBox(height: AppDimensions.marginSmall),
              Text(
                'Note: If Target Focus is selected above, it will override these selections',
                style: AppTextStyles.caption.copyWith(
                  fontStyle: FontStyle.italic,
                  color: AppColors.darkGray,
                ),
              ),
              const SizedBox(height: AppDimensions.marginSmall),
              _buildChipSelector(
                options: _muscleGroups,
                selectedItems: _selectedMuscleGroups,
                onSelectionChanged: (selected) {
                  setState(() => _selectedMuscleGroups = selected);
                },
              ),
              const SizedBox(height: AppDimensions.marginLarge),

              // Equipment
              _buildSectionTitle('Available Equipment'),
              const SizedBox(height: AppDimensions.marginSmall),
              _buildChipSelector(
                options: _equipmentOptions,
                selectedItems: _selectedEquipment,
                onSelectionChanged: (selected) {
                  setState(() => _selectedEquipment = selected);
                },
              ),
              const SizedBox(height: AppDimensions.marginLarge),

              // Additional Notes
              _buildSectionTitle('Additional Notes (optional)'),
              const SizedBox(height: AppDimensions.marginSmall),
              TextFormField(
                controller: _additionalNotesController,
                decoration: const InputDecoration(
                  hintText:
                      'Any specific preferences, limitations, or requirements...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: AppDimensions.marginXLarge),

              // Generate Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _generateWorkout,
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(
                    _isGenerating ? 'Generating...' : 'Generate Workout',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingLarge,
                      vertical: AppDimensions.paddingMedium,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMedium,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.headline3.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
    );
  }

  Widget _buildTargetFocusSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _targetFocusOptions.map((option) {
        final isSelected = _selectedTargetFocus == option;
        return FilterChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedTargetFocus = selected ? option : '';
            });
          },
          selectedColor: AppColors.primary.withOpacity(0.2),
          checkmarkColor: AppColors.primary,
        );
      }).toList(),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildChipSelector({
    required List<String> options,
    required List<String> selectedItems,
    required ValueChanged<List<String>> onSelectionChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selectedItems.contains(option);
        return FilterChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (selected) {
            final newSelection = List<String>.from(selectedItems);
            if (selected) {
              newSelection.add(option);
            } else {
              newSelection.remove(option);
            }
            onSelectionChanged(newSelection);
          },
          selectedColor: AppColors.primary.withOpacity(0.2),
          checkmarkColor: AppColors.primary,
        );
      }).toList(),
    );
  }
}
