import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../providers/workout_provider.dart';
import '../providers/auth_provider.dart';
import '../services/workout_editing_service.dart';
import '../utils/constants.dart';
import 'exercise_selection_screen.dart';

class WorkoutEditorScreen extends StatefulWidget {
  final Workout workout;
  final bool isFromAI;

  const WorkoutEditorScreen({
    super.key,
    required this.workout,
    this.isFromAI = false,
  });

  @override
  State<WorkoutEditorScreen> createState() => _WorkoutEditorScreenState();
}

class _WorkoutEditorScreenState extends State<WorkoutEditorScreen> {
  late Workout _editableWorkout;
  final WorkoutEditingService _editingService = WorkoutEditingService();
  bool _isLoading = false;
  String? _loadingMessage;

  @override
  void initState() {
    super.initState();
    _editableWorkout = widget.workout;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Workout'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _saveWorkout,
            icon: Icon(Icons.save, color: Colors.white),
            label: Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    _loadingMessage ?? 'Loading...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Workout Info Header
                  _buildWorkoutHeader(),

                  // Exercise List
                  _buildExerciseList(),

                  // Add Exercise Button
                  _buildAddExerciseButton(),

                  SizedBox(height: 100), // Bottom padding
                ],
              ),
            ),
    );
  }

  Widget _buildWorkoutHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _editableWorkout.name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              if (widget.isFromAI)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'AI Generated',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            _editableWorkout.description,
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip(
                icon: Icons.timer,
                label: '${_editableWorkout.estimatedDuration} min',
              ),
              SizedBox(width: 8),
              _buildInfoChip(
                icon: Icons.fitness_center,
                label: '${_editableWorkout.exercises.length} exercises',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _editableWorkout.exercises.length,
      itemBuilder: (context, index) {
        final exercise = _editableWorkout.exercises[index];
        return _buildExerciseCard(exercise, index);
      },
    );
  }

  Widget _buildExerciseCard(WorkoutExercise workoutExercise, int index) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise Header with Actions
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${index + 1}. ${workoutExercise.exercise.name}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        workoutExercise.exercise.primaryMuscles.join(', '),
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) =>
                      _handleExerciseAction(value, index, workoutExercise),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit_sets',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Edit Sets/Reps'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'replace_ai',
                      child: Row(
                        children: [
                          Icon(
                            Icons.psychology,
                            size: 20,
                            color: AppColors.secondary,
                          ),
                          SizedBox(width: 8),
                          Text('AI Alternatives'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'replace_manual',
                      child: Row(
                        children: [
                          Icon(Icons.library_books, size: 20),
                          SizedBox(width: 8),
                          Text('Browse Library'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Remove'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 12),

            // Exercise Details
            Row(
              children: [
                _buildDetailChip('${workoutExercise.sets} sets'),
                SizedBox(width: 8),
                _buildDetailChip('${workoutExercise.reps} reps'),
                if (workoutExercise.weight > 0) ...[
                  SizedBox(width: 8),
                  _buildDetailChip(
                    '${workoutExercise.weight.toStringAsFixed(1)} lbs',
                  ),
                ],
                SizedBox(width: 8),
                _buildDetailChip('${workoutExercise.restTime}s rest'),
              ],
            ),

            if (workoutExercise.notes.isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                'Notes: ${workoutExercise.notes}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildAddExerciseButton() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: _addNewExercise,
        icon: Icon(Icons.library_add),
        label: Text('Browse Exercise Library'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[100],
          foregroundColor: AppColors.primary,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
          ),
        ),
      ),
    );
  }

  void _handleExerciseAction(
    String action,
    int index,
    WorkoutExercise workoutExercise,
  ) {
    switch (action) {
      case 'edit_sets':
        _editExerciseSets(index, workoutExercise);
        break;
      case 'replace_ai':
        _replaceExerciseWithAI(index, workoutExercise);
        break;
      case 'replace_manual':
        _browseAlternativeExercises(index, workoutExercise);
        break;
      case 'remove':
        _removeExercise(index);
        break;
    }
  }

  void _editExerciseSets(int index, WorkoutExercise workoutExercise) {
    // Show dialog to edit sets, reps, weight
    showDialog(
      context: context,
      builder: (context) => _EditSetsDialog(
        workoutExercise: workoutExercise,
        onSave: (updatedExercise) {
          setState(() {
            List<WorkoutExercise> updatedExercises = List.from(
              _editableWorkout.exercises,
            );
            updatedExercises[index] = updatedExercise;
            _editableWorkout = _editableWorkout.copyWith(
              exercises: updatedExercises,
            );
          });
        },
      ),
    );
  }

  void _replaceExerciseWithAI(
    int index,
    WorkoutExercise workoutExercise,
  ) async {
    setState(() {
      _isLoading = true;
      _loadingMessage =
          'Finding AI alternatives for ${workoutExercise.exercise.name}...';
    });

    try {
      final result = await _editingService.replaceExerciseWithAI(
        exerciseToReplace: workoutExercise.exercise.name,
        targetMuscleGroups: workoutExercise.exercise.primaryMuscles,
        availableEquipment: workoutExercise.exercise.equipment,
        fitnessLevel: 'Intermediate', // Could get from user profile
        workoutType: workoutExercise.exercise.category,
      );

      setState(() {
        _isLoading = false;
      });

      if (result != null && result.alternatives.isNotEmpty) {
        _showAlternativesDialog(index, result.alternatives, isAI: true);
      } else {
        _showErrorSnackBar(
          'No alternatives found. Try browsing similar exercises.',
        );
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to get AI alternatives: ${error.toString()}');
    }
  }

  void _browseAlternativeExercises(
    int index,
    WorkoutExercise workoutExercise,
  ) async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Finding similar exercises...';
    });

    try {
      final result = await _editingService.getSimilarExercises(
        targetMuscleGroups: workoutExercise.exercise.primaryMuscles,
        availableEquipment: workoutExercise.exercise.equipment,
        exerciseType: workoutExercise.exercise.category,
        excludeExercises: [workoutExercise.exercise.name],
      );

      setState(() {
        _isLoading = false;
      });

      if (result != null && result.exercises.isNotEmpty) {
        _showSimilarExercisesDialog(index, result.exercises);
      } else {
        _showErrorSnackBar('No similar exercises found.');
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar(
        'Failed to find similar exercises: ${error.toString()}',
      );
    }
  }

  void _showAlternativesDialog(
    int index,
    List<AlternativeExercise> alternatives, {
    bool isAI = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      isAI ? Icons.psychology : Icons.fitness_center,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isAI ? 'AI Alternative Exercises' : 'Similar Exercises',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: alternatives.length,
                  itemBuilder: (context, altIndex) {
                    final alternative = alternatives[altIndex];
                    return _buildAlternativeCard(alternative, () {
                      _replaceExercise(index, alternative);
                      Navigator.of(context).pop();
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSimilarExercisesDialog(int index, List<Exercise> exercises) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.fitness_center, color: AppColors.primary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Similar Exercises',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: exercises.length,
                  itemBuilder: (context, exIndex) {
                    final exercise = exercises[exIndex];
                    return _buildSimilarExerciseCard(exercise, () {
                      _replaceSimilarExercise(index, exercise);
                      Navigator.of(context).pop();
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlternativeCard(
    AlternativeExercise alternative,
    VoidCallback onSelect,
  ) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(
          alternative.name,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Targets: ${alternative.muscleGroups.join(', ')}'),
            Text('Equipment: ${alternative.equipment.join(', ')}'),
            Text('Similarity: ${alternative.similarity}'),
            SizedBox(height: 4),
            Text(
              alternative.instructions,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: onSelect,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: Text('Select'),
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildSimilarExerciseCard(Exercise exercise, VoidCallback onSelect) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(
          exercise.name,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Targets: ${exercise.primaryMuscles.join(', ')}'),
            Text('Equipment: ${exercise.equipment.join(', ')}'),
            Text('Difficulty: ${exercise.difficulty}'),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: onSelect,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: Text('Select'),
        ),
        isThreeLine: true,
      ),
    );
  }

  void _replaceExercise(int index, AlternativeExercise alternative) {
    final workoutExercise = _editingService
        .createWorkoutExerciseFromAlternative(alternative);

    setState(() {
      List<WorkoutExercise> updatedExercises = List.from(
        _editableWorkout.exercises,
      );
      updatedExercises[index] = workoutExercise;
      _editableWorkout = _editableWorkout.copyWith(exercises: updatedExercises);
    });

    _showSuccessSnackBar('Replaced with ${alternative.name}');
  }

  void _replaceSimilarExercise(int index, Exercise exercise) {
    // Get the current exercise's sets/reps/weight to maintain consistency
    final currentWorkoutExercise = _editableWorkout.exercises[index];

    final newWorkoutExercise = WorkoutExercise(
      exercise: exercise,
      sets: currentWorkoutExercise.sets,
      reps: currentWorkoutExercise.reps,
      weight: currentWorkoutExercise.weight,
      restTime: currentWorkoutExercise.restTime,
      notes: '',
    );

    setState(() {
      List<WorkoutExercise> updatedExercises = List.from(
        _editableWorkout.exercises,
      );
      updatedExercises[index] = newWorkoutExercise;
      _editableWorkout = _editableWorkout.copyWith(exercises: updatedExercises);
    });

    _showSuccessSnackBar('Replaced with ${exercise.name}');
  }

  void _removeExercise(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Exercise'),
        content: Text(
          'Are you sure you want to remove this exercise from the workout?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                List<WorkoutExercise> updatedExercises = List.from(
                  _editableWorkout.exercises,
                );
                updatedExercises.removeAt(index);
                _editableWorkout = _editableWorkout.copyWith(
                  exercises: updatedExercises,
                );
              });
              Navigator.of(context).pop();
              _showSuccessSnackBar('Exercise removed');
            },
            child: Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _addNewExercise() async {
    print('DEBUG: Opening exercise selection screen...');

    // Open the exercise selection screen to browse and add from library
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ExerciseSelectionScreen()),
    );

    print('DEBUG: Exercise selection returned: $result');
    print('DEBUG: Result type: ${result.runtimeType}');

    if (result != null && result is List<WorkoutExercise>) {
      print('DEBUG: Adding ${result.length} exercises to workout');

      setState(() {
        // Add selected exercises to the workout
        List<WorkoutExercise> updatedExercises = List.from(
          _editableWorkout.exercises,
        );

        for (final workoutExercise in result) {
          print('DEBUG: Processing exercise: ${workoutExercise.exercise.name}');

          // Check if exercise is already in the workout
          if (!updatedExercises.any(
            (we) => we.exercise.id == workoutExercise.exercise.id,
          )) {
            updatedExercises.add(workoutExercise);
            print('DEBUG: Added exercise: ${workoutExercise.exercise.name}');
          } else {
            print(
              'DEBUG: Exercise already exists: ${workoutExercise.exercise.name}',
            );
          }
        }

        print(
          'DEBUG: Total exercises before: ${_editableWorkout.exercises.length}',
        );
        print('DEBUG: Total exercises after: ${updatedExercises.length}');

        _editableWorkout = _editableWorkout.copyWith(
          exercises: updatedExercises,
        );

        print(
          'DEBUG: Updated workout with ${_editableWorkout.exercises.length} exercises',
        );
      });

      final addedCount = result
          .where(
            (workoutExercise) => !_editableWorkout.exercises.any(
              (we) => we.exercise.id == workoutExercise.exercise.id,
            ),
          )
          .length;

      if (addedCount > 0) {
        _showSuccessSnackBar(
          'Added $addedCount exercise${addedCount > 1 ? 's' : ''} to workout',
        );
      } else {
        _showSuccessSnackBar('No new exercises added (duplicates skipped)');
      }
    } else {
      print('DEBUG: No exercises selected or invalid result type');
      if (result == null) {
        print('DEBUG: User cancelled exercise selection');
      }
    }
  }

  void _saveWorkout() async {
    try {
      final workoutProvider = Provider.of<WorkoutProvider>(
        context,
        listen: false,
      );
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.user != null) {
        final userId = authProvider.user!.id;
        await workoutProvider.saveWorkout(_editableWorkout, userId);

        _showSuccessSnackBar('Workout saved successfully!');
        Navigator.of(
          context,
        ).pop(_editableWorkout); // Return the edited workout
      } else {
        _showErrorSnackBar('User not authenticated');
      }
    } catch (error) {
      _showErrorSnackBar('Failed to save workout: ${error.toString()}');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// Dialog for editing sets/reps/weight
class _EditSetsDialog extends StatefulWidget {
  final WorkoutExercise workoutExercise;
  final Function(WorkoutExercise) onSave;

  const _EditSetsDialog({required this.workoutExercise, required this.onSave});

  @override
  State<_EditSetsDialog> createState() => _EditSetsDialogState();
}

class _EditSetsDialogState extends State<_EditSetsDialog> {
  late TextEditingController _setsController;
  late TextEditingController _repsController;
  late TextEditingController _weightController;
  late TextEditingController _restController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _setsController = TextEditingController(
      text: widget.workoutExercise.sets.toString(),
    );
    _repsController = TextEditingController(
      text: widget.workoutExercise.reps.toString(),
    );
    _weightController = TextEditingController(
      text: widget.workoutExercise.weight.toString(),
    );
    _restController = TextEditingController(
      text: widget.workoutExercise.restTime.toString(),
    );
    _notesController = TextEditingController(
      text: widget.workoutExercise.notes,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.workoutExercise.exercise.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _setsController,
              decoration: InputDecoration(labelText: 'Sets'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 12),
            TextField(
              controller: _repsController,
              decoration: InputDecoration(labelText: 'Reps'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 12),
            TextField(
              controller: _weightController,
              decoration: InputDecoration(labelText: 'Weight (lbs)'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _restController,
              decoration: InputDecoration(labelText: 'Rest Time (seconds)'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(labelText: 'Notes'),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(onPressed: _saveChanges, child: Text('Save')),
      ],
    );
  }

  void _saveChanges() {
    final updatedExercise = WorkoutExercise(
      exercise: widget.workoutExercise.exercise,
      sets: int.tryParse(_setsController.text) ?? widget.workoutExercise.sets,
      reps: int.tryParse(_repsController.text) ?? widget.workoutExercise.reps,
      weight:
          double.tryParse(_weightController.text) ??
          widget.workoutExercise.weight,
      restTime:
          int.tryParse(_restController.text) ?? widget.workoutExercise.restTime,
      notes: _notesController.text,
    );

    widget.onSave(updatedExercise);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _restController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

// Extension to add copyWith method to Workout
extension WorkoutCopyWith on Workout {
  Workout copyWith({
    String? id,
    String? name,
    String? description,
    List<WorkoutExercise>? exercises,
    int? estimatedDuration,
    String? difficulty,
    DateTime? createdAt,
  }) {
    return Workout(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      exercises: exercises ?? this.exercises,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      difficulty: difficulty ?? this.difficulty,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
