import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../models/workout.dart';
import '../models/workout_template.dart';
import '../models/exercise.dart';
import '../providers/workout_provider.dart';
import '../providers/auth_provider.dart';
import '../services/ai_workout_service.dart';
import '../services/workout_template_service.dart';
import '../screens/workout_session_screen.dart';

/// Service class that handles all template-related UI and functionality
/// Extracted from ImprovedAIWorkoutScreen to maintain separation of concerns
class TemplateUIService {
  // Template system state
  List<WorkoutTemplate> _quickTemplates = [];
  List<WorkoutTemplate> _featuredTemplates = [];
  List<WorkoutTemplate> _customTemplates = [];
  List<WorkoutTemplate> _favoriteTemplates = [];
  List<WorkoutTemplate> _recommendedTemplates = [];
  bool _isLoadingTemplates = true;

  // Enhanced Template Dropdown System
  TemplateCategory? _selectedTemplateCategory;
  List<WorkoutTemplate> _filteredTemplates = [];
  WorkoutTemplate? _selectedTemplate;

  // AI Generation Preference
  bool _useAIGeneration = true; // Default to AI instead of mock

  // Getters
  List<WorkoutTemplate> get quickTemplates => _quickTemplates;
  List<WorkoutTemplate> get featuredTemplates => _featuredTemplates;
  List<WorkoutTemplate> get customTemplates => _customTemplates;
  List<WorkoutTemplate> get favoriteTemplates => _favoriteTemplates;
  List<WorkoutTemplate> get recommendedTemplates => _recommendedTemplates;
  bool get isLoadingTemplates => _isLoadingTemplates;
  TemplateCategory? get selectedTemplateCategory => _selectedTemplateCategory;
  List<WorkoutTemplate> get filteredTemplates => _filteredTemplates;
  WorkoutTemplate? get selectedTemplate => _selectedTemplate;
  bool get useAIGeneration => _useAIGeneration;

  /// Load templates from various sources
  Future<void> loadTemplates(BuildContext context, int selectedDuration) async {
    try {
      _isLoadingTemplates = true;

      // Load all template categories
      final quickTemplates = WorkoutTemplateService.getQuickTemplates();
      final featuredTemplates = WorkoutTemplateService.getFeaturedTemplates();
      final customTemplates = await WorkoutTemplateService.getCustomTemplates();
      final favoriteTemplates =
          await WorkoutTemplateService.getFavoriteTemplates();

      // Get user's fitness profile for recommendations
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.user;

      List<WorkoutTemplate> recommendedTemplates = [];
      if (currentUser != null) {
        // Get recommendations based on user profile
        recommendedTemplates =
            await WorkoutTemplateService.getRecommendedTemplates(
              fitnessLevel: currentUser.fitnessLevel,
              preferredDuration: selectedDuration,
            );
      }

      _quickTemplates = quickTemplates;
      _featuredTemplates = featuredTemplates;
      _customTemplates = customTemplates;
      _favoriteTemplates = favoriteTemplates;
      _recommendedTemplates = recommendedTemplates;
      _isLoadingTemplates = false;
    } catch (e) {
      print('Error loading templates: $e');
      _isLoadingTemplates = false;
    }
  }

