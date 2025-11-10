class Exercise {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'equipment': equipment,
      'targetRegion': targetRegion,
      'primaryMuscles': primaryMuscles,
      'secondaryMuscles': secondaryMuscles,
      'difficulty': difficulty,
      'movementType': movementType,
      'movementPattern': movementPattern,
      'gripType': gripType,
      'rangeOfMotion': rangeOfMotion,
      'tempo': tempo,
      'muscleGroup': muscleGroup,
      'muscleInfo': muscleInfo.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  final String id;
  final String name;
  final String category;
  final List<String> equipment;
  final List<String> targetRegion;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final String difficulty;
  final String movementType;
  final String movementPattern;
  final String gripType;
  final String rangeOfMotion;
  final String tempo;
  final String muscleGroup;
  final MuscleInfo muscleInfo;
  final DateTime createdAt;
  final DateTime updatedAt;

  Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.equipment,
    required this.targetRegion,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.difficulty,
    required this.movementType,
    required this.movementPattern,
    required this.gripType,
    required this.rangeOfMotion,
    required this.tempo,
    required this.muscleGroup,
    required this.muscleInfo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    List<String> parseStringOrList(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      } else if (value is String) {
        // Try to split on common delimiters
        if (value.contains(',')) {
          return value.split(',').map((e) => e.trim()).toList();
        } else if (value.contains('+')) {
          return value.split('+').map((e) => e.trim()).toList();
        } else {
          return [value.trim()];
        }
      }
      return [];
    }

    return Exercise(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Exercise',
      category: json['category']?.toString() ?? '',
      equipment: parseStringOrList(json['equipment'] ?? json['Equipment']),
      targetRegion: parseStringOrList(
        json['target_region'] ?? json['muscleGroups'],
      ),
      primaryMuscles: parseStringOrList(
        json['primary_muscles'] ?? json['muscleGroups'] ?? [],
      ),
      secondaryMuscles: parseStringOrList(json['secondary_muscles'] ?? []),
      difficulty: json['difficulty']?.toString() ?? 'Beginner',
      movementType: json['movement_type']?.toString() ?? '',
      movementPattern: json['movement_pattern']?.toString() ?? '',
      gripType: json['grip_type']?.toString() ?? '',
      rangeOfMotion: json['range_of_motion']?.toString() ?? '',
      tempo: json['tempo']?.toString() ?? '',
      muscleGroup:
          json['muscle_group']?.toString() ??
          json['muscleGroups']?.toString() ??
          '',
      muscleInfo: MuscleInfo.fromJson(
        json['muscle_info'] ?? json['muscleInfo'] ?? {},
      ),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  // Helper method to parse various date formats from Firestore
  static DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) {
      return DateTime.now();
    }

    if (dateValue is DateTime) {
      return dateValue;
    }

    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        return DateTime.now();
      }
    }

    // Handle Firestore Timestamp (check for toDate method)
    try {
      if (dateValue.runtimeType.toString() == 'Timestamp' ||
          dateValue.toString().contains('Timestamp')) {
        return dateValue.toDate() as DateTime;
      }
    } catch (e) {
      // If toDate() fails, fall back
    }

    return DateTime.now();
  }

  /// Factory method to create Exercise from AI response
  factory Exercise.fromAIResponse(Map<String, dynamic> json) {
    List<String> parseStringOrList(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      } else if (value is String) {
        return [value];
      }
      return [];
    }

    return Exercise(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Exercise',
      category: json['category']?.toString() ?? '',
      equipment: parseStringOrList(json['equipment']),
      targetRegion: parseStringOrList(json['targetRegion']),
      primaryMuscles: parseStringOrList(json['primaryMuscles']),
      secondaryMuscles: parseStringOrList(json['secondaryMuscles'] ?? []),
      difficulty: json['difficulty']?.toString() ?? 'Beginner',
      movementType: json['movementType']?.toString() ?? '',
      movementPattern: json['movementPattern']?.toString() ?? '',
      gripType: json['gripType']?.toString() ?? 'Standard',
      rangeOfMotion: json['rangeOfMotion']?.toString() ?? 'Full',
      tempo: json['tempo']?.toString() ?? 'Moderate',
      muscleGroup: json['muscleGroup']?.toString() ?? '',
      muscleInfo: MuscleInfo(
        scientificName: '',
        commonName: json['muscleGroup']?.toString() ?? '',
        muscleRegions: [],
        primaryFunction: '',
        location: '',
        muscleFiberDirection: '',
      ),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }
}

class MuscleInfo {
  Map<String, dynamic> toJson() {
    return {
      'scientific_name': scientificName,
      'common_name': commonName,
      'muscle_regions': muscleRegions.map((e) => e.toJson()).toList(),
      'primary_function': primaryFunction,
      'location': location,
      'muscle_fiber_direction': muscleFiberDirection,
    };
  }

  final String scientificName;
  final String commonName;
  final List<MuscleRegion> muscleRegions;
  final String primaryFunction;
  final String location;
  final String muscleFiberDirection;

  MuscleInfo({
    required this.scientificName,
    required this.commonName,
    required this.muscleRegions,
    required this.primaryFunction,
    required this.location,
    required this.muscleFiberDirection,
  });

  factory MuscleInfo.fromJson(Map<String, dynamic> json) {
    return MuscleInfo(
      scientificName: json['scientific_name']?.toString() ?? '',
      commonName: json['common_name']?.toString() ?? '',
      muscleRegions: (json['muscle_regions'] as List<dynamic>? ?? [])
          .map((e) => MuscleRegion.fromJson(e as Map<String, dynamic>? ?? {}))
          .toList(),
      primaryFunction: json['primary_function']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      muscleFiberDirection: json['muscle_fiber_direction']?.toString() ?? '',
    );
  }
}

class MuscleRegion {
  Map<String, dynamic> toJson() {
    return {
      'region': region,
      'anatomical_name': anatomicalName,
      'description': description,
    };
  }

  final String region;
  final String anatomicalName;
  final String description;

  MuscleRegion({
    required this.region,
    required this.anatomicalName,
    required this.description,
  });

  factory MuscleRegion.fromJson(Map<String, dynamic> json) {
    return MuscleRegion(
      region: json['region']?.toString() ?? '',
      anatomicalName: json['anatomical_name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}
