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
  /// Animation preview types for the live widget preview
  final List<String> _availableAnimations = [
    'Fade In',
    'Slide In Left',
    'Slide In Right',
    'Scale In',
    'Rotate In',
    'Bounce In',
  ];

  /// Available PPTX transition effects (for export)
  final List<SlideEffect> _availableSlideEffects = SlideEffect.values;

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
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Enhanced Animation Effects',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(
                      'Preview animations and apply transition effects to your PPTX export'),
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
                  DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedAnimation,
                    items: _availableAnimations.map((String name) {
                      return DropdownMenuItem(
                        value: name,
                        child: Text(name),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() => _selectedAnimation = newValue);
                      }
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
                  DropdownButton<SlideEffect>(
                    isExpanded: true,
                    value: _selectedSlideEffect,
                    items: _availableSlideEffects.map((SlideEffect effect) {
                      return DropdownMenuItem(
                        value: effect,
                        child: Text(_slideEffectDisplayName(effect)),
                      );
                    }).toList(),
                    onChanged: (SlideEffect? newValue) {
                      if (newValue != null) {
                        setState(() => _selectedSlideEffect = newValue);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      presentationState.setEffect(_selectedSlideEffect);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Applied "${_slideEffectDisplayName(_selectedSlideEffect)}" effect to presentation!'),
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

          // --- Visual Effects Chips ---
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Advanced Visual Effects:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                          avatar: Icon(Icons.auto_awesome, size: 16),
                          label: Text('Glow Effect')),
                      Chip(
                          avatar: Icon(Icons.layers, size: 16),
                          label: Text('Shadow Depth')),
                      Chip(
                          avatar: Icon(Icons.gradient, size: 16),
                          label: Text('Gradient Background')),
                      Chip(
                          avatar: Icon(Icons.highlight, size: 16),
                          label: Text('Text Highlight')),
                      Chip(
                          avatar: Icon(Icons.style, size: 16),
                          label: Text('Image Masking')),
                    ],
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
