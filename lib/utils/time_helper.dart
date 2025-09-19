class TimeHelper {
  // Pakistan timezone offset (UTC+5)
  static const int pakistanOffset = 5;
  
  // Prayer times (approximate - can be made more precise with location)
  static const Map<String, String> defaultPrayerTimes = {
    'Fajr': '05:30',
    'Zuhr': '12:30',
    'Asr': '16:00',
    'Maghrib': '18:30',
    'Isha': '20:00',
  };
  
  // Get current Pakistan time
  static DateTime getCurrentPakistanTime() {
    final utc = DateTime.now().toUtc();
    return utc.add(Duration(hours: pakistanOffset));
  }
  
  // Get current time as formatted string
  static String getCurrentTimeString() {
    final now = getCurrentPakistanTime();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
  
  // Get current date as formatted string
  static String getCurrentDateString() {
    final now = getCurrentPakistanTime();
    return '${now.day}/${now.month}/${now.year}';
  }
  
  // Get day of week
  static String getDayOfWeek([DateTime? date]) {
    final targetDate = date ?? getCurrentPakistanTime();
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 
      'Friday', 'Saturday', 'Sunday'
    ];
    return days[targetDate.weekday - 1];
  }
  
  // Get day of week in Urdu
  static String getDayOfWeekUrdu([DateTime? date]) {
    final targetDate = date ?? getCurrentPakistanTime();
    const daysUrdu = [
      'پیر', 'منگل', 'بدھ', 'جمعرات', 
      'جمعہ', 'ہفتہ', 'اتوار'
    ];
    return daysUrdu[targetDate.weekday - 1];
  }
  
  // Check if current time is prayer time
  static bool isPrayerTime() {
    final currentTime = getCurrentTimeString();
    return defaultPrayerTimes.values.any((prayerTime) {
      final currentMinutes = _timeToMinutes(currentTime);
      final prayerMinutes = _timeToMinutes(prayerTime);
      // Within 5 minutes of prayer time
      return (currentMinutes - prayerMinutes).abs() <= 5;
    });
  }
  
  // Get next prayer time
  static String getNextPrayerTime() {
    final currentTime = getCurrentTimeString();
    final currentMinutes = _timeToMinutes(currentTime);
    
    for (final entry in defaultPrayerTimes.entries) {
      final prayerMinutes = _timeToMinutes(entry.value);
      if (prayerMinutes > currentMinutes) {
        return entry.key;
      }
    }
    
    // If no prayer left today, return tomorrow's Fajr
    return 'Fajr (Tomorrow)';
  }
  
  // Convert time string to minutes since midnight
  static int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
  
  // Convert minutes to time string
  static String minutesToTimeString(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }
  
  // Get week dates starting from Monday
  static List<DateTime> getWeekDates([DateTime? startDate]) {
    final start = startDate ?? getCurrentPakistanTime();
    final monday = start.subtract(Duration(days: start.weekday - 1));
    
    return List.generate(7, (index) => 
      DateTime(monday.year, monday.month, monday.day + index)
    );
  }
  
  // Format duration for timer display
  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  // Get study session duration based on age and subject
  static int getOptimalSessionLength(int age, String subject, String difficulty) {
    int baseMinutes = 25; // Default Pomodoro
    
    // Adjust for age
    if (age <= 12) {
      baseMinutes = 15;
    } else if (age <= 15) {
      baseMinutes = 20;
    } else if (age >= 18) {
      baseMinutes = 30;
    }
    
    // Adjust for subject difficulty
    if (difficulty == 'weak') {
      baseMinutes += 10;
    } else if (difficulty == 'strong') {
      baseMinutes = (baseMinutes * 0.6).round();
    }
    
    // Subject-specific adjustments
    switch (subject.toLowerCase()) {
      case 'mathematics':
      case 'physics':
      case 'chemistry':
        baseMinutes += 5; // More focus needed
        break;
      case 'urdu':
      case 'english':
        if (difficulty == 'strong') baseMinutes = (baseMinutes * 0.5).round();
        break;
    }
    
    return baseMinutes.clamp(10, 45); // Min 10, Max 45 minutes
  }
  
  // Get break duration based on session length
  static int getBreakDuration(int sessionMinutes) {
    if (sessionMinutes <= 15) return 3;
    if (sessionMinutes <= 25) return 5;
    if (sessionMinutes <= 35) return 8;
    return 10;
  }
}