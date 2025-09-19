// Session types
enum SessionType {
  study,      // Regular study session
  breakTime,  // Break between sessions
  prayer,     // Prayer time
  meal,       // Meal time
  sports,     // Physical activity
}

// Session status
enum SessionStatus {
  scheduled,  // Not started yet
  active,     // Currently running
  paused,     // Temporarily paused
  completed,  // Successfully finished
  skipped,    // User skipped this session
  cancelled,  // Session was cancelled
}

class StudySession {
  final String id;
  final String subjectId;
  final String subjectName;
  final String subjectNameUrdu;
  final DateTime scheduledStartTime;
  final DateTime scheduledEndTime;
  final int plannedDuration; // minutes
  final int plannedBreakDuration; // minutes
  final SessionType type;
  final SessionStatus status;
  final DateTime? actualStartTime;
  final DateTime? actualEndTime;
  final int? actualDuration; // minutes
  final List<String> chatMessages; // Chat history during session
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  StudySession({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.subjectNameUrdu,
    required this.scheduledStartTime,
    required this.scheduledEndTime,
    required this.plannedDuration,
    required this.plannedBreakDuration,
    required this.type,
    this.status = SessionStatus.scheduled,
    this.actualStartTime,
    this.actualEndTime,
    this.actualDuration,
    this.chatMessages = const [],
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });
  
  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'subjectNameUrdu': subjectNameUrdu,
      'scheduledStartTime': scheduledStartTime.toIso8601String(),
      'scheduledEndTime': scheduledEndTime.toIso8601String(),
      'plannedDuration': plannedDuration,
      'plannedBreakDuration': plannedBreakDuration,
      'type': type.toString(),
      'status': status.toString(),
      'actualStartTime': actualStartTime?.toIso8601String(),
      'actualEndTime': actualEndTime?.toIso8601String(),
      'actualDuration': actualDuration,
      'chatMessages': chatMessages,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
  
