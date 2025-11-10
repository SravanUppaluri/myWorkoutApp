import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// Mode selector widget for choosing workout generation mode
/// Supports Quick Generate and Template-Based modes with workout splits
class WorkoutModeSelector extends StatelessWidget {
  final String selectedMode;
  final Function(String) onModeChanged;

  const WorkoutModeSelector({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMedium,
      ),
      padding: const EdgeInsets.all(AppDimensions.paddingSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildModeButton(
            context,
            mode: 'quick',
            label: 'Quick',
            icon: Icons.flash_on,
            description: 'Generate instantly',
          ),
          _buildModeButton(
            context,
            mode: 'template',
            label: 'Templates',
            icon: Icons.library_books,
            description: 'Workout splits & templates',
          ),
        ],
      ),
    );
  }

  /// Build individual mode button
  Widget _buildModeButton(
    BuildContext context, {
    required String mode,
    required String label,
    required IconData icon,
    required String description,
  }) {
    final isSelected = selectedMode == mode;
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: () => onModeChanged(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.paddingMedium,
            horizontal: AppDimensions.paddingSmall,
          ),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.8),
                    ],
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : theme.dividerColor.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.onPrimary : theme.iconTheme.color,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: isSelected
                      ? AppColors.onPrimary
                      : theme.textTheme.titleSmall?.color,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected
                      ? AppColors.onPrimary.withOpacity(0.9)
                      : theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
