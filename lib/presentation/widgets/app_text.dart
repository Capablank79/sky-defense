import 'package:flutter/material.dart';
import 'package:sky_defense/core/localization/app_localizations.dart';
import 'package:sky_defense/core/theme/app_text_styles.dart';

enum AppTextVariant {
  heading,
  subheading,
  body,
  caption,
}

class AppText extends StatelessWidget {
  const AppText({
    required this.textKey,
    super.key,
    this.variant = AppTextVariant.body,
    this.styleOverride,
    this.textAlign,
    this.args = const <String, String>{},
  });

  final String textKey;
  final AppTextVariant variant;
  final TextStyle? styleOverride;
  final TextAlign? textAlign;
  final Map<String, String> args;

  @override
  Widget build(BuildContext context) {
    final String resolved = args.isEmpty
        ? AppLocalizations.of(context).tr(textKey)
        : AppLocalizations.of(context).trWithArgs(textKey, args);

    final TextStyle baseStyle = switch (variant) {
      AppTextVariant.heading =>
        Theme.of(context).textTheme.titleLarge ?? AppTextStyles.heading,
      AppTextVariant.subheading =>
        Theme.of(context).textTheme.titleMedium ?? AppTextStyles.subheading,
      AppTextVariant.body =>
        Theme.of(context).textTheme.bodyLarge ?? AppTextStyles.body,
      AppTextVariant.caption =>
        Theme.of(context).textTheme.bodySmall ?? AppTextStyles.caption,
    };

    return Text(
      resolved,
      style: styleOverride == null ? baseStyle : baseStyle.merge(styleOverride),
      textAlign: textAlign,
    );
  }
}
