import 'package:flutter/foundation.dart';
import '../models/workout_template.dart';
import '../services/workout_template_service.dart';

/// Service responsible for managing workout templates
/// Handles loading, filtering, and categorization of templates
class TemplateManagementService extends ChangeNotifier {
  // Template lists
  List<WorkoutTemplate> _quickTemplates = [];
  List<WorkoutTemplate> _featuredTemplates = [];
  final List<WorkoutTemplate> _customTemplates = [];
  final List<WorkoutTemplate> _favoriteTemplates = [];
  final List<WorkoutTemplate> _recommendedTemplates = [];
  List<WorkoutTemplate> _filteredTemplates = [];

  // State
  bool _isLoadingTemplates = true;
  TemplateCategory? _selectedTemplateCategory;
  WorkoutTemplate? _selectedTemplate;

  // Getters
  List<WorkoutTemplate> get quickTemplates => _quickTemplates;
  List<WorkoutTemplate> get featuredTemplates => _featuredTemplates;
  List<WorkoutTemplate> get customTemplates => _customTemplates;
  List<WorkoutTemplate> get favoriteTemplates => _favoriteTemplates;
  List<WorkoutTemplate> get recommendedTemplates => _recommendedTemplates;
  List<WorkoutTemplate> get filteredTemplates => _filteredTemplates;
  List<WorkoutTemplate> get templates => [
    ..._quickTemplates,
    ..._featuredTemplates,
    ..._customTemplates,
    ..._favoriteTemplates,
    ..._recommendedTemplates,
  ];

  bool get isLoadingTemplates => _isLoadingTemplates;
  bool get isLoading => _isLoadingTemplates;
  TemplateCategory? get selectedTemplateCategory => _selectedTemplateCategory;
  WorkoutTemplate? get selectedTemplate => _selectedTemplate;

  List<String> get categories => [
    'All',
    'PPL (Push/Pull/Legs)',
    'UL (Upper/Lower)',
    'Full Body',
    'Bro Split',
    'PHAT',
    'PHUL',
    'Quick',
    'Featured',
    'Strength',
    'Cardio',
    'HIIT',
  ];

  /// Load all templates from the service
  Future<void> loadTemplates() async {
    _isLoadingTemplates = true;
    notifyListeners();

    try {
      // Load templates from different sources
      final quickTemplates = WorkoutTemplateService.getQuickTemplates();
      final featuredTemplates = WorkoutTemplateService.getFeaturedTemplates();
      final customTemplates = await WorkoutTemplateService.getCustomTemplates();
      final favoriteTemplates =
          await WorkoutTemplateService.getFavoriteTemplates();

      final allTemplates = [
        ...quickTemplates,
        ...featuredTemplates,
        ...customTemplates,
        ...favoriteTemplates,
      ];

      _categorizeTemplates(allTemplates);
      _filterTemplatesByCategory();
    } catch (e) {
      debugPrint('Error loading templates: $e');
    } finally {
      _isLoadingTemplates = false;
      notifyListeners();
    }
  }

  /// Categorize templates into different lists
  void _categorizeTemplates(List<WorkoutTemplate> templates) {
    _quickTemplates.clear();
    _featuredTemplates.clear();
    _customTemplates.clear();
    _favoriteTemplates.clear();
    _recommendedTemplates.clear();

    for (final template in templates) {
      // Quick templates
      if (template.category == 'quick') {
        _quickTemplates.add(template);
      }

      // Featured templates
      if (template.category == 'featured' || template.popularity > 100) {
        _featuredTemplates.add(template);
      }

      // Custom templates (non-public templates)
      if (!template.isPublic) {
        _customTemplates.add(template);
      }

      // Favorite templates
      if (template.isFavorite) {
        _favoriteTemplates.add(template);
      }

      // Recommended templates (based on popularity and recent usage)
      if (template.popularity > 150 || template.usageCount > 5) {
        _recommendedTemplates.add(template);
      }
    }

    // Ensure we have some quick templates
    if (_quickTemplates.isEmpty && templates.isNotEmpty) {
      _quickTemplates = templates.take(6).toList();
    }

    // Ensure we have some featured templates
    if (_featuredTemplates.isEmpty && templates.isNotEmpty) {
      _featuredTemplates = templates.take(8).toList();
    }
  }

