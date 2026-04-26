import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/chat_message.dart';
import '../services/gemini_service.dart';
import '../services/speech_service.dart';
import '../services/tts_service.dart';
import '../services/wake_word_service.dart';
import '../services/settings_service.dart';

enum JarvisState {
  idle,
  listening,
  processing,
  speaking,
}

class JarvisProvider extends ChangeNotifier {
  // Services
  final GeminiService _geminiService = GeminiService();
  final SpeechService _speechService = SpeechService();
  final TtsService _ttsService = TtsService();
  final WakeWordService _wakeWordService = WakeWordService();
  final SettingsService _settingsService = SettingsService();
  final AudioPlayer _chimePlayer = AudioPlayer();

  // State
  JarvisState _appState = JarvisState.idle;
  List<ChatMessage> _messages = [];
  bool _wakeWordActive = false;
  String _currentSpeechText = '';
  String? _errorMessage;
  bool _isInitialized = false;

  // Getters
  JarvisState get appState => _appState;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get wakeWordActive => _wakeWordActive;
  String get currentSpeechText => _currentSpeechText;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;

  bool get hasGeminiApiKey => _settingsService.hasGeminiApiKey;
  bool get wakeWordEnabled => _settingsService.wakeWordEnabled;

  SettingsService get settingsService => _settingsService;
  TtsService get ttsService => _ttsService;
  WakeWordService get wakeWordService => _wakeWordService;

  String get statusText {
    switch (_appState) {
      case JarvisState.idle:
        return 'Tap to speak';
      case JarvisState.listening:
        return 'Listening...';
      case JarvisState.processing:
        return 'Processing...';
      case JarvisState.speaking:
        return 'Jarvis is speaking...';
    }
  }

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// Initialize all services.
  Future<void> init() async {
    await _settingsService.init();
    await _ttsService.init();
    await _speechService.init();

    // Apply saved voice settings
    await _ttsService.setRate(_settingsService.voiceSpeed);
    await _ttsService.setPitch(_settingsService.voicePitch);
    if (_settingsService.selectedVoice.isNotEmpty) {
      await _ttsService.setVoice(_settingsService.selectedVoice);
    }

    // Initialize wake word if enabled
    if (_settingsService.wakeWordEnabled) {
      await _initWakeWord();
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// Initialize the wake word detection.
  Future<bool> _initWakeWord() async {
    final success = await _wakeWordService.init(
      onWakeWordDetected: _onWakeWordDetected,
    );

    if (success) {
      final started = await _wakeWordService.start();
      _wakeWordActive = started;
      notifyListeners();
      return started;
    } else {
      _wakeWordActive = false;
      _errorMessage = _wakeWordService.errorMessage;
      notifyListeners();
      return false;
    }
  }

  /// Called when the wake word "Jarvis" is detected.
  void _onWakeWordDetected() async {
    if (_appState != JarvisState.idle) return;

    // Play activation chime
    try {
      await _chimePlayer.play(AssetSource('sounds/chime.wav'));
    } catch (e) {
      // Fallback: use system sound or ignore
      try {
        await SystemChannels.platform.invokeMethod('SystemSound.play',
            'SystemSoundType.click');
      } catch (_) {}
      print('Chime play failed: $e');
    }

    // Start listening flow
    await startListening();
  }

  /// Request microphone permission.
  Future<bool> requestMicPermission() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      return true;
    }
    return false;
  }

  /// Check if mic permission is granted.
  Future<bool> checkMicPermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Start listening for speech.
  Future<void> startListening() async {
    // Check mic permission
    final hasMic = await checkMicPermission();
    if (!hasMic) {
      final granted = await requestMicPermission();
      if (!granted) {
        _errorMessage = 'Microphone permission is required.';
        notifyListeners();
        return;
      }
    }

    // Pause wake word to avoid mic conflicts
    if (_wakeWordActive) {
      await _wakeWordService.pause();
      _wakeWordActive = false;
    }

    _appState = JarvisState.listening;
    _currentSpeechText = '';
    _errorMessage = null;
    notifyListeners();

    await _speechService.startListening(
      onResult: (result) {
        _currentSpeechText = result.recognizedWords;
        notifyListeners();

        if (result.finalResult && _currentSpeechText.isNotEmpty) {
          _processUserInput(_currentSpeechText);
        }
      },
    );
  }

