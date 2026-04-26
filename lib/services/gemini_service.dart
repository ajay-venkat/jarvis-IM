import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../models/chat_message.dart';

class GeminiService {
  /// Sends the full conversation history to Gemini API and returns the assistant's response.
  Future<String> sendMessage({
    required List<ChatMessage> conversationHistory,
    required String apiKey,
  }) async {
    if (apiKey.isEmpty) {
      throw GeminiException('API key is not configured.');
    }

    final endpoint = '${AppConstants.geminiEndpoint}?key=$apiKey';

    // Format history for Gemini structured format
    final contents = conversationHistory.map((m) {
      return {
        'role': m.role == 'user' ? 'user' : 'model',
        'parts': [
          {'text': m.content}
        ]
      };
    }).toList();

    try {
      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'system_instruction': {
                'parts': {'text': AppConstants.systemPrompt}
              },
              'contents': contents,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List<dynamic>?;
        
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content']?['parts']?[0]?['text'];
          if (content != null) {
            return content.toString().trim();
          }
        }
        throw GeminiException('Empty response from Jarvis.');
      } else if (response.statusCode == 400 || response.statusCode == 403) {
        throw GeminiException(
            'Invalid API key. Please check your Gemini API key in Settings.');
      } else if (response.statusCode == 429) {
        throw GeminiException(
            'Rate limit exceeded. Please wait a moment and try again.');
      } else {
        throw GeminiException(
            'API error (${response.statusCode}): ${response.reasonPhrase}');
      }
    } on GeminiException {
      rethrow;
    } catch (e) {
      throw GeminiException(
          'I seem to be having trouble connecting. Please check your connection.');
    }
  }
}

class GeminiException implements Exception {
  final String message;
  GeminiException(this.message);

  @override
  String toString() => message;
}