  /// Filter templates by selected category
  void filterTemplatesByCategory() {
    _filterTemplatesByCategory();
    notifyListeners();
  }

  /// Get templates filtered by category name
  List<WorkoutTemplate> getTemplatesByCategory(String category) {
    if (category == 'All') {
      return templates;
    }

    return templates
        .where(
          (template) =>
              template.category.toLowerCase() == category.toLowerCase(),
        )
        .toList();
  }

  void _filterTemplatesByCategory() {
    if (_selectedTemplateCategory == null) {
      _filteredTemplates = _featuredTemplates;
      return;
    }

    // Get all templates
    final allTemplates = <WorkoutTemplate>[
      ..._quickTemplates,
      ..._featuredTemplates,
      ..._customTemplates,
      ..._favoriteTemplates,
      ..._recommendedTemplates,
    ];

    // Remove duplicates
    final uniqueTemplates = <String, WorkoutTemplate>{};
    for (final template in allTemplates) {
      uniqueTemplates[template.id] = template;
    }

    // Filter by category
    _filteredTemplates = uniqueTemplates.values
        .where(
          (template) => template.category == _selectedTemplateCategory!.name,
        )
        .toList();

    // Sort by popularity
    _filteredTemplates.sort((a, b) {
      return b.popularity.compareTo(a.popularity);
    });
  }

  /// Set selected template category
  void setSelectedTemplateCategory(TemplateCategory? category) {
    _selectedTemplateCategory = category;
    _filterTemplatesByCategory();
    notifyListeners();
  }

  /// Set selected template
  void setSelectedTemplate(WorkoutTemplate? template) {
    _selectedTemplate = template;
    notifyListeners();
  }

  /// Get templates for a specific mode
  List<WorkoutTemplate> getTemplatesForMode(String mode) {
    switch (mode) {
      case 'quick':
        return _quickTemplates;
      case 'featured':
        return _featuredTemplates;
      case 'custom':
        return _customTemplates;
      case 'favorites':
        return _favoriteTemplates;
      default:
        return _featuredTemplates;
    }
  }

  /// Get template categories with counts
  Map<TemplateCategory, int> getTemplateCategoryCounts() {
    final counts = <TemplateCategory, int>{};

    // Get all unique templates
    final allTemplates = <String, WorkoutTemplate>{};
    for (final template in [
      ..._quickTemplates,
      ..._featuredTemplates,
      ..._customTemplates,
      ..._favoriteTemplates,
      ..._recommendedTemplates,
    ]) {
      allTemplates[template.id] = template;
    }

    // Count by category
    for (final template in allTemplates.values) {
      final categoryName = template.category;
      final category = TemplateCategory.values.firstWhere(
        (cat) => cat.name == categoryName,
        orElse: () => TemplateCategory.strength,
      );
      counts[category] = (counts[category] ?? 0) + 1;
    }

    return counts;
  }

  /// Search templates by query
  List<WorkoutTemplate> searchTemplates(String query) {
    if (query.isEmpty) {
      return _filteredTemplates;
    }

    final searchQuery = query.toLowerCase();

    // Get all unique templates
    final allTemplates = <String, WorkoutTemplate>{};
    for (final template in [
      ..._quickTemplates,
      ..._featuredTemplates,
      ..._customTemplates,
      ..._favoriteTemplates,
      ..._recommendedTemplates,
    ]) {
      allTemplates[template.id] = template;
    }

    return allTemplates.values.where((template) {
      return template.name.toLowerCase().contains(searchQuery) ||
          template.description.toLowerCase().contains(searchQuery) ||
          template.category.toLowerCase().contains(searchQuery) ||
          (template.params['muscleGroups'] as List<String>?)?.any(
                (muscle) => muscle.toLowerCase().contains(searchQuery),
              ) ==
              true;
    }).toList();
  }

