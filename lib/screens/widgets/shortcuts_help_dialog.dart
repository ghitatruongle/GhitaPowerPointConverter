import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/shortcuts_provider.dart';
import '../../utils/keyboard_shortcuts.dart';

class ShortcutsHelpDialog extends StatelessWidget {
  const ShortcutsHelpDialog({super.key});

  /// Descriptions keyed by action — shown next to the (possibly customized)
  /// binding read from [ShortcutsProvider].
  static const Map<ShortcutAction, String> _descriptions = {
    ShortcutAction.newSlide: 'Thêm Slide mới',
    ShortcutAction.saveProject: 'Lưu file dự án (.ghita)',
    ShortcutAction.exportPresentation: 'Xuất bài thuyết trình (hộp thoại Xuất nâng cao)',
    ShortcutAction.undo: 'Hoàn tác (Undo)',
    ShortcutAction.redo: 'Làm lại (Redo)',
    ShortcutAction.duplicateSlide: 'Nhân bản Slide hiện tại',
    ShortcutAction.deleteSlide: 'Xóa Slide hiện tại',
    ShortcutAction.previousSlide: 'Chuyển tới Slide trước',
    ShortcutAction.nextSlide: 'Chuyển tới Slide sau',
    ShortcutAction.goToSlide: 'Nhảy tới Slide theo số',
    ShortcutAction.startPresentation: 'Trình chiếu từ đầu',
    ShortcutAction.startFromCurrentSlide: 'Trình chiếu từ Slide hiện tại',
    ShortcutAction.presenterView: 'Mở Presenter View',
    ShortcutAction.toggleSidebar: 'Hiện/Ẩn thanh bên',
    ShortcutAction.toggleGrid: 'Hiện/Ẩn lưới (Grid)',
    ShortcutAction.toggleRuler: 'Hiện/Ẩn thước (Ruler)',
    ShortcutAction.commandPalette: 'Mở thanh tìm kiếm lệnh nhanh',
    ShortcutAction.selectAll: 'Chọn tất cả trong trình soạn thảo',
    ShortcutAction.copy: 'Sao chép vùng chọn',
    ShortcutAction.paste: 'Dán từ clipboard',
    ShortcutAction.cut: 'Cắt vùng chọn',
    ShortcutAction.zoomIn: 'Phóng to trình soạn thảo',
    ShortcutAction.zoomOut: 'Thu nhỏ trình soạn thảo',
    ShortcutAction.zoomReset: 'Đặt lại zoom 100%',
  };

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ShortcutsProvider>(context);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.keyboard, color: Colors.deepOrange),
          SizedBox(width: 8),
          Text('Bảng Tra Cứu Phím Tắt (Shortcuts)'),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final action in ShortcutAction.values)
              if (_descriptions[action] != null)
                ListTile(
                  dense: true,
                  leading: Text(
                    _keyLabel(provider.getShortcut(action)),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  title: Text(_descriptions[action]!,
                      style: const TextStyle(fontSize: 12)),
                ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    );
  }

  /// Compact label for a SingleActivator (e.g. "Ctrl+Shift+E").
  static String _keyLabel(SingleActivator activator) {
    final parts = <String>[];
    if (activator.control) parts.add('Ctrl');
    if (activator.shift) parts.add('Shift');
    if (activator.alt) parts.add('Alt');
    final key = activator.trigger;
    if (key == LogicalKeyboardKey.arrowLeft) {
      parts.add('←');
    } else if (key == LogicalKeyboardKey.arrowRight) {
      parts.add('→');
    } else if (key == LogicalKeyboardKey.delete) {
      parts.add('Delete');
    } else if (key == LogicalKeyboardKey.equal) {
      parts.add('=');
    } else if (key == LogicalKeyboardKey.minus) {
      parts.add('-');
    } else if (key == LogicalKeyboardKey.digit0) {
      parts.add('0');
    } else if (key == LogicalKeyboardKey.f5) {
      parts.add('F5');
    } else {
      parts.add(key.keyLabel.isNotEmpty ? key.keyLabel.toUpperCase() : '?');
    }
    return parts.join(' + ');
  }
}
