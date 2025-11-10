class User {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final int age;
  final double weight;
  final double height;
  final String fitnessLevel;
  final List<String> goals;
  final DateTime createdAt;

  // Onboarding and goal data
  final bool hasCompletedOnboarding;
  final Map<String, dynamic>? goalData;
  final String? motivation;

  User({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.age = 0,
    this.weight = 0.0,
    this.height = 0.0,
    this.fitnessLevel = 'Beginner',
    this.goals = const [],
    required this.createdAt,
    this.hasCompletedOnboarding = false,
    this.goalData,
    this.motivation,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'age': age,
      'weight': weight,
      'height': height,
      'fitnessLevel': fitnessLevel,
      'goals': goals,
      'createdAt': createdAt.toIso8601String(),
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'goalData': goalData,
      'motivation': motivation,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      displayName: json['displayName'],
      photoUrl: json['photoUrl'],
      age: json['age'] ?? 0,
      weight: json['weight']?.toDouble() ?? 0.0,
      height: json['height']?.toDouble() ?? 0.0,
      fitnessLevel: json['fitnessLevel'] ?? 'Beginner',
      goals: List<String>.from(json['goals'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      hasCompletedOnboarding: json['hasCompletedOnboarding'] ?? false,
      goalData: json['goalData'] != null
          ? Map<String, dynamic>.from(json['goalData'])
          : null,
      motivation: json['motivation'],
    );
  }

  // Create a copy with updated fields
  User copyWith({
    String? email,
    String? displayName,
    String? photoUrl,
    int? age,
    double? weight,
    double? height,
    String? fitnessLevel,
    List<String>? goals,
    bool? hasCompletedOnboarding,
    Map<String, dynamic>? goalData,
    String? motivation,
  }) {
    return User(
      id: id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      goals: goals ?? this.goals,
      createdAt: createdAt,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      goalData: goalData ?? this.goalData,
      motivation: motivation ?? this.motivation,
    );
  }
}
