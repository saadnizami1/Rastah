import 'study_session.dart';
import 'student_profile.dart';
import 'subject.dart';

class Timetable {
  final String id;
  final String studentId;
  final DateTime weekStartDate; // Monday of the week
  final List<StudySession> sessions;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  
  Timetable({
    required this.id,
    required this.studentId,
    required this.weekStartDate,
    required this.sessions,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });
  
  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'weekStartDate': weekStartDate.toIso8601String(),
      'sessions': sessions.map((s) => s.toJson()).toList(),
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
    };
  }
  
  // Create from JSON
  factory Timetable.fromJson(Map<String, dynamic> json) {
    return Timetable(
      id: json['id'] ?? '',
      studentId: json['studentId'] ?? '',
      weekStartDate: DateTime.tryParse(json['weekStartDate'] ?? '') ?? DateTime.now(),
      sessions: (json['sessions'] as List?)
          ?.map((s) => StudySession.fromJson(s))
          .toList() ?? [],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      isActive: json['isActive'] ?? true,
    );
  }
  
  // Create copy with updated fields
  Timetable copyWith({
    String? studentId,
    DateTime? weekStartDate,
    List<StudySession>? sessions,
    Map<String, dynamic>? metadata,
    bool? isActive,
  }) {
    return Timetable(
      id: id,
      studentId: studentId ?? this.studentId,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      sessions: sessions ?? this.sessions,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isActive: isActive ?? this.isActive,
    );
  }
  
  // Get sessions for a specific day
  List<StudySession> getSessionsForDay(DateTime date) {
    return sessions.where((session) {
      final sessionDate = DateTime(
        session.scheduledStartTime.year,
        session.scheduledStartTime.month,
        session.scheduledStartTime.day,
      );
      final targetDate = DateTime(date.year, date.month, date.day);
      return sessionDate.isAtSameMomentAs(targetDate);
    }).toList()
      ..sort((a, b) => a.scheduledStartTime.compareTo(b.scheduledStartTime));
  }
  
  // Get sessions for a specific subject
  List<StudySession> getSessionsForSubject(String subjectId) {
    return sessions.where((session) => session.subjectId == subjectId).toList();
  }
  
  // Get current active session
  StudySession? getCurrentSession() {
    final now = DateTime.now();
    return sessions.where((session) {
      return session.isCurrentSession || session.isActive;
    }).isNotEmpty 
        ? sessions.firstWhere((session) => session.isCurrentSession || session.isActive)
        : null;
  }
  
  // Get next upcoming session
  StudySession? getNextSession() {
    final now = DateTime.now();
    final upcomingSessions = sessions.where((session) {
      return session.scheduledStartTime.isAfter(now) && 
             session.status == SessionStatus.scheduled;
    }).toList()
      ..sort((a, b) => a.scheduledStartTime.compareTo(b.scheduledStartTime));
    
    return upcomingSessions.isNotEmpty ? upcomingSessions.first : null;
  }
  
  // Get all sessions for current week organized by day
  Map<String, List<StudySession>> getWeeklySchedule() {
    final weekDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final weeklySchedule = <String, List<StudySession>>{};
    
    for (int i = 0; i < 7; i++) {
      final date = weekStartDate.add(Duration(days: i));
      final dayName = weekDays[i];
      weeklySchedule[dayName] = getSessionsForDay(date);
    }
    
    return weeklySchedule;
  }
  
  // Update a specific session
  Timetable updateSession(StudySession updatedSession) {
    final updatedSessions = sessions.map((session) {
      return session.id == updatedSession.id ? updatedSession : session;
    }).toList();
    
    return copyWith(sessions: updatedSessions);
  }
  
  // Add a new session
  Timetable addSession(StudySession newSession) {
    final updatedSessions = List<StudySession>.from(sessions)..add(newSession);
    return copyWith(sessions: updatedSessions);
  }
  
  // Remove a session
  Timetable removeSession(String sessionId) {
    final updatedSessions = sessions.where((session) => session.id != sessionId).toList();
    return copyWith(sessions: updatedSessions);
  }
  
  // Get total study hours for the week
  double get totalWeeklyHours {
    return sessions
        .where((session) => session.type == SessionType.study)
        .fold(0.0, (sum, session) => sum + (session.plannedDuration / 60.0));
  }
  
  // Get study hours by subject
  Map<String, double> getHoursBySubject() {
    final hoursBySubject = <String, double>{};
    
    for (final session in sessions) {
      if (session.type == SessionType.study) {
        final hours = session.plannedDuration / 60.0;
        hoursBySubject[session.subjectId] = (hoursBySubject[session.subjectId] ?? 0) + hours;
      }
    }
    
    return hoursBySubject;
  }
  
  // Get completion statistics
  Map<String, int> getCompletionStats() {
    final stats = <String, int>{
      'total': sessions.length,
      'completed': 0,
      'skipped': 0,
      'cancelled': 0,
      'scheduled': 0,
      'active': 0,
    };
    
    for (final session in sessions) {
      switch (session.status) {
        case SessionStatus.completed:
          stats['completed'] = (stats['completed'] ?? 0) + 1;
          break;
        case SessionStatus.skipped:
          stats['skipped'] = (stats['skipped'] ?? 0) + 1;
          break;
        case SessionStatus.cancelled:
          stats['cancelled'] = (stats['cancelled'] ?? 0) + 1;
          break;
        case SessionStatus.scheduled:
          stats['scheduled'] = (stats['scheduled'] ?? 0) + 1;
          break;
        case SessionStatus.active:
        case SessionStatus.paused:
          stats['active'] = (stats['active'] ?? 0) + 1;
          break;
      }
    }
    
    return stats;
  }
  
  // Check if timetable needs updates (more than 7 days old)
  bool get needsUpdate {
    final now = DateTime.now();
    final weekEnd = weekStartDate.add(Duration(days: 7));
    return now.isAfter(weekEnd);
  }
  
  // Generate AI-powered timetable
  static Timetable generateTimetable({
    required String studentId,
    required StudentProfile profile,
    required List<Subject> subjects,
    DateTime? startDate,
  }) {
    final now = DateTime.now();
    final monday = startDate ?? _getMondayOfWeek(now);
    final sessions = <StudySession>[];
    
    // Default time slots for study sessions
    final studyTimeSlots = [
      {'start': 8, 'end': 10},   // Morning
      {'start': 15, 'end': 17},  // Afternoon  
      {'start': 19, 'end': 21},  // Evening
    ];
    
    // Prayer times
    final prayerTimes = [
      {'name': 'Fajr', 'time': 5.5, 'duration': 30},
      {'name': 'Zuhr', 'time': 12.5, 'duration': 30},
      {'name': 'Asr', 'time': 16, 'duration': 30},
      {'name': 'Maghrib', 'time': 18.5, 'duration': 30},
      {'name': 'Isha', 'time': 20, 'duration': 30},
    ];
    
    // Generate sessions for each day of the week
    for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
      final currentDate = monday.add(Duration(days: dayIndex));
      
      // Add prayer sessions
      for (final prayer in prayerTimes) {
        final startTime = currentDate.add(Duration(
          hours: (prayer['time'] as double).floor(),
          minutes: ((prayer['time'] as double) % 1 * 60).round(),
        ));
        
        sessions.add(StudySession(
          id: '${currentDate.millisecondsSinceEpoch}_${prayer['name']}',
          subjectId: 'prayer',
          subjectName: '${prayer['name']} Prayer',
          subjectNameUrdu: '${prayer['name']} نماز',
          scheduledStartTime: startTime,
          scheduledEndTime: startTime.add(Duration(minutes: prayer['duration'] as int)),
          plannedDuration: prayer['duration'] as int,
          plannedBreakDuration: 0,
          type: SessionType.prayer,
          metadata: {'color': '#059669', 'icon': '🕌'},
          createdAt: now,
          updatedAt: now,
        ));
      }
      
      // Add meal times
      final mealTimes = [
        {'name': 'Breakfast', 'time': 7, 'duration': 30},
        {'name': 'Lunch', 'time': 13, 'duration': 45},
        {'name': 'Dinner', 'time': 20.5, 'duration': 45},
      ];
      
      for (final meal in mealTimes) {
        final startTime = currentDate.add(Duration(
          hours: (meal['time'] as double).floor(),
          minutes: ((meal['time'] as double) % 1 * 60).round(),
        ));
        
        sessions.add(StudySession(
          id: '${currentDate.millisecondsSinceEpoch}_${meal['name']}',
          subjectId: 'meal',
          subjectName: meal['name'] as String,
          subjectNameUrdu: meal['name'] == 'Breakfast' ? 'ناشتہ' : 
                          meal['name'] == 'Lunch' ? 'دوپہر کا کھانا' : 'رات کا کھانا',
          scheduledStartTime: startTime,
          scheduledEndTime: startTime.add(Duration(minutes: meal['duration'] as int)),
          plannedDuration: meal['duration'] as int,
          plannedBreakDuration: 0,
          type: SessionType.meal,
          metadata: {'color': '#B54308', 'icon': '🍽️'},
          createdAt: now,
          updatedAt: now,
        ));
      }
      
      // Add study sessions based on subject preferences
      _generateStudySessionsForDay(
        sessions,
        currentDate,
        dayIndex,
        profile,
        subjects,
        studyTimeSlots,
        now,
      );
    }
    
    return Timetable(
      id: '${studentId}_${monday.millisecondsSinceEpoch}',
      studentId: studentId,
      weekStartDate: monday,
      sessions: sessions..sort((a, b) => a.scheduledStartTime.compareTo(b.scheduledStartTime)),
      metadata: {
        'generated_at': now.toIso8601String(),
        'profile_version': profile.updatedAt.toIso8601String(),
        'total_subjects': subjects.length,
        'daily_hours': profile.dailyStudyHours,
      },
      createdAt: now,
      updatedAt: now,
    );
  }
  
  // Helper method to get Monday of current week
  static DateTime _getMondayOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: daysFromMonday));
  }
  
  // Helper method to generate study sessions for a specific day
  static void _generateStudySessionsForDay(
    List<StudySession> sessions,
    DateTime date,
    int dayIndex,
    StudentProfile profile,
    List<Subject> subjects,
    List<Map<String, int>> timeSlots,
    DateTime now,
  ) {
    // Skip Friday afternoon and Sunday (lighter study days)
    if (dayIndex == 4) return; // Friday - only prayers
    if (dayIndex == 6) return; // Sunday - rest day
    
    // Distribute subjects across the week
    final subjectsForDay = _getSubjectsForDay(dayIndex, subjects, profile);
    
    int sessionCount = 0;
    final maxSessionsPerDay = profile.dailyStudyHours ~/ 1; // Rough estimate
    
    for (final subject in subjectsForDay) {
      if (sessionCount >= maxSessionsPerDay) break;
      
      // Find suitable time slot
      final timeSlot = timeSlots[sessionCount % timeSlots.length];
      final startHour = timeSlot['start']!;
      final sessionDuration = _getSessionDuration(subject, profile);
      
      final startTime = DateTime(
        date.year,
        date.month,
        date.day,
        startHour,
        0,
      ).add(Duration(minutes: sessionCount * 90)); // Space sessions 90 min apart
      
      // Don't schedule past 9 PM
      if (startTime.hour >= 21) break;
      
      final endTime = startTime.add(Duration(minutes: sessionDuration));
      
      sessions.add(StudySession(
        id: '${date.millisecondsSinceEpoch}_${subject.id}_$sessionCount',
        subjectId: subject.id,
        subjectName: subject.name,
        subjectNameUrdu: subject.nameUrdu,
        scheduledStartTime: startTime,
        scheduledEndTime: endTime,
        plannedDuration: sessionDuration,
        plannedBreakDuration: _getBreakDuration(sessionDuration),
        type: SessionType.study,
        metadata: {
          'color': subject.color,
          'icon': subject.icon,
          'difficulty': subject.difficulty,
        },
        createdAt: now,
        updatedAt: now,
      ));
      
      sessionCount++;
    }
  }
  
  // Helper to get subjects for specific day
  static List<Subject> _getSubjectsForDay(int dayIndex, List<Subject> subjects, StudentProfile profile) {
    // Prioritize weak subjects on weekdays
    final sortedSubjects = List<Subject>.from(subjects);
    sortedSubjects.sort((a, b) {
      final aDifficulty = profile.getSubjectDifficulty(a.id);
      final bDifficulty = profile.getSubjectDifficulty(b.id);
      
      // Weak subjects get priority
      if (aDifficulty == 'weak' && bDifficulty != 'weak') return -1;
      if (bDifficulty == 'weak' && aDifficulty != 'weak') return 1;
      
      return a.name.compareTo(b.name);
    });
    
    // Return 2-3 subjects per day
    return sortedSubjects.take(dayIndex == 5 ? 2 : 3).toList(); // Saturday lighter
  }
  
  // Helper to get session duration based on subject and profile
  static int _getSessionDuration(Subject subject, StudentProfile profile) {
    final difficulty = profile.getSubjectDifficulty(subject.id);
    final baseMinutes = subject.sessionDuration;
    
    // Adjust based on age and difficulty
    if (profile.age <= 12) return (baseMinutes * 0.8).round();
    if (difficulty == 'weak') return baseMinutes + 10;
    if (difficulty == 'strong') return (baseMinutes * 0.6).round();
    
    return baseMinutes;
  }
  
  // Helper to get break duration
  static int _getBreakDuration(int sessionDuration) {
    if (sessionDuration <= 15) return 3;
    if (sessionDuration <= 25) return 5;
    if (sessionDuration <= 35) return 8;
    return 10;
  }
}