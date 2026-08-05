import 'package:flutter/material.dart';
import '../../theme/office_colors.dart';

/// Quick Access Toolbar — Microsoft Office 365 style
/// Positioned at the top-left corner of the window.
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
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Undo
          _OfficeQATButton(
            icon: Icons.undo,
            tooltip: 'Undo (Ctrl+Z)',
            onPressed: canUndo ? onUndo : null,
            isDark: isDark,
          ),
          // Redo
          _OfficeQATButton(
            icon: Icons.redo,
            tooltip: 'Redo (Ctrl+Y)',
            onPressed: canRedo ? onRedo : null,
            isDark: isDark,
          ),

          // Separator
          Container(
            width: 1,
            height: 16,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color:
                isDark ? OfficeColors.gray30 : OfficeColors.ribbonBorderLight,
          ),

          // Save
          _OfficeQATButton(
            icon: Icons.save_outlined,
            tooltip: 'Save (Ctrl+S)',
            onPressed: onSave,
            isDark: isDark,
          ),

          // Separator
          Container(
            width: 1,
            height: 16,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color:
                isDark ? OfficeColors.gray30 : OfficeColors.ribbonBorderLight,
          ),

          // Present (with accent color)
          _OfficeQATButton(
            icon: Icons.slideshow,
            tooltip: 'Present (F5)',
            onPressed: onPresent,
            isDark: isDark,
            isAccent: true,
          ),
        ],
      ),
    );
  }
}

/// Individual QAT button with Office 365 hover behavior
class _OfficeQATButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool isDark;
  final bool isAccent;

  const _OfficeQATButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
    required this.isDark,
    this.isAccent = false,
  });

  @override
  State<_OfficeQATButton> createState() => _OfficeQATButtonState();
}

class _OfficeQATButtonState extends State<_OfficeQATButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;
    Color iconColor;
    Color? bgColor;

    if (!isEnabled) {
      iconColor = widget.isDark ? OfficeColors.gray40 : OfficeColors.gray60;
      bgColor = Colors.transparent;
    } else if (_isHovered) {
      iconColor = widget.isDark ? OfficeColors.gray90 : OfficeColors.gray10;
      bgColor = widget.isDark ? OfficeColors.gray30 : OfficeColors.gray90;
    } else {
      iconColor = widget.isAccent
          ? (widget.isDark ? OfficeColors.info : OfficeColors.officeBlue)
          : (widget.isDark ? OfficeColors.gray90 : OfficeColors.gray20);
      bgColor = Colors.transparent;
    }

    return Tooltip(
      message: widget.tooltip,
      child: Semantics(
        label: widget.tooltip,
        button: true,
        enabled: isEnabled,
        onTap: widget.onPressed,
        child: ExcludeSemantics(
          child: Container(
            width: 28,
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(2),
            ),
            child: IconButton(
              icon: Icon(widget.icon, size: 16, color: iconColor),
              onPressed: widget.onPressed,
              onHover: (hovered) => setState(() => _isHovered = hovered),
              tooltip: widget.tooltip,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 28, height: 24),
            ),
          ),
        ),
      ),
    );
  }
}
