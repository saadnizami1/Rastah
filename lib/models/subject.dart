class Subject {
  final String id;
  final String name;
  final String nameUrdu;
  final String difficulty; // 'weak', 'medium', 'strong'
  final int weeklyHours;
  final int sessionDuration; // minutes
  final int breakDuration; // minutes
  final String color; // hex color for UI
  final String icon; // icon name or emoji
  final List<String> topics;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  Subject({
    required this.id,
    required this.name,
    required this.nameUrdu,
    required this.difficulty,
    required this.weeklyHours,
    required this.sessionDuration,
    required this.breakDuration,
    required this.color,
    required this.icon,
    this.topics = const [],
    required this.createdAt,
    required this.updatedAt,
  });
  
  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameUrdu': nameUrdu,
      'difficulty': difficulty,
      'weeklyHours': weeklyHours,
      'sessionDuration': sessionDuration,
      'breakDuration': breakDuration,
      'color': color,
      'icon': icon,
      'topics': topics,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
  
  // Create from JSON
  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      nameUrdu: json['nameUrdu'] ?? '',
      difficulty: json['difficulty'] ?? 'medium',
      weeklyHours: json['weeklyHours'] ?? 2,
      sessionDuration: json['sessionDuration'] ?? 25,
      breakDuration: json['breakDuration'] ?? 5,
      color: json['color'] ?? '#2F3437',
      icon: json['icon'] ?? '📚',
      topics: List<String>.from(json['topics'] ?? []),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
  
  // Create copy with updated fields
  Subject copyWith({
    String? name,
    String? nameUrdu,
    String? difficulty,
    int? weeklyHours,
    int? sessionDuration,
    int? breakDuration,
    String? color,
    String? icon,
    List<String>? topics,
  }) {
    return Subject(
      id: id,
      name: name ?? this.name,
      nameUrdu: nameUrdu ?? this.nameUrdu,
      difficulty: difficulty ?? this.difficulty,
      weeklyHours: weeklyHours ?? this.weeklyHours,
      sessionDuration: sessionDuration ?? this.sessionDuration,
      breakDuration: breakDuration ?? this.breakDuration,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      topics: topics ?? this.topics,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
  
  // Predefined subjects with default configurations
  static List<Subject> getDefaultSubjects() {
    final now = DateTime.now();
    
    return [
      Subject(
        id: 'math',
        name: 'Mathematics',
        nameUrdu: 'ریاضی',
        difficulty: 'medium',
        weeklyHours: 4,
        sessionDuration: 30,
        breakDuration: 5,
        color: '#0F62FE',
        icon: '🔢',
        topics: ['Algebra', 'Geometry', 'Calculus'],
        createdAt: now,
        updatedAt: now,
      ),
      Subject(
        id: 'english',
        name: 'English',
        nameUrdu: 'انگریزی',
        difficulty: 'medium',
        weeklyHours: 3,
        sessionDuration: 25,
        breakDuration: 5,
        color: '#E5484D',
        icon: '📖',
        topics: ['Grammar', 'Literature', 'Writing'],
        createdAt: now,
        updatedAt: now,
      ),
      Subject(
        id: 'urdu',
        name: 'Urdu',
        nameUrdu: 'اردو',
        difficulty: 'medium',
        weeklyHours: 3,
        sessionDuration: 25,
        breakDuration: 5,
        color: '#0F7B0F',
        icon: '📝',
        topics: ['Grammar', 'Poetry', 'Prose'],
        createdAt: now,
        updatedAt: now,
      ),
      Subject(
        id: 'science',
        name: 'Science',
        nameUrdu: 'سائنس',
        difficulty: 'medium',
        weeklyHours: 4,
        sessionDuration: 30,
        breakDuration: 5,
        color: '#B54308',
        icon: '🔬',
        topics: ['Physics', 'Chemistry', 'Biology'],
        createdAt: now,
        updatedAt: now,
      ),
      Subject(
        id: 'physics',
        name: 'Physics',
        nameUrdu: 'طبیعیات',
        difficulty: 'medium',
        weeklyHours: 3,
        sessionDuration: 30,
        breakDuration: 5,
        color: '#7C3AED',
        icon: '⚛️',
        topics: ['Mechanics', 'Thermodynamics', 'Optics'],
        createdAt: now,
        updatedAt: now,
      ),
      Subject(
        id: 'chemistry',
        name: 'Chemistry',
        nameUrdu: 'کیمسٹری',
        difficulty: 'medium',
        weeklyHours: 3,
        sessionDuration: 30,
        breakDuration: 5,
        color: '#059669',
        icon: '🧪',
        topics: ['Organic', 'Inorganic', 'Physical'],
        createdAt: now,
        updatedAt: now,
      ),
      Subject(
        id: 'biology',
        name: 'Biology',
        nameUrdu: 'حیاتیات',
        difficulty: 'medium',
        weeklyHours: 3,
        sessionDuration: 25,
        breakDuration: 5,
        color: '#16A34A',
        icon: '🧬',
        topics: ['Botany', 'Zoology', 'Genetics'],
        createdAt: now,
        updatedAt: now,
      ),
      Subject(
        id: 'social_studies',
        name: 'Social Studies',
        nameUrdu: 'سماجی علوم',
        difficulty: 'medium',
        weeklyHours: 2,
        sessionDuration: 20,
        breakDuration: 5,
        color: '#DC2626',
        icon: '🌍',
        topics: ['History', 'Geography', 'Civics'],
        createdAt: now,
        updatedAt: now,
      ),
      Subject(
        id: 'islamic_studies',
        name: 'Islamic Studies',
        nameUrdu: 'اسلامیات',
        difficulty: 'medium',
        weeklyHours: 2,
        sessionDuration: 20,
        breakDuration: 5,
        color: '#059669',
        icon: '🕌',
        topics: ['Quran', 'Hadith', 'Fiqh'],
        createdAt: now,
        updatedAt: now,
      ),
      Subject(
        id: 'computer_science',
        name: 'Computer Science',
        nameUrdu: 'کمپیوٹر سائنس',
        difficulty: 'medium',
        weeklyHours: 3,
        sessionDuration: 30,
        breakDuration: 5,
        color: '#7C3AED',
        icon: '💻',
        topics: ['Programming', 'Algorithms', 'Data Structures'],
        createdAt: now,
        updatedAt: now,
      ),
      Subject(
        id: 'pakistan_studies',
        name: 'Pakistan Studies',
        nameUrdu: 'پاکستان کی تاریخ',
        difficulty: 'medium',
        weeklyHours: 2,
        sessionDuration: 20,
        breakDuration: 5,
        color: '#16A34A',
        icon: '🇵🇰',
        topics: ['History', 'Geography', 'Culture'],
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
  
  // Get subject by ID from default list
  static Subject? getById(String id) {
    try {
      return getDefaultSubjects().firstWhere((subject) => subject.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // Get subjects for specific class level
  static List<Subject> getSubjectsForClass(String classLevel) {
    final allSubjects = getDefaultSubjects();
    
    // Basic subjects for all classes
    var subjects = allSubjects.where((s) => 
      ['math', 'english', 'urdu', 'islamic_studies', 'pakistan_studies'].contains(s.id)
    ).toList();
    
    // Add science-based subjects for higher classes
    if (classLevel.contains('9') || classLevel.contains('10') || 
        classLevel.contains('11') || classLevel.contains('12') ||
        classLevel.toLowerCase().contains('level')) {
      subjects.addAll(allSubjects.where((s) => 
        ['physics', 'chemistry', 'biology', 'computer_science'].contains(s.id)
      ));
    } else {
      // General science for lower classes
      subjects.add(allSubjects.firstWhere((s) => s.id == 'science'));
    }
    
    // Add social studies for middle classes
    if (!classLevel.toLowerCase().contains('level')) {
      subjects.add(allSubjects.firstWhere((s) => s.id == 'social_studies'));
    }
    
    return subjects;
  }
}