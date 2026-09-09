import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  late FlutterTts _flutterTts;
  late stt.SpeechToText _speechToText;

  bool _isSpeechInitialized = false;
  bool _isListening = false;
  bool get isListening => _isListening;

  Future<void> init() async {
    _flutterTts = FlutterTts();
    _speechToText = stt.SpeechToText();

    try {
      await _flutterTts.setLanguage("en-IN");
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.5);
    } catch (e) {
      debugPrint("TTS Initialization Warning: $e");
    }

    try {
      _isSpeechInitialized = await _speechToText.initialize(
        onError: (val) => debugPrint('STT Error: $val'),
        onStatus: (val) => debugPrint('STT Status: $val'),
      );
    } catch (e) {
      debugPrint("Speech-to-Text Initialization Warning: $e");
    }
  }

  // --- Text to Speech (TTS) ---
  Future<void> speak(String text, {String language = "en-IN"}) async {
    try {
      await _flutterTts.setLanguage(language);
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint("Native TTS Speak Error: $e");
    }
  }

  Future<void> stopSpeaking() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint("Native TTS Stop Error: $e");
    }
  }

  // --- Speech to Text (ASR) ---
  Future<void> listen({
    required Function(String text) onResult,
    Function(bool isListening)? onStatusChange,
  }) async {
    if (!_isSpeechInitialized) {
      try {
        _isSpeechInitialized = await _speechToText.initialize();
      } catch (e) {
        debugPrint("Speech STT init failed: $e");
      }
    }

    if (_isSpeechInitialized) {
      _isListening = true;
      if (onStatusChange != null) onStatusChange(true);

      _speechToText.listen(
        onResult: (result) {
          onResult(result.recognizedWords);
        },
        listenOptions: stt.SpeechListenOptions(
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 5),
          partialResults: true,
        ),
      );
    } else {
      debugPrint("STT engine not available on this device.");
    }
  }

  Future<void> stopListening({Function(bool isListening)? onStatusChange}) async {
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
      if (onStatusChange != null) onStatusChange(false);
    }
  }
}
