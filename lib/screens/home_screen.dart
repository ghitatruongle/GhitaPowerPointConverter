import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/ai_provider_manager.dart';
import 'html_to_ppt_screen.dart';
import 'ai_chat_screen.dart';
import 'effects_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final aiProviderManager = Provider.of<AIProviderManager>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/images/app_logo.png',
                height: 32,
                width: 32,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.slideshow, size: 28),
              ),
            ),
            const SizedBox(width: 12),
            Text(appProvider.currentScreenName),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_themeIconForMode(appProvider.themeMode)),
            tooltip: 'Theme: ${_themeLabel(appProvider.themeMode)}',
            onPressed: () => appProvider.toggleTheme(),
          ),
        ],
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: IndexedStack(
        index: appProvider.currentIndex,
        children: [
          const HtmlToPPTScreen(),
          AiChatScreen(aiProviderManager: aiProviderManager),
          const EffectsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: appProvider.currentIndex,
        onDestinationSelected: (index) => appProvider.updateIndex(index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.insert_drive_file_outlined),
            selectedIcon: Icon(Icons.insert_drive_file),
            label: 'HTML to PPT',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'AI Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.animation_outlined),
            selectedIcon: Icon(Icons.animation),
            label: 'Effects',
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
