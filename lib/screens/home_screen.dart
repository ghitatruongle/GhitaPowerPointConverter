import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/ai_provider_manager.dart';
import '../providers/presentation_state.dart';
import '../providers/shortcuts_provider.dart';
import '../utils/keyboard_shortcuts.dart';
import '../utils/shortcut_intents.dart';
import 'present_screen.dart';
import 'presenter_view_screen.dart';
import 'slide_sorter_screen.dart';
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
import 'widgets/advanced_export_dialog.dart';
import '../theme/office_colors.dart';
import '../l10n/l10n.dart';

/// HomeScreen — Microsoft Office 365 style layout
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showSidebar = true;
  bool _showGrid = false;
  bool _showRuler = false;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  /// Build shortcuts map from ShortcutsProvider
  Map<ShortcutActivator, Intent> _buildShortcutsMap(
      ShortcutsProvider provider) {
    final shortcuts = <ShortcutActivator, Intent>{};

    // Map each action to its intent
    shortcuts[provider.getShortcut(ShortcutAction.newSlide)] =
        const NewSlideIntent();
    shortcuts[provider.getShortcut(ShortcutAction.saveProject)] =
        const SaveProjectIntent();
    shortcuts[provider.getShortcut(ShortcutAction.exportPresentation)] =
        const ExportIntent();
    shortcuts[provider.getShortcut(ShortcutAction.undo)] = const UndoIntent();
    shortcuts[provider.getShortcut(ShortcutAction.redo)] = const RedoIntent();
    shortcuts[provider.getShortcut(ShortcutAction.startPresentation)] =
        const PresentIntent();
    shortcuts[provider.getShortcut(ShortcutAction.startFromCurrentSlide)] =
        const PresentFromCurrentIntent();
    shortcuts[provider.getShortcut(ShortcutAction.presenterView)] =
        const PresenterViewIntent();
    shortcuts[provider.getShortcut(ShortcutAction.toggleSidebar)] =
        const ToggleSidebarIntent();
    shortcuts[provider.getShortcut(ShortcutAction.toggleGrid)] =
        const ToggleGridIntent();
    shortcuts[provider.getShortcut(ShortcutAction.toggleRuler)] =
        const ToggleRulerIntent();
    shortcuts[provider.getShortcut(ShortcutAction.commandPalette)] =
        const CommandPaletteIntent();

    return shortcuts;
  }

  /// Build actions map
  Map<Type, Action<Intent>> _buildActionsMap(
    AppProvider appProvider,
    PresentationState ps,
  ) {
    return {
      NewSlideIntent: CallbackAction<NewSlideIntent>(
        onInvoke: (_) {
          ps.addSlide(Slide(
              title: context.l10n.newSlide,
              htmlContent: '<h1>New Slide</h1>\n<p>Click to edit</p>'));
          return null;
        },
      ),
      SaveProjectIntent: CallbackAction<SaveProjectIntent>(
        onInvoke: (_) {
          ps.savePresentation();
          return null;
        },
      ),
      ExportIntent: CallbackAction<ExportIntent>(
        onInvoke: (_) {
          // Open the advanced export dialog (format, aspect ratio, quality, slide selection)
          showDialog(
            context: context,
            builder: (_) => const AdvancedExportDialog(),
          );
          return null;
        },
      ),
      UndoIntent: CallbackAction<UndoIntent>(
        onInvoke: (_) {
          if (ps.canUndo) ps.undo();
          return null;
        },
      ),
      RedoIntent: CallbackAction<RedoIntent>(
        onInvoke: (_) {
          if (ps.canRedo) ps.redo();
          return null;
        },
      ),
      PresentIntent: CallbackAction<PresentIntent>(
        onInvoke: (_) {
          _present(context, ps);
          return null;
        },
      ),
      PresentFromCurrentIntent: CallbackAction<PresentFromCurrentIntent>(
        onInvoke: (_) {
          _present(context, ps, startSlide: ps.currentSlideIndex);
          return null;
        },
      ),
      PresenterViewIntent: CallbackAction<PresenterViewIntent>(
        onInvoke: (_) {
          _openPresenterView(context, ps);
          return null;
        },
      ),
      ToggleSidebarIntent: CallbackAction<ToggleSidebarIntent>(
        onInvoke: (_) {
          setState(() {
            _showSidebar = !_showSidebar;
          });
          return null;
        },
      ),
      ToggleGridIntent: CallbackAction<ToggleGridIntent>(
        onInvoke: (_) {
          setState(() {
            _showGrid = !_showGrid;
          });
          return null;
        },
      ),
      ToggleRulerIntent: CallbackAction<ToggleRulerIntent>(
        onInvoke: (_) {
          setState(() {
            _showRuler = !_showRuler;
          });
          return null;
        },
      ),
      CommandPaletteIntent: CallbackAction<CommandPaletteIntent>(
        onInvoke: (_) {
          _openCommandPalette(context);
          return null;
        },
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final aiManager = Provider.of<AIProviderManager>(context);
    final ps = Provider.of<PresentationState>(context);
    final shortcutsProvider = Provider.of<ShortcutsProvider>(context);
    final theme = Theme.of(context);
    final isEditorTab = appProvider.currentIndex == 0;
    final isDark = theme.brightness == Brightness.dark;

    return Shortcuts(
      shortcuts: _buildShortcutsMap(shortcutsProvider),
      child: Actions(
        actions: _buildActionsMap(appProvider, ps),
        child: Focus(
          autofocus: true,
          child: Scaffold(
            backgroundColor:
                isDark ? const Color(0xFF1B1A19) : OfficeColors.gray98,
            body: Semantics(
              container: true,
              label: context.l10n.workspaceSemantics,
              child: Row(
                children: [
                  // ===== OFFICE SIDEBAR (NavigationRail) =====
                  if (_showSidebar)
                    _buildOfficeSidebar(context, appProvider, ps, isDark),

                  // ===== MAIN CONTENT =====
                  Expanded(
                    child: Column(
                      children: [
                        // === OFFICE TITLE BAR ===
                        _buildOfficeTitleBar(
                            context, appProvider, ps, isEditorTab, isDark),

                        // === RIBBON (editor tab only) ===
                        if (isEditorTab)
                          RibbonToolbar(
                            presentationState: ps,
                            onPresent: () => _present(context, ps),
                            onPresentFromCurrent: () => _present(context, ps,
                                startSlide: ps.currentSlideIndex),
                            onPresenterView: () =>
                                _openPresenterView(context, ps),
                            onUndo: () => ps.undo(),
                            onRedo: () => ps.redo(),
                            canUndo: ps.canUndo,
                            canRedo: ps.canRedo,
                            onNewSlide: () {
                              ps.addSlide(Slide(
                                  title: context.l10n.newSlide,
                                  htmlContent:
                                      '<h1>New Slide</h1>\n<p>Click to edit</p>'));
                            },
                            onNavigateToTab: (idx) =>
                                appProvider.updateIndex(idx),
                            onOpenSlideSorter: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const SlideSorterScreen()));
                            },
                            onSetSlideEffect: (effect) => ps.setEffect(effect),
                            onApplyEffectToAll: (effect) {
                              for (int i = 0; i < ps.slides.length; i++) {
                                ps.setSlideEffectOverride(i, effect);
                              }
                            },
                            onSetSlideBackground: (hex) {
                              final idx = ps.currentSlideIndex;
                              if (idx >= 0 && idx < ps.slides.length) {
                                final updated =
                                    ps.slides[idx].copyWith(bgColor: hex);
                                ps.updateSlide(idx, updated);
                              }
                            },
                            onToggleGrid: () =>
                                setState(() => _showGrid = !_showGrid),
                            onToggleRuler: () =>
                                setState(() => _showRuler = !_showRuler),
                            onToggleFullscreen: () async {
                              try {
                                // Toggle fullscreen if window_manager is available
                              } catch (_) {}
                            },
                            currentSlideIndex: ps.currentSlideIndex,
                          ),

                        // === MAIN CONTENT AREA ===
                        Expanded(
                          child: Stack(
                            children: [
                              IndexedStack(
                                index: appProvider.currentIndex,
                                children: [
                                  const EditorShell(),
                                  const RecentProjectsScreen(),
                                  const TemplateStudioScreen(),
                                  AiChatScreen(aiProviderManager: aiManager),
                                  const SettingsScreen(),
                                ],
                              ),
                              // Grid overlay
                              if (_showGrid && isEditorTab)
                                IgnorePointer(
                                  child: CustomPaint(
                                    size: Size.infinite,
                                    painter: _OfficeGridPainter(
                                        color: isDark
                                            ? OfficeColors.gray30
                                            : OfficeColors.gray90),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // === STATUS BAR ===
                        if (isEditorTab)
                          StatusBar(
                            currentSlide: ps.slides.isNotEmpty
                                ? ps.currentSlideIndex + 1
                                : 0,
                            totalSlides: ps.slides.length,
                            zoomLevel: 1.0,
                            onZoomChanged: (v) {},
                            autoSaveStatus: 'saved',
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // OFFICE SIDEBAR (72px wide, clean design)
  // ===========================================================================
  Widget _buildOfficeSidebar(BuildContext context, AppProvider appProvider,
      PresentationState ps, bool isDark) {
    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252423) : OfficeColors.gray95,
        border: Border(
          right: BorderSide(
            color:
                isDark ? OfficeColors.gray30 : OfficeColors.ribbonBorderLight,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // === App Logo + Title ===
          Container(
            // The logo, caption and vertical padding need 52 px at the
            // default text scale. Reserve a little headroom so the caption
            // never overflows the compact sidebar header.
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: OfficeColors.officeBlue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        height: 20,
                        width: 20,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.slideshow,
                          size: 18,
                          color: OfficeColors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'GhitaPPT',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: isDark ? OfficeColors.gray90 : OfficeColors.gray30,
                      fontFamily: 'Segoe UI',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // === Navigation items ===
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _OfficeSidebarItem(
                  icon: Icons.edit_note,
                  label: context.l10n.editorTitle,
                  tooltip: '${context.l10n.editorTitle} (Ctrl+1)',
                  isSelected: appProvider.currentIndex == 0,
                  onTap: () => appProvider.updateIndex(0),
                  isDark: isDark,
                ),
                _OfficeSidebarItem(
                  icon: Icons.folder_outlined,
                  label: context.l10n.projectsTitle,
                  tooltip: context.l10n.recentProjects,
                  isSelected: appProvider.currentIndex == 1,
                  onTap: () => appProvider.updateIndex(1),
                  isDark: isDark,
                ),
                _OfficeSidebarItem(
                  icon: Icons.style_outlined,
                  label: context.l10n.templatesTitle,
                  tooltip: context.l10n.templatesTitle,
                  isSelected: appProvider.currentIndex == 2,
                  onTap: () => appProvider.updateIndex(2),
                  isDark: isDark,
                ),
                _OfficeSidebarItem(
                  icon: Icons.smart_toy_outlined,
                  label: context.l10n.aiChatTitle,
                  tooltip: context.l10n.aiChat,
                  isSelected: appProvider.currentIndex == 3,
                  onTap: () => appProvider.updateIndex(3),
                  isDark: isDark,
                ),
                _OfficeSidebarItem(
                  icon: Icons.settings_outlined,
                  label: context.l10n.settingsTitle,
                  tooltip: context.l10n.settingsTitle,
                  isSelected: appProvider.currentIndex == 4,
                  onTap: () => appProvider.updateIndex(4),
                  isDark: isDark,
                ),
              ],
            ),
          ),

          // === Bottom actions ===
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // New Slide button
                _OfficeSidebarButton(
                  icon: Icons.add_circle_outline,
                  tooltip: context.l10n.newSlide,
                  onTap: () {
                    ps.addSlide(Slide(
                        title: context.l10n.newSlide,
                        htmlContent:
                            '<h1>New Slide</h1>\n<p>Click to edit</p>'));
                    appProvider.updateIndex(0);
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 4),
                // Theme toggle
                _OfficeSidebarButton(
                  icon: isDark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  tooltip: isDark
                      ? context.l10n.lightModeFull
                      : context.l10n.darkModeFull,
                  onTap: () => appProvider.toggleTheme(),
                  isDark: isDark,
                ),
                const SizedBox(height: 4),
                // Collapse sidebar
                _OfficeSidebarButton(
                  icon: Icons.menu_open,
                  tooltip: context.l10n.hideSidebar,
                  onTap: () => setState(() => _showSidebar = false),
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // OFFICE TITLE BAR
  // ===========================================================================
  Widget _buildOfficeTitleBar(
    BuildContext context,
    AppProvider appProvider,
    PresentationState ps,
    bool isEditorTab,
    bool isDark,
  ) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252423) : OfficeColors.white,
        border: Border(
          bottom: BorderSide(
            color:
                isDark ? OfficeColors.gray30 : OfficeColors.ribbonBorderLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Show sidebar button if hidden
          if (!_showSidebar)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _OfficeHeaderButton(
                icon: Icons.menu,
                tooltip: context.l10n.showSidebar,
                onTap: () => setState(() => _showSidebar = true),
                isDark: isDark,
              ),
            ),

          // Quick Access Toolbar
          QuickAccessToolbar(
            onUndo: () => ps.undo(),
            onRedo: () => ps.redo(),
            onSave: () => ps.savePresentation(),
            onPresent: () => _present(context, ps),
            canUndo: ps.canUndo,
            canRedo: ps.canRedo,
          ),

          const Spacer(),

          // Title
          Text(
            ps.presentationTitle.isNotEmpty
                ? ps.presentationTitle
                : context.l10n.untitledPresentation,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? OfficeColors.gray90 : OfficeColors.gray20,
              fontFamily: 'Segoe UI',
            ),
          ),

          // Badge showing it's a Ghita file
          if (ps.slides.isNotEmpty) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1B3A4F)
                    : OfficeColors.officeBlueLight,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                '.ghita',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFF50B8F4)
                      : OfficeColors.officeBlue,
                ),
              ),
            ),
          ],

          const Spacer(),

          // Action buttons (Office style)
          _OfficeHeaderButton(
            icon: Icons.search,
            tooltip: '${context.l10n.search} (Ctrl+K)',
            onTap: () => _openCommandPalette(context),
            isDark: isDark,
          ),
          _OfficeHeaderButton(
            icon: Icons.keyboard_outlined,
            tooltip: context.l10n.shortcuts,
            onTap: () => _openShortcutsHelp(context),
            isDark: isDark,
          ),
          _OfficeHeaderButton(
            icon: Icons.help_outline,
            tooltip: context.l10n.help,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('GhitaPPT v1.6.0+1 — Office 365 Style')),
              );
            },
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // === Navigation helpers ===
  void _openCommandPalette(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (_) => CommandPaletteDialog(
        items: [
          CommandPaletteItem(
              title: context.l10n.slideEditor,
              category: context.l10n.navigation,
              icon: Icons.edit_note,
              onSelect: () => appProvider.updateIndex(0)),
          CommandPaletteItem(
              title: context.l10n.projectsTitle,
              category: context.l10n.navigation,
              icon: Icons.folder_special,
              onSelect: () => appProvider.updateIndex(1)),
          CommandPaletteItem(
              title: context.l10n.templatesTitle,
              category: context.l10n.navigation,
              icon: Icons.style,
              onSelect: () => appProvider.updateIndex(2)),
          CommandPaletteItem(
              title: context.l10n.aiChatTitle,
              category: context.l10n.navigation,
              icon: Icons.chat_bubble,
              onSelect: () => appProvider.updateIndex(3)),
          CommandPaletteItem(
              title: context.l10n.settingsTitle,
              category: context.l10n.navigation,
              icon: Icons.settings,
              onSelect: () => appProvider.updateIndex(4)),
          CommandPaletteItem(
              title: context.l10n.toggleTheme,
              category: context.l10n.system,
              icon: Icons.palette,
              onSelect: () => appProvider.toggleTheme()),
        ],
      ),
    );
  }

  void _openShortcutsHelp(BuildContext context) {
    showDialog(context: context, builder: (_) => const ShortcutsHelpDialog());
  }

  void _present(BuildContext context, PresentationState state,
      {int startSlide = 0}) {
    if (state.slides.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.noSlides)));
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PresentScreen(state: state, startSlide: startSlide),
    ));
  }

  void _openPresenterView(BuildContext context, PresentationState state) {
    if (state.slides.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.noSlides)));
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PresenterViewScreen(
          state: state, startSlide: state.currentSlideIndex),
    ));
  }
}

