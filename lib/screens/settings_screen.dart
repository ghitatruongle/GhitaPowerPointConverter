import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/ai_provider_manager.dart';
import 'provider_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Map<String, TextEditingController> _keyControllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initKeyControllers();
    });
  }

  void _initKeyControllers() {
    final manager = Provider.of<AIProviderManager>(context, listen: false);
    for (final p in manager.providers) {
      _keyControllers[p.id] = TextEditingController(text: p.apiKey);
    }
  }

  @override
  void dispose() {
    for (final c in _keyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final aiManager = Provider.of<AIProviderManager>(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header title
          Row(
            children: [
              Icon(Icons.settings, size: 28, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                'Cài Đặt Hệ Thống (Settings)',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Section 1: UI & Theme Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.palette_outlined, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Giao Diện & Chủ Đề (Appearance)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Chế Độ Giao Diện (Theme Mode)'),
                    subtitle: Text('Hiện tại: ${_themeLabel(appProvider.themeMode)}'),
                    trailing: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode),
                          label: Text('Sáng'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode),
                          label: Text('Tối'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.brightness_auto),
                          label: Text('Hệ thống'),
                        ),
                      ],
                      selected: {appProvider.themeMode},
                      onSelectionChanged: (set) {
                        if (set.isNotEmpty) {
                          appProvider.setThemeMode(set.first);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Section 2: API Keys & Provider Manager
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.vpn_key_outlined, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Quản Lý API Key & Provider AI',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.tune, size: 18),
                        label: const Text('Quản lý chi tiết'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProviderSettingsScreen(
                                aiProviderManager: aiManager,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  ...aiManager.providers.map((p) {
                    final controller = _keyControllers.putIfAbsent(
                      p.id,
                      () => TextEditingController(text: p.apiKey),
                    );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 180,
                            child: Text(
                              p.name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: controller,
                              obscureText: true,
                              decoration: InputDecoration(
                                hintText: 'Nhập API Key cho ${p.name}...',
                                isDense: true,
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.save, size: 20),
                                  tooltip: 'Lưu API Key',
                                  onPressed: () {
                                    final updated = p.copyWith(apiKey: controller.text.trim());
                                    aiManager.updateProvider(updated);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Đã lưu API Key cho ${p.name}')),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Section 3: Editor Preferences & Backup/Restore
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.code_outlined, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Thiết Lập Mặc Định & Backup Settings',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.backup_outlined),
                    title: const Text('Sao lưu / Khôi phục Cài đặt (Backup & Restore)'),
                    subtitle: const Text('Đóng gói hoặc nạp toàn bộ cấu hình cài đặt JSON'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text('Xuất JSON'),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã xuất cấu hình cài đặt')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Sáng (Light)';
      case ThemeMode.dark:
        return 'Tối (Dark)';
      case ThemeMode.system:
        return 'Theo Hệ Thống (System)';
    }
  }
}
