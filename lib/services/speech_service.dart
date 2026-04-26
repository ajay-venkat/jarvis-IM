import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  bool get isListening => _speech.isListening;
  bool get isAvailable => _isInitialized;

  /// Initialize speech recognition engine.
  Future<bool> init() async {
    try {
      _isInitialized = await _speech.initialize(
        onError: (error) {
          print('SpeechService error: ${error.errorMsg}');
        },
        onStatus: (status) {
          print('SpeechService status: $status');
        },
        debugLogging: false,
      );
      return _isInitialized;
    } catch (e) {
      print('SpeechService init failed: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// Start listening for speech input.
  Future<void> startListening({
    required Function(SpeechRecognitionResult) onResult,
    Function(String)? onStatus,
    Duration? listenFor,
    Duration? pauseFor,
  }) async {
    if (!_isInitialized) {
      final success = await init();
      if (!success) return;
    }

    await _speech.listen(
      onResult: onResult,
      listenFor: listenFor ?? const Duration(seconds: 30),
      pauseFor: pauseFor ?? const Duration(seconds: 3),
      partialResults: true,
      cancelOnError: true,
      listenMode: ListenMode.confirmation,
    );
  }

  /// Stop listening.
  Future<void> stopListening() async {
    await _speech.stop();
  }

  /// Cancel listening without processing.
  Future<void> cancelListening() async {
    await _speech.cancel();
  }

  /// Get available locales for speech recognition.
  Future<List<LocaleName>> getLocales() async {
    if (!_isInitialized) return [];
    return await _speech.locales();
  }
}
