class ChatMessage {
  final String role; // 'user', 'assistant', 'system'
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, String> toApiMap() {
    return {
      'role': role,
      'content': content,
    };
  }

  factory ChatMessage.user(String content) {
    return ChatMessage(role: 'user', content: content);
  }

  factory ChatMessage.assistant(String content) {
    return ChatMessage(role: 'assistant', content: content);
  }

  factory ChatMessage.system(String content) {
    return ChatMessage(role: 'system', content: content);
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}
