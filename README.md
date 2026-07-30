# Ghita PPT Converter v0.3.0

Flutter application for creating PowerPoint presentations with HTML support and AI-powered content generation.

## Version
- **Current version:** `0.3.0+1`
- **Git tag:** `v0.3.0`

## Features

### 1. **HTML to PPTX Conversion**
Write custom HTML for slides — the engine preserves rich content in the output:
- Bold, italic, underline, strikethrough, headings, lists, tables, line breaks
- Inline styling: `color`, `background-color`, `font-size`, `font-family`, `text-align`
- Images (`<img>` with base64 data URIs or local file paths)
- Hyperlinks (`<a href>`)
- Speaker notes (notes field or `<aside class="notes">`)
- Slide background via `data-bg-color`
- Drag-to-reorder, edit, duplicate, delete slides with undo
- Export as 16:9 (default) or 4:3 PPTX with a proper Office theme and document properties

### 2. **Export Formats**
- **PPTX** — full OOXML package (theme, notes slides, embedded media)
- **PDF** — one landscape page per slide, same HTML interpretation as PPTX, with embedded Unicode system font (full Vietnamese support)
- **HTML** — standalone browser deck with keyboard/touch navigation, progress bar, fullscreen

### 3. **Live Preview & Present Mode**
- Live rendered preview beside the HTML editor (WebView2)
- Per-slide preview dialog in the slide list
- **Present mode**: fullscreen in-app playback (arrow keys, progress bar, Esc to exit)

### 4. **Slide Transition Effects**
14 transition effects (fade, push, wipe, split, blinds, clock, zoom, etc.) — deck-wide default plus per-slide overrides. Live preview with adjustable duration and looping.

### 5. **AI Assistant**
Chat interface to generate presentation HTML using **OpenAI**, **Anthropic**, **Google Gemini**, or **Ollama** (local, no API key needed).
- **Streaming responses** with a Stop button
- **Outline mode**: AI drafts an editable outline, then generates each slide with progress
- **Multi-slide generation**: Ask "Create 3 slides about Machine Learning"
- Customizable system prompt
- API keys stored encrypted via `flutter_secure_storage`

### 6. **Slide Templates**
5 bundled templates (Business, Creative, Academic, Marketing, Minimal) with recommended transitions and accent colors.

### 7. **Dark Mode**
Toggle between Light, Dark, and System theme mode. Persisted across restarts.

### 8. **Windows Desktop**
Native Windows application with Material Design 3.

## Project Structure

```
lib/
├── main.dart                           # App entry point with dark mode
├── models/
│   ├── slide.dart                      # Typed Slide model + SlideEffect enum
│   └── slide_template.dart             # Slide template model
├── screens/
│   ├── home_screen.dart                # Bottom navigation (3 tabs) + theme toggle
│   ├── html_to_ppt_screen.dart         # HTML editor + live preview + slide list + export
│   ├── ai_chat_screen.dart             # AI chat + streaming + outline mode
│   ├── effects_screen.dart             # Animation preview + PPTX transition picker
│   ├── present_screen.dart             # Fullscreen in-app present mode (WebView2)
│   └── widgets/
│       └── slide_preview.dart          # WebView2 slide preview widget
├── providers/
│   ├── app_provider.dart               # Tab navigation + theme state
│   ├── presentation_state.dart         # Slide CRUD + effects + exports (PPTX/HTML/PDF)
│   ├── ai_provider_manager.dart        # Providers (OpenAI/Anthropic/Gemini/Ollama) + streaming + outline
│   └── config_service.dart             # Persistence (secure + SharedPreferences)
└── services/
    ├── ppt_generator.dart              # PPTX OOXML builder (images, notes, links, theme)
    ├── pdf_export_service.dart         # PDF export (pdf package)
    ├── html_export_service.dart        # Standalone HTML deck export
    ├── html_image_loader.dart          # Image loading for exports (base64/local)
    └── template_service.dart           # Template asset loader
assets/
├── config/
│   └── providers.json                  # AI provider templates (no API keys)
├── templates/                          # 5 HTML slide templates + manifest
└── images/
    └── app_logo.png
test/
├── ppt_generator_test.dart             # PPTX engine + regression tests
├── pdf_export_test.dart                # PDF export tests
├── ai_provider_test.dart               # SSE parsing, outline JSON, provider validation
├── slide_model_test.dart               # Slide model round-trip tests
├── html_export_test.dart               # HTML deck export tests
├── slide_template_test.dart            # Template + provider config tests
└── widget_test.dart                    # Placeholder widget tests
```

## Getting Started

### Prerequisites
- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- **WebView2 Runtime** (preinstalled on Windows 10/11) — required for live preview and Present mode; the rest of the app works without it

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

## What's New in v0.3.0

| Category | Feature |
|----------|---------|
| 🐛 Fixes | 3 invalid-OOXML bugs fixed (table txBody, bullet glyph, xfrm tag) |
| 📊 PPTX | Images, colors/fonts/align, speaker notes, hyperlinks, per-slide transitions, Office theme |
| 📄 PDF | New PDF export sharing the PPTX HTML parser, Unicode/Vietnamese font embedding |
| 🖥️ Preview | Live WebView2 preview, per-slide preview, fullscreen Present mode |
| 🤖 AI | Gemini + Ollama providers, streaming with Stop, Outline mode |
| 🧱 Core | Typed `Slide` model with notes and per-slide effects |
| 🧪 Tests | 74 passing tests (up from 19), `flutter analyze` clean |

See [CHANGELOG.md](CHANGELOG.md) for full details.

## Security Note
API keys for AI providers are stored using `flutter_secure_storage` (encrypted keychain on each platform). No API keys are written to `SharedPreferences` or committed to version control. Local providers (Ollama) don't require an API key.

## License
MIT
