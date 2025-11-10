import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_template.dart';

class WorkoutTemplateService {
  static const String _keyCustomTemplates = 'workout_custom_templates';
  static const String _keyFavoriteTemplates = 'workout_favorite_templates';
  static const String _keyTemplateUsage = 'workout_template_usage';

  // Quick Templates - Pre-defined templates for instant generation
  static List<WorkoutTemplate> getQuickTemplates() {
    final now = DateTime.now();

    return [
      WorkoutTemplate(
        id: 'quick_upper_30',
        name: '⚡ Quick Upper Body',
        description: '30-minute focused upper body workout',
        category: 'quick',
        createdAt: now,
        isPublic: true,
        tags: ['upper-body', 'strength', 'quick'],
        params: {
          'workoutType': 'Upper Body',
          'duration': 30,
          'fitnessLevel': 'Intermediate',
          'muscleGroups': ['Chest', 'Back', 'Shoulders', 'Arms'],
          'equipment': ['Dumbbells', 'Barbell'],
          'goal': 'Muscle Building',
        },
      ),

      WorkoutTemplate(
        id: 'quick_lower_35',
        name: '🦵 Lower Body Power',
        description: '35-minute intense lower body session',
        category: 'quick',
        createdAt: now,
        isPublic: true,
        tags: ['lower-body', 'strength', 'power'],
        params: {
          'workoutType': 'Lower Body',
          'duration': 35,
          'fitnessLevel': 'Intermediate',
          'muscleGroups': ['Legs', 'Glutes', 'Calves', 'Core'],
          'equipment': ['Dumbbells', 'Barbell', 'Bodyweight'],
          'goal': 'Strength Building',
        },
      ),

      WorkoutTemplate(
        id: 'quick_fullbody_45',
        name: '💪 Full Body Blast',
        description: '45-minute complete body workout',
        category: 'quick',
        createdAt: now,
        isPublic: true,
        tags: ['full-body', 'strength', 'comprehensive'],
        params: {
          'workoutType': 'Full Body',
          'duration': 45,
          'fitnessLevel': 'Intermediate',
          'muscleGroups': ['Chest', 'Back', 'Legs', 'Arms', 'Core'],
          'equipment': ['Dumbbells', 'Barbell', 'Bodyweight'],
          'goal': 'General Fitness',
        },
      ),

      WorkoutTemplate(
        id: 'quick_hiit_20',
        name: '🔥 HIIT Cardio',
        description: '20-minute high-intensity interval training',
        category: 'quick',
        createdAt: now,
        isPublic: true,
        tags: ['hiit', 'cardio', 'fat-loss'],
        params: {
          'workoutType': 'HIIT',
          'duration': 20,
          'fitnessLevel': 'Intermediate',
          'muscleGroups': ['Full Body'],
          'equipment': ['Bodyweight'],
          'goal': 'Fat Loss',
        },
      ),

      WorkoutTemplate(
        id: 'quick_core_15',
        name: '🎯 Core Focus',
        description: '15-minute targeted core strengthening',
        category: 'quick',
        createdAt: now,
        isPublic: true,
        tags: ['core', 'abs', 'quick'],
        params: {
          'workoutType': 'Core',
          'duration': 15,
          'fitnessLevel': 'All Levels',
          'muscleGroups': ['Core'],
          'equipment': ['Bodyweight', 'Mat'],
          'goal': 'Core Strength',
        },
      ),

      WorkoutTemplate(
        id: 'quick_strength_60',
        name: '🏋️ Strength Training',
        description: '60-minute comprehensive strength workout',
        category: 'quick',
        createdAt: now,
        isPublic: true,
        tags: ['strength', 'powerlifting', 'advanced'],
        params: {
          'workoutType': 'Strength Training',
          'duration': 60,
          'fitnessLevel': 'Advanced',
          'muscleGroups': ['Chest', 'Back', 'Legs', 'Arms'],
          'equipment': ['Barbell', 'Dumbbells', 'Rack'],
          'goal': 'Strength Building',
        },
      ),
    ];
  }

