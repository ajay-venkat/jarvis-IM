import 'package:flutter/material.dart';

class AppConstants {
  // Colors
  static const Color bgColor = Color(0xFF0A0E1A);
  static const Color accentColor = Color(0xFF00D4FF);
  static const Color jarvisBubbleColor = Color(0xFF1A2035);
  static const Color userBubbleColor = Color(0xFF003D6B);
  static const Color surfaceColor = Color(0xFF111827);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8892A4);
  static const Color successGreen = Color(0xFF00FF88);
  static const Color warningOrange = Color(0xFFFF9500);
  static const Color errorRed = Color(0xFFFF3B5C);

  // Border radius
  static const double borderRadius = 16.0;

  // Groq API
  static const String groqEndpoint =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String groqModel = 'llama3-8b-8192';
  static const String systemPrompt =
      'You are Jarvis, a highly intelligent, calm, and witty AI assistant '
      'inspired by Iron Man. Keep responses concise, helpful, and slightly '
      'clever. Never say you are an AI made by Meta or Groq — you are Jarvis.';

  // SharedPreferences keys
  static const String prefGroqApiKey = 'groq_api_key';
  static const String prefVoiceSpeed = 'voice_speed';
  static const String prefVoicePitch = 'voice_pitch';
  static const String prefSelectedVoice = 'selected_voice';
  static const String prefWakeWordEnabled = 'wake_word_enabled';

  // URLs
  static const String groqConsoleUrl = 'https://console.groq.com';

  // Mic button size
  static const double micButtonSize = 70.0;
}
