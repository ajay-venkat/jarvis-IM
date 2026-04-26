import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;
  List<Map<String, String>> _voices = [];

  bool get isSpeaking => _isSpeaking;
  List<Map<String, String>> get voices => _voices;

  /// Initialize TTS engine with platform-specific settings.
  Future<void> init() async {
    try {
      // Platform-specific setup
      if (!kIsWeb) {
        if (Platform.isIOS || Platform.isMacOS) {
          await _tts.setSharedInstance(true);
          await _tts.setIosAudioCategory(
            IosTextToSpeechAudioCategory.ambient,
            [
              IosTextToSpeechAudioCategoryOptions.allowBluetooth,
              IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
              IosTextToSpeechAudioCategoryOptions.mixWithOthers,
            ],
            IosTextToSpeechAudioMode.voicePrompt,
          );
        }

        if (Platform.isAndroid) {
          await _tts.setEngine('com.google.android.tts');
        }
      }

      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(1.0);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);

      // Load available voices
      await _loadVoices();

      _tts.setStartHandler(() {
        _isSpeaking = true;
      });

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
      });

      _tts.setCancelHandler(() {
        _isSpeaking = false;
      });

      _tts.setErrorHandler((message) {
        _isSpeaking = false;
        print('TTS Error: $message');
      });

      _isInitialized = true;
    } catch (e) {
      print('TTS init failed: $e');
      _isInitialized = false;
    }
  }

  Future<void> _loadVoices() async {
    try {
      final voiceList = await _tts.getVoices;
      if (voiceList != null) {
        _voices = List<Map<String, String>>.from(
          (voiceList as List).map((v) => Map<String, String>.from(v as Map)),
        );
        // Filter to English voices
        _voices = _voices
            .where((v) =>
                v['locale']?.startsWith('en') == true ||
                v['name']?.toLowerCase().contains('english') == true)
            .toList();
      }
    } catch (e) {
      print('Failed to load voices: $e');
    }
  }

  /// Speak text aloud.
  Future<void> speak(
    String text, {
    VoidCallback? onComplete,
  }) async {
    if (!_isInitialized) await init();

    if (onComplete != null) {
      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        onComplete();
      });
    }

    _isSpeaking = true;
    await _tts.speak(text);
  }

  /// Stop speaking.
  Future<void> stop() async {
    _isSpeaking = false;
    await _tts.stop();
  }

  /// Set speech rate (0.5 to 2.0).
  Future<void> setRate(double rate) async {
    await _tts.setSpeechRate(rate.clamp(0.0, 1.0));
  }

  /// Set pitch (0.5 to 2.0).
  Future<void> setPitch(double pitch) async {
    await _tts.setPitch(pitch.clamp(0.5, 2.0));
  }

  /// Set a specific voice by name.
  Future<void> setVoice(String voiceName) async {
    final voice = _voices.firstWhere(
      (v) => v['name'] == voiceName,
      orElse: () => {},
    );
    if (voice.isNotEmpty) {
      await _tts.setVoice(voice);
    }
  }

  /// Dispose TTS engine.
  Future<void> dispose() async {
    await _tts.stop();
  }
}
