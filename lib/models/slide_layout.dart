import 'package:flutter/material.dart';

/// Slide layout types, similar to Microsoft PowerPoint's built-in layouts.
enum SlideLayoutType {
  blank,
  titleSlide,
  titleAndContent,
  sectionHeader,
  twoContent,
  comparison,
  titleOnly,
  contentAndCaption,
  pictureAndCaption,
}

/// Represents a slide layout with its placeholder positions and default content.
class SlideLayout {
  final SlideLayoutType type;
  final String name;
  final String description;
  final IconData icon;
  final List<SlidePlaceholder> placeholders;

  const SlideLayout({
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
    this.placeholders = const [],
  });

  /// All available layouts.
  static const List<SlideLayout> layouts = [
    SlideLayout(
      type: SlideLayoutType.blank,
      name: 'Blank',
      description: 'Empty slide with no placeholders',
      icon: Icons.crop_square,
    ),
    SlideLayout(
      type: SlideLayoutType.titleSlide,
      name: 'Title Slide',
      description: 'Title and subtitle for opening slides',
      icon: Icons.title,
      placeholders: [
        SlidePlaceholder(
          id: 'title',
          label: 'Click to add title',
          position: PlaceholderPosition.center,
          style: PlaceholderStyle.title,
        ),
        SlidePlaceholder(
          id: 'subtitle',
          label: 'Click to add subtitle',
          position: PlaceholderPosition.belowCenter,
          style: PlaceholderStyle.subtitle,
        ),
      ],
    ),
    SlideLayout(
      type: SlideLayoutType.titleAndContent,
      name: 'Title and Content',
      description: 'Title with content area for text, tables, or charts',
      icon: Icons.view_agenda,
      placeholders: [
        SlidePlaceholder(
          id: 'title',
          label: 'Click to add title',
          position: PlaceholderPosition.top,
          style: PlaceholderStyle.title,
        ),
        SlidePlaceholder(
          id: 'content',
          label: 'Click to add content',
          position: PlaceholderPosition.center,
          style: PlaceholderStyle.content,
        ),
      ],
    ),
    SlideLayout(
      type: SlideLayoutType.sectionHeader,
      name: 'Section Header',
      description: 'Large title for section dividers',
      icon: Icons.format_size,
      placeholders: [
        SlidePlaceholder(
          id: 'title',
          label: 'Click to add title',
          position: PlaceholderPosition.center,
          style: PlaceholderStyle.title,
        ),
        SlidePlaceholder(
          id: 'subtitle',
          label: 'Click to add subtitle',
          position: PlaceholderPosition.belowCenter,
          style: PlaceholderStyle.subtitle,
        ),
      ],
    ),
    SlideLayout(
      type: SlideLayoutType.twoContent,
      name: 'Two Content',
      description: 'Title with two side-by-side content areas',
      icon: Icons.view_column,
      placeholders: [
        SlidePlaceholder(
          id: 'title',
          label: 'Click to add title',
          position: PlaceholderPosition.top,
          style: PlaceholderStyle.title,
        ),
        SlidePlaceholder(
          id: 'content_left',
          label: 'Left content',
          position: PlaceholderPosition.left,
          style: PlaceholderStyle.content,
        ),
        SlidePlaceholder(
          id: 'content_right',
          label: 'Right content',
          position: PlaceholderPosition.right,
          style: PlaceholderStyle.content,
        ),
      ],
    ),
    SlideLayout(
      type: SlideLayoutType.comparison,
      name: 'Comparison',
      description: 'Title with two labeled columns',
      icon: Icons.compare_arrows,
      placeholders: [
        SlidePlaceholder(
          id: 'title',
          label: 'Click to add title',
          position: PlaceholderPosition.top,
          style: PlaceholderStyle.title,
        ),
        SlidePlaceholder(
          id: 'heading_left',
          label: 'Left heading',
          position: PlaceholderPosition.leftTop,
          style: PlaceholderStyle.subtitle,
        ),
        SlidePlaceholder(
          id: 'content_left',
          label: 'Left content',
          position: PlaceholderPosition.left,
          style: PlaceholderStyle.content,
        ),
        SlidePlaceholder(
          id: 'heading_right',
          label: 'Right heading',
          position: PlaceholderPosition.rightTop,
          style: PlaceholderStyle.subtitle,
        ),
        SlidePlaceholder(
          id: 'content_right',
          label: 'Right content',
          position: PlaceholderPosition.right,
          style: PlaceholderStyle.content,
        ),
      ],
    ),
    SlideLayout(
      type: SlideLayoutType.titleOnly,
      name: 'Title Only',
      description: 'Title with empty content area for custom content',
      icon: Icons.text_fields,
      placeholders: [
        SlidePlaceholder(
          id: 'title',
          label: 'Click to add title',
          position: PlaceholderPosition.top,
          style: PlaceholderStyle.title,
        ),
      ],
    ),
    SlideLayout(
      type: SlideLayoutType.contentAndCaption,
      name: 'Content and Caption',
      description: 'Content with a side caption area',
      icon: Icons.notes,
      placeholders: [
        SlidePlaceholder(
          id: 'title',
          label: 'Click to add title',
          position: PlaceholderPosition.top,
          style: PlaceholderStyle.title,
        ),
        SlidePlaceholder(
          id: 'content',
          label: 'Content',
          position: PlaceholderPosition.left,
          style: PlaceholderStyle.content,
        ),
        SlidePlaceholder(
          id: 'caption',
          label: 'Caption',
          position: PlaceholderPosition.right,
          style: PlaceholderStyle.caption,
        ),
      ],
    ),
    SlideLayout(
      type: SlideLayoutType.pictureAndCaption,
      name: 'Picture with Caption',
      description: 'Large image area with caption below',
      icon: Icons.image,
      placeholders: [
        SlidePlaceholder(
          id: 'title',
          label: 'Click to add title',
          position: PlaceholderPosition.top,
          style: PlaceholderStyle.title,
        ),
        SlidePlaceholder(
          id: 'picture',
          label: 'Click to add picture',
          position: PlaceholderPosition.center,
          style: PlaceholderStyle.picture,
        ),
        SlidePlaceholder(
          id: 'caption',
          label: 'Add caption text',
          position: PlaceholderPosition.bottom,
          style: PlaceholderStyle.caption,
        ),
      ],
    ),
  ];

