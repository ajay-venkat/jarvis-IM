import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';
import '../providers/jarvis_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _groqKeyController = TextEditingController();
  bool _groqKeyObscured = true;

  @override
  void initState() {
    super.initState();
    final provider = context.read<JarvisProvider>();
    _groqKeyController.text = provider.settingsService.groqApiKey;
  }

  @override
  void dispose() {
    _groqKeyController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.bgColor,
      appBar: AppBar(
        backgroundColor: AppConstants.bgColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          color: AppConstants.accentColor,
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.orbitron(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppConstants.accentColor,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<JarvisProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section: Groq API Key
                _buildSectionHeader('AI Engine', Icons.psychology_outlined),
                const SizedBox(height: 12),
                _buildApiKeyCard(
                  title: 'Groq API Key',
                  controller: _groqKeyController,
                  obscured: _groqKeyObscured,
                  onToggleObscured: () {
                    setState(() => _groqKeyObscured = !_groqKeyObscured);
                  },
                  onSave: () async {
                    await provider.setGroqApiKey(_groqKeyController.text.trim());
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        _buildSnackBar('Groq API key saved successfully'),
                      );
                    }
                  },
                  linkText: 'Get your free API key at console.groq.com',
                  linkUrl: AppConstants.groqConsoleUrl,
                ),

                const SizedBox(height: 28),

                // Section: Wake Word Toggle
                _buildSectionHeader(
                    'Wake Word Detection', Icons.record_voice_over_outlined),
                const SizedBox(height: 12),
                _buildWakeWordToggle(provider),

                const SizedBox(height: 28),

                // Section: Voice Settings
                _buildSectionHeader('Voice Settings', Icons.volume_up_outlined),
                const SizedBox(height: 12),
                _buildVoiceSettings(provider),

                const SizedBox(height: 28),

                // Section: About
                _buildSectionHeader('About', Icons.info_outline),
                const SizedBox(height: 12),
                _buildAboutCard(),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppConstants.accentColor, size: 20),
        const SizedBox(width: 10),
        Text(
          title.toUpperCase(),
          style: GoogleFonts.orbitron(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppConstants.accentColor,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildApiKeyCard({
    required String title,
    required TextEditingController controller,
    required bool obscured,
    required VoidCallback onToggleObscured,
    required VoidCallback onSave,
    required String linkText,
    required String linkUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppConstants.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            obscureText: obscured,
            style: const TextStyle(
              color: AppConstants.textPrimary,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'Paste your key here...',
              hintStyle: TextStyle(
                color: AppConstants.textSecondary.withOpacity(0.5),
                fontSize: 14,
              ),
              filled: true,
              fillColor: AppConstants.bgColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppConstants.accentColor,
                  width: 1.5,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: IconButton(
                icon: Icon(
                  obscured
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppConstants.textSecondary,
                  size: 20,
                ),
                onPressed: onToggleObscured,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.accentColor,
                    foregroundColor: AppConstants.bgColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Save',
                    style: GoogleFonts.orbitron(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _launchUrl(linkUrl),
            child: Row(
              children: [
                Icon(
                  Icons.open_in_new,
                  color: AppConstants.accentColor.withOpacity(0.6),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    linkText,
                    style: TextStyle(
                      color: AppConstants.accentColor.withOpacity(0.7),
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                      decorationColor:
                          AppConstants.accentColor.withOpacity(0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWakeWordToggle(JarvisProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '"Hey Jarvis" wake word',
                  style: TextStyle(
                    color: AppConstants.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  provider.wakeWordEnabled
                      ? 'Listening for "Jarvis" keyword'
                      : 'Tap to enable hands-free activation',
                  style: TextStyle(
                    color: AppConstants.textSecondary.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Uses your device\'s speech recognition — no API key needed',
                  style: TextStyle(
                    color: AppConstants.successGreen.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: provider.wakeWordEnabled,
            onChanged: (value) async {
              final success = await provider.setWakeWordEnabled(value);
              if (!success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  _buildSnackBar(
                    provider.errorMessage ??
                        'Failed to toggle wake word detection.',
                    isError: true,
                  ),
                );
                provider.clearError();
              }
            },
            activeColor: AppConstants.accentColor,
            inactiveTrackColor: Colors.grey.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceSettings(JarvisProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Voice Speed
          _buildSliderRow(
            label: 'Voice Speed',
            value: provider.settingsService.voiceSpeed,
            min: 0.5,
            max: 2.0,
            divisions: 6,
            displayValue:
                '${provider.settingsService.voiceSpeed.toStringAsFixed(1)}x',
            onChanged: (value) => provider.setVoiceSpeed(value),
          ),

          const SizedBox(height: 20),
          Divider(color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 20),

          // Voice Pitch
          _buildSliderRow(
            label: 'Voice Pitch',
            value: provider.settingsService.voicePitch,
            min: 0.5,
            max: 2.0,
            divisions: 6,
            displayValue:
                provider.settingsService.voicePitch.toStringAsFixed(1),
            onChanged: (value) => provider.setVoicePitch(value),
          ),

          const SizedBox(height: 20),
          Divider(color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 20),

          // Voice Selection
          const Text(
            'TTS Voice',
            style: TextStyle(
              color: AppConstants.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          _buildVoiceDropdown(provider),
        ],
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppConstants.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppConstants.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                displayValue,
                style: const TextStyle(
                  color: AppConstants.accentColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppConstants.accentColor,
            inactiveTrackColor: AppConstants.accentColor.withOpacity(0.15),
            thumbColor: AppConstants.accentColor,
            overlayColor: AppConstants.accentColor.withOpacity(0.1),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceDropdown(JarvisProvider provider) {
    final voices = provider.ttsService.voices;
    final selectedVoice = provider.settingsService.selectedVoice;

    if (voices.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppConstants.bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Text(
          'System default voice',
          style: TextStyle(
            color: AppConstants.textSecondary.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppConstants.bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButton<String>(
        value: voices.any((v) => v['name'] == selectedVoice)
            ? selectedVoice
            : null,
        isExpanded: true,
        dropdownColor: AppConstants.surfaceColor,
        underline: const SizedBox(),
        hint: Text(
          'Select voice',
          style: TextStyle(
            color: AppConstants.textSecondary.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        items: voices.map((voice) {
          return DropdownMenuItem<String>(
            value: voice['name'],
            child: Text(
              voice['name'] ?? 'Unknown',
              style: const TextStyle(
                color: AppConstants.textPrimary,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            provider.setSelectedVoice(value);
          }
        },
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'J.A.R.V.I.S',
            style: GoogleFonts.orbitron(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.accentColor,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Just A Rather Very Intelligent System',
            style: TextStyle(
              color: AppConstants.textSecondary.withOpacity(0.6),
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Version 1.0.0',
            style: TextStyle(
              color: AppConstants.textSecondary.withOpacity(0.4),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  SnackBar _buildSnackBar(String message, {bool isError = false}) {
    return SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor:
          isError ? AppConstants.errorRed : AppConstants.accentColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    );
  }
}
