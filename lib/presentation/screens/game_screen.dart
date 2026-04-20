import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sky_defense/core/theme/app_spacing.dart';
import 'package:sky_defense/domain/entities/player_profile.dart';
import 'package:sky_defense/game/engine/game_manager.dart';
import 'package:sky_defense/game/engine/sky_defense_game.dart';
import 'package:sky_defense/presentation/providers/feature_providers.dart';
import 'package:sky_defense/presentation/providers/system_providers.dart';
import 'package:sky_defense/presentation/widgets/app_button.dart';
import 'package:sky_defense/presentation/widgets/app_text.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late final SkyDefenseGame _game = ref.read(skyDefenseGameProvider);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppText(
          textKey: 'game_title',
          variant: AppTextVariant.heading,
        ),
      ),
      body: GameWidget<SkyDefenseGame>(
        game: _game,
        overlayBuilderMap: <String,
            Widget Function(BuildContext, SkyDefenseGame)>{
          SkyDefenseGame.hudOverlayId:
              (BuildContext context, SkyDefenseGame game) {
            return const _HudOverlay();
          },
          SkyDefenseGame.gameOverOverlayId:
              (BuildContext context, SkyDefenseGame game) {
            return const _GameOverOverlay();
          },
        },
      ),
    );
  }
}

class _HudOverlay extends StatelessWidget {
  const _HudOverlay();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Consumer(
                  builder:
                      (BuildContext context, WidgetRef ref, Widget? child) {
                    final GameSession session = ref.watch(gameManagerProvider);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        AppText(
                          textKey: 'game_score_value',
                          args: <String, String>{
                            'value': session.score.toString(),
                          },
                          variant: AppTextVariant.body,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AppText(
                          textKey: 'game_wave_value',
                          args: <String, String>{
                            'value': session.currentWave.toString(),
                          },
                          variant: AppTextVariant.caption,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AppText(
                          textKey: 'game_remaining_bases_value',
                          args: <String, String>{
                            'value': session.remainingBases.toString(),
                          },
                          variant: AppTextVariant.caption,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AppText(
                          textKey: 'game_interceptors_value',
                          args: <String, String>{
                            'value': session.remainingInterceptors.toString(),
                          },
                          variant: AppTextVariant.caption,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AppText(
                          textKey: 'game_interceptors_per_base_value',
                          args: <String, String>{
                            'value': session.interceptorsPerBase
                                .asMap()
                                .entries
                                .map((entry) =>
                                    'B${entry.key + 1}:${entry.value}')
                                .join('  '),
                          },
                          variant: AppTextVariant.caption,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: AppText(
                  textKey: 'game_tap_hint',
                  variant: AppTextVariant.caption,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? child) {
        final GameSession session = ref.watch(gameManagerProvider);
        final int credits = ref.watch(
              playerProvider.select(
                (AsyncValue<PlayerProfile> value) =>
                    value.asData?.value.economy.credits,
              ),
            ) ??
            0;
        final bool canContinue = credits >= GameManager.continueCostCredits;

        return Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const AppText(
                      textKey: 'game_over_overlay',
                      variant: AppTextVariant.heading,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppText(
                      textKey: 'game_score_value',
                      args: <String, String>{
                        'value': session.score.toString(),
                      },
                      variant: AppTextVariant.caption,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppText(
                      textKey: 'game_wave_value',
                      args: <String, String>{
                        'value': session.currentWave.toString(),
                      },
                      variant: AppTextVariant.caption,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      labelKey: 'game_continue_button',
                      isDisabled: !canContinue,
                      onPressed: canContinue
                          ? () async {
                              final bool spent = await ref
                                  .read(playerProvider.notifier)
                                  .spendCredits(
                                      GameManager.continueCostCredits);
                              if (!spent) {
                                return;
                              }
                              ref
                                  .read(gameManagerProvider.notifier)
                                  .continueGame();
                            }
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppButton(
                      labelKey: 'game_restart_button',
                      variant: AppButtonVariant.ghost,
                      onPressed: () {
                        ref.read(gameManagerProvider.notifier).restartGame();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
