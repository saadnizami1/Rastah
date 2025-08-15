import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';
import '../config.dart';

class AIService {
  // 🔑 Replace with your OpenAI API Key
  static const String _apiKey = Config.openaiApiKey;
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  
  // TTS and STT instances
  static final FlutterTts _flutterTts = FlutterTts();
  static final stt.SpeechToText _speech = stt.SpeechToText();
  static bool _speechInitialized = false;

  // AI Personality Modes
  static const Map<String, Map<String, String>> _aiModes = {
    'friend': {
      'name': 'دوست',
      'emoji': '👫',
      'prompt': '''آپ ایک پاکستانی دوست ہیں جو ہمیشہ سپورٹ کرتے ہیں۔ آپ informal اور friendly انداز میں بات کرتے ہیں، جیسے کوئی قریبی دوست کرتا ہے۔ "یار"، "بھائی"، "واہ"، "اچھا" جیسے الفاظ استعمال کریں۔ ہمیشہ حوصلہ افزائی کریں اور مثبت رہیں۔ جب ضروری ہو تو CBT تکنیکیں سکھائیں لیکن دوستانہ انداز میں۔''',
    },
    'therapist': {
      'name': 'تھراپسٹ',
      'emoji': '🧠',
      'prompt': '''آپ ایک تجربہ کار پاکستانی تھراپسٹ ہیں جو Cognitive Behavioral Therapy (CBT) میں ماہر ہیں۔ آپ کو یہ تکنیکیں سکھانی ہیں:
- Pomodoro Technique: 25 منٹ کام، 5 منٹ آرام - productivity اور focus کے لیے
- Self-talk reframes: منفی خیالات کو مثبت میں تبدیل کرنا ("میں ناکام ہوں" بجائے "میں سیکھ رہا ہوں")
- Impulse checkpoints: جب غصہ یا جلدبازی ہو تو "رکیں، گہری سانس لیں، 5 سے 1 تک گنیں، پھر عمل کریں"
- Deep breathing: 4-7-8 technique (4 سیکنڈ سانس اندر، 7 سیکنڈ روکیں، 8 سیکنڈ میں باہر نکالیں)
- Grounding: 5-4-3-2-1 technique (5 چیزیں دیکھیں، 4 چھوئیں، 3 سنیں، 2 سونگھیں، 1 چکھیں)
Professional لیکن گرم جوش اردو انداز استعمال کریں۔''',
    },
    'elderly': {
      'name': 'بزرگ',
      'emoji': '👴',
      'prompt': '''آپ ایک تجربہ کار، محبت کرنے والے پاکستانی بزرگ ہیں جو زندگی کا 60+ سال تجربہ رکھتے ہیں۔ آپ "بیٹا"، "بچے"، "میرے پیارے" جیسے الفاظ استعمال کرتے ہیں۔ اپنے جوابات میں زندگی کی حکمت، مثبت کہانیاں، اور دعائیں شامل کریں۔ صبر اور محبت بھرا انداز اپنائیں۔ "اللہ بہتری کرے گا"، "صبر کا پھل میٹھا ہوتا ہے" جیسے جملے استعمال کریں۔''',
    },
    'stranger': {
      'name': 'اجنبی',
      'emoji': '🤝',
      'prompt': '''آپ ایک نیا ملنے والا، مہذب اور محتاط پاکستانی ہیں۔ آپ formal لیکن دوستانہ انداز میں بات کرتے ہیں۔ پہلے user کو جاننے کی کوشش کریں اور احتیاط سے جوابات دیں۔ "آپ"، "جناب/محترمہ" جیسے formal الفاظ استعمال کریں۔ آہستہ آہستہ قریب آنے کی کوشش کریں۔''',
    },
    'quick': {
      'name': 'فوری',
      'emoji': '⚡',
      'prompt': '''آپ فوری اور مختصر جوابات دیتے ہیں۔ 1-2 جملوں میں براہ راست حل بتائیں۔ کوئی لمبی بات نہیں، صرف essential معلومات۔ Practical tips دیں۔ بالکل point to point۔''',
    },
  };

