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

  Slide({
    required this.title,
    required this.htmlContent,
    this.notes = '',
    this.effect,
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  Slide copyWith({
    String? title,
    String? htmlContent,
    String? notes,
    SlideEffect? effect,
    bool clearEffect = false,
    int? timestamp,
  }) {
    return Slide(
      title: title ?? this.title,
      htmlContent: htmlContent ?? this.htmlContent,
      notes: notes ?? this.notes,
      effect: clearEffect ? null : (effect ?? this.effect),
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'htmlContent': htmlContent,
      if (notes.isNotEmpty) 'notes': notes,
      if (effect != null) 'effect': effect!.name,
      'timestamp': timestamp,
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
    return Slide(
      title: (map['title'] ?? 'Untitled Slide').toString(),
      htmlContent: (map['htmlContent'] ?? '').toString(),
      notes: (map['notes'] ?? '').toString(),
      effect: effect,
      timestamp: map['timestamp'] is int
          ? map['timestamp'] as int
          : DateTime.now().millisecondsSinceEpoch,
    );
  }
}