  // Featured Templates - Curated by experts
  static List<WorkoutTemplate> getFeaturedTemplates() {
    final now = DateTime.now();

    return [
      WorkoutTemplate(
        id: 'featured_beginner_program',
        name: '🌟 Beginner\'s Foundation',
        description: 'Perfect starting point for fitness newcomers',
        category: 'featured',
        createdAt: now,
        popularity: 250,
        isPublic: true,
        tags: ['beginner', 'foundation', 'safe'],
        params: {
          'workoutType': 'Full Body',
          'duration': 40,
          'fitnessLevel': 'Beginner',
          'muscleGroups': ['Chest', 'Back', 'Legs', 'Arms'],
          'equipment': ['Dumbbells', 'Bodyweight'],
          'goal': 'General Fitness',
          'specialNotes': 'Focus on form and progression',
        },
      ),

      WorkoutTemplate(
        id: 'featured_athlete_prep',
        name: '🏃 Athletic Performance',
        description: 'Sport-specific conditioning and performance',
        category: 'featured',
        createdAt: now,
        popularity: 180,
        isPublic: true,
        tags: ['athletic', 'performance', 'conditioning'],
        params: {
          'workoutType': 'Athletic Training',
          'duration': 50,
          'fitnessLevel': 'Advanced',
          'muscleGroups': ['Full Body'],
          'equipment': ['Barbell', 'Plyometric', 'Resistance Bands'],
          'goal': 'Athletic Performance',
          'specialNotes': 'Explosive movements and agility',
        },
      ),
    ];
  }

  // Save custom template created by user
  static Future<void> saveCustomTemplate(WorkoutTemplate template) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = await getCustomTemplates();

      // Remove if already exists (update)
      existing.removeWhere((t) => t.id == template.id);
      existing.add(template);