  /// Get layout by type.
  static SlideLayout getByType(SlideLayoutType type) {
    return layouts.firstWhere((l) => l.type == type);
  }

  /// Get layout by name.
  static SlideLayout? getByName(String name) {
    try {
      return layouts.firstWhere((l) => l.name == name);
    } catch (_) {
      return null;
    }
  }

  /// Generate HTML template for this layout.
  String generateHtmlTemplate({String? title, String? content, String? subtitle}) {
    // Escape user-provided text: titles/content with <, >, & or " previously
    // produced broken markup or let imported content inject HTML.
    String esc(String? s) => (s ?? '')
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
    final bgColor = _defaultBgColor();
    final StringBuffer html = StringBuffer();
    html.write('<div data-bg-color="$bgColor">\n');

    switch (type) {
      case SlideLayoutType.blank:
        // Empty
        break;
      case SlideLayoutType.titleSlide:
        html.write('  <h1>${esc(title ?? 'Title')}</h1>\n');
        html.write('  <h2>${esc(subtitle ?? 'Subtitle')}</h2>\n');
        break;
      case SlideLayoutType.titleAndContent:
        html.write('  <h1>${esc(title ?? 'Title')}</h1>\n');
        html.write('  <p>${esc(content ?? 'Content goes here...')}</p>\n');
        break;
      case SlideLayoutType.sectionHeader:
        html.write('  <h1>${esc(title ?? 'Section Title')}</h1>\n');
        html.write('  <h2>${esc(subtitle ?? 'Section Subtitle')}</h2>\n');
        break;
      case SlideLayoutType.twoContent:
        html.write('  <h1>${esc(title ?? 'Title')}</h1>\n');
        html.write('  <div style="display: flex; gap: 20px;">\n');
        html.write('    <div style="flex: 1;"><p>${esc(content ?? 'Left content')}</p></div>\n');
        html.write('    <div style="flex: 1;"><p>${esc(content ?? 'Right content')}</p></div>\n');
        html.write('  </div>\n');
        break;
      case SlideLayoutType.comparison:
        html.write('  <h1>${esc(title ?? 'Comparison')}</h1>\n');
        html.write('  <div style="display: flex; gap: 20px;">\n');
        html.write('    <div style="flex: 1;"><h2>Option A</h2><p>Details...</p></div>\n');
        html.write('    <div style="flex: 1;"><h2>Option B</h2><p>Details...</p></div>\n');
        html.write('  </div>\n');
        break;
      case SlideLayoutType.titleOnly:
        html.write('  <h1>${esc(title ?? 'Title')}</h1>\n');
        break;
      case SlideLayoutType.contentAndCaption:
        html.write('  <h1>${esc(title ?? 'Title')}</h1>\n');
        html.write('  <div style="display: flex; gap: 20px;">\n');
        html.write('    <div style="flex: 2;"><p>${esc(content ?? 'Main content')}</p></div>\n');
        html.write('    <div style="flex: 1;"><p><i>Caption text</i></p></div>\n');
        html.write('  </div>\n');
        break;
      case SlideLayoutType.pictureAndCaption:
        html.write('  <h1>${esc(title ?? 'Title')}</h1>\n');
        html.write('  <div style="text-align: center; padding: 20px;">\n');
        html.write('    <p><i>[ Picture placeholder ]</i></p>\n');
        html.write('  </div>\n');
        html.write('  <p><i>Caption text</i></p>\n');
        break;
    }

    html.write('</div>');
    return html.toString();
  }

  String _defaultBgColor() {
    switch (type) {
      case SlideLayoutType.titleSlide:
        return '#1a3a5c';
      case SlideLayoutType.sectionHeader:
        return '#2d1b4e';
      case SlideLayoutType.comparison:
        return '#1a2e1a';
      default:
        return '#1a1a2e';
    }
  }
}

/// A placeholder position within a slide layout.
enum PlaceholderPosition {
  top,
  center,
  bottom,
  left,
  right,
  leftTop,
  rightTop,
  belowCenter,
}

/// The visual style of a placeholder.
enum PlaceholderStyle {
  title,
  subtitle,
  content,
  caption,
  picture,
}

/// Represents a single placeholder in a slide layout.
class SlidePlaceholder {
  final String id;
  final String label;
  final PlaceholderPosition position;
  final PlaceholderStyle style;

  const SlidePlaceholder({
    required this.id,
    required this.label,
    required this.position,
    required this.style,
  });
}
