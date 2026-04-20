import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sky_defense/core/localization/app_localizations.dart';
import 'package:sky_defense/core/theme/app_spacing.dart';
import 'package:sky_defense/domain/entities/app_language.dart';
import 'package:sky_defense/presentation/providers/app_providers.dart';
import 'package:sky_defense/presentation/widgets/app_container.dart';
import 'package:sky_defense/presentation/widgets/app_text.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Future<void> _changeLanguage(AppLanguage language) async {
    await ref.read(appLanguageControllerProvider.notifier).setLanguage(language);
    if (!mounted) {
      return;
    }
    final AppLocalizations localization = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AppText(
          textKey: 'settings_language_changed',
          args: <String, String>{
            'value': localization.tr(
              language == AppLanguage.spanish
                  ? 'settings_language_es'
                  : 'settings_language_en',
            ),
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLanguage selected = ref.watch(appLanguageControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const AppText(
          textKey: 'settings_title',
          variant: AppTextVariant.heading,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const AppText(
              textKey: 'settings_language_section',
              variant: AppTextVariant.heading,
            ),
            const SizedBox(height: AppSpacing.sm),
            const AppText(textKey: 'settings_language_description'),
            const SizedBox(height: AppSpacing.lg),
            AppContainer(
              elevationPreset: AppContainerElevation.low,
              child: Column(
                children: <Widget>[
                  _LanguageOption(
                    textKey: 'settings_language_es',
                    selected: selected == AppLanguage.spanish,
                    onTap: () => _changeLanguage(AppLanguage.spanish),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _LanguageOption(
                    textKey: 'settings_language_en',
                    selected: selected == AppLanguage.english,
                    onTap: () => _changeLanguage(AppLanguage.english),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppText(
              textKey: 'settings_current_language_value',
              args: <String, String>{'value': selected.code.toUpperCase()},
              variant: AppTextVariant.caption,
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.textKey,
    required this.selected,
    required this.onTap,
  });

  final String textKey;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        title: AppText(
          textKey: textKey,
          variant: selected ? AppTextVariant.subheading : AppTextVariant.body,
        ),
        trailing: AppText(
          textKey: selected ? 'settings_language_active' : 'settings_language_select',
          variant: AppTextVariant.caption,
        ),
      ),
    );
  }
}
