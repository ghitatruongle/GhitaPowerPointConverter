import 'package:flutter/material.dart';

/// Quick Access Toolbar — the small toolbar at the top-left corner,
/// similar to Microsoft PowerPoint's Quick Access Toolbar.
class QuickAccessToolbar extends StatelessWidget {
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback? onSave;
  final VoidCallback? onPresent;
  final bool canUndo;
  final bool canRedo;

  const QuickAccessToolbar({
    super.key,
    this.onUndo,
    this.onRedo,
    this.onSave,
    this.onPresent,
    this.canUndo = false,
    this.canRedo = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QATButton(
            icon: Icons.undo,
            tooltip: 'Undo (Ctrl+Z)',
            onPressed: canUndo ? onUndo : null,
          ),
          _QATButton(
            icon: Icons.redo,
            tooltip: 'Redo (Ctrl+Y)',
            onPressed: canRedo ? onRedo : null,
          ),
          _QATButton(
            icon: Icons.save_outlined,
            tooltip: 'Save (Ctrl+S)',
            onPressed: onSave,
          ),
          _QATButton(
            icon: Icons.play_arrow,
            tooltip: 'Present (F5)',
            onPressed: onPresent,
          ),
        ],
      ),
    );
  }
}

class _QATButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _QATButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 16),
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
    );
  }
}
