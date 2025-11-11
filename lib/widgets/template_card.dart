import 'package:flutter/material.dart';
import '../models/workout_template.dart';
import '../utils/constants.dart';

class TemplateCard extends StatelessWidget {
  final WorkoutTemplate template;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool showFavoriteButton;
  final bool showUsageStats;

  const TemplateCard({
    super.key,
    required this.template,
    this.onTap,
    this.onFavorite,
    this.showFavoriteButton = true,
    this.showUsageStats = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMedium,
        vertical: AppDimensions.paddingSmall,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Template Icon/Category
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getCategoryColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(),
                      color: _getCategoryColor(),
                      size: 20,
                    ),
                  ),

                  const SizedBox(width: AppDimensions.marginMedium),

                  // Template Name and Category
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.name,
                          style: AppTextStyles.bodyText1.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode
                                ? AppColors.darkOnSurface
                                : AppColors.onSurface,
                          ),
                        ),
                        Text(
                          template.category.toUpperCase(),
                          style: AppTextStyles.caption.copyWith(
                            color: _getCategoryColor(),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Favorite Button
                  if (showFavoriteButton)
                    IconButton(
                      onPressed: onFavorite,
                      icon: Icon(
                        template.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: template.isFavorite
                            ? Colors.red
                            : AppColors.darkGray,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: AppDimensions.marginMedium),

              // Description
              Text(
                template.description,
                style: AppTextStyles.bodyText2.copyWith(
                  color: isDarkMode
                      ? AppColors.darkOnSurface.withValues(alpha: 0.8)
                      : AppColors.darkGray,
                ),
              ),

              const SizedBox(height: AppDimensions.marginMedium),

              // Template Details Row
              Row(
                children: [
                  _buildDetailChip(
                    icon: Icons.schedule,
                    label: template.displayDuration,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: AppDimensions.marginSmall),
                  _buildDetailChip(
                    icon: Icons.fitness_center,
                    label: template.displayType,
                    color: Colors.green,
                  ),
                  const SizedBox(width: AppDimensions.marginSmall),
                  _buildDetailChip(
                    icon: Icons.trending_up,
                    label: template.difficultyLevel,
                    color: Colors.orange,
                  ),
                ],
              ),

              // Target Muscles (if available)
              if (template.targetMuscles.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.marginSmall),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: template.targetMuscles.take(4).map((muscle) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        muscle,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              // Usage Stats (if enabled)
              if (showUsageStats && template.usageCount > 0) ...[
                const SizedBox(height: AppDimensions.marginMedium),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? AppColors.darkSurface
                        : AppColors.lightGray.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.analytics,
                        size: 16,
                        color: AppColors.darkGray,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Used ${template.usageCount} times',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.darkGray,
                        ),
                      ),
                      if (template.lastUsed != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '• Last used ${_formatLastUsed(template.lastUsed!)}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.darkGray,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // Popular Badge
              if (template.isPopular) ...[
                const SizedBox(height: AppDimensions.marginSmall),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.amber[700]),
                      const SizedBox(width: 4),
                      Text(
                        'Popular',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.amber[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor() {
    switch (template.category.toLowerCase()) {
      case 'quick':
        return Colors.orange;
      case 'featured':
        return Colors.purple;
      case 'custom':
        return Colors.blue;
      case 'favorites':
        return Colors.red;
      default:
        return AppColors.primary;
    }
  }

  IconData _getCategoryIcon() {
    switch (template.category.toLowerCase()) {
      case 'quick':
        return Icons.flash_on;
      case 'featured':
        return Icons.star;
      case 'custom':
        return Icons.person;
      case 'favorites':
        return Icons.favorite;
      default:
        return Icons.fitness_center;
    }
  }

  String _formatLastUsed(DateTime lastUsed) {
    final now = DateTime.now();
    final difference = now.difference(lastUsed);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }
}

class TemplateGridCard extends StatelessWidget {
  final WorkoutTemplate template;
  final VoidCallback? onTap;

  const TemplateGridCard({super.key, required this.template, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon and Category
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getCategoryColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(),
                      color: _getCategoryColor(),
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  if (template.isFavorite)
                    Icon(Icons.favorite, color: Colors.red, size: 16),
                ],
              ),

              const SizedBox(height: AppDimensions.marginMedium),

              // Template Name
              Text(
                template.name,
                style: AppTextStyles.bodyText1.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode
                      ? AppColors.darkOnSurface
                      : AppColors.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: AppDimensions.marginSmall),

              // Duration and Type
              Text(
                '${template.displayDuration} • ${template.displayType}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const Spacer(),

              // Quick Stats
              if (template.targetMuscles.isNotEmpty)
                Text(
                  template.targetMuscles.take(2).join(', '),
                  style: AppTextStyles.caption.copyWith(
                    color: isDarkMode
                        ? AppColors.darkOnSurface.withValues(alpha: 0.7)
                        : AppColors.darkGray,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor() {
    switch (template.category.toLowerCase()) {
      case 'quick':
        return Colors.orange;
      case 'featured':
        return Colors.purple;
      case 'custom':
        return Colors.blue;
      case 'favorites':
        return Colors.red;
      default:
        return AppColors.primary;
    }
  }

  IconData _getCategoryIcon() {
    switch (template.category.toLowerCase()) {
      case 'quick':
        return Icons.flash_on;
      case 'featured':
        return Icons.star;
      case 'custom':
        return Icons.person;
      case 'favorites':
        return Icons.favorite;
      default:
        return Icons.fitness_center;
    }
  }
}

class TemplateCategoryHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onSeeAll;

  const TemplateCategoryHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.color,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMedium,
        vertical: AppDimensions.paddingSmall,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: color ?? AppColors.primary, size: 20),
            const SizedBox(width: AppDimensions.marginSmall),
          ],

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.headline3.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode
                        ? AppColors.darkOnSurface
                        : AppColors.onSurface,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: AppTextStyles.caption.copyWith(
                      color: isDarkMode
                          ? AppColors.darkOnSurface.withValues(alpha: 0.7)
                          : AppColors.darkGray,
                    ),
                  ),
              ],
            ),
          ),

          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: Text(
                'See All',
                style: AppTextStyles.caption.copyWith(
                  color: color ?? AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
