import 'package:flutter/material.dart';
import '../../providers/presentation_state.dart';
import '../../utils/effect_helpers.dart';

/// PowerPoint-style Ribbon toolbar with tabbed interface.
///
/// Tabs: Home, Insert, Design, Transitions, Slide Show, View
/// Each tab contains grouped tool buttons similar to Microsoft PowerPoint.
class RibbonToolbar extends StatefulWidget {
  final VoidCallback? onExport;
  final VoidCallback? onPresent;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final bool canUndo;
  final bool canRedo;

  const RibbonToolbar({
    super.key,
    this.onExport,
    this.onPresent,
    this.onUndo,
    this.onRedo,
    this.canUndo = false,
    this.canRedo = false,
  });

  @override
  State<RibbonToolbar> createState() => _RibbonToolbarState();
}

class _RibbonToolbarState extends State<RibbonToolbar>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tab bar
          Container(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              labelPadding: const EdgeInsets.symmetric(horizontal: 16),
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(text: 'Trang chủ'),
                Tab(text: 'Chèn'),
                Tab(text: 'Thiết kế'),
                Tab(text: 'Chuyển động'),
                Tab(text: 'Trình chiếu'),
                Tab(text: 'Xem'),
              ],
            ),
          ),

          // Tab content
          SizedBox(
            height: 90,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildHomeTab(context),
                _buildInsertTab(context),
                _buildDesignTab(context),
                _buildTransitionsTab(context),
                _buildSlideshowTab(context),
                _buildViewTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- Home Tab ----
  Widget _buildHomeTab(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Clipboard group
            _RibbonGroup(
              label: 'Clipboard',
              children: [
                _RibbonButton(
                  icon: Icons.content_paste,
                  label: 'Paste',
                  onPressed: () {},
                  large: true,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RibbonButton(
                      icon: Icons.content_cut,
                      label: 'Cut',
                      onPressed: () {},
                      compact: true,
                    ),
                    _RibbonButton(
                      icon: Icons.content_copy,
                      label: 'Copy',
                      onPressed: () {},
                      compact: true,
                    ),
                  ],
                ),
              ],
            ),

            _RibbonDivider(),

            // Font group
            _RibbonGroup(
              label: 'Font',
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RibbonButton(
                      icon: Icons.format_bold,
                      tooltip: 'Bold',
                      onPressed: () {},
                      compact: true,
                    ),
                    _RibbonButton(
                      icon: Icons.format_italic,
                      tooltip: 'Italic',
                      onPressed: () {},
                      compact: true,
                    ),
                    _RibbonButton(
                      icon: Icons.format_underlined,
                      tooltip: 'Underline',
                      onPressed: () {},
                      compact: true,
                    ),
                    _RibbonButton(
                      icon: Icons.strikethrough_s,
                      tooltip: 'Strikethrough',
                      onPressed: () {},
                      compact: true,
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RibbonButton(
                      icon: Icons.format_color_text,
                      tooltip: 'Font Color',
                      onPressed: () {},
                      compact: true,
                    ),
                    _RibbonButton(
                      icon: Icons.highlight,
                      tooltip: 'Highlight',
                      onPressed: () {},
                      compact: true,
                    ),
                  ],
                ),
              ],
            ),

            _RibbonDivider(),

            // Paragraph group
            _RibbonGroup(
              label: 'Paragraph',
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RibbonButton(
                      icon: Icons.format_align_left,
                      tooltip: 'Align Left',
                      onPressed: () {},
                      compact: true,
                    ),
                    _RibbonButton(
                      icon: Icons.format_align_center,
                      tooltip: 'Align Center',
                      onPressed: () {},
                      compact: true,
                    ),
                    _RibbonButton(
                      icon: Icons.format_align_right,
                      tooltip: 'Align Right',
                      onPressed: () {},
                      compact: true,
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RibbonButton(
                      icon: Icons.format_list_bulleted,
                      tooltip: 'Bullet List',
                      onPressed: () {},
                      compact: true,
                    ),
                    _RibbonButton(
                      icon: Icons.format_list_numbered,
                      tooltip: 'Numbered List',
                      onPressed: () {},
                      compact: true,
                    ),
                    _RibbonButton(
                      icon: Icons.format_indent_increase,
                      tooltip: 'Increase Indent',
                      onPressed: () {},
                      compact: true,
                    ),
                  ],
                ),
              ],
            ),

            _RibbonDivider(),

            // Drawing group
            _RibbonGroup(
              label: 'Drawing',
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RibbonButton(
                      icon: Icons.crop_square,
                      tooltip: 'Rectangle',
                      onPressed: () {},
                      compact: true,
                    ),
                    _RibbonButton(
                      icon: Icons.circle_outlined,
                      tooltip: 'Circle',
                      onPressed: () {},
                      compact: true,
                    ),
                    _RibbonButton(
                      icon: Icons.horizontal_rule,
                      tooltip: 'Line',
                      onPressed: () {},
                      compact: true,
                    ),
                    _RibbonButton(
                      icon: Icons.text_fields,
                      tooltip: 'Text Box',
                      onPressed: () {},
                      compact: true,
                    ),
                  ],
                ),
              ],
            ),

            _RibbonDivider(),

            // Editing group
            _RibbonGroup(
              label: 'Editing',
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RibbonButton(
                      icon: Icons.undo,
                      tooltip: 'Undo (Ctrl+Z)',
                      onPressed: widget.canUndo ? widget.onUndo : null,
                      compact: true,
                    ),
                    _RibbonButton(
                      icon: Icons.redo,
                      tooltip: 'Redo (Ctrl+Y)',
                      onPressed: widget.canRedo ? widget.onRedo : null,
                      compact: true,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---- Insert Tab ----
  Widget _buildInsertTab(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RibbonGroup(
              label: 'Slides',
              children: [
                _RibbonButton(
                  icon: Icons.add_circle_outline,
                  label: 'New Slide',
                  onPressed: () {},
                  large: true,
                ),
              ],
            ),
            _RibbonDivider(),
            _RibbonGroup(
              label: 'Images',
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RibbonButton(
                      icon: Icons.image_outlined,
                      label: 'Pictures',
                      onPressed: () {},
                      compact: true,
                    ),
                    _RibbonButton(
                      icon: Icons.photo_library_outlined,
                      label: 'Stock',
                      onPressed: () {},
                      compact: true,
                    ),
                  ],
                ),
              ],
            ),
            _RibbonDivider(),
            _RibbonGroup(
              label: 'Illustrations',
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RibbonButton(
                      icon: Icons.table_chart_outlined,
                      label: 'Table',
                      onPressed: () {},
                      compact: true,
                    ),
                    _RibbonButton(
                      icon: Icons.pie_chart_outline,
                      label: 'Chart',
                      onPressed: () {},
                      compact: true,
                    ),
                    _RibbonButton(
                      icon: Icons.account_tree_outlined,
                      label: 'SmartArt',
                      onPressed: () {},
                      compact: true,
                    ),
                  ],
                ),
              ],
            ),
            _RibbonDivider(),
            _RibbonGroup(
              label: 'Text',
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RibbonButton(
                      icon: Icons.text_fields,
                      label: 'Text Box',
                      onPressed: () {},
                      compact: true,
                    ),
                    _RibbonButton(
                      icon: Icons.art_track,
                      label: 'WordArt',
                      onPressed: () {},
                      compact: true,
                    ),
                    _RibbonButton(
                      icon: Icons.shortcut,
                      label: 'Header',
                      onPressed: () {},
                      compact: true,
                    ),
                  ],
                ),
              ],
            ),
            _RibbonDivider(),
            _RibbonGroup(
              label: 'Symbols',
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RibbonButton(
                      icon: Icons.emoji_symbols,
                      label: 'Symbol',
                      onPressed: () {},
                      compact: true,
                    ),
                    _RibbonButton(
                      icon: Icons.code,
                      label: 'Code',
                      onPressed: () {},
                      compact: true,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---- Design Tab ----
  Widget _buildDesignTab(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RibbonGroup(
              label: 'Themes',
              children: [
                SizedBox(
                  height: 56,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 8,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final colors = [
                        [Colors.blue.shade800, Colors.blue.shade200],
                        [Colors.grey.shade800, Colors.grey.shade300],
                        [Colors.teal.shade700, Colors.teal.shade200],
                        [Colors.purple.shade700, Colors.purple.shade200],
                        [Colors.red.shade700, Colors.red.shade200],
                        [Colors.indigo.shade700, Colors.indigo.shade200],
                        [Colors.brown.shade700, Colors.brown.shade200],
                        [Colors.green.shade700, Colors.green.shade200],
                      ];
                      return GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: colors[index],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: theme.colorScheme.outline.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Aa',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            _RibbonDivider(),
            _RibbonGroup(
              label: 'Variants',
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _colorVariant(Colors.blue, 'Blue'),
                    _colorVariant(Colors.red, 'Red'),
                    _colorVariant(Colors.green, 'Green'),
                    _colorVariant(Colors.orange, 'Orange'),
                  ],
                ),
              ],
            ),
            _RibbonDivider(),
            _RibbonGroup(
              label: 'Customize',
              children: [
                _RibbonButton(
                  icon: Icons.format_color_fill,
                  label: 'Background',
                  onPressed: () {},
                  compact: true,
                ),
                _RibbonButton(
                  icon: Icons.gradient,
                  label: 'Gradient',
                  onPressed: () {},
                  compact: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorVariant(Color color, String label) {
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: () {},
        child: Container(
          width: 24,
          height: 24,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }

  // ---- Transitions Tab ----
  Widget _buildTransitionsTab(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RibbonGroup(
              label: 'Transition to This Slide',
              children: [
                SizedBox(
                  height: 56,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 14,
                    separatorBuilder: (_, __) => const SizedBox(width: 4),
                    itemBuilder: (context, index) {
                      final effects = SlideEffect.values.where((e) => e != SlideEffect.none).toList();
                      if (index >= effects.length) return const SizedBox.shrink();
                      final effect = effects[index];
                      return _TransitionButton(
                        effect: effect,
                        label: EffectHelpers.effectName(effect),
                        onPressed: () {},
                      );
                    },
                  ),
                ),
              ],
            ),
            _RibbonDivider(),
            _RibbonGroup(
              label: 'Timing',
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RibbonButton(
                      icon: Icons.timer_outlined,
                      label: 'Duration',
                      onPressed: () {},
                      compact: true,
                    ),
                    _RibbonButton(
                      icon: Icons.mouse,
                      label: 'On Click',
                      onPressed: () {},
                      compact: true,
                    ),
                    _RibbonButton(
                      icon: Icons.access_time,
                      label: 'Auto',
                      onPressed: () {},
                      compact: true,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---- Slide Show Tab ----
  Widget _buildSlideshowTab(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RibbonGroup(
              label: 'Start Slide Show',
              children: [
                _RibbonButton(
                  icon: Icons.play_arrow,
                  label: 'From Beginning',
                  onPressed: widget.onPresent,
                  large: true,
                ),
                _RibbonButton(
                  icon: Icons.play_circle_outline,
                  label: 'From Current',
                  onPressed: widget.onPresent,
                  compact: true,
                ),
              ],
            ),
            _RibbonDivider(),
            _RibbonGroup(
              label: 'Set Up',
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RibbonButton(
                      icon: Icons.slideshow,
                      label: 'Presenter View',
                      onPressed: () {},
                      compact: true,
                    ),
                    _RibbonButton(
                      icon: Icons.record_voice_over,
                      label: 'Rehearse',
                      onPressed: () {},
                      compact: true,
                    ),
                    _RibbonButton(
                      icon: Icons.timer,
                      label: 'Timings',
                      onPressed: () {},
                      compact: true,
                    ),
                  ],
                ),
              ],
            ),
            _RibbonDivider(),
            _RibbonGroup(
              label: 'Monitors',
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RibbonButton(
                      icon: Icons.monitor,
                      label: 'Primary',
                      onPressed: () {},
                      compact: true,
                    ),
                    _RibbonButton(
                      icon: Icons.aspect_ratio,
                      label: 'Use Presenter View',
                      onPressed: () {},
                      compact: true,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---- View Tab ----
  Widget _buildViewTab(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RibbonGroup(
              label: 'Presentation Views',
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RibbonButton(
                      icon: Icons.edit_note,
                      label: 'Normal',
                      onPressed: () {},
                      compact: true,
                    ),
                    _RibbonButton(
                      icon: Icons.grid_view,
                      label: 'Slide Sorter',
                      onPressed: () {},
                      compact: true,
                    ),
                    _RibbonButton(
                      icon: Icons.auto_stories,
                      label: 'Reading View',
                      onPressed: () {},
                      compact: true,
                    ),
                  ],
                ),
              ],
            ),
            _RibbonDivider(),
            _RibbonGroup(
              label: 'Show',
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RibbonButton(
                      icon: Icons.grid_on,
                      label: 'Grid',
                      onPressed: () {},
                      compact: true,
                    ),
                    _RibbonButton(
                      icon: Icons.straighten,
                      label: 'Ruler',
                      onPressed: () {},
                      compact: true,
                    ),
                    _RibbonButton(
                      icon: Icons.zoom_out_map,
                      label: 'Zoom',
                      onPressed: () {},
                      compact: true,
                    ),
                  ],
                ),
              ],
            ),
            _RibbonDivider(),
            _RibbonGroup(
              label: 'Window',
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RibbonButton(
                      icon: Icons.fullscreen,
                      label: 'Fullscreen',
                      onPressed: () {},
                      compact: true,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A group of related ribbon buttons with a label.
class _RibbonGroup extends StatelessWidget {
  final String label;
  final List<Widget> children;

  const _RibbonGroup({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group content
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
        // Group label
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}

/// A single ribbon button — can be large (with label) or compact (icon only).
class _RibbonButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final String? tooltip;
  final VoidCallback? onPressed;
  final bool large;
  final bool compact;

  const _RibbonButton({
    required this.icon,
    this.label,
    this.tooltip,
    this.onPressed,
    this.large = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (large) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(icon, size: 22),
              tooltip: tooltip ?? label,
              onPressed: onPressed,
              visualDensity: VisualDensity.compact,
            ),
            if (label != null)
              Text(
                label!,
                style: TextStyle(
                  fontSize: 9,
                  color: onPressed != null
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: IconButton(
        icon: Icon(icon, size: compact ? 16 : 18),
        tooltip: tooltip ?? label,
        onPressed: onPressed,
        visualDensity: VisualDensity.compact,
        padding: compact ? EdgeInsets.zero : null,
        constraints: compact
            ? const BoxConstraints(minWidth: 24, minHeight: 24)
            : null,
      ),
    );
  }
}

/// A transition effect button in the ribbon.
class _TransitionButton extends StatelessWidget {
  final SlideEffect effect;
  final String label;
  final VoidCallback onPressed;

  const _TransitionButton({
    required this.effect,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = _iconForEffect(effect);

    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 56,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(fontSize: 8, color: theme.colorScheme.onSurface),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForEffect(SlideEffect effect) {
    switch (effect) {
      case SlideEffect.fade:
        return Icons.opacity;
      case SlideEffect.pushLeft:
        return Icons.arrow_back;
      case SlideEffect.pushRight:
        return Icons.arrow_forward;
      case SlideEffect.pushUp:
        return Icons.arrow_upward;
      case SlideEffect.pushDown:
        return Icons.arrow_downward;
      case SlideEffect.wipe:
        return Icons.cleaning_services;
      case SlideEffect.splitIn:
        return Icons.call_split;
      case SlideEffect.splitOut:
        return Icons.call_merge;
      case SlideEffect.randomBar:
        return Icons.view_column;
      case SlideEffect.checkerboard:
        return Icons.grid_view;
      case SlideEffect.blinds:
        return Icons.view_column;
      case SlideEffect.clock:
        return Icons.schedule;
      case SlideEffect.zoom:
        return Icons.zoom_in;
      default:
        return Icons.animation;
    }
  }
}

/// Vertical divider between ribbon groups.
class _RibbonDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 70,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
    );
  }
}
