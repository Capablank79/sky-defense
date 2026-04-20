import 'package:flutter/material.dart';
import 'package:sky_defense/core/localization/app_localizations.dart';
import 'package:sky_defense/core/theme/app_spacing.dart';

enum AppButtonVariant {
  primary,
  secondary,
  ghost,
}

enum AppButtonSize {
  small,
  medium,
  large,
}

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.labelKey,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isDisabled = false,
    this.isExpanded = true,
  });

  final String labelKey;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final bool isDisabled;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final String label = AppLocalizations.of(context).tr(labelKey);
    final double height = switch (size) {
      AppButtonSize.small => AppSpacing.buttonSmallHeight,
      AppButtonSize.medium => AppSpacing.buttonMediumHeight,
      AppButtonSize.large => AppSpacing.buttonLargeHeight,
    };

    final bool blocked = isDisabled || isLoading;
    final VoidCallback? action = blocked ? null : onPressed;

    final Widget content = isLoading
        ? const SizedBox(
            width: AppSpacing.progressIndicatorSize,
            height: AppSpacing.progressIndicatorSize,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label);

    final Widget button;
    switch (variant) {
      case AppButtonVariant.primary:
        button = FilledButton(
          onPressed: action,
          style: FilledButton.styleFrom(
            minimumSize: Size(double.infinity, height),
          ),
          child: content,
        );
      case AppButtonVariant.secondary:
        button = OutlinedButton(
          onPressed: action,
          style: OutlinedButton.styleFrom(
            minimumSize: Size(double.infinity, height),
          ),
          child: content,
        );
      case AppButtonVariant.ghost:
        button = TextButton(
          onPressed: action,
          style: TextButton.styleFrom(
            minimumSize: Size(double.infinity, height),
          ),
          child: content,
        );
    }

    if (!isExpanded) {
      return button;
    }

    return SizedBox(width: double.infinity, child: button);
  }
}
