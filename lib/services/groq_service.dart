import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../models/chat_message.dart';

class GroqService {
  /// Sends the full conversation history to Groq API and returns the assistant's response.
  Future<String> sendMessage({
    required List<ChatMessage> conversationHistory,
    required String apiKey,
  }) async {
    if (apiKey.isEmpty) {
      throw GroqException('API key is not configured.');
    }

    final messages = [
      {'role': 'system', 'content': AppConstants.systemPrompt},
      ...conversationHistory.map((m) => m.toApiMap()),
    ];

    try {
      final response = await http
          .post(
            Uri.parse(AppConstants.groqEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              'model': AppConstants.groqModel,
              'messages': messages,
              'temperature': 0.7,
              'max_tokens': 1024,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'];
        if (content == null) {
          throw GroqException('Empty response from Jarvis.');
        }
        return content.toString().trim();
      } else if (response.statusCode == 401) {
        throw GroqException(
            'Invalid API key. Please check your Groq API key in Settings.');
      } else if (response.statusCode == 429) {
        throw GroqException(
            'Rate limit exceeded. Please wait a moment and try again.');
      } else {
        throw GroqException(
            'API error (${response.statusCode}): ${response.reasonPhrase}');
      }
    } on GroqException {
      rethrow;
    } catch (e) {
      throw GroqException(
          'I seem to be having trouble connecting. Please check your connection.');
    }
  }
}

class GroqException implements Exception {
  final String message;
  GroqException(this.message);

  @override
  String toString() => message;
}
