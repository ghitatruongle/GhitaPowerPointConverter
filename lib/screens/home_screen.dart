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
