import '../models/slide.dart';

/// Represents a single history snapshot/milestone entry.
class HistorySnapshot {
  final String id;
  final String description;
  final int timestamp;
  final List<Slide> slides;

  HistorySnapshot({
    required this.id,
    required this.description,
    required this.slides,
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'timestamp': timestamp,
      'slides': slides.map((s) => s.toMap()).toList(),
    };
  }

  factory HistorySnapshot.fromMap(Map<String, dynamic> map) {
    final rawSlides = map['slides'] as List? ?? [];
    // Tolerate persisted JSON with string/ISO timestamps (foreign or older
    // writers) — a TypeError here would fail the ENTIRE .ghita bundle load.
    final rawTimestamp = map['timestamp'];
    return HistorySnapshot(
      id: (map['id'] ?? '').toString(),
      description: (map['description'] ?? 'Snapshot').toString(),
      timestamp: rawTimestamp is int
          ? rawTimestamp
          : DateTime.now().millisecondsSinceEpoch,
      slides: rawSlides.map((e) => Slide.fromMap(e as Map<String, dynamic>)).toList(),
    );
  }
}

/// Time Machine History Service for snapshot timeline management.
class TimeMachineHistoryService {
  final List<HistorySnapshot> _snapshots = [];
  int _currentIndex = -1;
  final int maxHistoryLength;
  // Two snapshots created in the same millisecond would otherwise share an
  // id, corrupting key-based lookups and timeline rendering.
  int _idSeq = 0;

  TimeMachineHistoryService({this.maxHistoryLength = 30});

  bool get canUndo => _currentIndex > 0;
  bool get canRedo => _currentIndex < _snapshots.length - 1;
  List<HistorySnapshot> get snapshots => List.unmodifiable(_snapshots);
  int get currentIndex => _currentIndex;

  /// Records a new snapshot in the history timeline.
  void recordSnapshot(String description, List<Slide> slides) {
    // If we're not at the end of the history tree, truncate redo steps.
    if (_currentIndex >= 0 && _currentIndex < _snapshots.length - 1) {
      _snapshots.removeRange(_currentIndex + 1, _snapshots.length);
    }

    final newSnapshot = HistorySnapshot(
      id: '${DateTime.now().millisecondsSinceEpoch}-${_idSeq++}',
      description: description,
      slides: slides.map((s) => s.copyWith()).toList(),
    );

    _snapshots.add(newSnapshot);

    // Limit maximum history snapshots to avoid memory bloat
    if (_snapshots.length > maxHistoryLength) {
      _snapshots.removeAt(0);
    }

    _currentIndex = _snapshots.length - 1;
  }

  /// Performs undo operation and returns the previous slides snapshot.
  /// Returns a deep copy so callers can never mutate a stored snapshot.
  List<Slide>? undo() {
    if (canUndo) {
      _currentIndex--;
      return _snapshots[_currentIndex].slides.map((s) => s.copyWith()).toList();
    }
    return null;
  }

  /// Performs redo operation and returns the next slides snapshot.
  List<Slide>? redo() {
    if (canRedo) {
      _currentIndex++;
      return _snapshots[_currentIndex].slides.map((s) => s.copyWith()).toList();
    }
    return null;
  }

  /// Jump directly to a specific snapshot index.
  List<Slide>? jumpToIndex(int index) {
    if (index >= 0 && index < _snapshots.length) {
      _currentIndex = index;
      return _snapshots[_currentIndex].slides.map((s) => s.copyWith()).toList();
    }
    return null;
  }

  /// Clears the history stack.
  void clear() {
    _snapshots.clear();
    _currentIndex = -1;
  }
}
