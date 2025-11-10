import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../utils/constants.dart';
import 'workout_session_screen.dart';

class WorkoutReviewScreen extends StatelessWidget {
  final Workout workout;

  const WorkoutReviewScreen({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? AppColors.darkBackground
          : AppColors.background,
      appBar: AppBar(
        title: Text(
          'Review Workout',
          style: TextStyle(
            color: isDarkMode ? AppColors.darkOnSurface : AppColors.onSurface,
          ),
        ),
        elevation: 0,
        backgroundColor: isDarkMode ? AppColors.darkSurface : AppColors.surface,
        iconTheme: IconThemeData(
          color: isDarkMode ? AppColors.darkOnSurface : AppColors.onSurface,
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.darkSurface : AppColors.surface,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: isDarkMode
                          ? AppColors.darkOnSurface
                          : AppColors.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Meta chips (wrap to prevent overflow)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildMetaChip(
                        context,
                        icon: Icons.schedule,
                        label: '${workout.estimatedDuration} min',
                        isDarkMode: isDarkMode,
                      ),
                      _buildMetaChip(
                        context,
                        icon: Icons.fitness_center,
                        label: '${workout.exercises.length} exercises',
                        isDarkMode: isDarkMode,
                      ),
                      if (workout.difficulty.isNotEmpty)
                        _buildMetaChip(
                          context,
                          icon: Icons.terrain,
                          label: workout.difficulty,
                          isDarkMode: isDarkMode,
                        ),
                    ],
                  ),
                  if (workout.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      workout.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDarkMode
                            ? AppColors.darkGray
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Exercises list
          if (workout.exercises.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                child: _buildEmptyState(context, isDarkMode),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final exercise = workout.exercises[index];
                return Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  child: _buildExerciseCard(
                    context,
                    exercise,
                    index + 1,
                    isDarkMode,
                  ),
                );
              }, childCount: workout.exercises.length),
            ),

          // Bottom spacer so list doesn't hide behind bottom bar
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      // Sticky action bar at the bottom
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingLarge,
            vertical: AppDimensions.paddingMedium,
          ),
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.darkSurface : AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: isDarkMode
                          ? AppColors.darkGray
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    'Back',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isDarkMode
                          ? AppColors.darkOnSurface
                          : AppColors.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: workout.exercises.isEmpty
                      ? null
                      : () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  WorkoutSessionScreen(workout: workout),
                            ),
                          );
                        },
                  icon: const Icon(Icons.play_arrow),
                  label: Text(
                    'Start Workout',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Small pill-like chip for meta info
  Widget _buildMetaChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppColors.darkBackground
            : AppColors.lightGray.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isDarkMode ? AppColors.darkOnSurface : AppColors.onSurface,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDarkMode ? AppColors.darkOnSurface : AppColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: isDarkMode ? AppColors.darkGray : Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'No exercises found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: isDarkMode ? AppColors.darkOnSurface : AppColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The AI was unable to generate exercises for this workout.\nPlease try generating again.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDarkMode ? AppColors.darkGray : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(
    BuildContext context,
    WorkoutExercise exercise,
    int exerciseNumber,
    bool isDarkMode,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      elevation: 2,
      color: isDarkMode ? AppColors.darkSurface : AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise Header
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '$exerciseNumber',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    exercise.exercise.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isDarkMode
                          ? AppColors.darkOnSurface
                          : AppColors.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Exercise Details
            Row(
              children: [
                _buildExerciseDetail(
                  context,
                  icon: Icons.repeat,
                  label: 'Sets',
                  value: '${exercise.sets}',
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(width: 16),
                _buildExerciseDetail(
                  context,
                  icon: Icons.fitness_center,
                  label: 'Reps',
                  value: '${exercise.reps}',
                  isDarkMode: isDarkMode,
                ),
                if (exercise.weight > 0) ...[
                  const SizedBox(width: 16),
                  _buildExerciseDetail(
                    context,
                    icon: Icons.monitor_weight,
                    label: 'Weight',
                    value: '${exercise.weight}kg',
                    isDarkMode: isDarkMode,
                  ),
                ],
                if (exercise.restTime > 0) ...[
                  const SizedBox(width: 16),
                  _buildExerciseDetail(
                    context,
                    icon: Icons.timer,
                    label: 'Rest',
                    value: '${exercise.restTime}s',
                    isDarkMode: isDarkMode,
                  ),
                ],
              ],
            ),

            // Target Muscles
            if (exercise.exercise.primaryMuscles.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: exercise.exercise.primaryMuscles
                    .map(
                      (muscle) => Chip(
                        label: Text(
                          muscle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: isDarkMode
                                    ? AppColors.darkOnSurface
                                    : AppColors.onSurface,
                              ),
                        ),
                        backgroundColor: isDarkMode
                            ? AppColors.darkLightGray
                            : AppColors.lightGray,
                        side: BorderSide.none,
                      ),
                    )
                    .toList(),
              ),
            ],

            // Exercise Category and Equipment
            if (exercise.exercise.category.isNotEmpty ||
                exercise.exercise.equipment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (exercise.exercise.category.isNotEmpty) ...[
                    Icon(
                      Icons.category,
                      size: 16,
                      color: isDarkMode ? AppColors.darkGray : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      exercise.exercise.category,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDarkMode
                            ? AppColors.darkGray
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                  if (exercise.exercise.category.isNotEmpty &&
                      exercise.exercise.equipment.isNotEmpty)
                    const SizedBox(width: 16),
                  if (exercise.exercise.equipment.isNotEmpty) ...[
                    Icon(
                      Icons.fitness_center,
                      size: 16,
                      color: isDarkMode ? AppColors.darkGray : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        exercise.exercise.equipment.join(', '),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDarkMode
                              ? AppColors.darkGray
                              : Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseDetail(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required bool isDarkMode,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDarkMode ? AppColors.darkGray : Colors.grey[600],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDarkMode ? AppColors.darkGray : Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDarkMode ? AppColors.darkOnSurface : AppColors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
