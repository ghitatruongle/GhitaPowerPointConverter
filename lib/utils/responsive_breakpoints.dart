import 'package:flutter/material.dart';

/// Responsive breakpoints for layout adaptations
class Breakpoints {
  static const double compact = 600;
  static const double medium = 900;
  static const double expanded = 1200;
  static const double large = 1600;
}

/// Layout size class
enum LayoutSize { compact, medium, expanded, large }

extension LayoutSizeExtension on LayoutSize {
  bool get isCompact => this == LayoutSize.compact;
  bool get isMedium => this == LayoutSize.medium;
  bool get isExpanded => this == LayoutSize.expanded;
  bool get isLarge => this == LayoutSize.large;

  bool get isAtLeastMedium =>
      this == LayoutSize.medium || this == LayoutSize.expanded || this == LayoutSize.large;
  bool get isAtLeastExpanded => this == LayoutSize.expanded || this == LayoutSize.large;
}

/// Helper to determine layout size from constraints
LayoutSize layoutSizeFromWidth(double width) {
  if (width < Breakpoints.compact) return LayoutSize.compact;
  if (width < Breakpoints.medium) return LayoutSize.medium;
  if (width < Breakpoints.expanded) return LayoutSize.expanded;
  return LayoutSize.large;
}

/// Responsive widget helper
class Responsive extends StatelessWidget {
  final Widget compact;
  final Widget? medium;
  final Widget? expanded;
  final Widget? large;

  const Responsive({
    super.key,
    required this.compact,
    this.medium,
    this.expanded,
    this.large,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = layoutSizeFromWidth(constraints.maxWidth);
        switch (size) {
          case LayoutSize.compact:
            return compact;
          case LayoutSize.medium:
            return medium ?? compact;
          case LayoutSize.expanded:
            return expanded ?? medium ?? compact;
          case LayoutSize.large:
            return large ?? expanded ?? medium ?? compact;
        }
      },
    );
  }
}

/// Responsive value helper - returns different values based on layout size
class ResponsiveValue<T> {
  final T compact;
  final T? medium;
  final T? expanded;
  final T? large;

  const ResponsiveValue({
    required this.compact,
    this.medium,
    this.expanded,
    this.large,
  });

  T getValue(LayoutSize size) {
    switch (size) {
      case LayoutSize.compact:
        return compact;
      case LayoutSize.medium:
        return medium ?? compact;
      case LayoutSize.expanded:
        return expanded ?? medium ?? compact;
      case LayoutSize.large:
        return large ?? expanded ?? medium ?? compact;
    }
  }
}

/// Helper extension to get responsive sidebar widths
class ResponsiveSizes {
  static double sidebarWidth(LayoutSize size) {
    switch (size) {
      case LayoutSize.compact:
        return 56;
      case LayoutSize.medium:
        return 64;
      case LayoutSize.expanded:
        return 72;
      case LayoutSize.large:
        return 80;
    }
  }

  static double slideListWidth(LayoutSize size) {
    switch (size) {
      case LayoutSize.compact:
        return 140;
      case LayoutSize.medium:
        return 180;
      case LayoutSize.expanded:
        return 200;
      case LayoutSize.large:
        return 220;
    }
  }

  static double propertiesPanelWidth(LayoutSize size) {
    switch (size) {
      case LayoutSize.compact:
        return 200;
      case LayoutSize.medium:
        return 240;
      case LayoutSize.expanded:
        return 280;
      case LayoutSize.large:
        return 320;
    }
  }
}