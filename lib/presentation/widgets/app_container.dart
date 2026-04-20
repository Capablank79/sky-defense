import 'package:flutter/material.dart';
import 'package:sky_defense/core/theme/app_spacing.dart';

enum AppContainerPadding {
  none,
  small,
  medium,
  large,
}

enum AppContainerRadius {
  small,
  medium,
  large,
}

enum AppContainerElevation {
  none,
  low,
  medium,
  high,
}

class AppContainer extends StatelessWidget {
  const AppContainer({
    super.key,
    required this.child,
    this.paddingPreset = AppContainerPadding.medium,
    this.radiusPreset = AppContainerRadius.medium,
    this.elevationPreset = AppContainerElevation.none,
    this.margin = EdgeInsets.zero,
    this.backgroundColor,
  });

  final Widget child;
  final AppContainerPadding paddingPreset;
  final AppContainerRadius radiusPreset;
  final AppContainerElevation elevationPreset;
  final EdgeInsetsGeometry margin;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final double padding = switch (paddingPreset) {
      AppContainerPadding.none => 0,
      AppContainerPadding.small => AppSpacing.sm,
      AppContainerPadding.medium => AppSpacing.lg,
      AppContainerPadding.large => AppSpacing.xl,
    };
    final double radius = switch (radiusPreset) {
      AppContainerRadius.small => 8,
      AppContainerRadius.medium => 12,
      AppContainerRadius.large => 18,
    };
    final double elevation = switch (elevationPreset) {
      AppContainerElevation.none => 0,
      AppContainerElevation.low => 1,
      AppContainerElevation.medium => 3,
      AppContainerElevation.high => 6,
    };

    return Material(
      elevation: elevation,
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        margin: margin,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: backgroundColor ??
              Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: child,
      ),
    );
  }
}
