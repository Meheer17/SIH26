import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
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

    await _requestMicrophonePermission();

    try {
      _isSpeechInitialized = await _speechToText.initialize(
        onError: (val) => debugPrint('STT Error: $val'),
        onStatus: (val) => debugPrint('STT Status: $val'),
      );
    } catch (e) {
      debugPrint("Speech-to-Text Initialization Warning: $e");
      _isSpeechInitialized = false;
    }
  }

  Future<bool> _requestMicrophonePermission() async {
    try {
      var status = await Permission.microphone.status;
      if (!status.isGranted) {
        status = await Permission.microphone.request();
      }
      if (status.isPermanentlyDenied) {
        debugPrint("Microphone permission permanently denied. Directing user to App Settings.");
        await openAppSettings();
      }
      return status.isGranted;
    } catch (e) {
      debugPrint("Error requesting microphone permission: $e");
      return false;
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
    try {
      bool hasPermission = await _requestMicrophonePermission();
      if (!hasPermission) {
        debugPrint("Microphone permission not granted by user.");
        if (onStatusChange != null) onStatusChange(false);
        return;
      }

      if (!_isSpeechInitialized) {
        _isSpeechInitialized = await _speechToText.initialize(
          onError: (val) {
            debugPrint('STT Error: ${val.errorMsg} - permanent: ${val.permanent}');
            _isListening = false;
            if (onStatusChange != null) onStatusChange(false);
          },
          onStatus: (status) {
            debugPrint('STT Status: $status');
            if (status == 'listening') {
              _isListening = true;
              if (onStatusChange != null) onStatusChange(true);
            } else if (status == 'notListening' || status == 'done') {
              _isListening = false;
              if (onStatusChange != null) onStatusChange(false);
            }
          },
          debugLogging: kDebugMode,
        );
      }

      if (_isSpeechInitialized && _speechToText.isAvailable) {
        _isListening = true;
        if (onStatusChange != null) onStatusChange(true);

        await _speechToText.listen(
          onResult: (result) {
            if (result.recognizedWords.isNotEmpty) {
              onResult(result.recognizedWords);
            }
          },
          listenOptions: stt.SpeechListenOptions(
            listenFor: const Duration(seconds: 30),
            pauseFor: const Duration(seconds: 5),
            partialResults: true,
            cancelOnError: false,
          ),
        );
      } else {
        debugPrint("Speech recognition not ready. Attempting fresh initialization...");
        _isSpeechInitialized = await _speechToText.initialize(
          onError: (val) => debugPrint('STT Retry Error: ${val.errorMsg}'),
          onStatus: (val) => debugPrint('STT Retry Status: $val'),
          debugLogging: kDebugMode,
        );

        if (_isSpeechInitialized) {
          _isListening = true;
          if (onStatusChange != null) onStatusChange(true);
          await _speechToText.listen(
            onResult: (result) {
              if (result.recognizedWords.isNotEmpty) {
                onResult(result.recognizedWords);
              }
            },
            listenOptions: stt.SpeechListenOptions(
              listenFor: const Duration(seconds: 30),
              pauseFor: const Duration(seconds: 5),
              partialResults: true,
            ),
          );
        } else {
          debugPrint("STT is unavailable on this device. Please grant Microphone permission in Android Settings or install Google Speech Services.");
        }
      }
    } catch (e) {
      debugPrint("Speech STT Exception: $e");
      _isListening = false;
      if (onStatusChange != null) onStatusChange(false);
    }
  }

  Future<void> stopListening({Function(bool isListening)? onStatusChange}) async {
    if (_isListening) {
      try {
        await _speechToText.stop();
      } catch (_) {}
      _isListening = false;
      if (onStatusChange != null) onStatusChange(false);
    }
  }
}