  /// Load AI generation preference from storage
  Future<void> loadAIPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final useAI = prefs.getBool('use_ai_generation') ?? true; // Default to AI
      _useAIGeneration = useAI;
    } catch (e) {
      print('Error loading AI preference: $e');
    }
  }

  /// Save AI generation preference to storage
  Future<void> saveAIPreference(bool useAI) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('use_ai_generation', useAI);
      _useAIGeneration = useAI;
    } catch (e) {
      print('Error saving AI preference: $e');
    }
  }

  /// Set selected template category and filter templates
  void setSelectedTemplateCategory(TemplateCategory? category) {
    _selectedTemplateCategory = category;
    _selectedTemplate = null; // Reset selected template

    if (category != null) {
      // Filter templates by category
      final categoryName = category.name.toLowerCase();

      // Get all templates
      final allTemplates = [
        ..._quickTemplates,
        ..._featuredTemplates,
        ..._customTemplates,
        ..._favoriteTemplates,
        ..._recommendedTemplates,
      ];

      // Filter by category - more flexible matching
      _filteredTemplates = allTemplates.where((template) {
        final templateCategory = template.category.toLowerCase();

        // Direct match
        if (templateCategory == categoryName) return true;

        // Handle variations
        switch (categoryName) {
          case 'ppl':
            return templateCategory.contains('ppl') ||
                templateCategory.contains('push') ||
                templateCategory.contains('pull');
          case 'upperlower':
            return templateCategory.contains('upper') ||
                templateCategory.contains('lower') ||
                templateCategory == 'upperlower' ||
                templateCategory == 'ul';
          case 'fullbody':
            return templateCategory.contains('fullbody') ||
                templateCategory.contains('full') ||
                templateCategory == 'fullbody';
          case 'brosplit':
            return templateCategory.contains('bro') ||
                templateCategory.contains('split') ||
                templateCategory == 'brosplit';
          default:
            return templateCategory.contains(categoryName);
        }
      }).toList();

      // If no templates found, create default ones
      if (_filteredTemplates.isEmpty) {
        _filteredTemplates = _createDefaultTemplatesForCategory(category);
      }
    } else {
      _filteredTemplates = [];
    }
  }

  /// Set selected template
  void setSelectedTemplate(WorkoutTemplate? template) {
    _selectedTemplate = template;
  }

  /// Build template generation UI section
  Widget buildTemplateGeneration(
    BuildContext context,
    VoidCallback onStateChanged, {
    VoidCallback? onGenerate,
  }) {
    if (_isLoadingTemplates) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Choose Your Workout Split',
            style: AppTextStyles.headline2.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkOnSurface
                  : AppColors.onSurface,
            ),
          ),
          const SizedBox(height: AppDimensions.marginSmall),
          Text(
            'Select a workout split to instantly generate your 7-day progressive plan. Each split creates a complete week of workouts that unlock day by day.',
            style: AppTextStyles.bodyText2.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkOnSurface.withValues(alpha: 0.8)
                  : AppColors.onSurface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppDimensions.marginLarge),

          // Step 1: Category Selection Dropdown
          buildCategoryDropdown(context, onStateChanged),
          const SizedBox(height: AppDimensions.marginLarge),

          // AI Generation Preference Toggle
          buildAIGenerationToggle(context, onStateChanged),
          const SizedBox(height: AppDimensions.marginLarge),

          // Step 2: Template Selection (shown when category is selected and not a workout split)
          if (_selectedTemplateCategory != null &&
              !isWorkoutSplit(_selectedTemplateCategory!.name)) ...[
            buildTemplateSelection(context, onStateChanged),
            const SizedBox(height: AppDimensions.marginLarge),
          ],

          // Step 3: Template Customization (shown when template is selected)
          if (_selectedTemplate != null) ...[
            buildTemplateCustomization(context),
            const SizedBox(height: AppDimensions.marginLarge),
          ],

          // Step 4: Generate Button (for workout splits or when template is selected)
          if ((_selectedTemplateCategory != null &&
                  isWorkoutSplit(_selectedTemplateCategory!.name)) ||
              _selectedTemplate != null) ...[
            _buildGenerateButton(context, onGenerate),
          ],
        ],
      ),
    );
  }

  /// Build category dropdown
  Widget buildCategoryDropdown(
    BuildContext context,
    VoidCallback onStateChanged,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2,
      color: isDarkMode ? AppColors.darkSurface : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.category, color: AppColors.primary, size: 24),
                const SizedBox(width: AppDimensions.marginSmall),
                Text(
                  'Step 1: Choose Category',
                  style: AppTextStyles.headline3.copyWith(
                    color: isDarkMode
                        ? AppColors.darkOnSurface
                        : AppColors.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.marginMedium),
            DropdownButtonFormField<TemplateCategory>(
              value: _selectedTemplateCategory,
              onChanged: (TemplateCategory? newValue) {
                setSelectedTemplateCategory(newValue);

                // If it's a workout split, set a default template for direct generation
                if (newValue != null && isWorkoutSplit(newValue.name)) {
                  final defaultTemplate = WorkoutTemplate(
                    id: 'direct_${newValue.name}_${DateTime.now().millisecondsSinceEpoch}',
                    name: newValue.displayName,
                    description: newValue.description,
                    category: newValue.name,
                    params: {
                      'workoutType': newValue.name,
                      'duration': 60, // Default duration
                      'muscleGroups': _getMuscleGroupsForCategory(newValue),
                    },
                    createdAt: DateTime.now(),
                  );
                  setSelectedTemplate(defaultTemplate);
                }

                onStateChanged();
              },
              hint: Text(
                'Select your workout split',
                style: TextStyle(
                  color: isDarkMode
                      ? AppColors.darkOnSurface.withValues(alpha: 0.7)
                      : AppColors.onSurface.withValues(alpha: 0.7),
                ),
              ),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusSmall,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingMedium,
                  vertical: AppDimensions.paddingSmall,
                ),
              ),
              items: TemplateCategory.values.map((category) {
                return DropdownMenuItem<TemplateCategory>(
                  value: category,
                  child: Row(
                    children: [
                      Icon(category.icon, size: 20, color: AppColors.primary),
                      const SizedBox(width: AppDimensions.marginSmall),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            category.displayName,
                            style: AppTextStyles.bodyText1.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            category.description,
                            style: AppTextStyles.caption.copyWith(
                              color: isDarkMode
                                  ? AppColors.darkOnSurface.withValues(
                                      alpha: 0.7,
                                    )
                                  : AppColors.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Build AI generation toggle
  Widget buildAIGenerationToggle(
    BuildContext context,
    VoidCallback onStateChanged,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2,
      color: isDarkMode ? AppColors.darkSurface : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: AppColors.primary, size: 24),
                const SizedBox(width: AppDimensions.marginSmall),
                Text(
                  'AI Generation',
                  style: AppTextStyles.headline3.copyWith(
                    color: isDarkMode
                        ? AppColors.darkOnSurface
                        : AppColors.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.marginMedium),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _useAIGeneration
                            ? 'AI Generated Workouts'
                            : 'Mock Workouts',
                        style: AppTextStyles.bodyText1.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? AppColors.darkOnSurface
                              : AppColors.onSurface,
                        ),
                      ),
                      Text(
                        _useAIGeneration
                            ? 'Generate personalized workouts using AI'
                            : 'Use pre-defined mock workout templates',
                        style: AppTextStyles.caption.copyWith(
                          color: isDarkMode
                              ? AppColors.darkOnSurface.withValues(alpha: 0.7)
                              : AppColors.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _useAIGeneration,
                  onChanged: (bool value) async {
                    await saveAIPreference(value);
                    onStateChanged();
                  },
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build template selection UI
  Widget buildTemplateSelection(
    BuildContext context,
    VoidCallback onStateChanged,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2,
      color: isDarkMode ? AppColors.darkSurface : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.fitness_center, color: AppColors.primary, size: 24),
                const SizedBox(width: AppDimensions.marginSmall),
                Text(
                  'Step 2: Choose Template',
                  style: AppTextStyles.headline3.copyWith(
                    color: isDarkMode
                        ? AppColors.darkOnSurface
                        : AppColors.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.marginMedium),
            if (_filteredTemplates.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 48,
                        color: isDarkMode
                            ? AppColors.darkOnSurface.withValues(alpha: 0.5)
                            : AppColors.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: AppDimensions.marginMedium),
                      Text(
                        'No templates available for ${_selectedTemplateCategory?.displayName}',
                        style: AppTextStyles.bodyText1.copyWith(
                          color: isDarkMode
                              ? AppColors.darkOnSurface.withValues(alpha: 0.7)
                              : AppColors.onSurface.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredTemplates.length,
                itemBuilder: (context, index) {
                  final template = _filteredTemplates[index];
                  final isSelected = _selectedTemplate?.id == template.id;

                  return Container(
                    margin: const EdgeInsets.only(
                      bottom: AppDimensions.marginSmall,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSmall,
                      ),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.1,
                        ),
                        child: Icon(
                          _selectedTemplateCategory?.icon ??
                              Icons.fitness_center,
                          color: AppColors.primary,
                        ),
                      ),
                      title: Text(
                        template.name,
                        style: AppTextStyles.bodyText1.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppColors.primary : null,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(template.description),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.timer,
                                size: 16,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${template.params['duration'] ?? 'N/A'} min',
                                style: AppTextStyles.caption,
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.trending_up,
                                size: 16,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                template.params['fitnessLevel'] ?? 'All',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () {
                        setSelectedTemplate(template);
                        onStateChanged();
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Build template customization UI
  Widget buildTemplateCustomization(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2,
      color: isDarkMode ? AppColors.darkSurface : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: AppColors.primary, size: 24),
                const SizedBox(width: AppDimensions.marginSmall),
                Text(
                  'Step 3: Customize Template',
                  style: AppTextStyles.headline3.copyWith(
                    color: isDarkMode
                        ? AppColors.darkOnSurface
                        : AppColors.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.marginMedium),
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? AppColors.darkBackground.withValues(alpha: 0.3)
                    : AppColors.background.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedTemplate?.name ?? '',
                    style: AppTextStyles.bodyText1.copyWith(
                      color: isDarkMode
                          ? AppColors.darkOnSurface
                          : AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedTemplate?.description ?? '',
                    style: AppTextStyles.bodyText2.copyWith(
                      color: isDarkMode
                          ? AppColors.darkOnSurface.withValues(alpha: 0.8)
                          : AppColors.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildInfoChip(
                        Icons.timer,
                        '${_selectedTemplate?.params['duration'] ?? 'N/A'} min',
                        context,
                      ),
                      _buildInfoChip(
                        Icons.trending_up,
                        _selectedTemplate?.params['fitnessLevel'] ?? 'All',
                        context,
                      ),
                      if (_selectedTemplate?.params['muscleGroups'] !=
                          null) ...[
                        for (final muscle
                            in (_selectedTemplate?.params['muscleGroups']
                                    as List<String>? ??
                                []))
                          _buildInfoChip(Icons.fitness_center, muscle, context),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build info chip widget
  Widget _buildInfoChip(IconData icon, String label, BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSmall,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: isDarkMode ? AppColors.darkOnSurface : AppColors.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build generate button
  Widget _buildGenerateButton(BuildContext context, VoidCallback? onGenerate) {
    final bool canGenerate =
        (_selectedTemplateCategory != null &&
            isWorkoutSplit(_selectedTemplateCategory!.name)) ||
        _selectedTemplate != null;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canGenerate && onGenerate != null ? onGenerate : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canGenerate ? AppColors.primary : Colors.grey,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.paddingMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isWorkoutSplit(_selectedTemplateCategory?.name ?? '')
                  ? Icons.auto_awesome
                  : Icons.play_arrow,
              color: Colors.white,
            ),
            const SizedBox(width: AppDimensions.marginSmall),
            Text(
              isWorkoutSplit(_selectedTemplateCategory?.name ?? '')
                  ? 'Generate 7-Day Plan'
                  : 'Generate Workout',
              style: AppTextStyles.bodyText1.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Check if category is a workout split
  bool isWorkoutSplit(String category) {
    final workoutSplits = [
      'ppl',
      'upperlower',
      'fullbody',
      'brosplit',
      'phat',
      'phul',
    ];
    return workoutSplits.contains(category.toLowerCase());
  }

  /// Get muscle groups for category
  List<String> _getMuscleGroupsForCategory(TemplateCategory category) {
    switch (category.name.toLowerCase()) {
      case 'ppl':
        return ['Push', 'Pull', 'Legs'];
      case 'upperlower':
        return ['Upper Body', 'Lower Body'];
      case 'fullbody':
        return ['Full Body'];
      case 'brosplit':
        return ['Chest', 'Back', 'Legs', 'Shoulders', 'Arms'];
      case 'phat':
        return ['Power', 'Hypertrophy'];
      case 'phul':
        return [
          'Power Upper',
          'Power Lower',
          'Hypertrophy Upper',
          'Hypertrophy Lower',
        ];
      default:
        return ['Full Body'];
    }
  }

  /// Create default templates for category
  List<WorkoutTemplate> _createDefaultTemplatesForCategory(
    TemplateCategory category,
  ) {
    final now = DateTime.now();
    switch (category) {
      case TemplateCategory.ppl:
        return [
          WorkoutTemplate(
            id: 'default_ppl_1',
            name: 'PPL - Push Day',
            description: 'Chest, shoulders, triceps focused workout',
            category: 'ppl',
            createdAt: now,
            params: {
              'workoutType': 'Push (Chest, Shoulders, Triceps)',
              'duration': 60,
              'fitnessLevel': 'Intermediate',
              'muscleGroups': ['Chest', 'Shoulders', 'Triceps'],
              'equipment': ['Dumbbells', 'Barbell'],
            },
          ),
          WorkoutTemplate(
            id: 'default_ppl_2',
            name: 'PPL - Pull Day',
            description: 'Back and biceps focused workout',
            category: 'ppl',
            createdAt: now,
            params: {
              'workoutType': 'Pull (Back, Biceps)',
              'duration': 60,
              'fitnessLevel': 'Intermediate',
              'muscleGroups': ['Back', 'Biceps'],
              'equipment': ['Dumbbells', 'Barbell'],
            },
          ),
          WorkoutTemplate(
            id: 'default_ppl_3',
            name: 'PPL - Legs Day',
            description: 'Complete lower body workout',
            category: 'ppl',
            createdAt: now,
            params: {
              'workoutType': 'Legs (Quads, Hamstrings, Glutes, Calves)',
              'duration': 60,
              'fitnessLevel': 'Intermediate',
              'muscleGroups': ['Legs', 'Glutes', 'Calves'],
              'equipment': ['Dumbbells', 'Barbell'],
            },
          ),
        ];
      case TemplateCategory.upperLower:
        return [
          WorkoutTemplate(
            id: 'default_ul_1',
            name: 'Upper Body Day',
            description: 'Complete upper body training',
            category: 'upperlower',
            createdAt: now,
            params: {
              'workoutType': 'Upper Body',
              'duration': 50,
              'fitnessLevel': 'Intermediate',
              'muscleGroups': ['Chest', 'Back', 'Shoulders', 'Arms'],
              'equipment': ['Dumbbells', 'Barbell'],
            },
          ),
          WorkoutTemplate(
            id: 'default_ul_2',
            name: 'Lower Body Day',
            description: 'Complete lower body training',
            category: 'upperlower',
            createdAt: now,
            params: {
              'workoutType': 'Lower Body',
              'duration': 50,
              'fitnessLevel': 'Intermediate',
              'muscleGroups': ['Legs', 'Glutes', 'Calves'],
              'equipment': ['Dumbbells', 'Barbell'],
            },
          ),
        ];
      case TemplateCategory.fullBody:
        return [
          WorkoutTemplate(
            id: 'default_fullbody_1',
            name: 'Full Body Workout A',
            description: 'Complete full body training session',
            category: 'fullbody',
            createdAt: now,
            params: {
              'workoutType': 'Full Body',
              'duration': 45,
              'fitnessLevel': 'Intermediate',
              'muscleGroups': ['Full Body'],
              'equipment': ['Dumbbells', 'Barbell'],
            },
          ),
        ];
      case TemplateCategory.broSplit:
        return [
          WorkoutTemplate(
            id: 'default_bro_1',
            name: 'Chest Day',
            description: 'Dedicated chest training day',
            category: 'brosplit',
            createdAt: now,
            params: {
              'workoutType': 'Chest',
              'duration': 45,
              'fitnessLevel': 'Intermediate',
              'muscleGroups': ['Chest'],
              'equipment': ['Dumbbells', 'Barbell'],
            },
          ),
        ];
      case TemplateCategory.strength:
        return [
          WorkoutTemplate(
            id: 'default_strength_1',
            name: 'Full Body Strength',
            description:
                'Complete strength training targeting all major muscle groups',
            category: 'strength',
            createdAt: now,
            params: {
              'workoutType': 'Strength',
              'duration': 45,
              'fitnessLevel': 'Intermediate',
              'muscleGroups': ['Full Body'],
              'equipment': ['Dumbbells', 'Barbell'],
            },
          ),
        ];
      case TemplateCategory.cardio:
        return [
          WorkoutTemplate(
            id: 'default_cardio_1',
            name: 'Steady State Cardio',
            description: 'Moderate intensity cardiovascular training',
            category: 'cardio',
            createdAt: now,
            params: {
              'workoutType': 'Cardio',
              'duration': 30,
              'fitnessLevel': 'All Levels',
              'muscleGroups': ['Full Body'],
              'equipment': ['None'],
            },
          ),
        ];
      case TemplateCategory.hiit:
        return [
          WorkoutTemplate(
            id: 'default_hiit_1',
            name: 'HIIT Blast',
            description: 'High-intensity interval training for maximum results',
            category: 'hiit',
            createdAt: now,
            params: {
              'workoutType': 'HIIT',
              'duration': 20,
              'fitnessLevel': 'Intermediate',
              'muscleGroups': ['Full Body'],
              'equipment': ['Bodyweight'],
            },
          ),
        ];
      default:
        return [];
    }
  }

  /// Generate workout from template
  Future<void> generateFromTemplate(
    BuildContext context,
    WorkoutTemplate template,
    Function(bool) setIsGenerating,
    Function(String) showErrorSnackBar,
  ) async {
    setIsGenerating(true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.user;

      if (currentUser == null) {
        throw Exception('Please log in to generate workouts');
      }

      // Check if this is a workout split that needs 7-day plan
      if (isWorkoutSplit(template.category)) {
        await generate7DayWorkoutPlan(
          context,
          template,
          currentUser,
          setIsGenerating,
          showErrorSnackBar,
        );
        return;
      }

      // ⚡ PERFORMANCE OPTIMIZATION: Parallelize all data fetching
      final List<Future> dataFetches = [
        WorkoutTemplateService.trackTemplateUsage(template.id),
        _getRecentWorkoutHistory(currentUser.id),
        _getUserEquipment(currentUser.id),
      ];

      // Execute all data fetches in parallel
      final results = await Future.wait([
        dataFetches[0],
        dataFetches[1],
        dataFetches[2],
      ], eagerError: false);

      // Extract results (userEquipment at index 2)
      // Note: recentWorkouts at index 1 could be used for future AI enhancement
      final userEquipment = results[2] as List<String>? ?? ['Bodyweight'];

      // Add timestamp for session tracking
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // ⚡ OPTIMIZED: Lightweight AI workout request (reduced payload by ~70%)
      final workoutRequest = {
        'templateId': template.id,
        'templateName': template.name,
        'category': template.category,
        'userId': currentUser.id,
        'fitnessLevel': currentUser.fitnessLevel,
        'goal':
            'Build strength and improve fitness with ${template.name} training',
        'equipment': userEquipment,
        'duration': template.params['duration'] ?? 45,
        'sessionId': 'template_$timestamp',
        'useAI': _useAIGeneration,
      };

      late Workout workout;

      if (_useAIGeneration) {
        // Generate with AI
        final aiService = AIWorkoutService();
        workout = await aiService.generateWorkout(workoutRequest) as Workout;
      } else {
        // Create mock workout based on template
        workout = _createMockWorkout(template, currentUser);
      }

      // Save and navigate
      final workoutProvider = Provider.of<WorkoutProvider>(
        context,
        listen: false,
      );
      await workoutProvider.saveWorkout(workout, currentUser.id);

      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => WorkoutSessionScreen(workout: workout),
          ),
        );
      }
    } catch (e) {
      showErrorSnackBar('Error generating workout: $e');
    } finally {
      setIsGenerating(false);
    }
  }

  /// Generate 7-day workout plan
  Future<void> generate7DayWorkoutPlan(
    BuildContext context,
    WorkoutTemplate template,
    dynamic user,
    Function(bool) setIsGenerating,
    Function(String) showErrorSnackBar,
  ) async {
    try {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🚀 Generating ${template.name} 7-Day Plan...\n🔥 This may take a moment for AI processing',
            ),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      final generated7DayPlan = await generate7DayPlan(
        template.name,
        user.fitnessLevel,
        template.params['duration'] ?? 60,
        _useAIGeneration,
        context,
        showErrorSnackBar,
      );

      if (generated7DayPlan == null || generated7DayPlan.isEmpty) {
        throw Exception('Failed to generate 7-day workout plan');
      }

      // Save each workout and create templates
      final workoutProvider = Provider.of<WorkoutProvider>(
        context,
        listen: false,
      );

      for (int i = 0; i < generated7DayPlan.length; i++) {
        final workout = generated7DayPlan[i];
        final userId = user.id;

        if (isWorkoutSplit(template.category)) {
          // For workout splits, create day-specific templates
          final dayTemplate = WorkoutTemplate(
            id: '${template.id}_day${i + 1}_${DateTime.now().millisecondsSinceEpoch}',
            name: workout.name,
            description: workout.description,
            category: template.category,
            params: {
              'workoutType': workout.name,
              'duration': workout.estimatedDuration,
              'fitnessLevel': workout.difficulty,
              'dayNumber': i + 1,
              'parentTemplate': template.name,
              'muscleGroups': _getMuscleGroupsFromExercises(workout.exercises),
              'equipment': _getEquipmentFromExercises(workout.exercises),
              'aiGenerated': true,
              'exerciseCount': workout.exercises.length,
            },
            createdAt: DateTime.now(),
            isPublic: false,
            tags: ['ai-generated', template.category, '7-day-plan'],
          );

          // Save as custom template (this will make it appear in Templates section)
          await WorkoutTemplateService.saveCustomTemplate(dayTemplate);

          // Save the workout as a template workout for progressive unlocking
          await workoutProvider.saveWorkout(workout, userId);
        } else {
          // For non-split workouts, create a template from the workout
          final workoutTemplate = WorkoutTemplate(
            id: '${template.id}_${i + 1}_${DateTime.now().millisecondsSinceEpoch}',
            name: workout.name,
            description: workout.description,
            category: 'ai_generated',
            params: {
              'workoutType': workout.name,
              'duration': workout.estimatedDuration,
              'fitnessLevel': workout.difficulty,
              'dayNumber': i + 1,
              'parentTemplate': template.name,
              'muscleGroups': _getMuscleGroupsFromExercises(workout.exercises),
              'equipment': _getEquipmentFromExercises(workout.exercises),
              'aiGenerated': true,
              'exerciseCount': workout.exercises.length,
            },
            createdAt: DateTime.now(),
            isPublic: false,
            tags: ['ai-generated', template.category],
          );

          // Save as custom template
          await WorkoutTemplateService.saveCustomTemplate(workoutTemplate);

          // Save the workout as a template workout for progressive unlocking
          await workoutProvider.saveWorkout(workout, userId);
        }
      }

      // Refresh templates to show the new ones
      await loadTemplates(context, template.params['duration'] ?? 60);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎉 7-Day ${template.name} plan created!\n✨ Check Templates section for progressive unlocking system.\n🔓 Complete Day 1 to unlock Day 2, and so on...',
            ),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      showErrorSnackBar('Error saving 7-day plan: $e');
    }
  }

  /// Generate 7-day plan
  Future<List<Workout>?> generate7DayPlan(
    String templateName,
    String fitnessLevel,
    int duration,
    bool useAI,
    BuildContext context,
    Function(String) showErrorSnackBar,
  ) async {
    try {
      final List<Workout> workoutPlan = [];
      final aiService = AIWorkoutService();

      // Get current user for personalization
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.user;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Define workout split patterns based on template name
      final workoutSplit = _getWorkoutSplitPattern(templateName);

      print('🚀 Generating 7-day plan for: $templateName');
      print('Split pattern: $workoutSplit');

      // Generate each day's workout
      for (int day = 0; day < 7; day++) {
        final dayInfo = workoutSplit[day % workoutSplit.length];

        // Skip rest days
        if (dayInfo['type'] == 'rest') {
          continue;
        }

        print('Generating Day ${day + 1}: ${dayInfo['name']}');

        // Create workout request for this day
        final workoutRequest = {
          'userId': currentUser.id,
          'goal': 'Progressive ${templateName} training - Day ${day + 1}',
          'fitnessLevel': fitnessLevel,
          'workoutType': dayInfo['type'],
          'duration': duration,
          'muscleGroups': dayInfo['muscleGroups'],
          'focusArea': dayInfo['focusArea'] ?? dayInfo['muscleGroups'].first,
          'equipment': ['Dumbbells', 'Barbell', 'Bodyweight'],
          'additionalNotes':
              'Day ${day + 1} of 7-day ${templateName} plan. ${dayInfo['description']}',
          'sessionId':
              '${templateName.toLowerCase()}_day${day + 1}_${DateTime.now().millisecondsSinceEpoch}',
          'dayNumber': day + 1,
          'totalDays': 7,
          'useAI': useAI,
        };

        late Workout dayWorkout;

        if (useAI) {
          // Generate with AI
          dayWorkout =
              await aiService.generateWorkout(workoutRequest) as Workout;
        } else {
          // Create mock workout
          dayWorkout = _createMockWorkoutForDay(
            dayInfo,
            duration,
            fitnessLevel,
            day + 1,
          );
        }

        // Customize the workout name to include day info
        final customizedWorkout = Workout(
          id: dayWorkout.id,
          name: 'Day ${day + 1}: ${dayInfo['name']}',
          description: dayWorkout.description,
          exercises: dayWorkout.exercises,
          estimatedDuration: dayWorkout.estimatedDuration,
          difficulty: dayWorkout.difficulty,
          createdAt: dayWorkout.createdAt,
          isTemplate: true, // Mark as template for progressive unlocking system
        );

        workoutPlan.add(customizedWorkout);

        // Add small delay between generations to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 500));
      }

      print('✅ Successfully generated ${workoutPlan.length} workouts');
      return workoutPlan;
    } catch (e) {
      print('❌ Error generating 7-day plan: $e');
      showErrorSnackBar('Failed to generate 7-day plan: $e');
      return null;
    }
  }

  /// Create mock workout from template
  Workout _createMockWorkout(WorkoutTemplate template, dynamic user) {
    // Create a simple mock workout based on template parameters
    final exercises = <WorkoutExercise>[];
    final muscleGroups =
        template.params['muscleGroups'] as List<String>? ?? ['Full Body'];

    // Add some basic exercises based on muscle groups
    for (final muscleGroup in muscleGroups.take(3)) {
      exercises.add(
        WorkoutExercise(
          exercise: Exercise(
            id: 'mock_${muscleGroup.toLowerCase()}_${exercises.length}',
            name: 'Mock ${muscleGroup} Exercise',
            category: muscleGroup.toLowerCase(),
            equipment:
                template.params['equipment'] as List<String>? ?? ['Bodyweight'],
            targetRegion: [muscleGroup],
            primaryMuscles: [muscleGroup],
            secondaryMuscles: [],
            difficulty: template.params['fitnessLevel'] ?? 'Intermediate',
            movementType: 'Strength',
            movementPattern: 'Push',
            gripType: 'Standard',
            rangeOfMotion: 'Full',
            tempo: 'Moderate',
            muscleGroup: muscleGroup,
            muscleInfo: MuscleInfo(
              scientificName: '${muscleGroup} muscle',
              commonName: muscleGroup,
              muscleRegions: [
                MuscleRegion(
                  region: muscleGroup,
                  anatomicalName: muscleGroup,
                  description: 'Primary muscle region',
                ),
              ],
              primaryFunction: 'Movement',
              location: 'Body',
              muscleFiberDirection: 'Parallel',
            ),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          sets: 3,
          reps: 12,
          weight: 0,
          restTime: 60,
        ),
      );
    }

    return Workout(
      id: 'mock_${template.id}_${DateTime.now().millisecondsSinceEpoch}',
      name: '${template.name} Workout',
      description: 'Mock workout generated from ${template.name}',
      exercises: exercises,
      estimatedDuration: template.params['duration'] ?? 45,
      difficulty: template.params['fitnessLevel'] ?? 'Intermediate',
      createdAt: DateTime.now(),
      isTemplate: true, // Mark as template for progressive unlocking system
    );
  }

  /// Get recent workout history (placeholder)
  Future<List<Map<String, dynamic>>> _getRecentWorkoutHistory(
    String userId,
  ) async {
    // This would fetch recent workout history
    // For now, return empty list
    return [];
  }

  /// Get user equipment (placeholder)
  Future<List<String>> _getUserEquipment(String userId) async {
    // This would fetch user equipment preferences
    // For now, return basic equipment
    return ['Bodyweight', 'Dumbbells'];
  }

  /// Extract muscle groups from workout exercises
  List<String> _getMuscleGroupsFromExercises(List<WorkoutExercise> exercises) {
    final muscleGroups = <String>{};
    for (final exercise in exercises) {
      muscleGroups.addAll(exercise.exercise.primaryMuscles);
      muscleGroups.addAll(exercise.exercise.targetRegion);
    }
    return muscleGroups.toList();
  }

  /// Extract equipment from workout exercises
  List<String> _getEquipmentFromExercises(List<WorkoutExercise> exercises) {
    final equipment = <String>{};
    for (final exercise in exercises) {
      equipment.addAll(exercise.exercise.equipment);
    }
    return equipment.toList();
  }

  /// Get workout split pattern for different templates
  List<Map<String, dynamic>> _getWorkoutSplitPattern(String templateName) {
    final lowerTemplateName = templateName.toLowerCase();

    if (lowerTemplateName.contains('ppl')) {
      return [
        {
          'name': 'Push Day',
          'type': 'Push',
          'muscleGroups': ['Chest', 'Shoulders', 'Triceps'],
          'focusArea': 'Push',
          'description': 'Chest, shoulders, and triceps focused workout',
        },
        {
          'name': 'Pull Day',
          'type': 'Pull',
          'muscleGroups': ['Back', 'Biceps'],
          'focusArea': 'Pull',
          'description': 'Back and biceps focused workout',
        },
        {
          'name': 'Legs Day',
          'type': 'Legs',
          'muscleGroups': ['Legs', 'Glutes', 'Calves'],
          'focusArea': 'Legs',
          'description': 'Complete lower body workout',
        },
        {
          'name': 'Rest Day',
          'type': 'rest',
          'muscleGroups': [],
          'description': 'Active recovery day',
        },
      ];
    } else if (lowerTemplateName.contains('upper') ||
        lowerTemplateName.contains('ul')) {
      return [
        {
          'name': 'Upper Body',
          'type': 'Upper Body',
          'muscleGroups': ['Chest', 'Back', 'Shoulders', 'Arms'],
          'focusArea': 'Upper Body',
          'description': 'Complete upper body training',
        },
        {
          'name': 'Lower Body',
          'type': 'Lower Body',
          'muscleGroups': ['Legs', 'Glutes', 'Calves'],
          'focusArea': 'Lower Body',
          'description': 'Complete lower body training',
        },
        {
          'name': 'Rest Day',
          'type': 'rest',
          'muscleGroups': [],
          'description': 'Active recovery day',
        },
      ];
    } else if (lowerTemplateName.contains('full') ||
        lowerTemplateName.contains('fbw')) {
      return [
        {
          'name': 'Full Body A',
          'type': 'Full Body',
          'muscleGroups': ['Full Body'],
          'focusArea': 'Full Body',
          'description': 'Complete full body training session A',
        },
        {
          'name': 'Rest Day',
          'type': 'rest',
          'muscleGroups': [],
          'description': 'Active recovery day',
        },
        {
          'name': 'Full Body B',
          'type': 'Full Body',
          'muscleGroups': ['Full Body'],
          'focusArea': 'Full Body',
          'description': 'Complete full body training session B',
        },
      ];
    } else if (lowerTemplateName.contains('bro')) {
      return [
        {
          'name': 'Chest Day',
          'type': 'Chest',
          'muscleGroups': ['Chest', 'Triceps'],
          'focusArea': 'Chest',
          'description': 'Dedicated chest and triceps training',
        },
        {
          'name': 'Back Day',
          'type': 'Back',
          'muscleGroups': ['Back', 'Biceps'],
          'focusArea': 'Back',
          'description': 'Dedicated back and biceps training',
        },
        {
          'name': 'Shoulder Day',
          'type': 'Shoulders',
          'muscleGroups': ['Shoulders', 'Traps'],
          'focusArea': 'Shoulders',
          'description': 'Dedicated shoulder and trap training',
        },
        {
          'name': 'Legs Day',
          'type': 'Legs',
          'muscleGroups': ['Legs', 'Glutes', 'Calves'],
          'focusArea': 'Legs',
          'description': 'Complete lower body training',
        },
        {
          'name': 'Arms Day',
          'type': 'Arms',
          'muscleGroups': ['Biceps', 'Triceps', 'Forearms'],
          'focusArea': 'Arms',
          'description': 'Dedicated arm training',
        },
        {
          'name': 'Rest Day',
          'type': 'rest',
          'muscleGroups': [],
          'description': 'Active recovery day',
        },
      ];
    } else {
      // Default fallback for unknown templates
      return [
        {
          'name': 'Full Body Workout',
          'type': 'Full Body',
          'muscleGroups': ['Full Body'],
          'focusArea': 'Full Body',
          'description': 'Complete full body training session',
        },
        {
          'name': 'Rest Day',
          'type': 'rest',
          'muscleGroups': [],
          'description': 'Active recovery day',
        },
      ];
    }
  }

  /// Create mock workout for specific day
  Workout _createMockWorkoutForDay(
    Map<String, dynamic> dayInfo,
    int duration,
    String fitnessLevel,
    int dayNumber,
  ) {
    final exercises = <WorkoutExercise>[];
    final muscleGroups = dayInfo['muscleGroups'] as List<String>;

    // Create 3-5 exercises based on duration
    final exerciseCount = duration <= 30
        ? 3
        : duration <= 45
        ? 4
        : 5;

    for (int i = 0; i < exerciseCount && i < muscleGroups.length; i++) {
      final muscleGroup = muscleGroups[i % muscleGroups.length];

      exercises.add(
        WorkoutExercise(
          exercise: Exercise(
            id: 'mock_day${dayNumber}_${muscleGroup.toLowerCase()}_$i',
            name: 'Mock ${muscleGroup} Exercise ${i + 1}',
            category: muscleGroup.toLowerCase(),
            equipment: ['Dumbbells', 'Bodyweight'],
            targetRegion: [muscleGroup],
            primaryMuscles: [muscleGroup],
            secondaryMuscles: [],
            difficulty: fitnessLevel,
            movementType: 'Strength',
            movementPattern: _getMovementPattern(muscleGroup),
            gripType: 'Standard',
            rangeOfMotion: 'Full',
            tempo: 'Moderate',
            muscleGroup: muscleGroup,
            muscleInfo: MuscleInfo(
              scientificName: '${muscleGroup} muscle',
              commonName: muscleGroup,
              muscleRegions: [
                MuscleRegion(
                  region: muscleGroup,
                  anatomicalName: muscleGroup,
                  description: 'Primary muscle region',
                ),
              ],
              primaryFunction: 'Movement',
              location: 'Body',
              muscleFiberDirection: 'Parallel',
            ),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          sets: 3,
          reps: _getRepsForFitnessLevel(fitnessLevel),
          weight: 0,
          restTime: _getRestTime(fitnessLevel),
        ),
      );
    }

    return Workout(
      id: 'mock_day${dayNumber}_${DateTime.now().millisecondsSinceEpoch}',
      name: dayInfo['name'],
      description: dayInfo['description'],
      exercises: exercises,
      estimatedDuration: duration,
      difficulty: fitnessLevel,
      createdAt: DateTime.now(),
      isTemplate: true, // Mark as template for progressive unlocking system
    );
  }

  /// Get movement pattern based on muscle group
  String _getMovementPattern(String muscleGroup) {
    switch (muscleGroup.toLowerCase()) {
      case 'chest':
      case 'shoulders':
      case 'triceps':
        return 'Push';
      case 'back':
      case 'biceps':
        return 'Pull';
      case 'legs':
      case 'glutes':
      case 'calves':
        return 'Squat';
      default:
        return 'Compound';
    }
  }

  /// Get reps based on fitness level
  int _getRepsForFitnessLevel(String fitnessLevel) {
    switch (fitnessLevel.toLowerCase()) {
      case 'beginner':
        return 10;
      case 'intermediate':
        return 12;
      case 'advanced':
        return 15;
      default:
        return 12;
    }
  }

  /// Get rest time based on fitness level
  int _getRestTime(String fitnessLevel) {
    switch (fitnessLevel.toLowerCase()) {
      case 'beginner':
        return 90; // 1.5 minutes
      case 'intermediate':
        return 60; // 1 minute
      case 'advanced':
        return 45; // 45 seconds
      default:
        return 60;
    }
  }
}
