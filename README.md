# Ghita PPT Converter v0.0.5

Flutter application for creating PowerPoint presentations with HTML support and AI-powered content generation.

## Version
- **Current version:** `0.0.5+1`
- **Git tag:** `v0.0.5`

## Features

### 1. **HTML to PPTX Conversion**
Write custom HTML/CSS for slides — bold, italic, headings, lists, tables, and line breaks are preserved in the output.
- Drag-to-reorder slides
- Edit, duplicate, or delete slides
- Undo delete action
- Export as 16:9 (default) or 4:3 PPTX

### 2. **Slide Transition Effects**
Choose from 14 transition effects (fade, push, wipe, split, blinds, clock, zoom, etc.) applied per-export. Live preview with adjustable duration and looping.

### 3. **AI Assistant**
Chat interface to generate presentation HTML content using OpenAI or Anthropic APIs.
- **Multi-slide generation**: Ask "Create 3 slides about Machine Learning"
- **Single slide**: Ask "Create a title slide for my presentation"
- Customizable system prompt
- API keys stored encrypted via `flutter_secure_storage`

### 4. **Dark Mode**
Toggle between Light, Dark, and System theme mode. Persisted across restarts.

### 5. **Windows Desktop**
Native Windows application with Material Design 3.

## Project Structure

```
lib/
├── main.dart                           # App entry point with dark mode
├── screens/
│   ├── home_screen.dart                # Bottom navigation (3 tabs) + theme toggle
│   ├── html_to_ppt_screen.dart         # HTML editor + slide list + reorder + export
│   ├── ai_chat_screen.dart             # AI chat + multi-slide + system prompt
│   └── effects_screen.dart             # Animation preview + PPTX transition picker
├── providers/
│   ├── app_provider.dart               # Tab navigation + theme state
│   ├── presentation_state.dart         # Slide CRUD + effects + export
│   ├── ai_provider_manager.dart        # AI provider CRUD + API calls + multi-slide
│   └── config_service.dart             # Persistence (secure + SharedPreferences)
└── services/
    └── ppt_generator.dart              # PPTX ZIP archive builder (16:9, lists, tables)
assets/
├── config/
│   └── providers.json                  # AI provider templates (no API keys)
└── images/
    └── app_logo.png
test/
├── widget_test.dart                    # Placeholder widget tests
└── ppt_generator_test.dart             # 19 tests for PPTGenerator
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

### Building for Release
```bash
flutter build windows --release
```

## What's New in v0.0.5

| Category | Feature |
|----------|---------|
| 🐛 Fixes | EffectsScreen completely rewritten (was broken) |
| 📊 PPTX | 16:9 widescreen, proper bullet lists, table support |
| 📝 Slides | Drag reorder, edit, duplicate, clear all, undo delete |
| 🤖 AI | Multi-slide generation, custom system prompt |
| 🎨 UI | Dark/light/system theme, Material 3 NavigationBar |
| 🧪 Tests | 19 passing tests (up from 12) |

See [CHANGELOG.md](CHANGELOG.md) for full details.

## Security Note
API keys for AI providers are stored using `flutter_secure_storage` (encrypted keychain on each platform). No API keys are written to `SharedPreferences` or committed to version control.

## License
MIT