// =============================================================================
// OFFICE SIDEBAR ITEM (72px wide, Office 365 style)
// =============================================================================
class _OfficeSidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? tooltip;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _OfficeSidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
    this.tooltip,
  });

  @override
  State<_OfficeSidebarItem> createState() => _OfficeSidebarItemState();
}

class _OfficeSidebarItemState extends State<_OfficeSidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color? bgColor;
    Color iconColor;
    Color labelColor;

    if (widget.isSelected) {
      bgColor = widget.isDark
          ? const Color(0xFF1B3A4F)
          : OfficeColors.officeBlueLight;
      iconColor =
          widget.isDark ? const Color(0xFF50B8F4) : OfficeColors.officeBlue;
      labelColor =
          widget.isDark ? const Color(0xFF50B8F4) : OfficeColors.officeBlue;
    } else if (_isHovered) {
      bgColor = widget.isDark ? OfficeColors.gray30 : OfficeColors.gray90;
      iconColor = widget.isDark ? OfficeColors.gray90 : OfficeColors.gray20;
      labelColor = widget.isDark ? OfficeColors.gray90 : OfficeColors.gray30;
    } else {
      bgColor = Colors.transparent;
      iconColor = widget.isDark ? OfficeColors.gray60 : OfficeColors.gray40;
      labelColor = widget.isDark ? OfficeColors.gray60 : OfficeColors.gray40;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        child: Tooltip(
          message: widget.tooltip ?? widget.label,
          waitDuration: const Duration(milliseconds: 600),
          preferBelow: false,
          child: Semantics(
            label: widget.tooltip ?? widget.label,
            button: true,
            selected: widget.isSelected,
            onTap: widget.onTap,
            child: ExcludeSemantics(
              child: InkWell(
                onTap: widget.onTap,
                onHover: (hovered) => setState(() => _isHovered = hovered),
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      // Left accent bar for selected item
                      if (widget.isSelected)
                        Container(
                          width: 3,
                          height: 24,
                          margin: const EdgeInsets.only(left: 2, right: 2),
                          decoration: BoxDecoration(
                            color: widget.isDark
                                ? const Color(0xFF50B8F4)
                                : OfficeColors.officeBlue,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        )
                      else
                        const SizedBox(width: 7),
                      // Icon and label
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(widget.icon, size: 20, color: iconColor),
                            const SizedBox(height: 2),
                            Text(
                              widget.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: widget.isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: labelColor,
                                fontFamily: 'Segoe UI',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// OFFICE SIDEBAR BUTTON (icon-only, square)
// =============================================================================
class _OfficeSidebarButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isDark;

  const _OfficeSidebarButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<_OfficeSidebarButton> createState() => _OfficeSidebarButtonState();
}

class _OfficeSidebarButtonState extends State<_OfficeSidebarButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color iconColor;

    if (_isHovered) {
      bgColor = widget.isDark ? OfficeColors.gray30 : OfficeColors.gray90;
      iconColor = widget.isDark ? OfficeColors.gray90 : OfficeColors.gray20;
    } else {
      bgColor = Colors.transparent;
      iconColor = widget.isDark ? OfficeColors.gray60 : OfficeColors.gray40;
    }

    return Tooltip(
      message: widget.tooltip,
      child: Semantics(
        label: widget.tooltip,
        button: true,
        onTap: widget.onTap,
        child: ExcludeSemantics(
          child: Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: IconButton(
              icon: Icon(widget.icon, size: 18, color: iconColor),
              onPressed: widget.onTap,
              onHover: (hovered) => setState(() => _isHovered = hovered),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
              tooltip: widget.tooltip,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// OFFICE HEADER BUTTON (32x32, title bar actions)
// =============================================================================
class _OfficeHeaderButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isDark;

  const _OfficeHeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<_OfficeHeaderButton> createState() => _OfficeHeaderButtonState();
}

class _OfficeHeaderButtonState extends State<_OfficeHeaderButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color? bgColor;
    Color iconColor;

    if (_isHovered) {
      bgColor = widget.isDark ? OfficeColors.gray30 : OfficeColors.gray90;
      iconColor = widget.isDark ? OfficeColors.gray90 : OfficeColors.gray20;
    } else {
      bgColor = Colors.transparent;
      iconColor = widget.isDark ? OfficeColors.gray60 : OfficeColors.gray40;
    }

    return Tooltip(
      message: widget.tooltip,
      child: Semantics(
        label: widget.tooltip,
        button: true,
        onTap: widget.onTap,
        child: ExcludeSemantics(
          child: Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(2),
            ),
            child: IconButton(
              icon: Icon(widget.icon, size: 16, color: iconColor),
              onPressed: widget.onTap,
              onHover: (hovered) => setState(() => _isHovered = hovered),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              tooltip: widget.tooltip,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// OFFICE GRID PAINTER
// =============================================================================
class _OfficeGridPainter extends CustomPainter {
  final Color color;
  _OfficeGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;
    const gridSize = 20.0;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
