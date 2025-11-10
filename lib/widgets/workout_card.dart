import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../utils/constants.dart';

class WorkoutCard extends StatelessWidget {
  final Workout workout;
  final VoidCallback? onTap;
  final VoidCallback? onStart;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const WorkoutCard({
    super.key,
    required this.workout,
    this.onTap,
    this.onStart,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: AppDimensions.marginMedium),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Difficulty Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingSmall,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(workout.difficulty),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSmall,
                      ),
                    ),
                    child: Text(
                      workout.difficulty,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // More Options
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      if (onStart != null)
                        PopupMenuItem(
                          value: 'start',
                          child: const Row(
                            children: [
                              Icon(Icons.play_arrow),
                              SizedBox(width: 8),
                              Text(AppStrings.startWorkout),
                            ],
                          ),
                        ),
                      if (onEdit != null)
                        PopupMenuItem(
                          value: 'edit',
                          child: const Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 8),
                              Text(AppStrings.edit),
                            ],
                          ),
                        ),
                      if (onDelete != null)
                        PopupMenuItem(
                          value: 'delete',
                          child: const Row(
                            children: [
                              Icon(Icons.delete, color: AppColors.error),
                              SizedBox(width: 8),
                              Text(
                                AppStrings.delete,
                                style: TextStyle(color: AppColors.error),
                              ),
                            ],
                          ),
                        ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'start':
                          onStart?.call();
                          break;
                        case 'edit':
                          onEdit?.call();
                          break;
                        case 'delete':
                          onDelete?.call();
                          break;
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.marginSmall),

              // Workout Title
              Text(
                workout.name,
                style: AppTextStyles.headline3,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Description
              if (workout.description.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.marginSmall),
                Text(
                  workout.description,
                  style: AppTextStyles.bodyText2.copyWith(
                    color: AppColors.darkGray,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: AppDimensions.marginMedium),

              // Stats Row
              Row(
                children: [
                  _buildStat(
                    icon: Icons.fitness_center,
                    label: '${workout.exercises.length} exercises',
                  ),
                  const SizedBox(width: AppDimensions.marginMedium),
                  _buildStat(
                    icon: Icons.timer,
                    label: '${workout.estimatedDuration} min',
                  ),
                ],
              ),

              // Action Button (if onStart is provided)
              if (onStart != null) ...[
                const SizedBox(height: AppDimensions.marginMedium),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onStart,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text(AppStrings.startWorkout),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMedium,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat({required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(icon, size: AppDimensions.iconSmall, color: AppColors.darkGray),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.darkGray),
        ),
      ],
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return AppColors.forestGreen;
      case 'intermediate':
        return AppColors.steelBlue;
      case 'advanced':
        return AppColors.cardinalRed;
      default:
        return AppColors.primary;
    }
  }
}
