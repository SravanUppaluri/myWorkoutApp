import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../utils/constants.dart';

class ExerciseTile extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;
  final Widget? trailing;

  const ExerciseTile({
    super.key,
    required this.exercise,
    this.onTap,
    this.onAdd,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: AppDimensions.marginSmall),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: _getMuscleGroupColor(exercise.muscleGroup),
          child: Icon(
            _getMuscleGroupIcon(exercise.muscleGroup),
            color: AppColors.onPrimary,
            size: AppDimensions.iconMedium,
          ),
        ),
        title: Text(
          exercise.name,
          style: AppTextStyles.bodyText1.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                _buildTag(
                  exercise.muscleGroup,
                  _getMuscleGroupColor(exercise.muscleGroup),
                ),
                const SizedBox(width: 8),
                _buildTag(exercise.equipment.join(', '), AppColors.darkGray),
              ],
            ),
            // Description removed: Exercise model does not have a description field
          ],
        ),
        trailing:
            trailing ??
            (onAdd != null
                ? IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppColors.primary,
                    onPressed: onAdd,
                    tooltip: 'Add to workout',
                  )
                : const Icon(Icons.arrow_forward_ios, size: 16)),
        contentPadding: const EdgeInsets.all(AppDimensions.paddingMedium),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSmall,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(color: color, fontSize: 10),
      ),
    );
  }

  Color _getMuscleGroupColor(String muscleGroup) {
    switch (muscleGroup.toLowerCase()) {
      case 'chest':
        return AppColors.cardinalRed;
      case 'back':
        return AppColors.forestGreen;
      case 'legs':
        return AppColors.steelBlue;
      case 'shoulders':
        return Colors.orange;
      case 'arms':
        return Colors.purple;
      case 'core':
        return Colors.teal;
      default:
        return AppColors.primary;
    }
  }

  IconData _getMuscleGroupIcon(String muscleGroup) {
    switch (muscleGroup.toLowerCase()) {
      case 'chest':
        return Icons.fitness_center;
      case 'back':
        return Icons.back_hand;
      case 'legs':
        return Icons.directions_run;
      case 'shoulders':
        return Icons.accessibility_new;
      case 'arms':
        return Icons.sports_martial_arts;
      case 'core':
        return Icons.sports_gymnastics;
      default:
        return Icons.fitness_center;
    }
  }
}