      final jsonString = json.encode(existing.map((t) => t.toJson()).toList());
      await prefs.setString(_keyCustomTemplates, jsonString);
    } catch (e) {
      print('Error saving custom template: $e');
    }
  }

  // Get user's custom templates
  static Future<List<WorkoutTemplate>> getCustomTemplates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyCustomTemplates);

      if (jsonString != null) {
        final List<dynamic> decoded = json.decode(jsonString);
        return decoded.map((item) => WorkoutTemplate.fromJson(item)).toList();
      }
    } catch (e) {
      print('Error loading custom templates: $e');
    }
    return [];
  }

  // Add template to favorites
  static Future<void> addToFavorites(WorkoutTemplate template) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = await getFavoriteTemplates();

      if (!existing.any((t) => t.id == template.id)) {
        final favoriteTemplate = template.copyWith(
          isFavorite: true,
          lastUsed: DateTime.now(),
        );
        existing.add(favoriteTemplate);

        final jsonString = json.encode(
          existing.map((t) => t.toJson()).toList(),
        );
        await prefs.setString(_keyFavoriteTemplates, jsonString);
      }
    } catch (e) {
      print('Error adding to favorites: $e');
    }
  }

  // Remove from favorites
  static Future<void> removeFromFavorites(String templateId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = await getFavoriteTemplates();

      existing.removeWhere((t) => t.id == templateId);

      final jsonString = json.encode(existing.map((t) => t.toJson()).toList());
      await prefs.setString(_keyFavoriteTemplates, jsonString);
    } catch (e) {
      print('Error removing from favorites: $e');
    }
  }

  // Get favorite templates
  static Future<List<WorkoutTemplate>> getFavoriteTemplates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyFavoriteTemplates);

      if (jsonString != null) {
        final List<dynamic> decoded = json.decode(jsonString);
        return decoded.map((item) => WorkoutTemplate.fromJson(item)).toList();
      }
    } catch (e) {
      print('Error loading favorite templates: $e');
    }
    return [];
  }

  // Track template usage
  static Future<void> trackTemplateUsage(String templateId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyTemplateUsage);

      Map<String, dynamic> usage = {};
      if (jsonString != null) {
        usage = json.decode(jsonString);
      }

      final now = DateTime.now().toIso8601String();
      usage[templateId] = {
        'count': (usage[templateId]?['count'] ?? 0) + 1,
        'lastUsed': now,
        'dates': [...(usage[templateId]?['dates'] ?? []), now],
      };

      await prefs.setString(_keyTemplateUsage, json.encode(usage));
    } catch (e) {
      print('Error tracking template usage: $e');
    }
  }

  // Get template usage statistics
  static Future<Map<String, dynamic>> getTemplateUsage(
    String templateId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyTemplateUsage);

      if (jsonString != null) {
        final Map<String, dynamic> usage = json.decode(jsonString);
        return usage[templateId] ?? {'count': 0, 'lastUsed': null, 'dates': []};
      }
    } catch (e) {
      print('Error getting template usage: $e');
    }
    return {'count': 0, 'lastUsed': null, 'dates': []};
  }

  // Get all templates by category
  static Future<List<WorkoutTemplate>> getTemplatesByCategory(
    String category,
  ) async {
    switch (category.toLowerCase()) {
      case 'quick':
        return getQuickTemplates();
      case 'featured':
        return getFeaturedTemplates();
      case 'custom':
        return await getCustomTemplates();
      case 'favorites':
        return await getFavoriteTemplates();
      default:
        return [];
    }
  }

  // Search templates
  static Future<List<WorkoutTemplate>> searchTemplates(String query) async {
    final allTemplates = [
      ...getQuickTemplates(),
      ...getFeaturedTemplates(),
      ...await getCustomTemplates(),
    ];

    final queryLower = query.toLowerCase();
    return allTemplates.where((template) {
      return template.name.toLowerCase().contains(queryLower) ||
          template.description.toLowerCase().contains(queryLower) ||
          template.tags.any((tag) => tag.toLowerCase().contains(queryLower)) ||
          template.displayType.toLowerCase().contains(queryLower);
    }).toList();
  }

  // Get recommended templates based on user's workout history
  static Future<List<WorkoutTemplate>> getRecommendedTemplates({
    String? fitnessLevel,
    List<String>? preferredMuscleGroups,
    int? preferredDuration,
    String? goal,
  }) async {
    final allTemplates = [...getQuickTemplates(), ...getFeaturedTemplates()];

    return allTemplates.where((template) {
      // Filter by fitness level
      if (fitnessLevel != null &&
          template.params['fitnessLevel'] != fitnessLevel &&
          template.params['fitnessLevel'] != 'All Levels') {
        return false;
      }

      // Filter by preferred muscle groups
      if (preferredMuscleGroups != null && preferredMuscleGroups.isNotEmpty) {
        final templateMuscles = List<String>.from(
          template.params['muscleGroups'] ?? [],
        );
        final hasCommonMuscle = templateMuscles.any(
          (muscle) => preferredMuscleGroups.contains(muscle),
        );
        if (!hasCommonMuscle) return false;
      }

      // Filter by duration (within 15 minutes)
      if (preferredDuration != null) {
        final templateDuration = template.params['duration'] as int?;
        if (templateDuration != null &&
            (templateDuration - preferredDuration).abs() > 15) {
          return false;
        }
      }

      // Filter by goal
      if (goal != null && template.params['goal'] != goal) {
        return false;
      }

      return true;
    }).toList();
  }

  // Create template from workout parameters
  static WorkoutTemplate createTemplateFromParams({
    required String name,
    required String description,
    required Map<String, dynamic> params,
    String category = 'custom',
    List<String> tags = const [],
  }) {
    return WorkoutTemplate(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      category: category,
      params: params,
      createdAt: DateTime.now(),
      tags: tags,
      isPublic: false,
    );
  }
}
