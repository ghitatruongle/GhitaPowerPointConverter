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
                errorBuilder: (_, __, ___) => const Icon(Icons.slideshow, size: 28),
              ),
            ),
            const SizedBox(width: 12),
            Text(appProvider.currentScreenName),
          ],
        ),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: appProvider.currentIndex,
        onTap: (index) => appProvider.updateIndex(index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.insert_drive_file),
            label: 'HTML to PPT',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'AI Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.animation),
            label: 'Effects',
          ),
        ],
      ),
    );
  }
}

