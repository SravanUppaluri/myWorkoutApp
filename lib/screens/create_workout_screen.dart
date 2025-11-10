import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../models/workout.dart';
import '../providers/workout_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/superset_utils.dart';
import '../widgets/superset_creation_dialog.dart';
import 'exercise_selection_screen.dart';

class CreateWorkoutScreen extends StatefulWidget {
  final Workout? existingWorkout;

  const CreateWorkoutScreen({super.key, this.existingWorkout});

  @override
  State<CreateWorkoutScreen> createState() => _CreateWorkoutScreenState();
}

class _CreateWorkoutScreenState extends State<CreateWorkoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedDifficulty = 'Beginner';
  int _estimatedDuration = 30;
  List<WorkoutExercise> _selectedExercises = [];

  final List<String> _difficulties = ['Beginner', 'Intermediate', 'Advanced'];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      setState(() {
        // Update UI when name changes
      });
    });
    if (widget.existingWorkout != null) {
      _loadExistingWorkout();
    }
    _loadWorkoutData();
  }

  void _loadWorkoutData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final workoutProvider = Provider.of<WorkoutProvider>(
        context,
        listen: false,
      );
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.user != null) {
        final userId = authProvider.user!.id;
        workoutProvider.loadUserWorkoutSessions(userId);
      }
    });
  }

  void _loadExistingWorkout() {
    final workout = widget.existingWorkout!;
    _nameController.text = workout.name;
    _descriptionController.text = workout.description;
    _selectedDifficulty = workout.difficulty;
    _estimatedDuration = workout.estimatedDuration;
    _selectedExercises = List.from(workout.exercises);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveWorkout() async {
    print('DEBUG: _saveWorkout called');
    if (!_formKey.currentState!.validate()) {
      print('DEBUG: Form validation failed');
      return;
    }

    if (_selectedExercises.isEmpty) {
      print('DEBUG: No exercises selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one exercise to your workout'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print(
      'DEBUG: Creating workout with ${_selectedExercises.length} exercises',
    );
    final workout = Workout(
      id: widget.existingWorkout?.id ?? '', // Empty string for new workouts
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      exercises: _selectedExercises,
      estimatedDuration: _estimatedDuration,
      difficulty: _selectedDifficulty,
      createdAt: widget.existingWorkout?.createdAt ?? DateTime.now(),
    );

    print('DEBUG: Returning workout: ${workout.name}');
    // For now, just return the workout to be handled by the calling screen
    // This maintains compatibility with the current flow
    Navigator.pop(context, workout);
  }

  void _addExercises() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ExerciseSelectionScreen()),
    );

    if (result != null && result is List<WorkoutExercise>) {
      setState(() {
        for (final workoutExercise in result) {
          // Check if exercise is already added
          if (!_selectedExercises.any(
            (we) => we.exercise.id == workoutExercise.exercise.id,
          )) {
            _selectedExercises.add(workoutExercise);
          }
        }
      });
    }
  }

  void _removeExercise(int index) {
    setState(() {
      _selectedExercises.removeAt(index);
    });
  }

  void _createSuperset() {
    showDialog(
      context: context,
      builder: (context) => SupersetCreationDialog(
        availableExercises: _selectedExercises,
        onSupersetCreated: (supersetExercises) {
          setState(() {
            // Remove original exercises and add superset exercises
            final originalIds = supersetExercises
                .map((e) => e.exercise.id)
                .where(
                  (id) => _selectedExercises.any((ex) => ex.exercise.id == id),
                )
                .toList();

            // Remove original exercises
            _selectedExercises.removeWhere(
              (exercise) => originalIds.contains(exercise.exercise.id),
            );

            // Add superset exercises
            _selectedExercises.addAll(supersetExercises);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Superset created with ${supersetExercises.length} exercises',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        },
      ),
    );
  }

  void _breakSuperset(String supersetId) {
    setState(() {
      final supersetExercises = _selectedExercises
          .where((exercise) => exercise.supersetId == supersetId)
          .toList();

      final updatedExercises = SupersetUtils.removeFromSuperset(
        supersetExercises,
      );

      // Replace superset exercises with individual exercises
      final newExercises = _selectedExercises
          .where((exercise) => exercise.supersetId != supersetId)
          .toList();

      newExercises.addAll(updatedExercises);
      _selectedExercises = newExercises;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Superset broken into individual exercises'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _deleteSuperset(String supersetId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Superset'),
        content: const Text(
          'Are you sure you want to delete this entire superset?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedExercises.removeWhere(
                  (exercise) => exercise.supersetId == supersetId,
                );
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Superset deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _removeFromSuperset(WorkoutExercise exercise) {
    setState(() {
      final updatedExercise = SupersetUtils.removeFromSuperset([
        exercise,
      ]).first;
      final index = _selectedExercises.indexWhere(
        (e) => e.exercise.id == exercise.exercise.id,
      );

      if (index != -1) {
        _selectedExercises[index] = updatedExercise;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${exercise.exercise.name} removed from superset'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _editExercise(int index) {
    _showExerciseEditDialog(_selectedExercises[index], index);
  }

  void _showExerciseEditDialog(WorkoutExercise exercise, int index) {
    final setsController = TextEditingController(
      text: exercise.sets.toString(),
    );
    final repsController = TextEditingController(
      text: exercise.reps.toString(),
    );
    final weightController = TextEditingController(
      text: exercise.weight.toString(),
    );
    final restController = TextEditingController(
      text: exercise.restTime.toString(),
    );
    final notesController = TextEditingController(text: exercise.notes);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${exercise.exercise.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: setsController,
                      decoration: const InputDecoration(
                        labelText: 'Sets',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: repsController,
                      decoration: const InputDecoration(
                        labelText: 'Reps',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: weightController,
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: restController,
                      decoration: const InputDecoration(
                        labelText: 'Rest (sec)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedExercises[index] = WorkoutExercise(
                  exercise: exercise.exercise,
                  sets: int.tryParse(setsController.text) ?? exercise.sets,
                  reps: int.tryParse(repsController.text) ?? exercise.reps,
                  weight:
                      double.tryParse(weightController.text) ?? exercise.weight,
                  restTime:
                      int.tryParse(restController.text) ?? exercise.restTime,
                  notes: notesController.text,
                );
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.headline3.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildWorkoutNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Workout Name',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.fitness_center),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a workout name';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Description (optional)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.description),
      ),
      maxLines: 3,
    );
  }

  Widget _buildDifficultySelector() {
    return DropdownButtonFormField<String>(
      value: _selectedDifficulty,
      decoration: const InputDecoration(
        labelText: 'Difficulty',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.trending_up),
      ),
      items: _difficulties.map((difficulty) {
        return DropdownMenuItem<String>(
          value: difficulty,
          child: Text(difficulty),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedDifficulty = value;
          });
        }
      },
    );
  }

  Widget _buildDurationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estimated Duration: $_estimatedDuration minutes',
          style: AppTextStyles.bodyText1,
        ),
        const SizedBox(height: 8),
        Slider(
          value: _estimatedDuration.toDouble(),
          min: 15,
          max: 120,
          divisions: 21,
          label: '$_estimatedDuration min',
          onChanged: (value) {
            setState(() {
              _estimatedDuration = value.round();
            });
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingWorkout != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Workout' : 'Create Workout'),
        actions: [
          ElevatedButton.icon(
            onPressed: _saveWorkout,
            icon: const Icon(Icons.save, size: 18),
            label: Text(isEditing ? 'Update' : 'Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic Info Section
                    _buildSectionTitle('Basic Information'),
                    const SizedBox(height: AppDimensions.marginSmall),

                    _buildWorkoutNameField(),

                    const SizedBox(height: AppDimensions.marginMedium),

                    _buildDescriptionField(),

                    const SizedBox(height: AppDimensions.marginMedium),

                    _buildDifficultySelector(),

                    const SizedBox(height: AppDimensions.marginMedium),

                    _buildDurationSelector(),

                    const SizedBox(height: AppDimensions.marginLarge),

                    // Exercises Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionTitle(
                          'Exercises (${_selectedExercises.length})',
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_selectedExercises.length >= 2)
                              ElevatedButton.icon(
                                onPressed: _createSuperset,
                                icon: const Icon(Icons.link),
                                label: const Text('Create Superset'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.secondary,
                                  foregroundColor: AppColors.onSecondary,
                                ),
                              ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _addExercises,
                              icon: const Icon(Icons.library_add),
                              label: const Text('Browse Exercise Library'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.onPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: AppDimensions.marginMedium),

                    // Exercises List
                    if (_selectedExercises.isEmpty)
                      _buildEmptyExercisesState()
                    else
                      _buildExercisesList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        decoration: BoxDecoration(
          color: AppColors.background,
          boxShadow: [
            BoxShadow(
              color: AppColors.darkGray.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nameController.text.isEmpty
                          ? 'New Workout'
                          : _nameController.text,
                      style: AppTextStyles.bodyText1.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${_selectedExercises.length} exercise${_selectedExercises.length != 1 ? 's' : ''} • $_estimatedDuration min',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.darkGray,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.marginMedium),
              ElevatedButton.icon(
                onPressed: _saveWorkout,
                icon: const Icon(Icons.save),
                label: Text(
                  widget.existingWorkout != null
                      ? 'Update Workout'
                      : 'Save Workout',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingLarge,
                    vertical: AppDimensions.paddingMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _getPersonalRecord(
    String exerciseId,
    WorkoutProvider workoutProvider,
  ) {
    try {
      final sessions = workoutProvider.workoutSessions;
      double maxWeight = 0.0;

      for (final session in sessions) {
        for (final completedExercise in session.completedExercises) {
          if (completedExercise.exerciseId == exerciseId) {
            for (final set in completedExercise.sets) {
              if (set.weight != null && set.completed) {
                maxWeight = maxWeight < set.weight! ? set.weight! : maxWeight;
              }
            }
          }
        }
      }

      return maxWeight;
    } catch (e) {
      // If there's any error accessing the providers, return 0
      return 0.0;
    }
  }

  Widget _buildEmptyExercisesState() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.lightGray),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Column(
        children: [
          Icon(
            Icons.fitness_center_outlined,
            size: 48,
            color: AppColors.darkGray.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppDimensions.marginMedium),
          Text(
            'No exercises added yet',
            style: AppTextStyles.bodyText1.copyWith(color: AppColors.darkGray),
          ),
          const SizedBox(height: AppDimensions.marginSmall),
          Text(
            'Tap "Browse Exercise Library" to select exercises from your collection',
            style: AppTextStyles.bodyText2.copyWith(
              color: AppColors.darkGray.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesList() {
    final workoutProvider = Provider.of<WorkoutProvider>(
      context,
      listen: false,
    );

    // Group exercises by supersets and individual exercises
    final supersets = SupersetUtils.groupBySupersets(_selectedExercises);
    final individualExercises = SupersetUtils.getNonSupersetExercises(
      _selectedExercises,
    );

    final List<Widget> exerciseWidgets = [];

    // Add superset sections
    for (final supersetEntry in supersets.entries) {
      final supersetId = supersetEntry.key;
      final exercises = supersetEntry.value;

      exerciseWidgets.add(
        _buildSupersetCard(supersetId, exercises, workoutProvider),
      );
    }

    // Add individual exercises
    for (int i = 0; i < individualExercises.length; i++) {
      final exercise = individualExercises[i];
      final originalIndex = _selectedExercises.indexOf(exercise);
      exerciseWidgets.add(
        _buildExerciseCard(exercise, originalIndex, workoutProvider),
      );
    }

    return Column(children: exerciseWidgets);
  }

  Widget _buildSupersetCard(
    String supersetId,
    List<WorkoutExercise> exercises,
    WorkoutProvider workoutProvider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.marginSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Superset header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.link, color: AppColors.secondary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Superset (${exercises.length} exercises)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'break_superset') {
                      _breakSuperset(supersetId);
                    } else if (value == 'delete_superset') {
                      _deleteSuperset(supersetId);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'break_superset',
                      child: Row(
                        children: [
                          Icon(Icons.link_off),
                          SizedBox(width: 8),
                          Text('Break Superset'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete_superset',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete Superset'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Superset exercises
          ...exercises.map(
            (exercise) => _buildSupersetExerciseTile(exercise, workoutProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildSupersetExerciseTile(
    WorkoutExercise exercise,
    WorkoutProvider workoutProvider,
  ) {
    final personalRecord = _getPersonalRecord(
      exercise.exercise.id,
      workoutProvider,
    );

    return ListTile(
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: AppColors.secondary,
        child: Text(
          exercise.supersetLabel ?? '',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              exercise.exercise.name,
              style: AppTextStyles.bodyText1.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: personalRecord > 0
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'PR: ${personalRecord > 0 ? '${personalRecord.toStringAsFixed(0)}kg' : '0kg'}',
              style: AppTextStyles.caption.copyWith(
                color: personalRecord > 0 ? AppColors.primary : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        '${exercise.sets} sets × ${exercise.reps} reps'
        '${exercise.weight > 0 ? ' @ ${exercise.weight}kg' : ''}',
        style: AppTextStyles.bodyText2,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              final index = _selectedExercises.indexOf(exercise);
              _editExercise(index);
            },
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle, color: Colors.red),
            onPressed: () => _removeFromSuperset(exercise),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(
    WorkoutExercise exercise,
    int index,
    WorkoutProvider workoutProvider,
  ) {
    final personalRecord = _getPersonalRecord(
      exercise.exercise.id,
      workoutProvider,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.marginSmall),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                exercise.exercise.name,
                style: AppTextStyles.bodyText1.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: personalRecord > 0
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'PR: ${personalRecord > 0 ? '${personalRecord.toStringAsFixed(0)}kg' : '0kg'}',
                style: AppTextStyles.caption.copyWith(
                  color: personalRecord > 0 ? AppColors.primary : Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          '${exercise.sets} sets × ${exercise.reps} reps'
          '${exercise.weight > 0 ? ' @ ${exercise.weight}kg' : ''}',
          style: AppTextStyles.bodyText2,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editExercise(index),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeExercise(index),
            ),
          ],
        ),
      ),
    );
  }
}