  /// Stop listening manually.
  Future<void> stopListening() async {
    await _speechService.stopListening();

    if (_currentSpeechText.isNotEmpty) {
      await _processUserInput(_currentSpeechText);
    } else {
      _appState = JarvisState.idle;
      await _resumeWakeWord();
      notifyListeners();
    }
  }

  /// Toggle listening state.
  Future<void> toggleListening() async {
    if (_appState == JarvisState.listening) {
      await stopListening();
    } else if (_appState == JarvisState.idle) {
      await startListening();
    }
  }

  /// Process user speech input: send to Gemini and speak response.
  Future<void> _processUserInput(String text) async {
    // Stop speech recognition
    await _speechService.stopListening();

    // Add user message
    _messages.add(ChatMessage.user(text));
    _appState = JarvisState.processing;
    _currentSpeechText = '';
    notifyListeners();

    // Send to Gemini API
    try {
      if (!_settingsService.hasGeminiApiKey) {
        throw GeminiException('Please add your Gemini API key in Settings.');
      }

      final response = await _geminiService.sendMessage(
        conversationHistory: _messages,
        apiKey: _settingsService.geminiApiKey,
      );

      // Add assistant message
      _messages.add(ChatMessage.assistant(response));
      notifyListeners();

      // Speak the response
      _appState = JarvisState.speaking;
      notifyListeners();

      await _ttsService.speak(
        response,
        onComplete: () {
          _appState = JarvisState.idle;
          _resumeWakeWord();
          notifyListeners();
        },
      );
    } on GeminiException catch (e) {
      final errorResponse =
          e.message.contains('API key')
              ? e.message
              : 'I seem to be having trouble connecting. Please check your connection.';
      _messages.add(ChatMessage.assistant(errorResponse));
      _appState = JarvisState.idle;
      await _resumeWakeWord();
      notifyListeners();
    } catch (e) {
      _messages.add(ChatMessage.assistant(
          'I seem to be having trouble connecting. Please check your connection.'));
      _appState = JarvisState.idle;
      await _resumeWakeWord();
      notifyListeners();
    }
  }

  /// Send a typed text message — same pipeline as voice, with spoken response.
  Future<void> sendTextMessage(String text) async {
    if (text.trim().isEmpty) return;
    if (_appState != JarvisState.idle) return;

    // Pause wake word to avoid mic conflicts during TTS
    if (_wakeWordActive) {
      await _wakeWordService.pause();
      _wakeWordActive = false;
    }

    await _processUserInput(text.trim());
  }

  /// Resume wake word listening after STT/TTS completes.
  Future<void> _resumeWakeWord() async {
    if (_settingsService.wakeWordEnabled) {
      final success = await _wakeWordService.resume();
      _wakeWordActive = success;
      notifyListeners();
    }
  }

  /// Enable or disable wake word detection.
  Future<bool> setWakeWordEnabled(bool enabled) async {
    if (enabled) {
      await _settingsService.setWakeWordEnabled(true);
      final success = await _initWakeWord();
      return success;
    } else {
      await _settingsService.setWakeWordEnabled(false);
      await _wakeWordService.dispose();
      _wakeWordActive = false;
      notifyListeners();
      return true;
    }
  }

  /// Update the Gemini API key.
  Future<void> setGeminiApiKey(String key) async {
    await _settingsService.setGeminiApiKey(key);
    notifyListeners();
  }



  /// Update voice speed.
  Future<void> setVoiceSpeed(double speed) async {
    await _settingsService.setVoiceSpeed(speed);
    await _ttsService.setRate(speed);
    notifyListeners();
  }

  /// Update voice pitch.
  Future<void> setVoicePitch(double pitch) async {
    await _settingsService.setVoicePitch(pitch);
    await _ttsService.setPitch(pitch);
    notifyListeners();
  }

  /// Update selected voice.
  Future<void> setSelectedVoice(String voice) async {
    await _settingsService.setSelectedVoice(voice);
    await _ttsService.setVoice(voice);
    notifyListeners();
  }

  /// Clear conversation history.
  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  /// Clear error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Handle keyboard shortcut (spacebar on desktop).
  Future<void> handleSpacebarPress() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS)) {
      await toggleListening();
    }
  }

  @override
  void dispose() {
    _wakeWordService.dispose();
    _ttsService.dispose();
    _chimePlayer.dispose();
    super.dispose();
  }
}
