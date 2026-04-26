# J.A.R.V.I.S — AI Voice Assistant

A full-featured, cross-platform AI voice assistant built with Flutter, inspired by Iron Man's J.A.R.V.I.S. Speaks, listens, thinks, and responds — all with a futuristic glowing HUD interface.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)
![License](https://img.shields.io/badge/License-MIT-green)
![Platforms](https://img.shields.io/badge/Platforms-Android%20|%20iOS%20|%20Windows%20|%20macOS-blue)

## ✨ Features

- 🎤 **Voice-first interaction** — Speak to Jarvis, get spoken responses
- 🧠 **Gemini AI Backend** — Powered by Google's Gemini 1.5 Flash for rapid, smart responses
- 🗣️ **"Hey Jarvis" wake word** — Hands-free activation using built-in speech recognition (no API key needed!)
- 🔵 **Animated arc reactor** — Pulses idle, ripples when listening, glows when speaking
- 💬 **Chat log** — Full conversation history with styled bubbles
- ⚙️ **Voice controls** — Speed, pitch, and voice selection
- ⌨️ **Spacebar shortcut** — Quick trigger on desktop
- 🌗 **Dark futuristic UI** — Iron Man HUD aesthetic with Orbitron font
- 📱 **Cross-platform** — Single codebase for Android, iOS, Windows, macOS

## 📸 Screens

| Splash | Home | Settings |
|--------|------|----------|
| Arc reactor animation + "J.A.R.V.I.S" fade-in | Greeting, reactor, chat log, mic button | API keys, voice controls, wake word toggle |

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.x+
- Android Studio / Xcode (for mobile)
- Visual Studio 2022 with C++ workload (for Windows)

### Setup

```bash
# Clone the repo
git clone https://github.com/AjayVenkat28/jarvis-IM.git
cd jarvis-IM

# Create native scaffolding (if not present)
flutter create --project-name jarvis_ai --org com.jarvis.ai --platforms windows,android,ios,macos .

# Install dependencies
flutter pub get

# Run on your platform
flutter run -d windows    # Windows
flutter run -d macos      # macOS
flutter run -d android    # Android
flutter run -d ios        # iOS
```

### Add a chime sound
Place a short `.wav` chime file at `assets/sounds/chime.wav` for wake word activation feedback.

### Configure API Keys (inside the app)
1. Open **Settings** (⚙️ icon)
2. Paste your **Gemini API Key** — free from [Google AI Studio](https://aistudio.google.com/app/apikey)
3. Enable **"Hey Jarvis" wake word** toggle (no API key needed — uses your device's speech recognition!)

## 🏗️ Architecture

```
lib/
├── main.dart                    # App entry, theme, routing
├── constants/
│   └── app_constants.dart       # Colors, API config, pref keys
├── models/
│   └── chat_message.dart        # Message model
├── services/
│   ├── gemini_service.dart      # Gemini API calls
│   ├── speech_service.dart      # Speech-to-text
│   ├── tts_service.dart         # Text-to-speech
│   ├── wake_word_service.dart   # Speech-based wake word (no API key)
│   └── settings_service.dart    # SharedPreferences
├── providers/
│   └── jarvis_provider.dart     # Central state (ChangeNotifier)
├── screens/
│   ├── splash_screen.dart       # Arc reactor splash
│   ├── home_screen.dart         # Main conversation UI
│   └── settings_screen.dart     # API keys & voice settings
└── widgets/
    ├── arc_reactor.dart         # CustomPainter animated reactor
    ├── chat_bubble.dart         # Styled message bubbles
    ├── typing_indicator.dart    # Bouncing dots
    └── wake_word_indicator.dart # Green/grey status dot
```

## 📦 Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `speech_to_text` | ^7.3.0 | Microphone → text + wake word |
| `flutter_tts` | ^4.0.2 | Text → speech |
| `http` | ^1.2.1 | API calls |
| `audioplayers` | ^6.0.0 | Chime sound |
| `provider` | ^6.1.2 | State management |
| `shared_preferences` | ^2.2.3 | Persistent settings |
| `google_fonts` | ^6.2.1 | Orbitron font |
| `animate_do` | ^3.3.4 | UI animations |
| `permission_handler` | ^11.3.1 | Mic permissions |
| `url_launcher` | ^6.2.5 | External links |

## 🔑 How It Works

```
User speaks "Hey Jarvis"
    → Speech recognition detects "Jarvis" keyword (on-device, free)
    → Chime plays 🔔
    → Speech-to-text captures command
    → Full conversation sent to Gemini API
    → AI response received
    → Text-to-speech reads it aloud
    → Porcupine resumes listening
```

## 🎨 Design

- **Background**: `#0A0E1A`
- **Accent**: `#00D4FF` (electric blue)
- **User bubbles**: `#003D6B`
- **Jarvis bubbles**: `#1A2035`
- **Font**: Orbitron (headings), Inter (body)
- **Border radius**: 16px everywhere

## 📄 License

MIT License — feel free to use, modify, and distribute.
