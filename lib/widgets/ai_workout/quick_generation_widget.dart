import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/workout_generation_controller.dart';
import '../../services/workout_preferences_service.dart';
import '../../utils/constants.dart';
import '../../models/workout.dart';

/// Quick generation widget for instant workout creation
/// Uses user's history and preferences for one-click generation
class QuickGenerationWidget extends StatefulWidget {
  final VoidCallback? onWorkoutGenerated;

  const QuickGenerationWidget({super.key, this.onWorkoutGenerated});

  @override
  State<QuickGenerationWidget> createState() => _QuickGenerationWidgetState();
}

class _QuickGenerationWidgetState extends State<QuickGenerationWidget> {
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    return Consumer2<WorkoutGenerationController, WorkoutPreferencesService>(
      builder: (context, controller, preferencesService, child) {
        return Container(
          margin: const EdgeInsets.all(AppDimensions.paddingMedium),
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.paddingSmall),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSmall,
                      ),
                    ),
                    child: Icon(
                      Icons.flash_on,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Generate',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Generate instantly based on your profile and history',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color
                                    ?.withValues(alpha: 0.7),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.paddingLarge),

              // Personalized insights
              if (preferencesService.recentPreferences.isNotEmpty) ...[
                _buildInsightsSection(context, preferencesService),
                const SizedBox(height: AppDimensions.paddingLarge),
              ],

              // Generate button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isGenerating
                      ? null
                      : () => _generateWorkout(controller),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.paddingMedium,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMedium,
                      ),
                    ),
                    elevation: 4,
                  ),
                  child: _isGenerating
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: AppColors.onPrimary,
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: AppDimensions.paddingSmall),
                            Text(
                              'Generating...',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppColors.onPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: AppColors.onPrimary,
                            ),
                            const SizedBox(width: AppDimensions.paddingSmall),
                            Text(
                              'Generate My Workout',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppColors.onPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: AppDimensions.paddingMedium),

              // Tips
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusSmall,
                  ),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: AppDimensions.paddingSmall),
                    Expanded(
                      child: Text(
                        'Quick generation uses your workout history and preferences to create the perfect workout for you.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build insights section showing personalized recommendations
  Widget _buildInsightsSection(
    BuildContext context,
    WorkoutPreferencesService preferencesService,
  ) {
    final insights = preferencesService.getPersonalizedRecommendations();
    if (insights.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Based on your profile:',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        Wrap(
          spacing: AppDimensions.paddingSmall,
          runSpacing: AppDimensions.paddingSmall,
          children: insights
              .take(3)
              .map((insight) => _buildInsightChip(context, insight.toString()))
              .toList(),
        ),
      ],
    );
  }

  /// Build individual insight chip
  Widget _buildInsightChip(BuildContext context, String insight) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSmall,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Text(
        insight,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Generate workout using controller
  Future<void> _generateWorkout(WorkoutGenerationController controller) async {
    if (_isGenerating) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      final workout = await controller.generateOneClickWorkout(
        userId: 'user123', // TODO: Get from auth provider
        fitnessLevel: 'Intermediate',
        duration: 45,
      );

      if (mounted) {
        if (workout != null) {
          widget.onWorkoutGenerated?.call();
          _showWorkoutPreview(workout);
        } else {
          _showErrorMessage('Failed to generate workout. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Error generating workout: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  /// Show workout preview dialog
  void _showWorkoutPreview(Workout workout) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Workout Generated!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              workout.name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(workout.description),
            const SizedBox(height: 16),
            Text(
              '${workout.exercises.length} exercises • ${workout.estimatedDuration} min',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to workout detail screen
              Navigator.pushNamed(
                context,
                '/workout-detail',
                arguments: workout,
              );
            },
            child: Text('View Workout'),
          ),
        ],
      ),
    );
  }

  /// Show error message
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
