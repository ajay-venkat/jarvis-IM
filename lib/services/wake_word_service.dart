import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// State of the wake word detection engine.
enum WakeWordState {
  idle,
  listening,
  paused,
  error,
}

/// Wake word detection using speech_to_text — no API key needed.
/// Continuously listens in the background and triggers when it hears "jarvis".
class WakeWordService {
  stt.SpeechToText? _speech;
  WakeWordState _state = WakeWordState.idle;
  String? _errorMessage;
  Timer? _restartTimer;
  Function? _onWakeWordDetected;
  bool _shouldBeListening = false;

  WakeWordState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isActive => _state == WakeWordState.listening;

  /// Initialize the speech-based wake word listener.
  /// No access key needed — uses the device's built-in speech recognition.
  Future<bool> init({
    String accessKey = '', // kept for API compatibility, ignored
    required Function onWakeWordDetected,
  }) async {
    _onWakeWordDetected = onWakeWordDetected;

    try {
      _speech = stt.SpeechToText();
      final available = await _speech!.initialize(
        onError: (error) {
          debugPrint('Wake word STT error: ${error.errorMsg}');
          // Auto-restart on non-fatal errors
          if (_shouldBeListening && error.errorMsg != 'error_busy') {
            _scheduleRestart();
          }
        },
        onStatus: (status) {
          debugPrint('Wake word STT status: $status');
          // Restart listening when it stops (speech_to_text times out)
          if (status == 'notListening' && _shouldBeListening) {
            _scheduleRestart();
          }
        },
      );

      if (!available) {
        _errorMessage = 'Speech recognition is not available on this device.';
        _state = WakeWordState.error;
        return false;
      }

      _errorMessage = null;
      return true;
    } catch (e) {
      if (e.toString().contains('microphone') ||
          e.toString().contains('audio')) {
        _errorMessage = 'Microphone is busy. Close other apps using the mic.';
      } else {
        _errorMessage = 'Failed to initialize wake word: $e';
      }
      _state = WakeWordState.error;
      return false;
    }
  }

  /// Start listening for the wake word.
  Future<bool> start() async {
    if (_speech == null) return false;

    _shouldBeListening = true;

    try {
      await _speech!.listen(
        onResult: (result) {
          final text = result.recognizedWords.toLowerCase();
          debugPrint('Wake word heard: "$text"');

          // Check if "jarvis" was spoken
          if (text.contains('jarvis')) {
            debugPrint('🎯 Wake word "Jarvis" detected!');
            // Stop listening before triggering callback
            _speech?.stop();
            _shouldBeListening = false;
            _state = WakeWordState.paused;
            _onWakeWordDetected?.call();
          }
        },
        listenMode: stt.ListenMode.dictation,
        cancelOnError: false,
        partialResults: true,
        listenFor: const Duration(seconds: 30), // Listen for 30s then restart
        pauseFor: const Duration(seconds: 5), // Allow 5s silence between words
      );

      _state = WakeWordState.listening;
      _errorMessage = null;
      return true;
    } catch (e) {
      if (e.toString().contains('microphone') ||
          e.toString().contains('audio') ||
          e.toString().contains('recorder') ||
          e.toString().contains('busy')) {
        _errorMessage = 'Microphone is busy. Close other apps using the mic.';
      } else {
        _errorMessage = 'Failed to start wake word detection: $e';
      }
      _state = WakeWordState.error;
      return false;
    }
  }

  /// Pause wake word detection (e.g., when main STT is active).
  Future<void> pause() async {
    _shouldBeListening = false;
    _restartTimer?.cancel();
    if (_speech != null) {
      try {
        await _speech!.stop();
        _state = WakeWordState.paused;
      } catch (e) {
        debugPrint('Wake word pause error: $e');
      }
    }
  }

  /// Resume wake word detection.
  Future<bool> resume() async {
    if (_speech == null) return false;
    return await start();
  }

  /// Stop and dispose the wake word service.
  Future<void> dispose() async {
    _shouldBeListening = false;
    _restartTimer?.cancel();
    if (_speech != null) {
      try {
        await _speech!.stop();
        await _speech!.cancel();
      } catch (e) {
        debugPrint('Wake word dispose error: $e');
      }
      _speech = null;
    }
    _state = WakeWordState.idle;
  }

  /// Schedule a restart after the listener times out or encounters an error.
  void _scheduleRestart() {
    _restartTimer?.cancel();
    _restartTimer = Timer(const Duration(seconds: 1), () async {
      if (_shouldBeListening) {
        debugPrint('Restarting wake word listener...');
        await start();
      }
    });
  }
}
