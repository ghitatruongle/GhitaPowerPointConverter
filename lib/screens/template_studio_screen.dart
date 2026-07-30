import 'package:flutter/material.dart';

class TemplateStudioScreen extends StatelessWidget {
  const TemplateStudioScreen({super.key});

  static const List<Map<String, String>> _templates = [
    {
      'name': 'Business Executive',
      'category': 'Doanh Nghiệp',
      'color': '#0F172A',
      'desc': 'Phong cách hiện đại, thanh lịch với tông màu xanh đen quý phái'
    },
    {
      'name': 'Modern Dark Neon',
      'category': 'Công Nghệ',
      'color': '#1E1B4B',
      'desc': 'Nổi bật với nền tối dải màu Neon tím xanh thu hút'
    },
    {
      'name': 'Academic Gold',
      'category': 'Học Thuật',
      'color': '#78350F',
      'desc': 'Trang nhã cho các bài nghiên cứu, luận văn và giảng dạy'
    },
    {
      'name': 'Creative Pitch',
      'category': 'Sáng Tạo',
      'color': '#BE185D',
      'desc': 'Ấn tượng dành cho slide gọi vốn đầu tư và giới thiệu ý tưởng'
    },
    {
      'name': 'Minimal Slate',
      'category': 'Tối Giản',
      'color': '#334155',
      'desc': 'Thiết kế tinh gọn tập trung tối đa vào nội dung chính'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.style, size: 28, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Thư Viện Template & Theme Studio',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 320,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _templates.length,
                itemBuilder: (ctx, idx) {
                  final t = _templates[idx];
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 80,
                          color: theme.colorScheme.primaryContainer,
                          alignment: Alignment.center,
                          child: Icon(Icons.slideshow,
                              size: 40, color: theme.colorScheme.onPrimaryContainer),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t['name']!,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(t['desc']!,
                                  style: theme.textTheme.bodySmall, maxLines: 2),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
