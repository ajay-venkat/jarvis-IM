import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import '../models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final int index;

  const ChatBubble({
    super.key,
    required this.message,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final maxBubbleWidth = screenWidth > 600 ? 500.0 : screenWidth * 0.75;

    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      delay: Duration(milliseconds: 50 * (index % 5)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser) ...[
              _buildAvatar(),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isUser
                      ? AppConstants.userBubbleColor
                      : AppConstants.jarvisBubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(AppConstants.borderRadius),
                    topRight: const Radius.circular(AppConstants.borderRadius),
                    bottomLeft: Radius.circular(
                        isUser ? AppConstants.borderRadius : 4),
                    bottomRight: Radius.circular(
                        isUser ? 4 : AppConstants.borderRadius),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isUser
                              ? AppConstants.userBubbleColor
                              : AppConstants.accentColor)
                          .withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isUser)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'JARVIS',
                          style: GoogleFonts.orbitron(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.accentColor.withOpacity(0.7),
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    Text(
                      message.content,
                      style: TextStyle(
                        color: isUser
                            ? Colors.white
                            : Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isUser) ...[
              const SizedBox(width: 8),
              _buildUserAvatar(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppConstants.accentColor.withOpacity(0.3),
            AppConstants.accentColor.withOpacity(0.1),
          ],
        ),
        border: Border.all(
          color: AppConstants.accentColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          'J',
          style: GoogleFonts.orbitron(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppConstants.accentColor,
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppConstants.userBubbleColor,
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.person,
          size: 18,
          color: Colors.white70,
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
