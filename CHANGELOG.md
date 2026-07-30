# Changelog

## [0.3.0] - 2026-07-30 — Siêu cập nhật (Mega Update)

### 🧱 Typed Slide Model
- New `Slide` model (`lib/models/slide.dart`): `title`, `htmlContent`, `notes`, per-slide `effect` override, `timestamp`
- `SlideEffect` enum moved to `lib/models/slide.dart` (re-exported from `presentation_state.dart` for compatibility)
- `PresentationState` now holds `List<Slide>`; legacy persisted slide maps still load correctly

### 🐛 Critical PPTX Bug Fixes
- Fixed duplicated `</a:txBody>` closing tag in table cells (produced invalid OOXML)
- Fixed bullet character written as literal `\u2022` escape instead of the real • glyph
- Fixed table `<p:xfrm>` closed with mismatched `</a:xfrm>` tag
- Fixed multi-slide JSON extraction truncating nested arrays (now uses balanced-bracket scanning)

### 📊 PPTX Engine — Major Upgrade
- **Images**: `<img>` with base64 data URIs or local file paths embedded as `ppt/media/*` with `<p:pic>` shapes, auto-scaled to fit
- **Rich text styling**: inline `color`, `background-color` (highlight), `font-size` (px/pt/em), `font-family`, `text-align`, plus `<u>` underline and `<s>/<del>` strikethrough
- **Speaker notes**: from the new notes field or `<aside class="notes">` → proper `notesSlide` parts + notes master
- **Hyperlinks**: `<a href>` → `<a:hlinkClick>` with external relationships
- **Per-slide transitions**: each slide can override the deck-wide effect
- **Office theme**: `ppt/theme/theme1.xml`, `docProps/core.xml`/`app.xml`, master/layout relationship chain — no more PowerPoint repair prompts
- Content shapes now flow vertically instead of overlapping; wider content area in 16:9

### 📄 PDF Export (new)
- `PdfExportService`: one landscape page per slide (16:9 or 4:3), sharing the exact HTML parsing with the PPTX engine
- Supports text styling, lists, tables, images, background colors with automatic contrast text
- **Unicode/Vietnamese text support**: embeds a Windows system font (Segoe UI → Arial → Tahoma fallback) instead of the built-in Helvetica, so diacritics render correctly
- Export dialog now offers PPTX / HTML / PDF

### 🤖 AI — Gemini, Ollama, Streaming, Outline
- **Google Gemini** provider (`gemini` format type, `x-goog-api-key`, `systemInstruction`)
- **Ollama (local)** template — API key not required for localhost endpoints
- **Streaming responses** (SSE) for OpenAI/Anthropic/Gemini with a Stop button
- **Outline mode**: AI drafts an editable outline (titles + bullets), then generates each slide with progress

### 🖥️ In-App Preview & Present Mode (new)
- Live slide preview beside the HTML editor (WebView2, 500 ms debounce)
- Per-slide preview dialog from the slide list
- **Present mode**: fullscreen in-app playback of the HTML deck (arrow keys, progress bar, Esc to exit)
- Graceful fallback when the WebView2 runtime is missing

### ✍️ Editor
- Speaker notes field and per-slide transition picker
- Fixed export dialog running the export twice

### 🧪 Testing & Quality
- 74 tests passing (up from 19): XML regression tests (incl. UTF-8 ZIP header sizes with Vietnamese content), image embedding, styling, notes, hyperlinks, per-slide transitions, package structure, PDF export incl. Vietnamese font embedding, SSE parsing, outline JSON, Slide model round-trips
- Deep review pass: fixed UTF-8 byte-length ZIP headers, network errors no longer swallowed as stream cancels, `<img>` inside `<p>` now exported, Stop button only shown when cancellable, outline dialog controller leaks fixed
- `flutter analyze`: 0 issues (cleaned all deprecations and icon tree-shake warnings)

### 🔧 Dependencies
- Added `webview_windows`, `image`; dev: `xml`
- Removed unused `dart_openai`, `webview_flutter`, `js`
- Version bump to `0.3.0+1`

## [0.1.5] - 2026-07-30 (previously undocumented)

### Added
- **Slide templates**: 5 bundled HTML templates (Business, Creative, Academic, Marketing, Minimal) with recommended transition effects, icons and accent colors (`TemplateService`, `SlideTemplate`, template gallery dialog)
- **HTML export**: standalone browser presentation with keyboard/touch navigation, progress bar, fullscreen and per-slide background colors (`HtmlExportService`)
- Tests: `html_export_test.dart`, `slide_template_test.dart`

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
