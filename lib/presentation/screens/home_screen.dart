import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sky_defense/core/config/game_config_provider.dart';
import 'package:sky_defense/core/localization/app_localizations.dart';
import 'package:sky_defense/core/router/app_routes.dart';
import 'package:sky_defense/core/theme/app_spacing.dart';
import 'package:sky_defense/domain/entities/player_profile.dart';
import 'package:sky_defense/game/engine/game_manager.dart';
import 'package:sky_defense/presentation/providers/feature_providers.dart';
import 'package:sky_defense/presentation/providers/system_providers.dart';
import 'package:sky_defense/presentation/widgets/app_button.dart';
import 'package:sky_defense/presentation/widgets/app_container.dart';
import 'package:sky_defense/presentation/widgets/app_text.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isClaimingReward = false;
  int _lastClaimedReward = 0;
  String? _lastEconomyActionKey;

  @override
  Widget build(BuildContext context) {
    final WidgetRef ref = this.ref;
    final PlayerProfile? playerData =
        ref.watch(playerProvider.select((AsyncValue<PlayerProfile> value) => value.asData?.value));
    final bool isLoading =
        ref.watch(playerProvider.select((AsyncValue<PlayerProfile> value) => value.isLoading));
    final bool hasError =
        ref.watch(playerProvider.select((AsyncValue<PlayerProfile> value) => value.hasError));
    final economyConfig = ref.watch(resolvedEconomyConfigProvider);
    final gameBalanceConfig = ref.watch(resolvedGameBalanceConfigProvider);
    final retentionConfig = ref.watch(resolvedRetentionConfigProvider);
    final GameState gameState =
        ref.watch(gameManagerProvider.select((GameSession session) => session.gameState));

    return Scaffold(
      appBar: AppBar(
        title: const AppText(textKey: 'home_title', variant: AppTextVariant.heading),
        actions: <Widget>[
          IconButton(
            onPressed: () => context.push(AppRoutes.settings),
            icon: const Icon(Icons.settings),
            tooltip: AppLocalizations.of(context).tr('home_open_settings'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const AppText(
              textKey: 'home_player_section',
              variant: AppTextVariant.heading,
            ),
            const SizedBox(height: AppSpacing.xs),
            AppText(
              textKey: 'home_game_state_value',
              args: <String, String>{
                'value': AppLocalizations.of(context).tr(_gameStateKey(gameState)),
              },
              variant: AppTextVariant.caption,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (isLoading)
              const AppContainer(
                elevationPreset: AppContainerElevation.low,
                child: AppText(
                  textKey: 'home_loading_player_data',
                  variant: AppTextVariant.body,
                ),
              )
            else if (hasError)
              const AppContainer(
                elevationPreset: AppContainerElevation.low,
                child: AppText(
                  textKey: 'home_player_data_error',
                  variant: AppTextVariant.body,
                ),
              )
            else if (playerData != null)
              Builder(
                builder: (BuildContext context) {
                  final PlayerProfile data = playerData;
                  final int safeCurrency = data.economy.credits;
                  final int safeLevel = data.progress.progressLevel;
                  final int safeStreak = data.progress.currentStreakDay;
                  final bool rewardAvailable = ref
                      .read(playerProvider.notifier)
                      .isDailyRewardAvailable(data, DateTime.now());
                  final bool isEmptyState =
                      safeCurrency == 0 && safeLevel == 1 && data.progress.totalSessions == 0;
                  return AppContainer(
                    elevationPreset: AppContainerElevation.low,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const AppText(
                          textKey: 'home_daily_reward_card_title',
                          variant: AppTextVariant.subheading,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        if (isEmptyState) ...<Widget>[
                          const AppText(
                            textKey: 'home_player_empty_state',
                            variant: AppTextVariant.caption,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        AppText(
                          textKey: 'home_currency_value',
                          args: <String, String>{'value': safeCurrency.toString()},
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppText(
                          textKey: 'home_progress_level_value',
                          args: <String, String>{'value': safeLevel.toString()},
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppText(
                          textKey: 'home_base_reward_value',
                          args: <String, String>{
                            'value': economyConfig.baseRewardPerSession.toString(),
                          },
                          variant: AppTextVariant.caption,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AppText(
                          textKey: 'home_max_threats_value',
                          args: <String, String>{
                            'value': gameBalanceConfig.maxConcurrentThreats.toString(),
                          },
                          variant: AppTextVariant.caption,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AppText(
                          textKey: 'home_progress_hint_value',
                          args: <String, String>{
                            'current': safeLevel.toString(),
                            'max': economyConfig.maxProgressLevel.toString(),
                          },
                          variant: AppTextVariant.caption,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AppText(
                          textKey: 'home_upgrade_cost_value',
                          args: <String, String>{
                            'value': economyConfig.upgradeCostPerLevel.toString(),
                          },
                          variant: AppTextVariant.caption,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppText(
                          textKey: 'home_streak_value',
                          args: <String, String>{'value': safeStreak.toString()},
                          variant: AppTextVariant.caption,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AppText(
                          textKey: rewardAvailable
                              ? 'home_daily_reward_available'
                              : 'home_daily_reward_claimed',
                          variant: AppTextVariant.caption,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AppText(
                          textKey: 'home_reward_preview_value',
                          args: <String, String>{
                            'value': retentionConfig.dailyRewardBase.toString(),
                          },
                          variant: AppTextVariant.caption,
                        ),
                        if (_lastClaimedReward > 0) ...<Widget>[
                          const SizedBox(height: AppSpacing.xs),
                          AppText(
                            textKey: 'home_last_reward_value',
                            args: <String, String>{
                              'value': _lastClaimedReward.toString(),
                            },
                            variant: AppTextVariant.caption,
                          ),
                        ],
                        if (_lastEconomyActionKey != null) ...<Widget>[
                          const SizedBox(height: AppSpacing.xs),
                          AppText(
                            textKey: _lastEconomyActionKey!,
                            variant: AppTextVariant.caption,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.sm),
                        AppButton(
                          labelKey: 'home_claim_daily_reward',
                          variant: AppButtonVariant.secondary,
                          size: AppButtonSize.medium,
                          isLoading: _isClaimingReward,
                          isDisabled: !rewardAvailable || _isClaimingReward,
                          onPressed: rewardAvailable && !_isClaimingReward
                              ? () async {
                                  setState(() {
                                    _isClaimingReward = true;
                                  });
                                  final int reward =
                                      await ref.read(playerProvider.notifier).claimDailyReward();
                                  if (mounted) {
                                    setState(() {
                                      _isClaimingReward = false;
                                      _lastClaimedReward = reward;
                                      _lastEconomyActionKey = reward > 0
                                          ? 'home_action_reward_claimed'
                                          : 'home_action_denied';
                                    });
                                  }
                                }
                              : null,
                          isExpanded: true,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppButton(
                          labelKey: 'home_spend_credits',
                          variant: AppButtonVariant.ghost,
                          size: AppButtonSize.small,
                          onPressed: () async {
                            final bool ok =
                                await ref.read(playerProvider.notifier).spendCredits(100);
                            if (mounted) {
                              setState(() {
                                _lastEconomyActionKey =
                                    ok ? 'home_action_spend_success' : 'home_action_denied';
                              });
                            }
                          },
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AppButton(
                          labelKey: 'home_upgrade_progress',
                          variant: AppButtonVariant.ghost,
                          size: AppButtonSize.small,
                          onPressed: () async {
                            final bool ok =
                                await ref.read(playerProvider.notifier).upgradeProgress();
                            if (mounted) {
                              setState(() {
                                _lastEconomyActionKey =
                                    ok ? 'home_action_upgrade_success' : 'home_action_denied';
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              )
            else
              const AppContainer(
                elevationPreset: AppContainerElevation.low,
                child: AppText(
                  textKey: 'home_player_empty_state',
                  variant: AppTextVariant.body,
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              labelKey: 'home_start_game',
              variant: AppButtonVariant.primary,
              size: AppButtonSize.large,
              onPressed: () => context.push(AppRoutes.game),
              isExpanded: true,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              labelKey: 'home_open_settings',
              variant: AppButtonVariant.ghost,
              size: AppButtonSize.medium,
              onPressed: () => context.push(AppRoutes.settings),
              isExpanded: true,
            ),
            const SizedBox(height: AppSpacing.md),
            const AppText(
              textKey: 'home_start_game_placeholder',
              variant: AppTextVariant.caption,
            ),
          ],
        ),
      ),
    );
  }

  String _gameStateKey(GameState state) {
    switch (state) {
      case GameState.initializing:
        return 'game_state_initializing';
      case GameState.ready:
        return 'game_state_ready';
      case GameState.running:
        return 'game_state_running';
      case GameState.paused:
        return 'game_state_paused';
      case GameState.gameOver:
        return 'game_state_game_over';
    }
  }
}
