import '../models/slide.dart';

/// Shared helper for effect display names.
/// Used by ribbon_toolbar, effects_screen, and editor_state.
class EffectHelpers {
  EffectHelpers._();

  static String effectName(SlideEffect effect) {
    switch (effect) {
      case SlideEffect.none: return 'None';
      case SlideEffect.fade: return 'Fade';
      case SlideEffect.pushLeft: return 'Push Left';
      case SlideEffect.pushRight: return 'Push Right';
      case SlideEffect.pushUp: return 'Push Up';
      case SlideEffect.pushDown: return 'Push Down';
      case SlideEffect.wipe: return 'Wipe';
      case SlideEffect.splitIn: return 'Split In';
      case SlideEffect.splitOut: return 'Split Out';
      case SlideEffect.randomBar: return 'Random Bars';
      case SlideEffect.checkerboard: return 'Checkerboard';
      case SlideEffect.blinds: return 'Blinds';
      case SlideEffect.clock: return 'Clock';
      case SlideEffect.zoom: return 'Zoom';
      case SlideEffect.flyInLeft: return 'Fly In Left';
      case SlideEffect.flyInRight: return 'Fly In Right';
      case SlideEffect.flyInTop: return 'Fly In Top';
      case SlideEffect.flyInBottom: return 'Fly In Bottom';
      case SlideEffect.appear: return 'Appear';
      case SlideEffect.basicZoom: return 'Basic Zoom';
      case SlideEffect.swivel: return 'Swivel';
      case SlideEffect.boomerang: return 'Boomerang';
      case SlideEffect.pulse: return 'Pulse';
      case SlideEffect.growShrink: return 'Grow/Shrink';
      case SlideEffect.spin: return 'Spin';
      case SlideEffect.teeter: return 'Teeter';
      case SlideEffect.flicker: return 'Flicker';
      case SlideEffect.colorPulse: return 'Color Pulse';
      case SlideEffect.flyOutLeft: return 'Fly Out Left';
      case SlideEffect.flyOutRight: return 'Fly Out Right';
      case SlideEffect.disappear: return 'Disappear';
      case SlideEffect.arc: return 'Arc';
      case SlideEffect.customPath: return 'Custom Path';
    }
  }
}