  // Create from JSON
  factory StudySession.fromJson(Map<String, dynamic> json) {
    return StudySession(
      id: json['id'] ?? '',
      subjectId: json['subjectId'] ?? '',
      subjectName: json['subjectName'] ?? '',
      subjectNameUrdu: json['subjectNameUrdu'] ?? '',
      scheduledStartTime: DateTime.tryParse(json['scheduledStartTime'] ?? '') ?? DateTime.now(),
      scheduledEndTime: DateTime.tryParse(json['scheduledEndTime'] ?? '') ?? DateTime.now(),
      plannedDuration: json['plannedDuration'] ?? 25,
      plannedBreakDuration: json['plannedBreakDuration'] ?? 5,
      type: _parseSessionType(json['type']),
      status: _parseSessionStatus(json['status']),
      actualStartTime: json['actualStartTime'] != null ? DateTime.tryParse(json['actualStartTime']) : null,
      actualEndTime: json['actualEndTime'] != null ? DateTime.tryParse(json['actualEndTime']) : null,
      actualDuration: json['actualDuration'],
      chatMessages: List<String>.from(json['chatMessages'] ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
  
  // Helper methods for parsing enums
  static SessionType _parseSessionType(String? value) {
    switch (value) {
      case 'SessionType.study': return SessionType.study;
      case 'SessionType.breakTime': return SessionType.breakTime;
      case 'SessionType.prayer': return SessionType.prayer;
      case 'SessionType.meal': return SessionType.meal;
      case 'SessionType.sports': return SessionType.sports;
      default: return SessionType.study;
    }
  }
  
  static SessionStatus _parseSessionStatus(String? value) {
    switch (value) {
      case 'SessionStatus.scheduled': return SessionStatus.scheduled;
      case 'SessionStatus.active': return SessionStatus.active;
      case 'SessionStatus.paused': return SessionStatus.paused;
      case 'SessionStatus.completed': return SessionStatus.completed;
      case 'SessionStatus.skipped': return SessionStatus.skipped;
      case 'SessionStatus.cancelled': return SessionStatus.cancelled;
      default: return SessionStatus.scheduled;
    }
  }
  
  // Create copy with updated fields
  StudySession copyWith({
    String? subjectId,
    String? subjectName,
    String? subjectNameUrdu,
    DateTime? scheduledStartTime,
    DateTime? scheduledEndTime,
    int? plannedDuration,
    int? plannedBreakDuration,
    SessionType? type,
    SessionStatus? status,
    DateTime? actualStartTime,
    DateTime? actualEndTime,
    int? actualDuration,
    List<String>? chatMessages,
    Map<String, dynamic>? metadata,
  }) {
    return StudySession(
      id: id,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      subjectNameUrdu: subjectNameUrdu ?? this.subjectNameUrdu,
      scheduledStartTime: scheduledStartTime ?? this.scheduledStartTime,
      scheduledEndTime: scheduledEndTime ?? this.scheduledEndTime,
      plannedDuration: plannedDuration ?? this.plannedDuration,
      plannedBreakDuration: plannedBreakDuration ?? this.plannedBreakDuration,
      type: type ?? this.type,
      status: status ?? this.status,
      actualStartTime: actualStartTime ?? this.actualStartTime,
      actualEndTime: actualEndTime ?? this.actualEndTime,
      actualDuration: actualDuration ?? this.actualDuration,
      chatMessages: chatMessages ?? this.chatMessages,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
  
  // Computed properties
  bool get isActive => status == SessionStatus.active;
  bool get isPaused => status == SessionStatus.paused;
  bool get isCompleted => status == SessionStatus.completed;
  bool get isScheduled => status == SessionStatus.scheduled;
  bool get isStudySession => type == SessionType.study;
  bool get isBreak => type == SessionType.breakTime;
  bool get isPrayer => type == SessionType.prayer;
  
  // Check if session should be highlighted (current time)
  bool get isCurrentSession {
    final now = DateTime.now();
    return now.isAfter(scheduledStartTime) && now.isBefore(scheduledEndTime) && status == SessionStatus.scheduled;
  }
  
  // Get remaining time until session starts
  Duration get timeUntilStart {
    final now = DateTime.now();
    if (now.isAfter(scheduledStartTime)) return Duration.zero;
    return scheduledStartTime.difference(now);
  }
  
  // Get elapsed time since session started
  Duration get elapsedTime {
    if (actualStartTime == null) return Duration.zero;
    final endTime = actualEndTime ?? DateTime.now();
    return endTime.difference(actualStartTime!);
  }
  
  // Get time remaining in session
  Duration get timeRemaining {
    if (!isActive && !isPaused) return Duration.zero;
    final elapsed = elapsedTime;
    final planned = Duration(minutes: plannedDuration);
    final remaining = planned - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }
  
  // Get formatted time string for display
  String get timeDisplayString {
    final start = scheduledStartTime;
    final end = scheduledEndTime;
    return '${_formatTime(start)} - ${_formatTime(end)}';
  }
  
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
  
  // Get subject color (from metadata or default)
  String get subjectColor => metadata['color'] ?? '#2F3437';
  
  // Get subject icon (from metadata or default)
  String get subjectIcon => metadata['icon'] ?? '📚';
  
  // Add chat message to session
  StudySession addChatMessage(String message) {
    final updatedMessages = List<String>.from(chatMessages)..add(message);
    return copyWith(chatMessages: updatedMessages);
  }
  
  // Start the session
  StudySession start() {
    return copyWith(
      status: SessionStatus.active,
      actualStartTime: DateTime.now(),
    );
  }
  
  // Pause the session
  StudySession pause() {
    return copyWith(status: SessionStatus.paused);
  }
  
  // Resume the session
  StudySession resume() {
    return copyWith(status: SessionStatus.active);
  }
  
  // Complete the session
  StudySession complete() {
    final now = DateTime.now();
    final duration = actualStartTime != null ? now.difference(actualStartTime!).inMinutes : plannedDuration;
    
    return copyWith(
      status: SessionStatus.completed,
      actualEndTime: now,
      actualDuration: duration,
    );
  }
  
  // Skip the session
  StudySession skip() {
    return copyWith(status: SessionStatus.skipped);
  }
  
  // Cancel the session
  StudySession cancel() {
    return copyWith(status: SessionStatus.cancelled);
  }
}