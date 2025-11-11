import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../models/workout.dart';
import 'workout_session_screen.dart';
import 'workout_editor_screen.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class WorkoutDetailScreen extends StatefulWidget {
  final Workout workout;

  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  late Workout _workout;

  @override
  void initState() {
    super.initState();
    _workout = widget.workout;

    // Console logging for analysis
    logger.e('🎯 WORKOUT DETAIL SCREEN OPENED');
    logger.e('📊 Workout ID: ${_workout.id}');
    logger.e('📊 Workout Name: "${_workout.name}"');
    logger.e('📊 Workout Description: "${_workout.description}"');
    logger.e('📊 Exercise Count: ${_workout.exercises.length}');
    logger.e('📊 Estimated Duration: ${_workout.estimatedDuration} minutes');
    logger.e('📊 Difficulty: ${_workout.difficulty}');
    logger.e('📊 Created At: ${_workout.createdAt}');

    // Log exercise details for optimization analysis
    logger.e('📊 Exercise Details:');
    for (int i = 0; i < _workout.exercises.length; i++) {
      final exercise = _workout.exercises[i];
      logger.e(
        '  ${i + 1}. ${exercise.exercise.name} - ${exercise.sets}x${exercise.reps} (${exercise.restTime}s rest)',
      );
    }
    logger.e('🎯 END WORKOUT DETAIL LOGGING');
  }

  void _startWorkout() {
    logger.e('🏃‍♀️ USER ACTION: Starting workout "${_workout.name}"');
    logger.e('📊 Starting at: ${DateTime.now()}');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutSessionScreen(workout: _workout),
      ),
    );
  }

  void _editWorkout() async {
    logger.e('✏️ USER ACTION: Editing workout "${_workout.name}"');

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            WorkoutEditorScreen(workout: _workout, isFromAI: false),
      ),
    );

    if (result != null && result is Workout) {
      logger.e('✅ WORKOUT EDIT SUCCESS: "${result.name}"');
      logger.e('📊 Updated at: ${DateTime.now()}');

      setState(() {
        _workout = result;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Workout "${result.name}" updated successfully!'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      logger.e('❌ WORKOUT EDIT CANCELLED');
    }
  }

  void _deleteWorkout() {
    logger.e(
      '🗑️ USER ACTION: Attempting to delete workout "${_workout.name}"',
    );

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? AppColors.darkSurface : AppColors.surface,
        title: Text(
          'Delete Workout',
          style: TextStyle(
            color: isDarkMode ? AppColors.darkOnSurface : AppColors.onSurface,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${_workout.name}"?',
          style: TextStyle(
            color: isDarkMode ? AppColors.darkOnSurface : AppColors.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDarkMode
                    ? AppColors.darkOnSurface
                    : AppColors.onSurface,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              logger.e(
                '🗑️ CONFIRMING DELETE: "${_workout.name}" (ID: ${_workout.id})',
              );

              // Attempt delete via provider
              final provider = Provider.of<WorkoutProvider>(
                context,
                listen: false,
              );
              final success = await provider.deleteWorkout(_workout.id);

              if (mounted) {
                Navigator.pop(context); // Close dialog
                if (success) {
                  logger.e(
                    '✅ DELETE SUCCESS: Workout "${_workout.name}" deleted',
                  );
                  // Pop this detail screen and notify caller we deleted
                  Navigator.pop(context, true);
                } else {
                  logger.e('❌ DELETE FAILED: ${provider.errorMessage}');
                  final error = provider.errorMessage;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        error != null && error.isNotEmpty
                            ? 'Failed to delete workout: $error'
                            : 'Failed to delete workout',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? AppColors.darkBackground
          : AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Collapsible Header
          SliverAppBar(
            expandedHeight: 200, // Further reduced from 240
            floating: false,
            pinned: true,
            backgroundColor: isDarkMode
                ? AppColors.darkSurface
                : AppColors.surface,
            foregroundColor: isDarkMode
                ? AppColors.darkOnSurface
                : AppColors.onSurface,
            actions: [
              PopupMenuButton<String>(
                iconColor: isDarkMode
                    ? AppColors.darkOnSurface
                    : AppColors.onSurface,
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _editWorkout();
                      break;
                    case 'delete':
                      _deleteWorkout();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit,
                          color: isDarkMode
                              ? AppColors.darkOnSurface
                              : AppColors.onSurface,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Edit',
                          style: TextStyle(
                            color: isDarkMode
                                ? AppColors.darkOnSurface
                                : AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _workout.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode
                      ? AppColors.darkOnSurface
                      : AppColors.onSurface,
                ),
                maxLines: 2, // Allow title to wrap to 2 lines
                overflow:
                    TextOverflow.ellipsis, // Add ellipsis if still too long
                textAlign: TextAlign.justify, // Justify the title
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDarkMode
                        ? [
                            AppColors.darkPrimary.withValues(alpha: 0.2),
                            AppColors.darkPrimary.withValues(alpha: 0.1),
                          ]
                        : [
                            AppColors.primary.withValues(alpha: 0.1),
                            AppColors.primary.withValues(alpha: 0.05),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(
                      AppDimensions.paddingMedium,
                    ), // Reduced from paddingLarge
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 30), // Further reduced space
                        Expanded(
                          // Changed from Flexible to Expanded for better constraint
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_workout.description.isNotEmpty) ...[
                                Flexible(
                                  // Wrap description in Flexible
                                  child: Text(
                                    _workout.description,
                                    style: AppTextStyles.bodyText2.copyWith(
                                      // Smaller text
                                      color: isDarkMode
                                          ? AppColors.darkOnSurface.withValues(
                                              alpha: 0.7,
                                            )
                                          : AppColors.darkGray,
                                    ),
                                    maxLines:
                                        2, // Allow 2 lines for description
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(
                                  height: 12,
                                ), // More spacing for description
                              ],
                              // Simple info list instead of cards
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildInfoRow(
                                      Icons.timer,
                                      'Duration',
                                      '${_workout.estimatedDuration} minutes',
                                    ),
                                    const SizedBox(height: 4),
                                    _buildInfoRow(
                                      Icons.trending_up,
                                      'Level',
                                      _workout.difficulty,
                                    ),
                                    const SizedBox(height: 4),
                                    _buildInfoRow(
                                      Icons.fitness_center,
                                      'Exercises',
                                      '${_workout.exercises.length} ${_workout.exercises.length == 1 ? 'exercise' : 'exercises'}',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Exercises List
          _workout.exercises.isEmpty
              ? SliverFillRemaining(child: _buildEmptyExercisesState())
              : SliverPadding(
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final exercise = _workout.exercises[index];
                      return _buildExerciseCard(exercise, index);
                    }, childCount: _workout.exercises.length),
                  ),
                ),
        ],
      ),
      bottomNavigationBar: _workout.exercises.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              color: isDarkMode
                  ? AppColors.darkBackground
                  : AppColors.background,
              child: ElevatedButton.icon(
                onPressed: _startWorkout,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Workout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode
                      ? AppColors.darkPrimary
                      : AppColors.primary,
                  foregroundColor: isDarkMode
                      ? AppColors.darkOnPrimary
                      : AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.paddingMedium,
                  ),
                  textStyle: AppTextStyles.headline3,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: isDarkMode
              ? AppColors.darkPrimary.withValues(alpha: 0.8)
              : AppColors.primary.withValues(alpha: 0.8),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            '$label: $value',
            style: AppTextStyles.caption.copyWith(
              color: isDarkMode
                  ? AppColors.darkOnSurface.withValues(alpha: 0.9)
                  : AppColors.onSurface.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyExercisesState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center_outlined,
            size: 80,
            color: isDarkMode
                ? AppColors.darkOnSurface.withValues(alpha: 0.5)
                : AppColors.darkGray.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppDimensions.marginMedium),
          Text(
            'No exercises added',
            style: AppTextStyles.headline3.copyWith(
              color: isDarkMode ? AppColors.darkOnSurface : AppColors.onSurface,
            ),
          ),
          const SizedBox(height: AppDimensions.marginSmall),
          Text(
            'Edit this workout to add exercises',
            style: AppTextStyles.bodyText2.copyWith(
              color: isDarkMode
                  ? AppColors.darkOnSurface.withValues(alpha: 0.7)
                  : AppColors.darkGray,
            ),
          ),
          const SizedBox(height: AppDimensions.marginLarge),
          ElevatedButton.icon(
            onPressed: _editWorkout,
            icon: const Icon(Icons.edit),
            label: const Text('Edit Workout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode
                  ? AppColors.darkPrimary
                  : AppColors.primary,
              foregroundColor: isDarkMode
                  ? AppColors.darkOnPrimary
                  : AppColors.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(WorkoutExercise workoutExercise, int index) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final exercise = workoutExercise.exercise;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.marginSmall),
      padding: const EdgeInsets.symmetric(
        vertical: AppDimensions.paddingSmall,
        horizontal: AppDimensions.paddingMedium,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDarkMode
                ? AppColors.darkOnSurface.withValues(alpha: 0.1)
                : AppColors.lightGray.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise Header
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? AppColors.darkPrimary.withValues(alpha: 0.2)
                      : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isDarkMode
                          ? AppColors.darkPrimary
                          : AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: AppTextStyles.bodyText1.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDarkMode
                            ? AppColors.darkOnSurface
                            : AppColors.onSurface,
                      ),
                    ),
                    if (exercise.primaryMuscles.isNotEmpty)
                      Text(
                        exercise.primaryMuscles.join(', '),
                        style: AppTextStyles.caption.copyWith(
                          color: isDarkMode
                              ? AppColors.darkOnSurface.withValues(alpha: 0.7)
                              : AppColors.darkGray,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Exercise Details - Horizontal List
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _buildExerciseDetailRow(
                  Icons.fitness_center,
                  'Sets',
                  workoutExercise.sets.toString(),
                ),
                _buildExerciseDetailRow(
                  Icons.repeat,
                  'Reps',
                  workoutExercise.reps.toString(),
                ),
                if (workoutExercise.weight > 0)
                  _buildExerciseDetailRow(
                    Icons.monitor_weight,
                    'Weight',
                    '${workoutExercise.weight}kg',
                  ),
                _buildExerciseDetailRow(
                  Icons.timer,
                  'Rest',
                  '${workoutExercise.restTime}s',
                ),
              ],
            ),
          ),

          if (workoutExercise.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Text(
                'Notes: ${workoutExercise.notes}',
                style: AppTextStyles.caption.copyWith(
                  fontStyle: FontStyle.italic,
                  color: isDarkMode
                      ? AppColors.darkOnSurface.withValues(alpha: 0.8)
                      : AppColors.darkGray,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExerciseDetailRow(IconData icon, String label, String value) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: isDarkMode
              ? AppColors.darkOnSurface.withValues(alpha: 0.7)
              : AppColors.darkGray,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            '$label: $value',
            style: AppTextStyles.bodyText2.copyWith(
              color: isDarkMode ? AppColors.darkOnSurface : AppColors.onSurface,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}
