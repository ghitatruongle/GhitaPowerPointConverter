// Slide transition effects that map to PPTX transitions.
enum SlideEffect {
  none,
  fade,
  pushLeft,
  pushRight,
  pushUp,
  pushDown,
  wipe,
  splitIn,
  splitOut,
  randomBar,
  checkerboard,
  blinds,
  clock,
  zoom,
}

/// A typed presentation slide.
///
/// Replaces the loose `Map<String, dynamic>` slide representation.
/// [toMap]/[fromMap] stay backward compatible with previously persisted maps
/// (missing fields fall back to sensible defaults).
class Slide {
  final String title;
  final String htmlContent;

  /// Speaker notes exported to the PPTX notes slide (empty = none).
  final String notes;

  /// Per-slide transition override; null means "use the deck-wide effect".
  final SlideEffect? effect;

  /// Creation timestamp used as a stable list key in the UI.
  final int timestamp;

  /// Per-slide background color override (hex e.g. #FFFFFF or data-bg-color).
  final String? bgColor;

  /// Custom inline CSS style overrides for this specific slide.
  final String? customCss;

  /// Layout structure classification (e.g. 'standard', 'grid2', 'grid3', 'hero', 'quote', 'kpi').
  final String layoutType;

  /// Tags associated with the slide (e.g. ['intro', 'chart', 'summary']).
  final List<String> tags;

  /// Visual elements metadata for Drag-and-Drop overlay editing.
  final Map<String, dynamic> visualElements;

  Slide({
    required this.title,
    required this.htmlContent,
    this.notes = '',
    this.effect,
    int? timestamp,
    this.bgColor,
    this.customCss,
    this.layoutType = 'standard',
    List<String>? tags,
    Map<String, dynamic>? visualElements,
  })  : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch,
        tags = tags ?? const [],
        visualElements = visualElements ?? const {};

  Slide copyWith({
    String? title,
    String? htmlContent,
    String? notes,
    SlideEffect? effect,
    bool clearEffect = false,
    int? timestamp,
    String? bgColor,
    String? customCss,
    String? layoutType,
    List<String>? tags,
    Map<String, dynamic>? visualElements,
  }) {
    return Slide(
      title: title ?? this.title,
      htmlContent: htmlContent ?? this.htmlContent,
      notes: notes ?? this.notes,
      effect: clearEffect ? null : (effect ?? this.effect),
      timestamp: timestamp ?? this.timestamp,
      bgColor: bgColor ?? this.bgColor,
      customCss: customCss ?? this.customCss,
      layoutType: layoutType ?? this.layoutType,
      tags: tags ?? this.tags,
      visualElements: visualElements ?? this.visualElements,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'htmlContent': htmlContent,
      if (notes.isNotEmpty) 'notes': notes,
      if (effect != null) 'effect': effect!.name,
      'timestamp': timestamp,
      if (bgColor != null) 'bgColor': bgColor,
      if (customCss != null) 'customCss': customCss,
      'layoutType': layoutType,
      if (tags.isNotEmpty) 'tags': tags,
      if (visualElements.isNotEmpty) 'visualElements': visualElements,
    };
  }

  factory Slide.fromMap(Map<String, dynamic> map) {
    SlideEffect? effect;
    final effectName = map['effect'];
    if (effectName is String && effectName.isNotEmpty) {
      try {
        effect = SlideEffect.values.byName(effectName);
      } catch (_) {
        effect = null;
      }
    }
    final rawTags = map['tags'];
    final tagsList = rawTags is List
        ? rawTags.map((e) => e.toString()).toList()
        : <String>[];

    final rawVisual = map['visualElements'];
    final visualMap = rawVisual is Map<String, dynamic>
        ? rawVisual
        : (rawVisual is Map
            ? Map<String, dynamic>.from(rawVisual)
            : <String, dynamic>{});

    return Slide(
      title: (map['title'] ?? 'Untitled Slide').toString(),
      htmlContent: (map['htmlContent'] ?? '').toString(),
      notes: (map['notes'] ?? '').toString(),
      effect: effect,
      timestamp: map['timestamp'] is int
          ? map['timestamp'] as int
          : DateTime.now().millisecondsSinceEpoch,
      bgColor: map['bgColor']?.toString(),
      customCss: map['customCss']?.toString(),
      layoutType: map['layoutType']?.toString() ?? 'standard',
      tags: tagsList,
      visualElements: visualMap,
    );
  }
}
