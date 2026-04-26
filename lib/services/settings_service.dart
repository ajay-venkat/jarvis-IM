import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class SettingsService {
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Groq API Key
  String get groqApiKey => _prefs.getString(AppConstants.prefGroqApiKey) ?? '';
  Future<void> setGroqApiKey(String key) async {
    await _prefs.setString(AppConstants.prefGroqApiKey, key);
  }

  bool get hasGroqApiKey => groqApiKey.isNotEmpty;

  // Voice Speed
  double get voiceSpeed =>
      _prefs.getDouble(AppConstants.prefVoiceSpeed) ?? 1.0;
  Future<void> setVoiceSpeed(double speed) async {
    await _prefs.setDouble(AppConstants.prefVoiceSpeed, speed);
  }

  // Voice Pitch
  double get voicePitch =>
      _prefs.getDouble(AppConstants.prefVoicePitch) ?? 1.0;
  Future<void> setVoicePitch(double pitch) async {
    await _prefs.setDouble(AppConstants.prefVoicePitch, pitch);
  }

  // Selected Voice
  String get selectedVoice =>
      _prefs.getString(AppConstants.prefSelectedVoice) ?? '';
  Future<void> setSelectedVoice(String voice) async {
    await _prefs.setString(AppConstants.prefSelectedVoice, voice);
  }

  // Wake Word Enabled
  bool get wakeWordEnabled =>
      _prefs.getBool(AppConstants.prefWakeWordEnabled) ?? false;
  Future<void> setWakeWordEnabled(bool enabled) async {
    await _prefs.setBool(AppConstants.prefWakeWordEnabled, enabled);
  }
}
