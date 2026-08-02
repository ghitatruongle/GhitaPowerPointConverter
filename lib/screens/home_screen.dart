import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/ai_provider_manager.dart';
import '../providers/presentation_state.dart';
import 'present_screen.dart';
import 'presenter_view_screen.dart';
import 'editor/editor_shell.dart';
import 'recent_projects_screen.dart';
import 'template_studio_screen.dart';
import 'ai_chat_screen.dart';
import 'settings_screen.dart';
import 'widgets/command_palette_dialog.dart';
import 'widgets/shortcuts_help_dialog.dart';
import 'widgets/ribbon_toolbar.dart';
import 'widgets/quick_access_toolbar.dart';
import 'widgets/status_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openCommandPalette(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (_) => CommandPaletteDialog(
        items: [
          CommandPaletteItem(
            title: 'Slide Editor',
            category: 'Navigation',
            icon: Icons.edit_note,
            onSelect: () => appProvider.updateIndex(0),
          ),
          CommandPaletteItem(
            title: 'Projects (.ghita)',
            category: 'Navigation',
            icon: Icons.folder_special,
            onSelect: () => appProvider.updateIndex(1),
          ),
          CommandPaletteItem(
            title: 'Template Library',
            category: 'Navigation',
            icon: Icons.style,
            onSelect: () => appProvider.updateIndex(2),
          ),
          CommandPaletteItem(
            title: 'AI Pitch Deck Copilot',
            category: 'Navigation',
            icon: Icons.chat_bubble,
            onSelect: () => appProvider.updateIndex(3),
          ),
          CommandPaletteItem(
            title: 'Settings',
            category: 'Navigation',
            icon: Icons.settings,
            onSelect: () => appProvider.updateIndex(4),
          ),
          CommandPaletteItem(
            title: 'Toggle Theme',
            category: 'System',
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

  /// Launch in-app presentation, optionally starting at a specific slide.
  void _present(
      BuildContext context, PresentationState state, {int startSlide = 0}) {
    if (state.slides.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có slide để trình chiếu.')),
      );
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PresentScreen(state: state, startSlide: startSlide),
    ));
  }

  void _openPresenterView(BuildContext context, PresentationState state) {
    if (state.slides.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có slide để trình chiếu.')),
      );
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) =>
          PresenterViewScreen(state: state, startSlide: state.currentSlideIndex),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final aiProviderManager = Provider.of<AIProviderManager>(context);
    final presentationState = Provider.of<PresentationState>(context);
    final theme = Theme.of(context);
    final isEditorTab = appProvider.currentIndex == 0;

    return Scaffold(
      // Ribbon toolbar (only visible on Editor tab)
      body: Column(
        children: [
          // Quick Access Toolbar + Ribbon
          if (isEditorTab)
            Column(
              children: [
                // Quick Access Toolbar row
                Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                    border: Border(
                      bottom: BorderSide(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // App logo
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.tertiary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Image.asset(
                            'assets/images/app_logo.png',
                            height: 18,
                            width: 18,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.slideshow, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Quick Access Toolbar
                      QuickAccessToolbar(
                        onUndo: () => presentationState.undo(),
                        onRedo: () => presentationState.redo(),
                        onSave: () => presentationState.savePresentation(),
                        onPresent: () => _present(context, presentationState),
                        canUndo: presentationState.canUndo,
                        canRedo: presentationState.canRedo,
                      ),

                      const Spacer(),

                      // Current screen title
                      Text(
                        appProvider.currentScreenName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),

                      const Spacer(),

                      // Action buttons
                      IconButton(
                        icon: const Icon(Icons.search, size: 16),
                        tooltip: 'Command Palette (Ctrl+K)',
                        onPressed: () => _openCommandPalette(context),
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        icon: const Icon(Icons.keyboard, size: 16),
                        tooltip: 'Shortcuts (Ctrl+/)',
                        onPressed: () => _openShortcutsHelp(context),
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        icon: Icon(_themeIconForMode(appProvider.themeMode), size: 16),
                        tooltip: 'Theme: ${_themeLabel(appProvider.themeMode)}',
                        onPressed: () => appProvider.toggleTheme(),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),

                // Ribbon Toolbar
                RibbonToolbar(
                  onExport: () {},
                  onPresent: () => _present(context, presentationState),
                  onPresentFromCurrent: () => _present(
                    context,
                    presentationState,
                    startSlide: presentationState.currentSlideIndex,
                  ),
                  onPresenterView: () =>
                      _openPresenterView(context, presentationState),
                  presentationState: presentationState,
                  onUndo: () => presentationState.undo(),
                  onRedo: () => presentationState.redo(),
                  canUndo: presentationState.canUndo,
                  canRedo: presentationState.canRedo,
                ),
              ],
            ),

          // Main content area
          Expanded(
            child: IndexedStack(
              index: appProvider.currentIndex,
              children: [
                const EditorShell(),
                const RecentProjectsScreen(),
                const TemplateStudioScreen(),
                AiChatScreen(aiProviderManager: aiProviderManager),
                const SettingsScreen(),
              ],
            ),
          ),

          // Status Bar
          if (isEditorTab)
            StatusBar(
              currentSlide: presentationState.slides.isNotEmpty ? 1 : 0,
              totalSlides: presentationState.slides.length,
              zoomLevel: 1.0,
              onZoomChanged: (v) {},
              autoSaveStatus: 'saved',
            ),
        ],
      ),

      // Bottom NavigationBar
      bottomNavigationBar: NavigationBar(
        selectedIndex: appProvider.currentIndex,
        onDestinationSelected: (index) => appProvider.updateIndex(index),
        height: 56,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.insert_drive_file_outlined),
            selectedIcon: Icon(Icons.insert_drive_file),
            label: 'Editor',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Projects',
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
            label: 'Settings',
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
