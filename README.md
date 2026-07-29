# Ghita PPT Converter v0.0.1

Flutter application for creating PowerPoint presentations with HTML support and AI-powered content generation.

## Version
- **Current version:** `0.0.1+1`
- **Git tag:** `v0.0.1`

## Features

1. **HTML to PPTX Conversion** — Write custom HTML/CSS for slides (bold, italic, headings, lists, line breaks preserved in output).
2. **Slide Transition Effects** — Choose from 14 transition effects (fade, push, wipe, split, blinds, clock, zoom, etc.) applied per-export.
3. **AI Assistant** — Chat interface to generate presentation HTML content using OpenAI or Anthropic APIs; API keys stored encrypted via `flutter_secure_storage`.
4. **Windows Desktop** — Native Windows application.

## Project Structure

```
lib/
├── main.dart                           # App entry point
├── screens/
│   ├── home_screen.dart                # Bottom navigation with 3 tabs
│   ├── html_to_ppt_screen.dart         # HTML editor + slide list + export
│   ├── ai_chat_screen.dart             # AI chat with provider settings
│   └── effects_screen.dart             # Slide transition effects panel
├── providers/
│   ├── app_provider.dart               # Tab navigation state
│   ├── presentation_state.dart         # Slide list + effect + export logic
│   ├── ai_provider_manager.dart        # AI provider CRUD + API calls
│   └── config_service.dart             # Persistence (secure + SharedPreferences)
└── services/
    └── ppt_generator.dart              # PPTX ZIP archive builder
assets/
├── config/
│   └── providers.json                  # AI provider templates (no API keys)
└── images/
    └── app_logo.png
test/
├── widget_test.dart                    # Boilerplate (replace with real tests)
└── ppt_generator_test.dart             # Real tests for PPTGenerator
```

## Getting Started

### Prerequisites
- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0

### Setup
```bash
flutter pub get
```

### Running
```bash
flutter run -d windows
```

### Running Tests
```bash
flutter test
```

## Security Note
API keys for AI providers are stored using `flutter_secure_storage` (encrypted keychain on each platform). No API keys are written to `SharedPreferences` or committed to version control.

## License
MIT (or your preferred license).
