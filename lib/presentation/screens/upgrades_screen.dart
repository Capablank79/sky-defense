import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sky_defense/core/theme/app_spacing.dart';
import 'package:sky_defense/domain/entities/player_profile.dart';
import 'package:sky_defense/domain/entities/player_upgrades.dart';
import 'package:sky_defense/presentation/providers/feature_providers.dart';
import 'package:sky_defense/presentation/widgets/app_button.dart';
import 'package:sky_defense/presentation/widgets/app_container.dart';
import 'package:sky_defense/presentation/widgets/app_text.dart';

class UpgradesScreen extends ConsumerWidget {
  const UpgradesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PlayerProfile? profile = ref.watch(
      playerProvider
          .select((AsyncValue<PlayerProfile> value) => value.asData?.value),
    );
    final bool loading = ref.watch(
      playerProvider
          .select((AsyncValue<PlayerProfile> value) => value.isLoading),
    );

    return Scaffold(
      appBar: AppBar(
        title: const AppText(
          textKey: 'upgrades_title',
          variant: AppTextVariant.heading,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: loading || profile == null
            ? const Center(
                child: AppText(
                  textKey: 'upgrades_loading',
                  variant: AppTextVariant.body,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AppContainer(
                    elevationPreset: AppContainerElevation.low,
                    child: AppText(
                      textKey: 'upgrades_credits_value',
                      args: <String, String>{
                        'value': profile.economy.credits.toString(),
                      },
                      variant: AppTextVariant.subheading,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: ListView(
                      children: UpgradeType.values
                          .map((UpgradeType type) => _UpgradeCard(type: type))
                          .toList(growable: false),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _UpgradeCard extends ConsumerWidget {
  const _UpgradeCard({
    required this.type,
  });

  final UpgradeType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PlayerProfile? profile = ref.watch(playerProvider).value;
    if (profile == null) {
      return const SizedBox.shrink();
    }
    final PlayerController controller = ref.read(playerProvider.notifier);
    final int level = profile.upgrades.levelFor(type);
    final int cost = controller.upgradeCostFor(profile.upgrades, type);
    final bool maxed = level >= PlayerUpgrades.maxLevel;

    return AppContainer(
      elevationPreset: AppContainerElevation.low,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppText(
            textKey: _titleKey(type),
            variant: AppTextVariant.subheading,
          ),
          const SizedBox(height: AppSpacing.xs),
          AppText(
            textKey: 'upgrades_level_value',
            args: <String, String>{'value': level.toString()},
            variant: AppTextVariant.caption,
          ),
          const SizedBox(height: AppSpacing.xs),
          AppText(
            textKey: maxed ? 'upgrades_max_level' : 'upgrades_cost_value',
            args: <String, String>{'value': cost.toString()},
            variant: AppTextVariant.caption,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            labelKey: maxed ? 'upgrades_max_button' : 'upgrades_upgrade_button',
            isDisabled: maxed || profile.economy.credits < cost,
            onPressed: maxed
                ? null
                : () {
                    controller.buyUpgrade(type);
                  },
          ),
        ],
      ),
    );
  }

  String _titleKey(UpgradeType type) {
    switch (type) {
      case UpgradeType.ammo:
        return 'upgrades_ammo_title';
      case UpgradeType.reload:
        return 'upgrades_reload_title';
      case UpgradeType.explosionRadius:
        return 'upgrades_explosion_title';
      case UpgradeType.interceptorSpeed:
        return 'upgrades_interceptor_speed_title';
    }
  }
}
