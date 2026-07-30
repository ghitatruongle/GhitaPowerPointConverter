import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/ai_provider_manager.dart';
import 'html_to_ppt_screen.dart';
import 'recent_projects_screen.dart';
import 'template_studio_screen.dart';
import 'ai_chat_screen.dart';
import 'settings_screen.dart';
import 'widgets/command_palette_dialog.dart';
import 'widgets/shortcuts_help_dialog.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openCommandPalette(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (_) => CommandPaletteDialog(
        items: [
          CommandPaletteItem(
            title: 'Trình Soạn Thảo Slide (Editor)',
            category: 'Điều hướng',
            icon: Icons.edit_note,
            onSelect: () => appProvider.updateIndex(0),
          ),
          CommandPaletteItem(
            title: 'Quản Lý Dự Án (.ghita)',
            category: 'Điều hướng',
            icon: Icons.folder_special,
            onSelect: () => appProvider.updateIndex(1),
          ),
          CommandPaletteItem(
            title: 'Thư Viện Template',
            category: 'Điều hướng',
            icon: Icons.style,
            onSelect: () => appProvider.updateIndex(2),
          ),
          CommandPaletteItem(
            title: 'AI Pitch Deck Copilot',
            category: 'Điều hướng',
            icon: Icons.chat_bubble,
            onSelect: () => appProvider.updateIndex(3),
          ),
          CommandPaletteItem(
            title: 'Cài Đặt Hệ Thống',
            category: 'Điều hướng',
            icon: Icons.settings,
            onSelect: () => appProvider.updateIndex(4),
          ),
          CommandPaletteItem(
            title: 'Đổi Chế Độ Giao Diện (Theme Mode)',
            category: 'Hệ thống',
            icon: Icons.palette,
            onSelect: () => appProvider.toggleTheme(),
          ),
        ],
      ),
    );
  }

  void _openShortcutsHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const ShortcutsHelpDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final aiProviderManager = Provider.of<AIProviderManager>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.tertiary,
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  height: 28,
                  width: 28,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.slideshow, size: 24, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              appProvider.currentScreenName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Thanh lệnh nhanh Command Palette (Ctrl+K)',
            onPressed: () => _openCommandPalette(context),
          ),
          IconButton(
            icon: const Icon(Icons.keyboard),
            tooltip: 'Bảng phím tắt (Ctrl+/)',
            onPressed: () => _openShortcutsHelp(context),
          ),
          IconButton(
            icon: Icon(_themeIconForMode(appProvider.themeMode)),
            tooltip: 'Theme: ${_themeLabel(appProvider.themeMode)}',
            onPressed: () => appProvider.toggleTheme(),
          ),
        ],
      ),
      body: IndexedStack(
        index: appProvider.currentIndex,
        children: [
          const HtmlToPPTScreen(),
          const RecentProjectsScreen(),
          const TemplateStudioScreen(),
          AiChatScreen(aiProviderManager: aiProviderManager),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: appProvider.currentIndex,
        onDestinationSelected: (index) => appProvider.updateIndex(index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.insert_drive_file_outlined),
            selectedIcon: Icon(Icons.insert_drive_file),
            label: 'Editor',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Dự Án',
          ),
          NavigationDestination(
            icon: Icon(Icons.style_outlined),
            selectedIcon: Icon(Icons.style),
            label: 'Templates',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'AI Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Cài Đặt',
          ),
        ],
      ),
    );
  }

  IconData _themeIconForMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }
}

