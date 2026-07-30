import 'package:flutter/material.dart';

/// WYSIWYG Visual Formatting Toolbar for slide editing without raw HTML.
class WysiwygToolbar extends StatelessWidget {
  final Function(String tagOpen, String tagClose) onInsertTag;
  final VoidCallback? onInsertTable;
  final VoidCallback? onInsertCallout;
  final VoidCallback? onInsertCode;

  const WysiwygToolbar({
    super.key,
    required this.onInsertTag,
    this.onInsertTable,
    this.onInsertCallout,
    this.onInsertCode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          IconButton(
            icon: const Icon(Icons.title, size: 18),
            tooltip: 'Tiêu đề H1',
            onPressed: () => onInsertTag('<h1>', '</h1>'),
          ),
          IconButton(
            icon: const Icon(Icons.format_size, size: 18),
            tooltip: 'Tiêu đề H2',
            onPressed: () => onInsertTag('<h2>', '</h2>'),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.format_bold, size: 18),
            tooltip: 'In đậm (Bold)',
            onPressed: () => onInsertTag('<b>', '</b>'),
          ),
          IconButton(
            icon: const Icon(Icons.format_italic, size: 18),
            tooltip: 'In nghiêng (Italic)',
            onPressed: () => onInsertTag('<i>', '</i>'),
          ),
          IconButton(
            icon: const Icon(Icons.format_underlined, size: 18),
            tooltip: 'Gạch chân (Underline)',
            onPressed: () => onInsertTag('<u>', '</u>'),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.format_list_bulleted, size: 18),
            tooltip: 'Danh sách Bullet',
            onPressed: () => onInsertTag('<ul>\n  <li>', '</li>\n</ul>'),
          ),
          IconButton(
            icon: const Icon(Icons.table_chart_outlined, size: 18),
            tooltip: 'Chèn Bảng',
            onPressed: onInsertTable ??
                () => onInsertTag(
                      '<table border="1">\n  <tr><th>Tiêu đề 1</th><th>Tiêu đề 2</th></tr>\n  <tr><td>Nội dung 1</td><td>Nội dung 2</td></tr>\n',
                      '</table>',
                    ),
          ),
          IconButton(
            icon: const Icon(Icons.error_outline, size: 18),
            tooltip: 'Chèn Khối Ghi Chú (Callout)',
            onPressed: onInsertCallout ??
                () => onInsertTag(
                      '<div style="padding: 12px; background: rgba(59,130,246,0.1); border-left: 4px solid #3B82F6; border-radius: 6px;">\n  ',
                      '\n</div>',
                    ),
          ),
          IconButton(
            icon: const Icon(Icons.code, size: 18),
            tooltip: 'Chèn Khối Code',
            onPressed: onInsertCode ??
                () => onInsertTag(
                      '<pre><code style="background: #1e1e1e; color: #d4d4d4; padding: 12px; border-radius: 8px; display: block;">\n',
                      '\n</code></pre>',
                    ),
          ),
        ],
      ),
    );
  }
}
