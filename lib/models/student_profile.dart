class StudentProfile {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String province;
  final String classLevel;
  final List<String> subjects;
  final String weakestSubject;
  final int dailyStudyHours;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, String> subjectDifficulty; // subject -> 'weak'/'medium'/'strong'
  final Map<String, int> subjectPreferences; // subject -> hours per week
  
  StudentProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.province,
    required this.classLevel,
    required this.subjects,
    required this.weakestSubject,
    required this.dailyStudyHours,
    required this.createdAt,
    required this.updatedAt,
    this.subjectDifficulty = const {},
    this.subjectPreferences = const {},
  });
  
  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'province': province,
      'classLevel': classLevel,
      'subjects': subjects,
      'weakestSubject': weakestSubject,
      'dailyStudyHours': dailyStudyHours,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'subjectDifficulty': subjectDifficulty,
      'subjectPreferences': subjectPreferences,
    };
  }
  
  // Create from JSON
  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      province: json['province'] ?? '',
      classLevel: json['classLevel'] ?? '',
      subjects: List<String>.from(json['subjects'] ?? []),
      weakestSubject: json['weakestSubject'] ?? '',
      dailyStudyHours: json['dailyStudyHours'] ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      subjectDifficulty: Map<String, String>.from(json['subjectDifficulty'] ?? {}),
      subjectPreferences: Map<String, int>.from(json['subjectPreferences'] ?? {}),
    );
  }
  
  // Create a copy with updated fields
  StudentProfile copyWith({
    String? name,
    int? age,
    String? gender,
    String? province,
    String? classLevel,
    List<String>? subjects,
    String? weakestSubject,
    int? dailyStudyHours,
    Map<String, String>? subjectDifficulty,
    Map<String, int>? subjectPreferences,
  }) {
    return StudentProfile(
      id: id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      province: province ?? this.province,
      classLevel: classLevel ?? this.classLevel,
      subjects: subjects ?? this.subjects,
      weakestSubject: weakestSubject ?? this.weakestSubject,
      dailyStudyHours: dailyStudyHours ?? this.dailyStudyHours,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      subjectDifficulty: subjectDifficulty ?? this.subjectDifficulty,
      subjectPreferences: subjectPreferences ?? this.subjectPreferences,
    );
  }
  
  // Get total weekly study hours
  int get totalWeeklyHours => dailyStudyHours * 7;
  
  // Get study hours for a specific subject
  int getSubjectHours(String subject) {
    return subjectPreferences[subject] ?? 2; // default 2 hours/week
  }
  
  // Check if profile is complete
  bool get isComplete {
    return name.isNotEmpty &&
           age > 0 &&
           gender.isNotEmpty &&
           province.isNotEmpty &&
           classLevel.isNotEmpty &&
           subjects.isNotEmpty &&
           weakestSubject.isNotEmpty &&
           dailyStudyHours > 0;
  }
  
  // Get difficulty level for subject
  String getSubjectDifficulty(String subject) {
    if (subject == weakestSubject) return 'weak';
    return subjectDifficulty[subject] ?? 'medium';
  }
}