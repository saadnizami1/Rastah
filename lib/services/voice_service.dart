import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  // Speech to Text
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  
  // Text to Speech
  final FlutterTts _flutterTts = FlutterTts();
  bool _ttsEnabled = false;

  // Stream controllers
  final StreamController<bool> _listeningStateController = StreamController<bool>.broadcast();
  final StreamController<bool> _speakingStateController = StreamController<bool>.broadcast();
  final StreamController<String> _recognizedTextController = StreamController<String>.broadcast();

  // Getters for streams
  Stream<bool> get listeningState => _listeningStateController.stream;
  Stream<bool> get speakingState => _speakingStateController.stream;
  Stream<String> get recognizedText => _recognizedTextController.stream;

  // Current states
  bool _isListening = false;
  bool _isSpeaking = false;
  String _lastRecognizedText = '';

  Future<void> initialize() async {
    try {
      // Initialize Speech to Text
      _speechEnabled = await _speechToText.initialize(
        onError: (error) {
          debugPrint('Speech recognition error: $error');
          _listeningStateController.add(false);
          _isListening = false;
        },
        onStatus: (status) {
          debugPrint('Speech recognition status: $status');
          if (status == 'done' || status == 'notListening') {
            _listeningStateController.add(false);
            _isListening = false;
          }
        },
      );

      // Initialize Text to Speech
      await _initializeTTS();

      debugPrint('Voice service initialized - Speech: $_speechEnabled, TTS: $_ttsEnabled');
    } catch (e) {
      debugPrint('Error initializing voice service: $e');
    }
  }

  Future<void> _initializeTTS() async {
    try {
      // Set TTS language to Urdu if available, fallback to English
      var languages = await _flutterTts.getLanguages;
      
      if (languages.contains('ur-PK') || languages.contains('ur')) {
        await _flutterTts.setLanguage('ur-PK');
      } else if (languages.contains('en-US')) {
        await _flutterTts.setLanguage('en-US');
      }

      await _flutterTts.setSpeechRate(0.6); // Slower rate for better comprehension
      await _flutterTts.setVolume(0.8);
      await _flutterTts.setPitch(1.0);

      // Set up TTS callbacks
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        _speakingStateController.add(true);
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        _speakingStateController.add(false);
      });

      _flutterTts.setErrorHandler((message) {
        debugPrint('TTS Error: $message');
        _isSpeaking = false;
        _speakingStateController.add(false);
      });

      _ttsEnabled = true;
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
      _ttsEnabled = false;
    }
  }

  // Permission handling
  Future<bool> checkMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;
      return status.isGranted;
    } catch (e) {
      debugPrint('Error checking microphone permission: $e');
      return false;
    }
  }

  Future<bool> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('Error requesting microphone permission: $e');
      return false;
    }
  }

  // Speech to Text methods
  Future<void> startListening() async {
    if (!_speechEnabled) {
      debugPrint('Speech recognition not enabled');
      return;
    }

    if (_isListening) {
      debugPrint('Already listening');
      return;
    }

    try {
      final hasPermission = await checkMicrophonePermission();
      if (!hasPermission) {
        debugPrint('Microphone permission not granted');
        return;
      }

      _lastRecognizedText = '';
      _recognizedTextController.add('');

      await _speechToText.listen(
        onResult: (result) {
          _lastRecognizedText = result.recognizedWords;
          _recognizedTextController.add(_lastRecognizedText);
          
          if (result.finalResult) {
            _isListening = false;
            _listeningStateController.add(false);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'en_US', // Use English for better recognition, can be changed to 'ur_PK' if available
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      );

      _isListening = true;
      _listeningStateController.add(true);
    } catch (e) {
      debugPrint('Error starting speech recognition: $e');
      _isListening = false;
      _listeningStateController.add(false);
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speechToText.stop();
      _isListening = false;
      _listeningStateController.add(false);
    } catch (e) {
      debugPrint('Error stopping speech recognition: $e');
    }
  }

  // Text to Speech methods
  Future<void> speak(String text) async {
    if (!_ttsEnabled) {
      debugPrint('TTS not enabled');
      return;
    }

    if (_isSpeaking) {
      await stop();
    }

    try {
      // Clean the text for better TTS
      String cleanText = _cleanTextForTTS(text);
      await _flutterTts.speak(cleanText);
    } catch (e) {
      debugPrint('Error speaking text: $e');
      _isSpeaking = false;
      _speakingStateController.add(false);
    }
  }

  String _cleanTextForTTS(String text) {
    // Remove excessive punctuation and clean up text for better TTS
    return text
        .replaceAll(RegExp(r'[۔]{2,}'), '۔') // Remove multiple Urdu periods
        .replaceAll(RegExp(r'[.]{2,}'), '.') // Remove multiple periods
        .replaceAll(RegExp(r'[!]{2,}'), '!') // Remove multiple exclamations
        .replaceAll(RegExp(r'[?]{2,}'), '?') // Remove multiple questions
        .trim();
  }

  Future<void> stop() async {
    try {
      if (_isSpeaking) {
        await _flutterTts.stop();
        _isSpeaking = false;
        _speakingStateController.add(false);
      }
      
      if (_isListening) {
        await stopListening();
      }
    } catch (e) {
      debugPrint('Error stopping voice service: $e');
    }
  }

  // Getters for current state
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get isSpeechEnabled => _speechEnabled;
  bool get isTTSEnabled => _ttsEnabled;
  String get lastRecognizedText => _lastRecognizedText;

  // Dispose method
  void dispose() {
    _listeningStateController.close();
    _speakingStateController.close();
    _recognizedTextController.close();
    _speechToText.cancel();
    _flutterTts.stop();
  }
}