import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sky_defense/core/router/app_routes.dart';
import 'package:sky_defense/core/theme/app_spacing.dart';
import 'package:sky_defense/domain/entities/player_upgrades.dart';
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
  ProviderSubscription<int?>? _creditsSubscription;
  ProviderSubscription<PlayerUpgrades?>? _upgradesSubscription;
  ProviderSubscription<int>? _waveRewardSubscription;

  @override
  void initState() {
    super.initState();

    /// 🔹 Sync créditos
    _creditsSubscription = ref.listenManual<int?>(
      playerProvider.select((v) => v.asData?.value.economy.credits),
      (_, next) {
        if (next != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(gameManagerProvider.notifier).syncPlayerCredits(next);
          });
        }
      },
      fireImmediately: true,
    );

    /// 🔹 Sync upgrades
    _upgradesSubscription = ref.listenManual<PlayerUpgrades?>(
      playerProvider.select((v) => v.asData?.value.upgrades),
      (_, next) {
        if (next == null) return;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(gameManagerProvider.notifier).configurePlayerUpgrades(next);
        });
      },
      fireImmediately: true,
    );

    /// 🔹 Recompensas por oleada
    _waveRewardSubscription = ref.listenManual<int>(
      gameManagerProvider.select((s) => s.waveRewardCounter),
      (prev, next) {
        if (prev != null && next <= prev) return;

        final reward = ref.read(gameManagerProvider).lastWaveRewardCredits;

        if (reward > 0) {
          ref.read(playerProvider.notifier).addCredits(reward);
        }
      },
    );
  }

  @override
  void dispose() {
    _creditsSubscription?.close();
    _upgradesSubscription?.close();
    _waveRewardSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.read(skyDefenseGameProvider);

    return Scaffold(
      body: Row(
        children: [
          /// 🔹 HUD IZQUIERDO
          Container(
            width: 140,
            color: Colors.black.withValues(alpha: 0.85),
            padding: const EdgeInsets.all(12),
            child: Consumer(
              builder: (context, ref, _) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ref.read(gameManagerProvider.notifier).setHudWidth(140);
                });

                final session = ref.watch(gameManagerProvider);
                final manager = ref.read(gameManagerProvider.notifier);

                final ammo = List<int>.from(manager.ammoPerBase);
                while (ammo.length < 4) {
                  ammo.add(0);
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _hudText('Puntaje: ${session.score}'),
                    _hudText('Oleada: ${manager.wave}'),
                    _hudText('Créditos: ${manager.credits}'),
                    _hudText('Bases: ${manager.aliveBasesCount}'),
                    _hudText(
                        'Interceptores: ${manager.activeInterceptorsCount}'),
                    _hudText(
                        'Munición B1:${ammo[0]} B2:${ammo[1]} B3:${ammo[2]} B4:${ammo[3]}'),
                  ],
                );
              },
            ),
          ),

          /// 🔹 JUEGO + OVERLAYS
          Expanded(
            child: GameWidget<SkyDefenseGame>(
              game: game,
              initialActiveOverlays: const ['wave_ui'],
              overlayBuilderMap: {
                SkyDefenseGame.gameOverOverlayId: (_, __) =>
                    const _GameOverOverlay(),

                /// 🔥 Overlay central limpio (FIX REAL)
                'wave_ui': (_, __) => const _WaveCenterOverlay(),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _hudText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}

class _WaveCenterOverlay extends ConsumerWidget {
  const _WaveCenterOverlay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameManagerProvider);
    final isWaveActive = session.isWaveActive;
    final countdown = session.interWaveTimerSeconds.ceil();

    String? text;
    if (!isWaveActive && countdown > 0) {
      text = countdown.toString();
    } else if (session.bossWave && isWaveActive) {
      text = 'JEFE FINAL';
    }

    return IgnorePointer(
      child: Center(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: text == null ? 0 : 1,
          child: text == null
              ? const SizedBox()
              : Text(
                  text,
                  style: const TextStyle(
                    fontSize: 42,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
      builder: (context, ref, _) {
        final session = ref.watch(gameManagerProvider);

        final canContinue =
            session.playerCredits >= GameManager.continueCostCredits;

        return Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppText(
                    textKey: 'game_over_overlay',
                    variant: AppTextVariant.heading,
                  ),
                  const SizedBox(height: 10),
                  Text('Score: ${session.score}'),
                  Text('Wave: ${session.currentWave}'),
                  Text('Credits: ${session.creditsEarned}'),
                  const SizedBox(height: 16),

                  /// 🔹 CONTINUE
                  AppButton(
                    labelKey: 'game_continue_button',
                    isDisabled: !canContinue,
                    onPressed: canContinue
                        ? () async {
                            final spent = await ref
                                .read(playerProvider.notifier)
                                .spendCredits(GameManager.continueCostCredits);

                            if (!spent) return;

                            ref
                                .read(gameManagerProvider.notifier)
                                .continueGame();
                          }
                        : null,
                  ),

                  const SizedBox(height: 10),

                  /// 🔹 RESTART
                  AppButton(
                    labelKey: 'game_restart_button',
                    variant: AppButtonVariant.ghost,
                    onPressed: () {
                      ref.read(gameManagerProvider.notifier).restartGame();
                    },
                  ),

                  const SizedBox(height: 10),

                  /// 🔹 UPGRADES
                  AppButton(
                    labelKey: 'game_upgrades_button',
                    variant: AppButtonVariant.secondary,
                    onPressed: () => context.push(AppRoutes.upgrades),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