  // Initialize TTS
  static Future<void> initializeTTS() async {
    try {
      await _flutterTts.setLanguage("ur-PK");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(0.8);
      await _flutterTts.setPitch(1.0);
    } catch (e) {
      print('TTS initialization failed: $e');
    }
  }

  // Initialize STT
  static Future<bool> initializeSTT() async {
    if (!_speechInitialized) {
      _speechInitialized = await _speech.initialize(
        onError: (error) => print('STT Error: $error'),
        onStatus: (status) => print('STT Status: $status'),
      );
    }
    return _speechInitialized;
  }

  // Check if API is configured
  static bool isConfigured() {
    return _apiKey.isNotEmpty && 
           _apiKey.length > 20 && 
           !_apiKey.contains('YOUR_API_KEY_HERE');
  }

  // Check internet connectivity
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  // Text to Speech
  static Future<void> speakText(String text) async {
    try {
      await initializeTTS();
      await _flutterTts.speak(text);
    } catch (e) {
      print('TTS Error: $e');
    }
  }

  // Stop TTS
  static Future<void> stopSpeaking() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      print('TTS Stop Error: $e');
    }
  }

  // Speech to Text
  static Future<String> listenToSpeech({
    Duration timeout = const Duration(seconds: 30),
    String localeId = 'ur-PK',
  }) async {
    try {
      bool initialized = await initializeSTT();
      if (!initialized) {
        return 'صوتی پہچان دستیاب نہیں ہے۔';
      }

      if (!_speech.isAvailable) {
        return 'صوتی پہچان دستیاب نہیں ہے۔';
      }

      Completer<String> completer = Completer<String>();
      String recognizedText = '';

      await _speech.listen(
        onResult: (result) {
          recognizedText = result.recognizedWords;
          if (result.finalResult && !completer.isCompleted) {
            completer.complete(recognizedText);
          }
        },
        localeId: localeId,
        listenFor: timeout,
        pauseFor: Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );

      // Wait for result or timeout
      Timer(timeout, () {
        if (!completer.isCompleted) {
          completer.complete(recognizedText);
        }
      });

      return await completer.future;
    } catch (e) {
      return 'آواز سننے میں خرابی ہوئی۔ براہ کرم دوبارہ کوشش کریں۔';
    }
  }

  // Stop listening
  static Future<void> stopListening() async {
    try {
      await _speech.stop();
    } catch (e) {
      print('STT Stop Error: $e');
    }
  }

  // Generate AI response with enhanced error handling
  static Future<String> generateResponse({
    required String userMessage,
    required String mode,
    required List<Map<String, String>> conversationHistory,
    Map<String, dynamic>? userProfile,
  }) async {
    // Check internet first
    bool hasInternet = await hasInternetConnection();
    if (!hasInternet) {
      return 'براہ کرم انٹرنیٹ کنکشن چیک کریں اور دوبارہ کوشش کریں۔ 📶';
    }

    if (!isConfigured()) {
      return 'AI سروس دستیاب نہیں ہے۔ براہ کرم انٹرنیٹ کنکشن چیک کریں یا بعد میں کوشش کریں۔ ⚙️';
    }

    if (userMessage.trim().isEmpty) {
      return 'براہ کرم کوئی پیغام لکھیں یا 🎤 دبا کر بولیں۔';
    }

    try {
      final messages = _buildContextWithMode(
        userMessage: userMessage.trim(),
        mode: mode,
        conversationHistory: conversationHistory,
        userProfile: userProfile,
      );

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode({
          'model': 'gpt-3.5-turbo',
          'messages': messages,
          'max_tokens': mode == 'quick' ? 100 : 350,
          'temperature': 0.7,
          'presence_penalty': 0.3,
          'frequency_penalty': 0.2,
        }),
      ).timeout(Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final aiResponse = data['choices'][0]['message']['content'].toString().trim();
        
        // Background mood tracking
        _trackUserMood(conversationHistory, userMessage);
        
        return aiResponse;
      } else if (response.statusCode == 401) {
        return 'AI سروس میں خرابی ہے۔ براہ کرم بعد میں کوشش کریں۔ 🔧';
      } else if (response.statusCode == 429) {
        return 'AI سروس مصروف ہے۔ براہ کرم کچھ دیر بعد کوشش کریں۔ ⏰';
      } else {
        return 'AI سے جواب لینے میں خرابی ہوئی۔ براہ کرم دوبارہ کوشش کریں۔ 🔄';
      }
      
    } catch (e) {
      if (e is TimeoutException) {
        return 'انٹرنیٹ سست ہے۔ براہ کرم دوبارہ کوشش کریں۔ 🐌';
      }
      return 'کنکشن میں خرابی ہے۔ براہ کرم انٹرنیٹ چیک کر کے دوبارہ کوشش کریں۔ 📡';
    }
  }

  // Build context with enhanced mode-specific prompts
  static List<Map<String, String>> _buildContextWithMode({
    required String userMessage,
    required String mode,
    required List<Map<String, String>> conversationHistory,
    Map<String, dynamic>? userProfile,
  }) {
    final messages = <Map<String, String>>[];
    
    // System prompt with mode
    String systemPrompt = '''${_aiModes[mode]?['prompt'] ?? _aiModes['friend']!['prompt']}

اہم ہدایات:
- تمام زبانیں سمجھیں (اردو، رومن اردو، انگریزی، ہندی) لیکن ہمیشہ صرف اردو میں جواب دیں
- جب ضروری ہو تو یہ CBT تکنیکیں قدرتی انداز میں سکھائیں:
  • Pomodoro: "25 منٹ کام کریں، پھر 5 منٹ آرام - یہ concentration بہتر کرتا ہے"
  • Deep Breathing: "4 سیکنڈ سانس اندر، 7 روکیں، 8 میں نکالیں - یہ دل کو شانت کرتا ہے"
  • Self-talk reframe: "میں بے کار ہوں" کی بجائے "میں سیکھ رہا ہوں" سوچیں
  • Impulse control: "جب غصہ آئے تو رکیں، سانس لیں، 5 سے 1 گنیں، پھر بولیں"
  • Grounding: "5 چیزیں دیکھیں، 4 چھوئیں، 3 آوازیں سنیں - یہ anxiety کم کرتا ہے"
- صرف context کے مطابق تکنیکیں بتائیں، force نہ کریں
- جوابات میں مناسب emojis استعمال کریں لیکن زیادہ نہیں
- گرم جوش، محبت بھرا اور مددگار انداز رکھیں''';

    // Add user context if available
    if (userProfile != null && userProfile.isNotEmpty) {
      final profileInfo = <String>[];
      if (userProfile['name'] != null && userProfile['name'].toString().isNotEmpty) {
        profileInfo.add('نام: ${userProfile['name']}');
      }
      if (userProfile['age'] != null) profileInfo.add('عمر: ${userProfile['age']} سال');
      if (userProfile['city'] != null && userProfile['city'].toString().isNotEmpty) {
        profileInfo.add('شہر: ${userProfile['city']}');
      }
      if (userProfile['currentMood'] != null) profileInfo.add('موجودہ موڈ: ${userProfile['currentMood']}');
      if (userProfile['stressLevel'] != null) profileInfo.add('تناؤ کی سطح: ${userProfile['stressLevel']}/10');
      
      if (profileInfo.isNotEmpty) {
        systemPrompt += '\n\nUser کی معلومات:\n${profileInfo.join('\n')}';
      }
    }

    messages.add({'role': 'system', 'content': systemPrompt});

    // Add recent conversation history (last 8 messages for better context)
    final recentHistory = conversationHistory.length > 8 
        ? conversationHistory.sublist(conversationHistory.length - 8)
        : conversationHistory;
    
    for (final historyMessage in recentHistory) {
      messages.add({
        'role': historyMessage['role']!,
        'content': historyMessage['content']!,
      });
    }

    // Add current message
    messages.add({'role': 'user', 'content': userMessage});

    return messages;
  }

  // Enhanced mood tracking
  static Future<void> _trackUserMood(
    List<Map<String, String>> conversationHistory,
    String userMessage,
  ) async {
    try {
      final moodData = _analyzeMoodFromText(userMessage);
      
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      // Get existing mood logs
      final moodLogsJson = prefs.getString('mood_logs') ?? '{}';
      final Map<String, dynamic> moodLogs = json.decode(moodLogsJson);
      
      // Add today's mood (only if mood changed or first time)
      final existingMood = moodLogs[today];
      if (existingMood == null || existingMood['mood'] != moodData['mood']) {
        moodLogs[today] = {
          'mood': moodData['mood'],
          'stressLevel': moodData['stressLevel'],
          'timestamp': DateTime.now().toIso8601String(),
          'lastMessage': userMessage.substring(0, userMessage.length.clamp(0, 150)),
          'keywords': moodData['keywords'],
        };
      }
      
      // Remove logs older than 28 days
      final cutoffDate = DateTime.now().subtract(Duration(days: 28));
      moodLogs.removeWhere((key, value) {
        try {
          final date = DateTime.parse(key);
          return date.isBefore(cutoffDate);
        } catch (e) {
          return true;
        }
      });
      
      await prefs.setString('mood_logs', json.encode(moodLogs));
    } catch (e) {
      // Silent fail
    }
  }

  // Enhanced mood analysis
  static Map<String, dynamic> _analyzeMoodFromText(String text) {
    final lowerText = text.toLowerCase();
    
    String mood = '😐'; // neutral
    int stressLevel = 5;
    List<String> keywords = [];
    
    // Very happy indicators
    if (lowerText.contains(RegExp(r'بہت خوش|very happy|excellent|amazing|fantastic|شاندار|بہترین|perfect|best day|خوشی|بہت اچھا'))) {
      mood = '😄';
      stressLevel = 2;
      keywords.add('خوشی');
    }
    // Happy indicators
    else if (lowerText.contains(RegExp(r'خوش|happy|اچھا|بہتر|شکر|ٹھیک|alhamdulillah|great|good|fine|ok|okay|better'))) {
      mood = '😊';
      stressLevel = 3;
      keywords.add('خوش');
    }
    // Very sad/depressed
    else if (lowerText.contains(RegExp(r'بہت اداس|very sad|extremely|horrible|awful|terrible|depression|ڈپریشن|بے حد|worst|خودکشی'))) {
      mood = '😰';
      stressLevel = 9;
      keywords.add('شدید اداسی');
    }
    // Sad indicators
    else if (lowerText.contains(RegExp(r'اداس|sad|پریشان|worried|upset|down|depressed|غمگین|مایوس|دل ٹوٹا|hurt'))) {
      mood = '😔';
      stressLevel = 7;
      keywords.add('اداسی');
    }
    // Angry/frustrated
    else if (lowerText.contains(RegExp(r'غصہ|angry|mad|furious|غضب|ناراض|frustrated|irritated|annoyed|پاگل|کریزی'))) {
      mood = '😠';
      stressLevel = 8;
      keywords.add('غصہ');
    }
    // Anxious/stressed
    else if (lowerText.contains(RegExp(r'تناؤ|stress|tension|pressure|exam|امتحان|deadline|anxiety|worried|nervous|گھبراہٹ|بے چینی'))) {
      mood = '😰';
      stressLevel = 8;
      keywords.add('تناؤ');
    }
    // Tired/exhausted
    else if (lowerText.contains(RegExp(r'تھکا|tired|exhausted|fatigue|کمزور|نیند|sleepy|worn out'))) {
      mood = '😴';
      stressLevel = 6;
      keywords.add('تھکان');
    }
    // Confused
    else if (lowerText.contains(RegExp(r'confused|پریشان|doubt|شک|سمجھ نہیں|unclear|uncertain'))) {
      mood = '😕';
      stressLevel = 6;
      keywords.add('الجھن');
    }
    
    return {
      'mood': mood, 
      'stressLevel': stressLevel,
      'keywords': keywords,
    };
  }

  // Generate conversation summary after 4+ user messages
  static Future<String> generateConversationSummary(List<Map<String, String>> conversation) async {
    if (!isConfigured() || conversation.length < 8) return ''; // 4 user + 4 AI = 8 total

    try {
      // Get user messages only for summary
      final userMessages = conversation
          .where((msg) => msg['role'] == 'user')
          .map((msg) => msg['content'] ?? '')
          .take(8) // Take recent messages
          .join(' ');

      bool hasInternet = await hasInternetConnection();
      if (!hasInternet) return '';

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'آپ کو conversation کا بالکل 30-40 الفاظ میں اردو خلاصہ بنانا ہے۔ صرف خلاصہ لکھیں، کوئی اضافی بات نہیں۔ موضوع اور جذبات دونوں mention کریں۔',
            },
            {
              'role': 'user',
              'content': 'اس گفتگو کا خلاصہ بنائیں: $userMessages',
            }
          ],
          'max_tokens': 80,
          'temperature': 0.4,
        }),
      ).timeout(Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'].toString().trim();
      }
    } catch (e) {
      // Silent fail
    }
    
    // Fallback summary based on conversation length
    return 'ذہنی صحت اور جذباتی بہتری پر بات چیت';
  }

  // Auto-save conversation summary after every 4th user message
  static Future<void> autoSaveConversationSummary(List<Map<String, String>> conversation) async {
    try {
      final userMessageCount = conversation.where((msg) => msg['role'] == 'user').length;
      
      // Save summary after 4th user message and every 4 messages after that
      if (userMessageCount >= 4 && userMessageCount % 4 == 0) {
        final summary = await generateConversationSummary(conversation);
        if (summary.isNotEmpty) {
          await saveConversationSummary(summary);
        }
      }
    } catch (e) {
      // Silent fail
    }
  }

  // Save conversation summary with enhanced metadata
  static Future<void> saveConversationSummary(String summary) async {
    if (summary.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final conversationHistoryJson = prefs.getString('conversation_summaries') ?? '[]';
      final List<dynamic> summaries = json.decode(conversationHistoryJson);
      
      final now = DateTime.now();
      summaries.add({
        'summary': summary,
        'date': now.toIso8601String().split('T')[0],
        'time': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        'timestamp': now.toIso8601String(),
        'day': _getDayName(now.weekday),
      });
      
      // Keep only last 25 summaries
      if (summaries.length > 25) {
        summaries.removeRange(0, summaries.length - 25);
      }
      
      await prefs.setString('conversation_summaries', json.encode(summaries));
    } catch (e) {
      // Silent fail
    }
  }

  // Get day name in Urdu
  static String _getDayName(int weekday) {
    const days = ['پیر', 'منگل', 'بدھ', 'جمعرات', 'جمعہ', 'ہفتہ', 'اتوار'];
    return days[weekday - 1];
  }

  // Get conversation summaries
  static Future<List<Map<String, dynamic>>> getConversationSummaries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conversationHistoryJson = prefs.getString('conversation_summaries') ?? '[]';
      final List<dynamic> summaries = json.decode(conversationHistoryJson);
      
      return summaries.cast<Map<String, dynamic>>().reversed.toList();
    } catch (e) {
      return [];
    }
  }

  // Get mood logs with 28-day automatic cleanup
  static Future<Map<String, dynamic>> getMoodLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final moodLogsJson = prefs.getString('mood_logs') ?? '{}';
      Map<String, dynamic> moodLogs = json.decode(moodLogsJson);
      
      // Clean up logs older than 28 days
      final cutoffDate = DateTime.now().subtract(Duration(days: 28));
      bool needsCleanup = false;
      
      moodLogs.removeWhere((key, value) {
        try {
          final date = DateTime.parse(key);
          if (date.isBefore(cutoffDate)) {
            needsCleanup = true;
            return true;
          }
          return false;
        } catch (e) {
          needsCleanup = true;
          return true; // Remove invalid entries
        }
      });
      
      // Save cleaned data if cleanup occurred
      if (needsCleanup) {
        await prefs.setString('mood_logs', json.encode(moodLogs));
      }
      
      return moodLogs;
    } catch (e) {
      return {};
    }
  }

  // Get available AI modes with emojis
  static Map<String, Map<String, String>> getAvailableModes() {
    return _aiModes.map((key, value) => MapEntry(key, {
      'name': value['name']!,
      'emoji': value['emoji']!,
    }));
  }

  // Update user mood manually
  static Future<void> updateUserMood(String mood, int stressLevel, {DateTime? lastCried}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_mood', mood);
      await prefs.setInt('stress_level', stressLevel);
      
      if (lastCried != null) {
        await prefs.setString('last_cried', lastCried.toIso8601String());
      }
      
      // Also update today's mood log
      final today = DateTime.now().toIso8601String().split('T')[0];
      final moodLogsJson = prefs.getString('mood_logs') ?? '{}';
      final Map<String, dynamic> moodLogs = json.decode(moodLogsJson);
      
      moodLogs[today] = {
        'mood': mood,
        'stressLevel': stressLevel,
        'timestamp': DateTime.now().toIso8601String(),
        'manual': true,
        'keywords': ['دستی اپڈیٹ'],
      };
      
      await prefs.setString('mood_logs', json.encode(moodLogs));
    } catch (e) {
      // Silent fail
    }
  }

  // Get user profile with enhanced data
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'name': prefs.getString('user_name') ?? '',
        'age': prefs.getInt('user_age'),
        'city': prefs.getString('user_city') ?? '',
        'profilePic': prefs.getString('profile_pic') ?? '',
        'currentMood': prefs.getString('current_mood') ?? '😐',
        'stressLevel': prefs.getInt('stress_level') ?? 5,
        'lastCried': prefs.getString('last_cried'),
        'joinDate': prefs.getString('join_date') ?? DateTime.now().toIso8601String().split('T')[0],
        'totalChats': prefs.getInt('total_chats') ?? 0,
      };
    } catch (e) {
      return {};
    }
  }

  // Update user profile
  static Future<void> updateUserProfile(Map<String, dynamic> profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (profile['name'] != null) await prefs.setString('user_name', profile['name']);
      if (profile['age'] != null) await prefs.setInt('user_age', profile['age']);
      if (profile['city'] != null) await prefs.setString('user_city', profile['city']);
      if (profile['profilePic'] != null) await prefs.setString('profile_pic', profile['profilePic']);
      if (profile['currentMood'] != null) await prefs.setString('current_mood', profile['currentMood']);
      if (profile['stressLevel'] != null) await prefs.setInt('stress_level', profile['stressLevel']);
      if (profile['lastCried'] != null) await prefs.setString('last_cried', profile['lastCried']);
      
    } catch (e) {
      // Silent fail
    }
  }

  // Increment chat counter
  static Future<void> incrementChatCounter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt('total_chats') ?? 0;
      await prefs.setInt('total_chats', currentCount + 1);
    } catch (e) {
      // Silent fail
    }
  }

  // Clear all data
  static Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      // Silent fail
    }
  }

  // Clear current conversation only
  static Future<void> clearCurrentConversation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_conversation');
    } catch (e) {
      // Silent fail
    }
  }

  // Test connection with timeout
  static Future<bool> testConnection() async {
    try {
      bool hasInternet = await hasInternetConnection();
      if (!hasInternet) return false;
      
      if (!isConfigured()) return false;

      final result = await generateResponse(
        userMessage: "test connection",
        mode: 'quick',
        conversationHistory: [],
        userProfile: {},
      );
      return !result.contains('براہ کرم انٹرنیٹ') && !result.contains('AI سروس');
    } catch (e) {
      return false;
    }
  }

  // Get app statistics
  static Future<Map<String, dynamic>> getAppStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profile = await getUserProfile();
      final summaries = await getConversationSummaries();
      final moodLogs = await getMoodLogs();
      
      return {
        'totalChats': profile['totalChats'] ?? 0,
        'totalSummaries': summaries.length,
        'moodLogsCount': moodLogs.length,
        'joinDate': profile['joinDate'],
        'hasProfile': (profile['name']?.toString().isNotEmpty ?? false),
      };
    } catch (e) {
      return {};
    }
  }
}