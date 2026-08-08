import 'package:flutter/widgets.dart';

/// Intent classes for keyboard shortcuts
class NewSlideIntent extends Intent {
  const NewSlideIntent();
}

class SaveProjectIntent extends Intent {
  const SaveProjectIntent();
}

class ExportIntent extends Intent {
  const ExportIntent();
}

class UndoIntent extends Intent {
  const UndoIntent();
}

class RedoIntent extends Intent {
  const RedoIntent();
}

class PresentIntent extends Intent {
  const PresentIntent();
}

class PresentFromCurrentIntent extends Intent {
  const PresentFromCurrentIntent();
}

class PresenterViewIntent extends Intent {
  const PresenterViewIntent();
}

class ToggleSidebarIntent extends Intent {
  const ToggleSidebarIntent();
}

class ToggleGridIntent extends Intent {
  const ToggleGridIntent();
}

class ToggleRulerIntent extends Intent {
  const ToggleRulerIntent();
}

class CommandPaletteIntent extends Intent {
  const CommandPaletteIntent();
}

// ---- v1.6.3: previously-defined-but-unwired actions ----

class DuplicateSlideIntent extends Intent {
  const DuplicateSlideIntent();
}

class DeleteSlideIntent extends Intent {
  const DeleteSlideIntent();
}

class PreviousSlideIntent extends Intent {
  const PreviousSlideIntent();
}

class NextSlideIntent extends Intent {
  const NextSlideIntent();
}

class GoToSlideIntent extends Intent {
  const GoToSlideIntent();
}

class SelectAllIntent extends Intent {
  const SelectAllIntent();
}

class CopyIntent extends Intent {
  const CopyIntent();
}

class PasteIntent extends Intent {
  const PasteIntent();
}

class CutIntent extends Intent {
  const CutIntent();
}

class ZoomInIntent extends Intent {
  const ZoomInIntent();
}

class ZoomOutIntent extends Intent {
  const ZoomOutIntent();
}

class ZoomResetIntent extends Intent {
  const ZoomResetIntent();
}
