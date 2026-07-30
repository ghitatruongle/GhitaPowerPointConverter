import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart' hide SlideEffect;
import 'package:provider/provider.dart';
import '../providers/presentation_state.dart';

class EffectsScreen extends StatefulWidget {
  const EffectsScreen({super.key});

  @override
  State<EffectsScreen> createState() => _EffectsScreenState();
}

class _EffectsScreenState extends State<EffectsScreen> {
  /// Currently selected preview animation name
  String _selectedAnimation = 'Fade In';

  /// Currently selected PPTX slide effect for export
  SlideEffect _selectedSlideEffect = SlideEffect.none;

  double _animationDuration = 1.0;
  bool _enableLoop = false;

  @override
  Widget build(BuildContext context) {
    final presentationState = Provider.of<PresentationState>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Enhanced Animation Effects',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Preview animations and apply transition effects to your PPTX export',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // --- Preview Animation Settings ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Live Preview Animation',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'Fade In',
                        label: Text('Fade'),
                        icon: Icon(Icons.opacity, size: 18),
                      ),
                      ButtonSegment(
                        value: 'Slide In Left',
                        label: Text('Slide L'),
                        icon: Icon(Icons.swipe, size: 18),
                      ),
                      ButtonSegment(
                        value: 'Slide In Right',
                        label: Text('Slide R'),
                        icon: Icon(Icons.swipe, size: 18),
                      ),
                      ButtonSegment(
                        value: 'Scale In',
                        label: Text('Scale'),
                        icon: Icon(Icons.zoom_in, size: 18),
                      ),
                      ButtonSegment(
                        value: 'Rotate In',
                        label: Text('Rotate'),
                        icon: Icon(Icons.rotate_right, size: 18),
                      ),
                      ButtonSegment(
                        value: 'Bounce In',
                        label: Text('Bounce'),
                        icon: Icon(Icons.animation, size: 18),
                      ),
                    ],
                    selected: {_selectedAnimation},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() => _selectedAnimation = newSelection.first);
                    },
                  ),

                  const SizedBox(height: 16),

                  Text(
                      'Animation Duration (${_animationDuration.toStringAsFixed(1)}s)',
                      style: Theme.of(context).textTheme.titleMedium),
                  Slider(
                    min: 0.3,
                    max: 3.0,
                    value: _animationDuration,
                    divisions: 9,
                    label: '${_animationDuration.toStringAsFixed(1)}s',
                    onChanged: (double value) {
                      setState(() => _animationDuration = value);
                    },
                  ),

                  Row(
                    children: [
                      Checkbox(
                        value: _enableLoop,
                        onChanged: (value) =>
                            setState(() => _enableLoop = value ?? false),
                      ),
                      const Expanded(child: Text('Loop Animation Preview')),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // --- Live Preview ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Live Preview:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: _buildAnimatedWidget(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // --- PPTX Transition Effect Selection ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PPTX Export Transition',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('Choose a slide transition effect for your exported PPTX',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  SegmentedButton<SlideEffect>(
                    segments: const [
                      ButtonSegment(
                        value: SlideEffect.none,
                        label: Text('None'),
                        icon: Icon(Icons.block, size: 18),
                      ),
                      ButtonSegment(
                        value: SlideEffect.fade,
                        label: Text('Fade'),
                        icon: Icon(Icons.opacity, size: 18),
                      ),
                      ButtonSegment(
                        value: SlideEffect.pushLeft,
                        label: Text('Push L'),
                        icon: Icon(Icons.arrow_back, size: 18),
                      ),
                      ButtonSegment(
                        value: SlideEffect.wipe,
                        label: Text('Wipe'),
                        icon: Icon(Icons.cleaning_services, size: 18),
                      ),
                      ButtonSegment(
                        value: SlideEffect.zoom,
                        label: Text('Zoom'),
                        icon: Icon(Icons.zoom_in, size: 18),
                      ),
                    ],
                    selected: {_selectedSlideEffect},
                    onSelectionChanged: (Set<SlideEffect> newSelection) {
                      setState(() => _selectedSlideEffect = newSelection.first);
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      presentationState.setEffect(_selectedSlideEffect);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Applied "${_slideEffectDisplayName(_selectedSlideEffect)}" effect!'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Apply to Export'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // --- Visual Effects Info ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Available Transitions (${SlideEffect.values.length} total):',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: SlideEffect.values
                        .where((e) => e != SlideEffect.none)
                        .map((effect) {
                      return ActionChip(
                        label: Text(_slideEffectDisplayName(effect)),
                        onPressed: () {
                          setState(() => _selectedSlideEffect = effect);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build the animated preview widget based on selected animation name
  Widget _buildAnimatedWidget() {
    final duration =
        Duration(milliseconds: (_animationDuration * 1000).round());
    final textWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$_selectedAnimation Effect',
        style: const TextStyle(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );

    final onComplete = _enableLoop
        ? (AnimationController controller) =>
            controller.repeat(reverse: true)
        : null;

    late Animate animate;

    switch (_selectedAnimation) {
      case 'Fade In':
        animate = textWidget
            .animate(onComplete: onComplete)
            .fadeIn(duration: duration);
        break;
      case 'Slide In Left':
        animate = textWidget
            .animate(onComplete: onComplete)
            .slideX(begin: -1.0, end: 0.0, duration: duration);
        break;
      case 'Slide In Right':
        animate = textWidget
            .animate(onComplete: onComplete)
            .slideX(begin: 1.0, end: 0.0, duration: duration);
        break;
      case 'Scale In':
        animate = textWidget
            .animate(onComplete: onComplete)
            .scale(duration: duration);
        break;
      case 'Rotate In':
        animate = textWidget
            .animate(onComplete: onComplete)
            .rotate(duration: duration);
        break;
      case 'Bounce In':
        animate = textWidget
            .animate(onComplete: onComplete)
            .scale(duration: duration, curve: Curves.elasticOut);
        break;
      default:
        animate = textWidget
            .animate(onComplete: onComplete)
            .fadeIn(duration: duration);
    }

    return animate;
  }

  /// Convert a SlideEffect enum to a human-readable display name
  String _slideEffectDisplayName(SlideEffect? effect) {
    if (effect == null) return 'None';
    switch (effect) {
      case SlideEffect.none:
        return 'None';
      case SlideEffect.fade:
        return 'Fade';
      case SlideEffect.pushLeft:
        return 'Push Left';
      case SlideEffect.pushRight:
        return 'Push Right';
      case SlideEffect.pushUp:
        return 'Push Up';
      case SlideEffect.pushDown:
        return 'Push Down';
      case SlideEffect.wipe:
        return 'Wipe';
      case SlideEffect.splitIn:
        return 'Split In';
      case SlideEffect.splitOut:
        return 'Split Out';
      case SlideEffect.randomBar:
        return 'Random Bars';
      case SlideEffect.checkerboard:
        return 'Checkerboard';
      case SlideEffect.blinds:
        return 'Blinds';
      case SlideEffect.clock:
        return 'Clock';
      case SlideEffect.zoom:
        return 'Zoom';
    }
  }
}
