# Changelog

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
