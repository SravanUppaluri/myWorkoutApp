import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/workout_generation_controller.dart';
import '../../services/template_management_service.dart';
import '../../utils/constants.dart';
import '../../models/workout_template.dart';
import '../../models/workout.dart';

/// Template generation widget for creating workouts from templates
/// Allows users to browse, filter, and generate workouts from predefined templates
class TemplateGenerationWidget extends StatefulWidget {
  final VoidCallback? onWorkoutGenerated;

  const TemplateGenerationWidget({super.key, this.onWorkoutGenerated});

  @override
  State<TemplateGenerationWidget> createState() =>
      _TemplateGenerationWidgetState();
}

class _TemplateGenerationWidgetState extends State<TemplateGenerationWidget> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _showFavoritesOnly = false;
  bool _isGenerating = false;
  WorkoutTemplate? _selectedTemplate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TemplateManagementService>().loadTemplates();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<TemplateManagementService, WorkoutGenerationController>(
      builder: (context, templateService, controller, child) {
        final filteredTemplates = _getFilteredTemplates(templateService);

        return Container(
          margin: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(context),

              const SizedBox(height: AppDimensions.paddingLarge),

              // Search and filters
              _buildSearchAndFilters(context, templateService),

              const SizedBox(height: AppDimensions.paddingMedium),

              // Templates list
              if (templateService.isLoadingTemplates)
                _buildLoadingState()
              else if (filteredTemplates.isEmpty)
                _buildEmptyState()
              else
                _buildTemplatesList(filteredTemplates, templateService),

              const SizedBox(height: AppDimensions.paddingLarge),

              // Generate button
              if (_selectedTemplate != null) _buildGenerateButton(controller),
            ],
          ),
        );
      },
    );
  }

  /// Build header section
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingSmall),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          ),
          child: Icon(Icons.library_books, color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: AppDimensions.paddingMedium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Workout Splits & Templates',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'Choose from PPL, Upper/Lower, Full Body, and other proven splits',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build search and filters section
  Widget _buildSearchAndFilters(
    BuildContext context,
    TemplateManagementService templateService,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search templates...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),

          const SizedBox(height: AppDimensions.paddingMedium),

          // Category filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...templateService.categories.map(
                  (category) => _buildCategoryChip(category),
                ),
                const SizedBox(width: AppDimensions.paddingSmall),
                _buildFavoritesToggle(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build category filter chip
  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;

    return Container(
      margin: const EdgeInsets.only(right: AppDimensions.paddingSmall),
      child: FilterChip(
        label: Text(category),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? category : 'All';
          });
        },
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        checkmarkColor: AppColors.primary,
      ),
    );
  }

  /// Build favorites toggle
  Widget _buildFavoritesToggle() {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.favorite,
            size: 16,
            color: _showFavoritesOnly ? AppColors.primary : null,
          ),
          const SizedBox(width: 4),
          Text('Favorites'),
        ],
      ),
      selected: _showFavoritesOnly,
      onSelected: (selected) {
        setState(() {
          _showFavoritesOnly = selected;
        });
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
    );
  }

  /// Build loading state
  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: AppDimensions.paddingMedium),
            Text('Loading templates...'),
          ],
        ),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Text(
              'No templates found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              'Try adjusting your search or filters',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).disabledColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build templates list
  Widget _buildTemplatesList(
    List<WorkoutTemplate> templates,
    TemplateManagementService templateService,
  ) {
    return SizedBox(
      height: 400,
      child: ListView.builder(
        itemCount: templates.length,
        itemBuilder: (context, index) {
          final template = templates[index];
          final isSelected = _selectedTemplate?.id == template.id;

          return Container(
            margin: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
            child: Card(
              elevation: isSelected ? 8 : 2,
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(
                  AppDimensions.paddingMedium,
                ),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusSmall,
                    ),
                  ),
                  child: Icon(
                    _getCategoryIcon(template.category),
                    color: AppColors.primary,
                  ),
                ),
                title: Text(
                  template.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(template.description),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.timer, size: 16),
                        const SizedBox(width: 4),
                        Text('${template.params['duration'] ?? 30} min'),
                        const SizedBox(width: AppDimensions.paddingMedium),
                        Icon(Icons.fitness_center, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '5-8 exercises',
                        ), // Placeholder since exercises not in template
                      ],
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () =>
                          templateService.toggleTemplateFavorite(template),
                      icon: Icon(
                        template.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: template.isFavorite ? AppColors.primary : null,
                      ),
                    ),
                    Radio<WorkoutTemplate>(
                      value: template,
                      groupValue: _selectedTemplate,
                      onChanged: (value) {
                        setState(() {
                          _selectedTemplate = value;
                        });
                      },
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
                onTap: () {
                  setState(() {
                    _selectedTemplate = template;
                  });
                },
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build generate button
  Widget _buildGenerateButton(WorkoutGenerationController controller) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isGenerating
            ? null
            : () => _generateFromTemplate(controller),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.paddingMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, color: AppColors.onPrimary),
                  const SizedBox(width: AppDimensions.paddingSmall),
                  Text(
                    'Generate from Template',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// Get filtered templates based on search and filters
  List<WorkoutTemplate> _getFilteredTemplates(
    TemplateManagementService templateService,
  ) {
    var templates = templateService.templates;

    // Filter by category
    if (_selectedCategory != 'All') {
      templates = templateService.getTemplatesByCategory(_selectedCategory);
    }

    // Filter favorites
    if (_showFavoritesOnly) {
      templates = templates.where((template) => template.isFavorite).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      templates = templates.where((template) {
        return template.name.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            template.description.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            template.category.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
      }).toList();
    }

    return templates;
  }

  /// Get icon for template category
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'strength':
        return Icons.fitness_center;
      case 'cardio':
        return Icons.directions_run;
      case 'flexibility':
        return Icons.self_improvement;
      case 'hiit':
        return Icons.flash_on;
      case 'yoga':
        return Icons.spa;
      case 'pilates':
        return Icons.accessibility_new;
      default:
        return Icons.sports_gymnastics;
    }
  }

  /// Generate workout from selected template
  Future<void> _generateFromTemplate(
    WorkoutGenerationController controller,
  ) async {
    if (_isGenerating || _selectedTemplate == null) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      final workout = await controller.generateFromTemplate(
        userId: 'user123', // TODO: Get from auth provider
        fitnessLevel: 'Intermediate',
        template: _selectedTemplate!,
      );

      if (mounted) {
        if (workout != null) {
          widget.onWorkoutGenerated?.call();
          _showWorkoutPreview(workout);
        } else {
          _showErrorMessage(
            'Failed to generate workout from template. Please try again.',
          );
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
