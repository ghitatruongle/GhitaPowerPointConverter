import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/presentation_state.dart';

class EffectsScreen extends StatefulWidget {
  const EffectsScreen({super.key});

  @override
  State<EffectsScreen> createState() => _EffectsScreenState();
}

class _EffectsScreenState extends State<EffectsScreen> {
  final List<SlideEffect> _availableEffects = [
    SlideEffect.none,
    SlideEffect.fade,
    SlideEffect.pushLeft,
    SlideEffect.pushRight,
    SlideEffect.pushUp,
    SlideEffect.pushDown,
    SlideEffect.wipe,
    SlideEffect.splitIn,
    SlideEffect.splitOut,
    SlideEffect.randomBar,
    SlideEffect.checkerboard,
    SlideEffect.blinds,
    SlideEffect.clock,
    SlideEffect.zoom,
  ];

  SlideEffect _selectedEffect = SlideEffect.none;
  double _animationDuration = 1.0;
  bool _enableLoop = false;

  @override
  Widget build(BuildContext context) {
    final presentationState = Provider.of<PresentationState>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Enhanced Animation Effects', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Apply advanced animations and themes to your presentation slides'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select Animation Type', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedEffect.name,
                    items: _availableAnimations.map((String value) {
                      return DropdownMenuItem(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() => _selectedEffect.name = newValue);
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  Text('Animation Duration (${_animationDuration.toStringAsFixed(1)}s)', style: Theme.of(context).textTheme.titleMedium),
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
                        onChanged: (value) => setState(() => _enableLoop = value ?? false),
                      ),
                      const Expanded(child: Text('Loop Animation Preview')),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Live Preview:', style: TextStyle(fontWeight: FontWeight.bold)),
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

                  const SizedBox(height: 16),

                  ElevatedButton.icon(
                    onPressed: () {
                      presentationState.setEffect(_selectedEffect);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Applied effect to presentation!')),
                      );
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Apply Effect to Presentation'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Advanced Visual Effects:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(avatar: Icon(Icons.auto_awesome, size: 16), label: Text('Glow Effect')),
                      Chip(avatar: Icon(Icons.layers, size: 16), label: Text('Shadow Depth')),
                      Chip(avatar: Icon(Icons.gradient, size: 16), label: Text('Gradient Background')),
                      Chip(avatar: Icon(Icons.highlight, size: 16), label: Text('Text Highlight')),
                      Chip(avatar: Icon(Icons.style, size: 16), label: Text('Image Masking')),
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

  Widget _buildAnimatedWidget() {
    final duration = Duration(milliseconds: (_animationDuration * 1000).round());
    final textWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$_selectedEffect.name Effect',
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );

    Animate animate;

    switch (_selectedEffect.name) {
      case 'Fade In':
        animate = textWidget.animate(onComplete: _enableLoop ? (controller) => controller.repeat(reverse: true) : null).fadeIn(duration: duration);
        break;
      case 'Slide In Left':
        animate = textWidget.animate(onComplete: _enableLoop ? (controller) => controller.repeat(reverse: true) : null).slideX(begin: -1.0, end: 0.0, duration: duration);
        break;
      case 'Slide In Right':
        animate = textWidget.animate(onComplete: _enableLoop ? (controller) => controller.repeat(reverse: true) : null).slideX(begin: 1.0, end: 0.0, duration: duration);
        break;
      case 'Scale In':
        animate = textWidget.animate(onComplete: _enableLoop ? (controller) => controller.repeat(reverse: true) : null).scale(duration: duration);
        break;
      case 'Rotate In':
        animate = textWidget.animate(onComplete: _enableLoop ? (controller) => controller.repeat(reverse: true) : null).rotate(duration: duration);
        break;
      case 'Bounce In':
        animate = textWidget.animate(onComplete: _enableLoop ? (controller) => controller.repeat(reverse: true) : null).scale(duration: duration, curve: Curves.elasticOut);
        break;
      default:
        animate = textWidget.animate(onComplete: _enableLoop ? (controller) => controller.repeat(reverse: true) : null).fadeIn(duration: duration);
    }

    return animate;
  }
}