  /// Toggle template favorite status
  Future<void> toggleTemplateFavorite(WorkoutTemplate template) async {
    try {
      if (template.isFavorite) {
        await WorkoutTemplateService.removeFromFavorites(template.id);
      } else {
        await WorkoutTemplateService.addToFavorites(template);
      }

      // Reload templates to reflect changes
      await loadTemplates();
    } catch (e) {
      debugPrint('Error toggling template favorite: $e');
    }
  }

  /// Create a custom template
  Future<void> createCustomTemplate({
    required String name,
    required String description,
    required TemplateCategory category,
    required Map<String, dynamic> params,
  }) async {
    try {
      final template = WorkoutTemplate(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        description: description,
        category: category.name,
        params: params,
        createdAt: DateTime.now(),
        isPublic: false,
      );

      await WorkoutTemplateService.saveCustomTemplate(template);
      await loadTemplates();
    } catch (e) {
      debugPrint('Error creating custom template: $e');
    }
  }

  /// Delete a custom template
  Future<void> deleteCustomTemplate(String templateId) async {
    try {
      // Note: WorkoutTemplateService doesn't have deleteTemplate method
      // This would need to be implemented in the service
      debugPrint('Delete template functionality not yet implemented');
      await loadTemplates();
    } catch (e) {
      debugPrint('Error deleting custom template: $e');
    }
  }

  /// Get template by ID
  WorkoutTemplate? getTemplateById(String id) {
    // Search through all template lists
    final allTemplates = [
      ..._quickTemplates,
      ..._featuredTemplates,
      ..._customTemplates,
      ..._favoriteTemplates,
      ..._recommendedTemplates,
    ];

    for (final template in allTemplates) {
      if (template.id == id) {
        return template;
      }
    }

    return null;
  }

  /// Get recommended templates based on user preferences
  List<WorkoutTemplate> getRecommendedTemplates({
    String? userFitnessLevel,
    List<String>? preferredMuscleGroups,
    int? preferredDuration,
  }) {
    // Start with all templates
    final allTemplates = <String, WorkoutTemplate>{};
    for (final template in [
      ..._quickTemplates,
      ..._featuredTemplates,
      ..._customTemplates,
      ..._favoriteTemplates,
    ]) {
      allTemplates[template.id] = template;
    }

    var candidates = allTemplates.values.toList();

    // Filter by fitness level
    if (userFitnessLevel != null) {
      candidates = candidates.where((template) {
        final templateLevel = template.params['fitnessLevel'] as String?;
        return templateLevel == null ||
            templateLevel.toLowerCase() == userFitnessLevel.toLowerCase();
      }).toList();
    }

    // Filter by preferred muscle groups
    if (preferredMuscleGroups != null && preferredMuscleGroups.isNotEmpty) {
      candidates = candidates.where((template) {
        final templateMuscles =
            template.params['muscleGroups'] as List<String>?;
        if (templateMuscles == null) return false;

        return preferredMuscleGroups.any(
          (preferred) => templateMuscles.any(
            (muscle) => muscle.toLowerCase().contains(preferred.toLowerCase()),
          ),
        );
      }).toList();
    }

    // Filter by preferred duration (within 15 minutes)
    if (preferredDuration != null) {
      candidates = candidates.where((template) {
        final templateDuration = template.params['duration'] as int?;
        if (templateDuration == null) return true;

        return (templateDuration - preferredDuration).abs() <= 15;
      }).toList();
    }

    // Sort by popularity and usage count
    candidates.sort((a, b) {
      final aScore = a.popularity + (a.usageCount * 10);
      final bScore = b.popularity + (b.usageCount * 10);
      return bScore.compareTo(aScore);
    });

    return candidates.take(6).toList();
  }
}
