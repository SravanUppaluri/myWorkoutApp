import 'package:flutter/material.dart';

// Supporting classes for enhanced template structure
class BaseExercise {
  final String id;
  final String name;
  final String category;
  final String targetMuscle;
  final List<String> equipment;
  final String difficulty;
  final String instructions;
  final bool isCompound;

  const BaseExercise({
    required this.id,
    required this.name,
    required this.category,
    required this.targetMuscle,
    required this.equipment,
    required this.difficulty,
    required this.instructions,
    this.isCompound = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'targetMuscle': targetMuscle,
    'equipment': equipment,
    'difficulty': difficulty,
    'instructions': instructions,
    'isCompound': isCompound,
  };

  factory BaseExercise.fromJson(Map<String, dynamic> json) => BaseExercise(
    id: json['id'],
    name: json['name'],
    category: json['category'],
    targetMuscle: json['targetMuscle'],
    equipment: List<String>.from(json['equipment']),
    difficulty: json['difficulty'],
    instructions: json['instructions'],
    isCompound: json['isCompound'] ?? false,
  );
}

class SetRepRange {
  final int minSets;
  final int maxSets;
  final int minReps;
  final int maxReps;
  final String? timeRange; // for time-based exercises

  const SetRepRange({
    required this.minSets,
    required this.maxSets,
    required this.minReps,
    required this.maxReps,
    this.timeRange,
  });

  Map<String, dynamic> toJson() => {
    'minSets': minSets,
    'maxSets': maxSets,
    'minReps': minReps,
    'maxReps': maxReps,
    'timeRange': timeRange,
  };

  factory SetRepRange.fromJson(Map<String, dynamic> json) => SetRepRange(
    minSets: json['minSets'],
    maxSets: json['maxSets'],
    minReps: json['minReps'],
    maxReps: json['maxReps'],
    timeRange: json['timeRange'],
  );
}

// Template categories for dropdown with workout splits
enum TemplateCategory {
  ppl(
    'PPL (Push/Pull/Legs)',
    '6-day split targeting push, pull, and leg muscles',
    Icons.fitness_center,
  ),
  upperLower(
    'UL (Upper/Lower)',
    '4-day split alternating upper and lower body',
    Icons.accessibility_new,
  ),
  fullBody(
    'Full Body',
    '3-day full body workouts hitting all muscle groups',
    Icons.person,
  ),
  broSplit(
    'Bro Split',
    'Traditional 5-day body part split',
    Icons.sports_handball,
  ),
  phat(
    'PHAT',
    'Power Hypertrophy Adaptive Training',
    Icons.local_fire_department,
  ),
  phul('PHUL', 'Power Hypertrophy Upper Lower split', Icons.fitness_center),
  strength('Strength', 'Build muscle and increase power', Icons.fitness_center),
  cardio('Cardio', 'Improve cardiovascular fitness', Icons.favorite),
  hiit('HIIT', 'High-intensity interval training', Icons.local_fire_department),
  flexibility(
    'Flexibility',
    'Improve mobility and flexibility',
    Icons.self_improvement,
  ),
  sports('Sports', 'Sport-specific training', Icons.sports_soccer);

  const TemplateCategory(this.displayName, this.description, this.icon);
  final String displayName;
  final String description;
  final IconData icon;
}

class WorkoutTemplate {
  final String id;
  final String name;
  final String description;
  final String
  category; // 'strength', 'cardio', 'flexibility', 'hiit', 'sports'
  final Map<String, dynamic> params;
  final String? imageUrl;
  final int popularity;
  final DateTime createdAt;
  final String? authorId;
  final bool isPublic;
  final List<String> tags;

  // Enhanced Template Structure for AI
  final List<BaseExercise>? baseExercises;
  final Map<String, SetRepRange>? setRepRanges;
  final Map<String, int>? restPeriods; // in seconds
  final List<String>? progressionSuggestions;
  final Map<String, List<String>>? equipmentAlternatives;
  final Map<String, dynamic>? aiPersonalizationHints;

  // For favorites and usage tracking
  final bool isFavorite;
  final int usageCount;
  final DateTime? lastUsed;

  const WorkoutTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.params,
    this.imageUrl,
    this.popularity = 0,
    required this.createdAt,
    this.authorId,
    this.isPublic = false,
    this.tags = const [],
    this.baseExercises,
    this.setRepRanges,
    this.restPeriods,
    this.progressionSuggestions,
    this.equipmentAlternatives,
    this.aiPersonalizationHints,
    this.isFavorite = false,
    this.usageCount = 0,
    this.lastUsed,
  });

  WorkoutTemplate copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    Map<String, dynamic>? params,
    String? imageUrl,
    int? popularity,
    DateTime? createdAt,
    String? authorId,
    bool? isPublic,
    List<String>? tags,
    bool? isFavorite,
    int? usageCount,
    DateTime? lastUsed,
  }) {
    return WorkoutTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      params: params ?? this.params,
      imageUrl: imageUrl ?? this.imageUrl,
      popularity: popularity ?? this.popularity,
      createdAt: createdAt ?? this.createdAt,
      authorId: authorId ?? this.authorId,
      isPublic: isPublic ?? this.isPublic,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      usageCount: usageCount ?? this.usageCount,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'params': params,
      'imageUrl': imageUrl,
      'popularity': popularity,
      'createdAt': createdAt.toIso8601String(),
      'authorId': authorId,
      'isPublic': isPublic,
      'tags': tags,
      'isFavorite': isFavorite,
      'usageCount': usageCount,
      'lastUsed': lastUsed?.toIso8601String(),
    };
  }

  factory WorkoutTemplate.fromJson(Map<String, dynamic> json) {
    return WorkoutTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      params: Map<String, dynamic>.from(json['params'] as Map),
      imageUrl: json['imageUrl'] as String?,
      popularity: json['popularity'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      authorId: json['authorId'] as String?,
      isPublic: json['isPublic'] as bool? ?? false,
      tags: List<String>.from(json['tags'] as List? ?? []),
      isFavorite: json['isFavorite'] as bool? ?? false,
      usageCount: json['usageCount'] as int? ?? 0,
      lastUsed: json['lastUsed'] != null
          ? DateTime.parse(json['lastUsed'] as String)
          : null,
    );
  }

  // Template validation
  bool get isValid {
    return name.isNotEmpty &&
        description.isNotEmpty &&
        params.isNotEmpty &&
        params.containsKey('workoutType') &&
        params.containsKey('duration');
  }

  // Get display properties
  String get displayDuration => '${params['duration'] ?? '?'} min';
  String get displayType => params['workoutType'] ?? 'General';
  List<String> get targetMuscles =>
      List<String>.from(params['muscleGroups'] ?? []);
  String get difficultyLevel => params['fitnessLevel'] ?? 'All Levels';

  // Template metrics
  bool get isPopular => popularity > 100;
  bool get isRecent =>
      lastUsed != null && DateTime.now().difference(lastUsed!).inDays < 7;
  bool get isFrequentlyUsed => usageCount > 5;
}
