import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sky_defense/core/localization/app_localizations.dart';
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
  ProviderSubscription<int>? _sessionCreditsSubscription;
  final GlobalKey _topHudKey = GlobalKey();

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

    /// 🔹 Sync de creditos de sesion (dominio -> perfil persistido)
    _sessionCreditsSubscription = ref.listenManual<int>(
      gameManagerProvider.select((s) => s.playerCredits),
      (prev, next) {
        if (prev != null && next <= prev) return;
        ref.read(playerProvider.notifier).syncCredits(next);
      },
      fireImmediately: true,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameManagerProvider.notifier).restartGame();
    });
  }

  @override
  void dispose() {
    _creditsSubscription?.close();
    _upgradesSubscription?.close();
    _sessionCreditsSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.read(skyDefenseGameProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final manager = ref.read(gameManagerProvider.notifier);
      manager.setHudWidth(0);
      final BuildContext? hudContext = _topHudKey.currentContext;
      if (hudContext == null) {
        return;
      }
      final RenderObject? renderObject = hudContext.findRenderObject();
      if (renderObject is! RenderBox) {
        return;
      }
      final double topPadding = MediaQuery.of(context).padding.top;
      final double hudHeight = renderObject.size.height;
      manager.setHudTopInset(topPadding + hudHeight);
    });

    return Scaffold(
      body: Stack(
        children: [
          GameWidget<SkyDefenseGame>(
            game: game,
            initialActiveOverlays: const ['wave_ui'],
            overlayBuilderMap: {
              SkyDefenseGame.gameOverOverlayId: (_, __) =>
                  const _GameOverOverlay(),

              /// 🔥 Overlay central limpio (FIX REAL)
              'wave_ui': (_, __) => const _WaveCenterOverlay(),
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: KeyedSubtree(
                key: _topHudKey,
                child: const _WorldTopHud(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorldTopHud extends ConsumerWidget {
  const _WorldTopHud();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameManagerProvider);
    final manager = ref.read(gameManagerProvider.notifier);
    final boss = manager.visibleBoss;
    final l = AppLocalizations.of(context);
    final ammo = List<int>.from(manager.ammoPerBase);
    while (ammo.length < 4) {
      ammo.add(0);
    }
    return IgnorePointer(
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _hudText(
                    l.trWithArgs('game_score_value', <String, String>{
                      'value': session.score.toString(),
                    }),
                  ),
                  _hudText(
                    l.trWithArgs('game_phase_value', <String, String>{
                      'value': manager.phase.toString(),
                    }),
                  ),
                  _hudText(
                    l.trWithArgs('game_wave_value', <String, String>{
                      'value': manager.waveInPhase.toString(),
                    }),
                  ),
                  _hudText(
                    l.trWithArgs('game_global_wave_value', <String, String>{
                      'value': manager.globalWave.toString(),
                    }),
                  ),
                  _hudText(
                    l.trWithArgs('game_credits_value', <String, String>{
                      'value': manager.credits.toString(),
                    }),
                  ),
                  _hudText(
                    l.trWithArgs('game_remaining_bases_value', <String, String>{
                      'value': manager.aliveBasesCount.toString(),
                    }),
                  ),
                  _hudText(
                    l.trWithArgs('game_interceptors_value', <String, String>{
                      'value': manager.activeInterceptorsCount.toString(),
                    }),
                  ),
                  if (session.bossWave && boss != null && boss.isAlive)
                    _hudText(
                      l.trWithArgs('game_boss_hp_value', <String, String>{
                        'current': boss.health.toString(),
                        'max': boss.maxHealth.toString(),
                      }),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _hudText(
                    l.trWithArgs('game_ammo_bases_value', <String, String>{
                      'b1': ammo[0].toString(),
                      'b2': ammo[1].toString(),
                      'b3': ammo[2].toString(),
                      'b4': ammo[3].toString(),
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hudText(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }
}

class _WaveCenterOverlay extends ConsumerStatefulWidget {
  const _WaveCenterOverlay();

  @override
  ConsumerState<_WaveCenterOverlay> createState() => _WaveCenterOverlayState();
}

class _WaveCenterOverlayState extends ConsumerState<_WaveCenterOverlay> {
  ProviderSubscription<bool>? _bossWaveSubscription;
  Timer? _bossAlertTimer;
  String? _transientBannerKey;
  bool _transientVisible = false;
  int _transientStep = 0;
  int _transientRunId = 0;

  @override
  void initState() {
    super.initState();
    _bossWaveSubscription = ref.listenManual<bool>(
      gameManagerProvider.select((GameSession session) => session.bossWave),
      (bool? prev, bool next) {
        final bool enteringBossWave = next && (prev ?? false) == false;
        if (enteringBossWave) {
          _startTransientBanner('game_boss_alert');
        }
      },
      fireImmediately: false,
    );
  }

  @override
  void dispose() {
    _bossWaveSubscription?.close();
    _bossAlertTimer?.cancel();
    super.dispose();
  }

  void _startTransientBanner(String key) {
    _bossAlertTimer?.cancel();
    _transientRunId += 1;
    final int runId = _transientRunId;
    if (mounted) {
      setState(() {
        _transientBannerKey = key;
        _transientVisible = true;
        _transientStep = 0;
      });
    }
    _bossAlertTimer =
        Timer.periodic(const Duration(milliseconds: 220), (Timer timer) {
      if (!mounted || runId != _transientRunId) {
        timer.cancel();
        return;
      }
      _transientStep += 1;
      if (_transientStep == 1) {
        setState(() {
          _transientVisible = false;
        });
        return;
      }
      if (_transientStep >= 2 && _transientStep <= 7) {
        setState(() {
          _transientVisible = !_transientVisible;
        });
        return;
      }
      timer.cancel();
      setState(() {
        _transientVisible = false;
        _transientBannerKey = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameManagerProvider);
    final isWaveActive = session.isWaveActive;
    final countdown = session.interWaveTimerSeconds.ceil();
    final l = AppLocalizations.of(context);

    String? text;
    bool visible = false;
    if (!isWaveActive && countdown > 0) {
      text = countdown.toString();
      visible = true;
    } else if (_transientBannerKey != null) {
      text = l.tr(_transientBannerKey!);
      visible = _transientVisible;
    }

    return IgnorePointer(
      child: Center(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: text == null ? 0 : (visible ? 1 : 0),
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
        final l = AppLocalizations.of(context);

        final canContinue = !session.phaseOneDemoCompleted &&
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
                  AppText(
                    textKey: session.phaseOneDemoCompleted
                        ? 'game_phase1_complete'
                        : 'game_over_overlay',
                    variant: AppTextVariant.heading,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l.trWithArgs('game_score_value', <String, String>{
                      'value': session.score.toString(),
                    }),
                  ),
                  Text(
                    l.trWithArgs('game_phase_wave_compact', <String, String>{
                      'phase': session.phaseNumber.toString(),
                      'wave': session.waveNumber.toString(),
                    }),
                  ),
                  Text(
                    l.trWithArgs('game_credits_earned_value', <String, String>{
                      'value': session.creditsEarned.toString(),
                    }),
                  ),
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
