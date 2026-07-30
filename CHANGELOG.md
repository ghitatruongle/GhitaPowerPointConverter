# Changelog

## [0.0.5] - 2026-07-30 — Major Upgrade

### 🐛 Critical Bug Fixes
- **EffectsScreen completely rewritten**: Fixed all compile errors
  - `_availableAnimations` variable was undefined (used `_availableEffects` instead)
  - `_selectedEffect.name = newValue` was trying to mutate a Dart enum (now uses dedicated state)
  - Preview animation switch cases now use display strings correctly
- **PPTX transition XML**: Fixed OOXML compliance, added direction attributes (`dir`) for push transitions
- **ConfigService type safety**: Fixed `Map<dynamic, dynamic>` → `Map<String, dynamic>` cast

### 📊 PPTX Engine Upgrade
- **Widescreen 16:9 (default)**: Changed from 4:3 to 16:9 screen format (`screen16x9`, 12192000×6858000 EMUs). 4:3 still available as option.
- **Proper bullet lists**: Unordered lists use `a:buChar` (• bullet), ordered lists use `a:buAutoNum` (arabicPeriod numbering)
- **Table HTML support**: Parse `<table>`, `<thead>`, `<tbody>`, `<tr>`, `<th>`, `<td>` into PPTX `p:graphicFrame` with `a:tbl` grid
- **Structured block parsing**: New `parseHtmlContentFull()` returns typed blocks (text, list, table) for smarter PPTX output

### 📝 Slide Management
- **Drag-to-reorder slides**: `ReorderableListView` with drag handles
- **Edit existing slides**: Tap any slide → pre-fills HTML editor for editing
- **Duplicate slide**: One-click copy with "(Copy)" title suffix
- **Clear all slides**: Confirmation dialog with delete all
- **Undo delete**: Snackbar with undo action when deleting a slide
- **Empty state**: Illustrated prompt when no slides exist

### 🤖 AI Enhancements
- **Multi-slide generation**: Ask "Create 3 slides about X" → AI returns JSON array, all slides are generated at once
- **Add all slides button**: Add multiple AI-generated slides in one tap
- **Custom system prompt editor**: Edit the AI system prompt directly from the chat screen; reset to default option
- **System prompt persistence**: Custom prompts survive app restart via SharedPreferences
- **Anthropic API support**: Proper `system` parameter and `x-api-key` header for Claude models

### 🎨 UI/UX
- **Dark mode**: Toggle between Light / Dark / System theme via AppBar icon. Persisted across restarts.
- **AppBar theme toggle**: Cycle through light → dark → system → light
- **Modern NavigationBar**: Switched from `BottomNavigationBar` to Material 3 `NavigationBar`
- **Improved empty states**: Each screen has an illustrated empty state with guidance text
- **Export dialog**: Prompt user for file name before export with `.pptx` suffix
- **Export progress**: Loading indicator during PPTX generation

### ⌨️ Keyboard Shortcuts
- **Ctrl+Enter** — Add or update current slide
- **Ctrl+E** — Export presentation to PPTX
- Focus node auto-activates on the HTML to PPT screen

### 🎨 Slide Background & Subtitle
- **`data-bg-color` attribute**: Add `data-bg-color="#FF0000"` to any HTML element to set slide background color in PPTX output
- **Subtitle support**: `<h2>` elements are rendered as subtitle text boxes below the title in PPTX

### 🌡️ AI Parameters
- **Temperature setting**: Configure AI creativity (0.0–2.0) per provider
- **Max Tokens setting**: Control response length per provider
- Both settings persist in provider configuration

### 🖼️ Slide Thumbnails
- Each slide in the list now shows a mini chip-based preview (H1, H2, paragraph count, list items, tables)
- Visual tags help identify slide structure at a glance

### 🛡️ Error Boundary
- Global `FlutterError.onError` and `PlatformDispatcher.onError` handlers catch unhandled exceptions
- Errors are logged to debug console for easier troubleshooting

### 🧪 Testing
- **19 unit tests** (up from 12), all passing
- Added tests for: table blocks, ordered lists, structured blocks, 16:9, 4:3, list content, table content
- Fixed: test file had duplicate imports and duplicate `main()` definitions
- Added: `widget_test.dart` placeholder with valid `main()`

### 🔧 Dependency Updates
- `pubspec.yaml` version: `0.0.5+1`
- Updated all compatible dependencies (archive 3.6.1, flutter_secure_storage 9.2.4, etc.)

### 📦 Files Changed
- `lib/main.dart` — Multi-theme support (light/dark/system)
- `lib/screens/home_screen.dart` — Theme toggle, NavigationBar
- `lib/screens/effects_screen.dart` — Complete rewrite (fixed bugs)
- `lib/screens/html_to_ppt_screen.dart` — Reorder, edit, duplicate, clear, export dialog
- `lib/screens/ai_chat_screen.dart` — Multi-slide, system prompt editor
- `lib/providers/app_provider.dart` — Theme state management
- `lib/providers/presentation_state.dart` — moveSlide, updateSlide, duplicateSlide, exportToPPTPath
- `lib/providers/ai_provider_manager.dart` — Multi-slide generation, system prompt
- `lib/providers/config_service.dart` — System prompt persistence
- `lib/services/ppt_generator.dart` — 16:9, lists, tables, structured parsing, OOXML fixes
- `test/ppt_generator_test.dart` — Added table, list, block, format tests
- `test/widget_test.dart` — Valid placeholder
- `pubspec.yaml` — Version bump to 0.0.5+1

## [0.0.1] - 2026-07-30
### Added
- Slide transition effects (14 effects: fade, push, wipe, split, blinds, clock, zoom, etc.)
- Per-slide transition applied when exporting PPTX
- HTML formatting preservation in PPTX output (bold, italic, headings, lists, line breaks)
- API key encryption via `flutter_secure_storage`
- HTML input validation (empty check, size limit 100KB, script/iframe/object/embed removal)
- Real widget tests for `PPTGenerator` (parseHtmlContent + file generation)

### Changed
- Version bump: `0.1.0+1` → `0.0.1+1`
- API keys no longer stored in plaintext in `providers.json` or SharedPreferences
- Removed boilerplate counter test from `widget_test.dart` (kept as template)
- `PresentationState.currentTheme` renamed to semantic `slideEffect` (enum)
- `PPTGenerator` now uses `html/dom.dart` for proper DOM traversal

### Fixed
- EffectsScreen applied animation name as string theme (now stored as `SlideEffect` enum)
- `_buildSlideXml` stripped all HTML formatting → now preserves bold/italic/structure
- `ai_provider_manager.dart` — secure API key persistence per provider

## [0.1.0+1] - Previous version
Initial release (pre-security-fix).
