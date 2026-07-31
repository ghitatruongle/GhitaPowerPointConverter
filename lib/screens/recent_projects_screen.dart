import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/presentation_state.dart';

class RecentProjectsScreen extends StatefulWidget {
  const RecentProjectsScreen({super.key});

  @override
  State<RecentProjectsScreen> createState() => _RecentProjectsScreenState();
}

class _RecentProjectsScreenState extends State<RecentProjectsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<PresentationState>(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.folder_special, size: 28, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Quản Lý Dự Án PowerPoint (.ghita)',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search bar & Filters
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm dự án hoặc thẻ hashtag (#Work, #Sales)...',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Dự Án Mới'),
                  onPressed: () {
                    state.clearSlides();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Đã tạo dự án thuyết trình mới!'),
                        action: SnackBarAction(
                          label: 'Hoàn tác',
                          onPressed: () => state.undo(),
                        ),
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Project cards grid / list
            Expanded(
              child: state.slides.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.slideshow, size: 64, color: theme.colorScheme.outline),
                          const SizedBox(height: 16),
                          const Text('Chưa có dự án nào được chọn hoặc tạo mới.'),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.folder_open),
                            label: const Text('Mở File Dự Án .ghita'),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Vui lòng chọn file .ghita trên máy')),
                              );
                            },
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      children: [
                        Card(
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.present_to_all,
                                  color: theme.colorScheme.onPrimaryContainer),
                            ),
                            title: Text(
                              state.presentationTitle.isNotEmpty
                                  ? state.presentationTitle
                                  : 'Dự án thuyết trình hiện tại',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${state.slides.length} slide • Tỷ lệ: ${state.aspectRatio} • Lần cuối: Vừa xong',
                            ),
                            trailing: PopupMenuButton(
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                  value: 'export',
                                  child: Row(
                                    children: [
                                      Icon(Icons.save_alt, size: 18),
                                      SizedBox(width: 8),
                                      Text('Lưu file .ghita'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'duplicate',
                                  child: Row(
                                    children: [
                                      Icon(Icons.copy, size: 18),
                                      SizedBox(width: 8),
                                      Text('Nhân bản dự án'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
