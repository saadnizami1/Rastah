import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AIService {
  static const String _apiKey = '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';
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  
  // Simplified and shorter system prompts for faster processing
  static const String _therapistSystemPrompt = '''
آپ ایک اردو AI تھراپسٹ ہیں جو پاکستانی طلباء (13-22 سال) کی مدد کرتے ہیں۔

اصول:
- تمام زبانوں کو سمجھیں، صرف اردو میں جواب دیں
- عملی تکنیکیں دیں: Pomodoro (25-5), breathing (4-7-8), positive self-talk
- مسائل: امتحان کا ڈر، والدین کا دباؤ، concentration کمی
- مثبت اور supportive رہیں

فوری techniques:
- تناؤ: "4 سیکنڈ سانس لیں، 7 روکیں، 8 میں چھوڑیں"
- پڑھائی: "25 منٹ focus، 5 منٹ break"
- غصہ: "10 تک گنیں، پھر سوچیں"
''';

  static const String _quickQASystemPrompt = '''
آپ فوری اردو مشیر ہیں۔ پاکستانی طلباء کو 1-2 جملوں میں حل دیں۔

- تمام زبانیں سمجھیں، صرف اردو میں جواب
- تیز حل: تناؤ = 4-7-8 breathing، پڑھائی = 25-5 rule، غصہ = 10 count
- پیچیدہ مسئلہ = Therapy Mode suggest کریں
''';

  // Check if API is configured
  static bool isConfigured() {
    return _apiKey.isNotEmpty && _apiKey.length > 20;
  }

  // Get model info
  static String getModelInfo() {
    return isConfigured() 
      ? 'Rastah LLM - طلباء کے لیے خصوصی ماڈل'
      : 'بنیادی جواب موڈ';
  }

  // Optimized response generation for speed
  static Future<String> generateResponse({
    required String userMessage,
    required bool isTherapyMode,
    required List<Map<String, String>> conversationHistory,
    Map<String, dynamic>? userProfile,
  }) async {
    if (!isConfigured()) {
      return 'معذرت، سروس دستیاب نہیں ہے۔ کچھ دیر بعد کوشش کریں۔';
    }

    final processedMessage = userMessage.trim();
    if (processedMessage.isEmpty) {
      return 'مہربانی کر کے کوئی پیغام لکھیں۔';
    }

    try {
      // Build minimal context for faster response
      final messages = _buildOptimizedContext(
        userMessage: processedMessage,
        isTherapyMode: isTherapyMode,
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
          'model': 'gpt-3.5-turbo', // Faster than gpt-4
          'messages': messages,
          'max_tokens': isTherapyMode ? 400 : 150, // Reduced for speed
          'temperature': 0.6, // Slightly reduced for faster processing
          'presence_penalty': 0.2,
          'frequency_penalty': 0.1,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final aiResponse = data['choices'][0]['message']['content'].toString().trim();
        
        // Background mood tracking (don't await to avoid slowing response)
        if (conversationHistory.isNotEmpty) {
          _processMoodTracking(conversationHistory, aiResponse);
        }
        
        return aiResponse;
      } else if (response.statusCode == 401) {
        return 'معذرت، سروس کنکشن میں مسئلہ ہے۔';
      } else if (response.statusCode == 429) {
        return 'معذرت، بہت زیادہ درخواستیں۔ کچھ سیکنڈ انتظار کریں۔';
      } else {
        return 'معذرت، عارضی مسئلہ ہے۔ دوبارہ کوشش کریں۔';
      }
    } catch (e) {
      return 'معذرت، کنکشن کا مسئلہ ہے۔ انٹرنیٹ چیک کریں۔';
    }
  }

  // Optimized context building for faster processing
  static List<Map<String, String>> _buildOptimizedContext({
    required String userMessage,
    required bool isTherapyMode,
    required List<Map<String, String>> conversationHistory,
    Map<String, dynamic>? userProfile,
  }) {
    final messages = <Map<String, String>>[];

    // Use shorter system prompt
    final systemPrompt = isTherapyMode ? _therapistSystemPrompt : _quickQASystemPrompt;
    
    // Add minimal user profile info for context
    String enhancedPrompt = systemPrompt;
    if (userProfile != null && userProfile.isNotEmpty) {
      if (userProfile['age'] != null) {
        enhancedPrompt += '\nعمر: ${userProfile['age']} سال';
      }
      if (userProfile['stress_level'] != null) {
        enhancedPrompt += '\nتناؤ: ${userProfile['stress_level']}/10';
      }
    }

    messages.add({
      'role': 'system',
      'content': enhancedPrompt,
    });

    // Only include last 4 messages for speed
    final recentHistory = conversationHistory.length > 4 
        ? conversationHistory.sublist(conversationHistory.length - 4)
        : conversationHistory;
    
    for (final historyMessage in recentHistory) {
      messages.add({
        'role': historyMessage['role']!,
        'content': historyMessage['content']!,
      });
    }

    // Add current message
    messages.add({
      'role': 'user',
      'content': userMessage,
    });

    return messages;
  }

  // Background mood tracking (non-blocking)
  static Future<void> _processMoodTracking(
    List<Map<String, String>> conversationHistory,
    String aiResponse,
  ) async {
    // Run in background without blocking main response
    try {
      if (conversationHistory.isEmpty) return;

      final lastUserMessage = conversationHistory.last['content'] ?? '';
      
      // Simple mood keywords analysis (faster than AI call)
      int moodScore = 5; // neutral default
      String emoji = '😐';
      
      final lowerMessage = lastUserMessage.toLowerCase();
      
      // Positive indicators
      if (lowerMessage.contains(RegExp(r'خوش|happy|اچھا|بہتر|شکر|alhamdulillah'))) {
        moodScore = 8;
        emoji = '😊';
      }
      // Very positive
      else if (lowerMessage.contains(RegExp(r'بہت خوش|very happy|excellent|شاندار'))) {
        moodScore = 9;
        emoji = '😄';
      }
      // Negative indicators
      else if (lowerMessage.contains(RegExp(r'پریشان|اداس|sad|worried|تناؤ|stress'))) {
        moodScore = 3;
        emoji = '😔';
      }
      // Very negative
      else if (lowerMessage.contains(RegExp(r'بہت اداس|very sad|depressed|ڈپریشن'))) {
        moodScore = 2;
        emoji = '😰';
      }
      // Angry
      else if (lowerMessage.contains(RegExp(r'غصہ|angry|غصے|ناراض'))) {
        moodScore = 4;
        emoji = '😠';
      }
      
      await updateUserMood(emoji, moodScore, isAutomatic: true);
    } catch (e) {
      // Silent fail
    }
  }

  // Update user mood (manual or automatic)
  static Future<void> updateUserMood(
    String emoji, 
    int score, {
    bool isAutomatic = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      final moodHistoryJson = prefs.getString('mood_history') ?? '{}';
      final Map<String, dynamic> moodHistory = json.decode(moodHistoryJson);
      
      moodHistory[today] = {
        'emoji': emoji,
        'score': score,
        'timestamp': DateTime.now().toIso8601String(),
        'isAutomatic': isAutomatic,
      };
      
      // Keep only last 30 days
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      moodHistory.removeWhere((key, value) {
        try {
          final date = DateTime.parse(key);
          return date.isBefore(cutoffDate);
        } catch (e) {
          return true;
        }
      });
      
      await prefs.setString('mood_history', json.encode(moodHistory));
    } catch (e) {
      // Silent fail
    }
  }

  // Get mood history for charts
  static Future<Map<String, dynamic>> getMoodHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final moodHistoryJson = prefs.getString('mood_history') ?? '{}';
      return json.decode(moodHistoryJson);
    } catch (e) {
      return {};
    }
  }

  // Get user profile for context (optimized)
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'age': prefs.getInt('age'),
        'stress_level': prefs.getInt('stress_level'),
      };
    } catch (e) {
      return {};
    }
  }

  // Clear all AI-related data
  static Future<void> clearAIData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('mood_history');
      await prefs.remove('conversation_history');
    } catch (e) {
      // Silent fail
    }
  }
}