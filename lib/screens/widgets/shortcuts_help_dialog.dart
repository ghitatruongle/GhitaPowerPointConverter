import 'package:flutter/material.dart';

class ShortcutsHelpDialog extends StatelessWidget {
  const ShortcutsHelpDialog({super.key});

  static const Map<String, String> _shortcuts = {
    'Ctrl + K': 'Mở thanh tìm kiếm lệnh nhanh (Command Palette)',
    'Ctrl + Enter': 'Thêm hoặc Cập nhật Slide hiện tại',
    'Ctrl + E': 'Xuất bài thuyết trình ra PPTX',
    'Ctrl + P': 'Mở chế độ trình chiếu (Present Mode / Fullscreen)',
    'Ctrl + S': 'Lưu file dự án (.ghita)',
    'Ctrl + Z': 'Hoàn tác (Undo)',
    'Ctrl + Y': 'Làm lại (Redo)',
    'Ctrl + /': 'Mở bảng tra cứu phím tắt này',
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.keyboard, color: Colors.deepOrange),
          SizedBox(width: 8),
          Text('Bảng Tra Cứu Phím Tắt (Shortcuts)'),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: ListView(
          shrinkWrap: true,
          children: _shortcuts.entries.map((entry) {
            return ListTile(
              title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(entry.value),
            );
          }).toList(),
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
}
