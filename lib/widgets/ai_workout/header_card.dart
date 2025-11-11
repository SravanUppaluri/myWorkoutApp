import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// Header card widget for AI Workout Screen
/// Displays the main title and description
class AIWorkoutHeaderCard extends StatelessWidget {
  const AIWorkoutHeaderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.paddingMedium),
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingSmall),
                decoration: BoxDecoration(
                  color: AppColors.onPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusSmall,
                  ),
                ),
                child: Icon(
                  Icons.psychology,
                  color: AppColors.onPrimary,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Workout Generator',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Generate personalized workouts instantly using your profile, preferences, and workout history.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onPrimary.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.paddingMedium),

          // Feature highlights
          Row(
            children: [
              _buildFeatureTag('🎯 Personalized'),
              const SizedBox(width: AppDimensions.paddingSmall),
              _buildFeatureTag('⚡ Instant'),
              const SizedBox(width: AppDimensions.paddingSmall),
              _buildFeatureTag('🧠 AI-Powered'),
            ],
          ),
        ],
      ),
    );
  }

  /// Build feature tag widget
  Widget _buildFeatureTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSmall,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.onPrimary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(
          color: AppColors.onPrimary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.onPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
