import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../constants/app_constants.dart';
import '../providers/jarvis_provider.dart';
import '../widgets/arc_reactor.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/wake_word_indicator.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _keyboardFocusNode = FocusNode();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFieldFocusNode = FocusNode();
  bool _isTextFieldFocused = false;

  @override
  void initState() {
    super.initState();

    // Initialize the provider services
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<JarvisProvider>();
      provider.init();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _keyboardFocusNode.dispose();
    _textController.dispose();
    _textFieldFocusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool get _isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: (event) {
        // Only handle spacebar when text field is NOT focused
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.space &&
            _isDesktop &&
            !_isTextFieldFocused) {
          context.read<JarvisProvider>().handleSpacebarPress();
        }
      },
      child: Scaffold(
        backgroundColor: AppConstants.bgColor,
        body: SafeArea(
          child: Consumer<JarvisProvider>(
            builder: (context, provider, _) {
              // Auto-scroll when messages change
              if (provider.messages.isNotEmpty) {
                _scrollToBottom();
              }

              return Column(
                children: [
                  // Top bar: Wake word indicator + Settings
                  _buildTopBar(provider),

                  // Main content
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),

                          // Greeting
                          _buildGreeting(provider),

                          const SizedBox(height: 24),

                          // Arc Reactor
                          _buildArcReactor(provider),

                          const SizedBox(height: 16),

                          // Status text
                          _buildStatusText(provider),

                          // Speech recognition text preview
                          if (provider.appState == JarvisState.listening &&
                              provider.currentSpeechText.isNotEmpty)
                            _buildSpeechPreview(provider),

                          const SizedBox(height: 8),

                          // API key warning banner
                          if (!provider.hasGroqApiKey)
                            _buildApiKeyBanner(context),

                          // Error banner
                          if (provider.errorMessage != null)
                            _buildErrorBanner(provider),

                          const SizedBox(height: 8),

                          // Chat messages
                          ...provider.messages.asMap().entries.map((entry) {
                            return ChatBubble(
                              message: entry.value,
                              index: entry.key,
                            );
                          }),

                          // Typing indicator
                          if (provider.appState == JarvisState.processing)
                            const TypingIndicator(),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // Bottom area: text input + mic button
        bottomNavigationBar: Consumer<JarvisProvider>(
          builder: (context, provider, _) {
            return _buildBottomInputArea(provider);
          },
        ),
      ),
    );
  }

  Widget _buildTopBar(JarvisProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Wake word indicator
          WakeWordIndicator(isActive: provider.wakeWordActive),

          // Settings button
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppConstants.surfaceColor.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.05),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.settings_outlined,
                color: AppConstants.textSecondary,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting(JarvisProvider provider) {
    return FadeIn(
      child: Text(
        '${provider.greeting}, Sir',
        style: GoogleFonts.orbitron(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: AppConstants.textSecondary,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildArcReactor(JarvisProvider provider) {
    final size = _isDesktop ? 200.0 : 160.0;
    return ArcReactor(
      state: provider.appState,
      size: size,
      onTap: () {
        if (provider.appState == JarvisState.idle) {
          provider.startListening();
        } else if (provider.appState == JarvisState.listening) {
          provider.stopListening();
        }
      },
    );
  }

  Widget _buildStatusText(JarvisProvider provider) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        provider.statusText,
        key: ValueKey(provider.statusText),
        style: GoogleFonts.orbitron(
          fontSize: 13,
          color: _getStatusColor(provider.appState),
          letterSpacing: 2,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Color _getStatusColor(JarvisState state) {
    switch (state) {
      case JarvisState.idle:
        return AppConstants.textSecondary;
      case JarvisState.listening:
        return AppConstants.accentColor;
      case JarvisState.processing:
        return AppConstants.warningOrange;
      case JarvisState.speaking:
        return AppConstants.successGreen;
    }
  }

  Widget _buildSpeechPreview(JarvisProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppConstants.accentColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Text(
          provider.currentSpeechText,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppConstants.accentColor.withOpacity(0.8),
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _buildApiKeyBanner(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppConstants.warningOrange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppConstants.warningOrange.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppConstants.warningOrange,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Please add your Groq API key in Settings',
                style: TextStyle(
                  color: AppConstants.warningOrange,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppConstants.warningOrange.withOpacity(0.6),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(JarvisProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppConstants.errorRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.errorRed.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: AppConstants.errorRed,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              provider.errorMessage!,
              style: TextStyle(
                color: AppConstants.errorRed,
                fontSize: 13,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => provider.clearError(),
            child: Icon(
              Icons.close,
              color: AppConstants.errorRed.withOpacity(0.6),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInputArea(JarvisProvider provider) {
    final isListening = provider.appState == JarvisState.listening;
    final isIdle = provider.appState == JarvisState.idle;
    final canTap = isIdle || isListening;
    final micSize = _isDesktop ? 50.0 : 56.0;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Text input field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppConstants.bgColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _isTextFieldFocused
                      ? AppConstants.accentColor.withOpacity(0.4)
                      : Colors.white.withOpacity(0.08),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _textController,
                focusNode: _textFieldFocusNode,
                onTap: () {
                  setState(() => _isTextFieldFocused = true);
                },
                onTapOutside: (_) {
                  _textFieldFocusNode.unfocus();
                  setState(() => _isTextFieldFocused = false);
                },
                onChanged: (_) => setState(() {}),
                onSubmitted: (text) {
                  if (text.trim().isNotEmpty) {
                    provider.sendTextMessage(text);
                    _textController.clear();
                    _textFieldFocusNode.unfocus();
                    setState(() => _isTextFieldFocused = false);
                  }
                },
                enabled: isIdle,
                style: const TextStyle(
                  color: AppConstants.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    color: AppConstants.textSecondary.withOpacity(0.4),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  // Send button inside field
                  suffixIcon: _textController.text.trim().isNotEmpty && isIdle
                      ? GestureDetector(
                          onTap: () {
                            final text = _textController.text;
                            if (text.trim().isNotEmpty) {
                              provider.sendTextMessage(text);
                              _textController.clear();
                              _textFieldFocusNode.unfocus();
                              setState(() => _isTextFieldFocused = false);
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppConstants.accentColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.send_rounded,
                              color: AppConstants.bgColor,
                              size: 20,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Mic button
          GestureDetector(
            onTap: canTap ? () => provider.toggleListening() : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: micSize,
              height: micSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isListening
                    ? AppConstants.errorRed
                    : AppConstants.accentColor,
                boxShadow: [
                  BoxShadow(
                    color: (isListening
                            ? AppConstants.errorRed
                            : AppConstants.accentColor)
                        .withOpacity(0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                isListening ? Icons.stop_rounded : Icons.mic,
                color: Colors.white,
                size: micSize * 0.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
