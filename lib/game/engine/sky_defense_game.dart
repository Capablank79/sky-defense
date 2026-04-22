import 'dart:async';
import 'dart:math';

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:sky_defense/game/audio/game_audio_controller.dart';
import 'package:sky_defense/game/entities/base.dart';
import 'package:sky_defense/game/entities/missile.dart';
import 'package:sky_defense/game/engine/game_manager.dart';

class SkyDefenseGame extends FlameGame with TapCallbacks {
  SkyDefenseGame(this._gameManager);

  static const String hudOverlayId = 'hud';
  static const String gameOverOverlayId = 'game_over';

  final GameManager _gameManager;
  final GameAudioController _audio = GameAudioController();
  final _EffectsSystem _effectsSystem = _EffectsSystem();
  late Paint _backgroundPaint;
  late Paint _starPaint;
  late Paint _missilePaint;
  late Paint _missileTrailHeadPaint;
  late Paint _missileTrailTailPaint;
  late List<Paint> _smokePaintLut;
  late Paint _interceptorPaint;
  late Paint _interceptorTrailPaint;
  late Paint _explosionFillPaint;
  late Paint _explosionStrokePaint;
  late Paint _explosionGlowPaint;
  late Paint _particlePaint;
  late Paint _particleGlowPaint;
  late Paint _basePaint;
  late Paint _baseDamagePaint;
  late Paint _flashPaint;
  late Paint _debugBoundsPaint;
  late List<Paint> _crosshairPaintLut;
  final _ParticleEngine _particleEngine = _ParticleEngine();
  static const double _missileRadius = 5;
  static const double _interceptorRadius = 3.5;
  static const double _baseRadius = 14;
  static const double _baseDamagePulseSeconds = 0.28;
  static const double _smokePersistenceSeconds = 0.5;
  static const double _crosshairPersistenceSeconds = 0.4;
  static const double _crosshairHalfSize = 10;
  static const int _maxParticlesPerExplosion = 30;
  final Map<String, Missile> _previousMissilesById = <String, Missile>{};
  final Map<String, int> _lastBaseHealthById = <String, int>{};
  final List<_Star> _stars = <_Star>[];
  final List<_SmokeTrail> _smokeTrails = <_SmokeTrail>[];
  final List<_BaseDamagePulse> _baseDamagePulses = <_BaseDamagePulse>[];
  final List<_CrosshairPreview> _crosshairPreviews = <_CrosshairPreview>[];
  int _lastBaseHitCounter = 0;
  int _lastExplosionImpactCounter = 0;
  int _lastExplosionCreatedCounter = 0;
  int _lastInterceptorLaunchCounter = 0;
  int _lastCountdownSecond = -1;
  int _lastRestartVersionSeen = -1;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _initializePaintObjects();
    unawaited(_audio.initialize());
    _gameManager.init();
    _gameManager.start();
    _gameManager.configureWorldBounds(width: size.x, height: size.y);
    _resetVisualState(reinitializePaints: false);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _gameManager.configureWorldBounds(width: size.x, height: size.y);
    _regenerateStars();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final missiles = _gameManager.visibleMissiles;
    final interceptors = _gameManager.visibleInterceptors;
    final bases = _gameManager.visibleBases;
    final cities = _gameManager.visibleCities;
    final explosions = _gameManager.visibleExplosions;
    final boss = _gameManager.visibleBoss;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      _backgroundPaint,
    );
    _renderStars(canvas);
    canvas.drawRect(
      Rect.fromLTRB(
        _gameManager.minX,
        _gameManager.minY,
        _gameManager.maxX,
        _gameManager.maxY,
      ),
      _debugBoundsPaint,
    );

    final bool isShaking = _effectsSystem.isShaking;
    if (isShaking) {
      canvas.save();
      canvas.translate(
          _effectsSystem.shakeOffsetX, _effectsSystem.shakeOffsetY);
    }

    final double now = _gameManager.elapsedTimeSeconds;
    for (final _SmokeTrail trail in _smokeTrails) {
      final double lifeRatio =
          ((trail.expiresAtSeconds - now) / _smokePersistenceSeconds)
              .clamp(0, 1);
      final int lutIndex = ((lifeRatio * (_smokePaintLut.length - 1)).round())
          .clamp(0, _smokePaintLut.length - 1);
      canvas.drawLine(
        Offset(trail.origin.x, trail.origin.y),
        Offset(trail.end.x, trail.end.y),
        _smokePaintLut[lutIndex],
      );
    }

    for (final _CrosshairPreview marker in _crosshairPreviews) {
      final double lifeRatio =
          ((marker.expiresAtSeconds - now) / _crosshairPersistenceSeconds)
              .clamp(0, 1);
      final int lutIndex =
          ((lifeRatio * (_crosshairPaintLut.length - 1)).round())
              .clamp(0, _crosshairPaintLut.length - 1);
      final Paint paint = _crosshairPaintLut[lutIndex];
      canvas.drawLine(
        Offset(marker.x - _crosshairHalfSize, marker.y),
        Offset(marker.x + _crosshairHalfSize, marker.y),
        paint,
      );
      canvas.drawLine(
        Offset(marker.x, marker.y - _crosshairHalfSize),
        Offset(marker.x, marker.y + _crosshairHalfSize),
        paint,
      );
    }

    for (final missile in missiles) {
      final double pathDx = missile.target.x - missile.origin.x;
      final double pathDy = missile.target.y - missile.origin.y;
      final double pathDistance = sqrt((pathDx * pathDx) + (pathDy * pathDy));
      final double traveledDx = missile.linearPosition.x - missile.origin.x;
      final double traveledDy = missile.linearPosition.y - missile.origin.y;
      final double traveledDistance =
          sqrt((traveledDx * traveledDx) + (traveledDy * traveledDy));
      final double progress = pathDistance <= 0.0001
          ? 1
          : (traveledDistance / pathDistance).clamp(0, 1);
      final double tailWidth = 1.2 + ((1 - progress) * 1.8);
      final double headWidth = 1.5 + (progress * 2.8);
      _missileTrailTailPaint
        ..strokeWidth = tailWidth
        ..color =
            Colors.orange.withValues(alpha: 0.16 + ((1 - progress) * 0.2));
      _missileTrailHeadPaint
        ..strokeWidth = headWidth
        ..color = Color.lerp(Colors.orangeAccent, Colors.redAccent, progress)!
            .withValues(alpha: 0.5 + (progress * 0.35));
      switch (missile.type) {
        case MissileType.slow:
          _missilePaint.color = Colors.lightGreenAccent;
          break;
        case MissileType.medium:
          _missilePaint.color =
              Color.lerp(Colors.amberAccent, Colors.redAccent, progress)!;
          break;
        case MissileType.fast:
          _missilePaint.color = Colors.deepOrangeAccent;
          break;
        case MissileType.split:
          _missilePaint.color = Colors.pinkAccent;
          break;
        case MissileType.zigzag:
          _missilePaint.color = Colors.lightBlueAccent;
          break;
        case MissileType.heavy:
          _missilePaint.color = Colors.brown.shade400;
          break;
        case MissileType.boss:
          _missilePaint.color = Colors.purpleAccent;
          break;
      }
      final double midX = (missile.origin.x + missile.x) * 0.5;
      final double midY = (missile.origin.y + missile.y) * 0.5;
      canvas.drawLine(
        Offset(missile.origin.x, missile.origin.y),
        Offset(midX, midY),
        _missileTrailTailPaint,
      );
      canvas.drawLine(
        Offset(midX, midY),
        Offset(missile.x, missile.y),
        _missileTrailHeadPaint,
      );
      canvas.drawCircle(
        Offset(missile.x, missile.y),
        missile.type == MissileType.boss
            ? _missileRadius * 1.9
            : _missileRadius,
        _missilePaint,
      );
    }

    if (boss != null && boss.isAlive) {
      final double hpRatio =
          boss.maxHealth <= 0 ? 0 : (boss.health / boss.maxHealth).clamp(0, 1);
      _missilePaint.color = Colors.deepPurpleAccent;
      canvas.drawCircle(
        Offset(boss.position.x, boss.position.y),
        22,
        _missilePaint,
      );
      _missileTrailTailPaint
        ..strokeWidth = 4
        ..color = Colors.black.withValues(alpha: 0.45);
      _missileTrailHeadPaint
        ..strokeWidth = 3
        ..color = Colors.redAccent.withValues(alpha: 0.9);
      final double hpBarLeft = boss.position.x - 24;
      final double hpBarTop = boss.position.y - 34;
      canvas.drawLine(
        Offset(hpBarLeft, hpBarTop),
        Offset(hpBarLeft + 48, hpBarTop),
        _missileTrailTailPaint,
      );
      canvas.drawLine(
        Offset(hpBarLeft, hpBarTop),
        Offset(hpBarLeft + (48 * hpRatio), hpBarTop),
        _missileTrailHeadPaint,
      );
    }

    for (final interceptor in interceptors) {
      final double progress = interceptor.progress.clamp(0, 1);
      _interceptorTrailPaint
        ..strokeWidth = 1.2 + (progress * 1.1)
        ..color =
            Colors.lightBlueAccent.withValues(alpha: 0.42 + (progress * 0.4));
      _interceptorPaint.color = Colors.cyanAccent;
      canvas.drawLine(
        Offset(interceptor.origin.x, interceptor.origin.y),
        Offset(interceptor.x, interceptor.y),
        _interceptorTrailPaint,
      );
      canvas.drawCircle(
        Offset(interceptor.x, interceptor.y),
        _interceptorRadius,
        _interceptorPaint,
      );
    }

    for (final Base base in bases) {
      final double healthRatio =
          base.healthMax <= 0 ? 0 : (base.health / base.healthMax).clamp(0, 1);
      if (base.isDestroyed) {
        _basePaint.color = Colors.grey.shade700;
      } else {
        _basePaint.color = Color.lerp(
          Colors.red.shade700,
          Colors.green.shade400,
          healthRatio,
        )!;
      }
      canvas.drawCircle(
        Offset(base.x, base.y),
        _baseRadius,
        _basePaint,
      );
      for (final _BaseDamagePulse pulse in _baseDamagePulses) {
        if (pulse.baseId != base.id) {
          continue;
        }
        final double ratio =
            (1 - (pulse.ageSeconds / _baseDamagePulseSeconds)).clamp(0, 1);
        _baseDamagePaint
          ..strokeWidth = 1.2 + ((1 - ratio) * 2.4)
          ..color = Colors.redAccent.withValues(alpha: 0.08 + (ratio * 0.5));
        canvas.drawCircle(
          Offset(base.x, base.y),
          _baseRadius + ((1 - ratio) * 10),
          _baseDamagePaint,
        );
      }
    }

    for (final city in cities) {
      _basePaint.color = Colors.orange.shade300;
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(city.x, city.y),
          width: 16,
          height: 10,
        ),
        _basePaint,
      );
      _baseDamagePaint
        ..strokeWidth = 1.2
        ..color = Colors.orange.shade900.withValues(alpha: 0.8);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(city.x, city.y),
          width: 18,
          height: 12,
        ),
        _baseDamagePaint,
      );
    }

    for (final explosion in explosions) {
      final double lifetimeRatio = explosion.maxLifetime <= 0
          ? 0
          : (explosion.lifetime / explosion.maxLifetime).clamp(0, 1);
      final double t = 1 - lifetimeRatio;
      final double easedGrowth = 1 - pow(1 - t, 4).toDouble();
      final double easedFade = pow(lifetimeRatio, 1.4).toDouble();
      final double visualRadius =
          explosion.radius * (0.55 + (easedGrowth * 1.1));
      _explosionGlowPaint.color =
          Colors.deepOrangeAccent.withValues(alpha: 0.08 + (easedFade * 0.28));
      _explosionFillPaint.color =
          Colors.orangeAccent.withValues(alpha: 0.12 + (easedFade * 0.38));
      _explosionStrokePaint
        ..strokeWidth = 1.8
        ..color =
            Colors.deepOrangeAccent.withValues(alpha: 0.22 + (easedFade * 0.6));
      canvas.drawCircle(
        Offset(explosion.x, explosion.y),
        visualRadius * 1.35,
        _explosionGlowPaint,
      );
      canvas.drawCircle(
        Offset(explosion.x, explosion.y),
        visualRadius,
        _explosionFillPaint,
      );
      canvas.drawCircle(
        Offset(explosion.x, explosion.y),
        visualRadius * 0.82,
        _explosionStrokePaint,
      );
    }

    _particleEngine.render(
      canvas: canvas,
      paint: _particlePaint,
      glowPaint: _particleGlowPaint,
    );
    if (isShaking) {
      canvas.restore();
    }

    if (_effectsSystem.flashTimeRemaining > 0) {
      final double ratio = _effectsSystem.flashRatio;
      _flashPaint.color = Colors.white.withValues(alpha: 0.18 * ratio);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        _flashPaint,
      );
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    final Vector2 position = event.localPosition;
    _crosshairPreviews.add(
      _CrosshairPreview(
        x: position.x,
        y: position.y,
        expiresAtSeconds:
            _gameManager.elapsedTimeSeconds + _crosshairPersistenceSeconds,
      ),
    );
    _gameManager.launchInterceptorTo(x: position.x, y: position.y);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _handleRestartResetIfNeeded();
    _gameManager.update(dt);
    _captureDestroyedMissileTrails();
    _smokeTrails.removeWhere(
      (_SmokeTrail trail) =>
          trail.expiresAtSeconds <= _gameManager.elapsedTimeSeconds,
    );
    _crosshairPreviews.removeWhere(
      (_CrosshairPreview marker) =>
          marker.expiresAtSeconds <= _gameManager.elapsedTimeSeconds,
    );
    for (int i = 0; i < _baseDamagePulses.length; i += 1) {
      final _BaseDamagePulse pulse = _baseDamagePulses[i];
      _baseDamagePulses[i] = pulse.copyWith(ageSeconds: pulse.ageSeconds + dt);
    }
    _baseDamagePulses.removeWhere(
      (_BaseDamagePulse pulse) => pulse.ageSeconds >= _baseDamagePulseSeconds,
    );
    _particleEngine.update(dt);
    _effectsSystem.update(dt);

    final List<Base> bases = _gameManager.visibleBases;
    _captureBaseDamagePulses(bases);

    if (_gameManager.interceptorLaunchCounter > _lastInterceptorLaunchCounter) {
      _lastInterceptorLaunchCounter = _gameManager.interceptorLaunchCounter;
      unawaited(_audio.playLaunch());
    }

    if (_gameManager.baseHitCounter > _lastBaseHitCounter) {
      final int delta = _gameManager.baseHitCounter - _lastBaseHitCounter;
      _lastBaseHitCounter = _gameManager.baseHitCounter;
      _effectsSystem.addShakeImpulse(0.6);
      for (int i = 0; i < delta; i += 1) {
        unawaited(_audio.playBaseHit());
      }
    }
    if (_gameManager.explosionImpactCounter > _lastExplosionImpactCounter) {
      _lastExplosionImpactCounter = _gameManager.explosionImpactCounter;
      _effectsSystem.addShakeImpulse(0.4);
    }
    if (_gameManager.explosionCreatedCounter > _lastExplosionCreatedCounter) {
      final int createdDelta =
          _gameManager.explosionCreatedCounter - _lastExplosionCreatedCounter;
      _lastExplosionCreatedCounter = _gameManager.explosionCreatedCounter;
      _effectsSystem.triggerFlash();
      final explosions = _gameManager.visibleExplosions;
      final int burstCount = createdDelta.clamp(1, explosions.length);
      for (int i = 0; i < burstCount; i += 1) {
        final int index = explosions.length - 1 - i;
        if (index < 0) {
          break;
        }
        final explosion = explosions[index];
        final int particleCount =
            (_maxParticlesPerExplosion * 0.65 + (explosion.radius * 0.35))
                .round()
                .clamp(12, _maxParticlesPerExplosion);
        _particleEngine.spawnExplosionBurst(
          x: explosion.x,
          y: explosion.y,
          particleCount: particleCount,
          baseSpeed: 46 + explosion.radius,
        );
      }
      unawaited(_audio.playExplosion());
    }

    final double interWaveTimer = _gameManager.interWaveTimerSeconds;
    if (!_gameManager.isWaveActive && interWaveTimer > 0) {
      final int countdownSecond = interWaveTimer.ceil();
      if (countdownSecond != _lastCountdownSecond) {
        _lastCountdownSecond = countdownSecond;
        unawaited(_audio.playCountdownBeep());
      }
    } else {
      _lastCountdownSecond = -1;
    }

    final bool isGameOver = _gameManager.isGameOver;
    if (isGameOver) {
      if (!overlays.isActive(gameOverOverlayId)) {
        overlays.add(gameOverOverlayId);
      }
    } else if (overlays.isActive(gameOverOverlayId)) {
      overlays.remove(gameOverOverlayId);
    }
  }

  @override
  void onRemove() {
    _gameManager.end();
    unawaited(_audio.dispose());
    super.onRemove();
  }

  void _captureDestroyedMissileTrails() {
    final List<Missile> currentMissiles = _gameManager.visibleMissiles;
    final Map<String, Missile> currentById = <String, Missile>{
      for (final missile in currentMissiles) missile.id: missile,
    };
    final double now = _gameManager.elapsedTimeSeconds;
    for (final MapEntry<String, Missile> entry
        in _previousMissilesById.entries) {
      if (!currentById.containsKey(entry.key)) {
        final Missile removed = entry.value;
        _smokeTrails.add(
          _SmokeTrail(
            origin: removed.origin.clone(),
            end: Vector2(removed.x, removed.y),
            expiresAtSeconds: now + _smokePersistenceSeconds,
          ),
        );
      }
    }
    _previousMissilesById
      ..clear()
      ..addAll(currentById);
  }

  void _captureBaseDamagePulses(List<Base> currentBases) {
    final Set<String> activeIds = <String>{};
    for (final Base base in currentBases) {
      activeIds.add(base.id);
      final int previousHealth = _lastBaseHealthById[base.id] ?? base.health;
      if (base.health < previousHealth) {
        _baseDamagePulses.add(
          _BaseDamagePulse(
            baseId: base.id,
            ageSeconds: 0,
          ),
        );
      }
      _lastBaseHealthById[base.id] = base.health;
    }
    _lastBaseHealthById
        .removeWhere((String key, int _) => !activeIds.contains(key));
  }

  void _regenerateStars() {
    _stars
      ..clear()
      ..addAll(_generateStars());
  }

  List<_Star> _generateStars() {
    if (size.x <= 0 || size.y <= 0) {
      return const <_Star>[];
    }
    final int count = max(22, (size.x * size.y / 28000).round());
    final Random random = Random(1337);
    final List<_Star> stars = <_Star>[];
    for (int i = 0; i < count; i += 1) {
      stars.add(
        _Star(
          x: random.nextDouble() * size.x,
          y: random.nextDouble() * size.y,
          radius: 0.6 + (random.nextDouble() * 1.6),
          twinklePhase: random.nextDouble() * pi * 2,
          twinkleSpeed: 0.4 + random.nextDouble() * 1.5,
          brightness: 0.25 + random.nextDouble() * 0.55,
        ),
      );
    }
    return stars;
  }

  void _renderStars(Canvas canvas) {
    if (_stars.isEmpty) {
      return;
    }
    final double now = _gameManager.elapsedTimeSeconds;
    for (final _Star star in _stars) {
      final double twinkle =
          0.65 + (0.35 * sin((now * star.twinkleSpeed) + star.twinklePhase));
      _starPaint.color = Colors.white
          .withValues(alpha: (star.brightness * twinkle).clamp(0, 1));
      canvas.drawCircle(
        Offset(star.x, star.y),
        star.radius,
        _starPaint,
      );
    }
  }

  void _handleRestartResetIfNeeded() {
    final int restartVersion = _gameManager.restartVersion;
    if (restartVersion == _lastRestartVersionSeen) {
      return;
    }
    _resetVisualState(reinitializePaints: true);
  }

  void _resetVisualState({required bool reinitializePaints}) {
    if (reinitializePaints) {
      _initializePaintObjects();
    }
    _effectsSystem.reset();
    _particleEngine.reset();
    _previousMissilesById.clear();
    _lastBaseHealthById.clear();
    _smokeTrails.clear();
    _baseDamagePulses.clear();
    _crosshairPreviews.clear();
    _lastBaseHitCounter = _gameManager.baseHitCounter;
    _lastExplosionImpactCounter = _gameManager.explosionImpactCounter;
    _lastExplosionCreatedCounter = _gameManager.explosionCreatedCounter;
    _lastInterceptorLaunchCounter = _gameManager.interceptorLaunchCounter;
    _lastCountdownSecond = -1;
    _lastRestartVersionSeen = _gameManager.restartVersion;
    _regenerateStars();
  }

  void _initializePaintObjects() {
    _backgroundPaint = Paint()..color = const Color(0xFF060A15);
    _starPaint = Paint()..style = PaintingStyle.fill;
    _missilePaint = Paint()..style = PaintingStyle.fill;
    _missileTrailHeadPaint = Paint()..style = PaintingStyle.stroke;
    _missileTrailTailPaint = Paint()..style = PaintingStyle.stroke;
    _smokePaintLut = List<Paint>.generate(
      8,
      (int i) => Paint()
        ..color = Colors.white.withValues(alpha: 0.04 + (i * 0.04))
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke,
    );
    _interceptorPaint = Paint()..style = PaintingStyle.fill;
    _interceptorTrailPaint = Paint()..style = PaintingStyle.stroke;
    _explosionFillPaint = Paint()..style = PaintingStyle.fill;
    _explosionStrokePaint = Paint()..style = PaintingStyle.stroke;
    _explosionGlowPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    _particlePaint = Paint()..style = PaintingStyle.fill;
    _particleGlowPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    _basePaint = Paint();
    _baseDamagePaint = Paint()..style = PaintingStyle.stroke;
    _flashPaint = Paint()..color = Colors.white.withValues(alpha: 0);
    _debugBoundsPaint = Paint()
      ..color = const Color(0x3300FF00)
      ..style = PaintingStyle.stroke;
    _crosshairPaintLut = List<Paint>.generate(
      8,
      (int i) => Paint()
        ..color = Colors.white.withValues(alpha: 0.08 + (i * 0.1))
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke,
    );
  }
}

class _SmokeTrail {
  const _SmokeTrail({
    required this.origin,
    required this.end,
    required this.expiresAtSeconds,
  });

  final Vector2 origin;
  final Vector2 end;
  final double expiresAtSeconds;
}

class _CrosshairPreview {
  const _CrosshairPreview({
    required this.x,
    required this.y,
    required this.expiresAtSeconds,
  });

  final double x;
  final double y;
  final double expiresAtSeconds;
}

class _Star {
  const _Star({
    required this.x,
    required this.y,
    required this.radius,
    required this.twinklePhase,
    required this.twinkleSpeed,
    required this.brightness,
  });

  final double x;
  final double y;
  final double radius;
  final double twinklePhase;
  final double twinkleSpeed;
  final double brightness;
}

class _BaseDamagePulse {
  const _BaseDamagePulse({
    required this.baseId,
    required this.ageSeconds,
  });

  final String baseId;
  final double ageSeconds;

  _BaseDamagePulse copyWith({
    String? baseId,
    double? ageSeconds,
  }) {
    return _BaseDamagePulse(
      baseId: baseId ?? this.baseId,
      ageSeconds: ageSeconds ?? this.ageSeconds,
    );
  }
}

class _EffectsSystem {
  static const double _shakeDurationSeconds = 0.22;
  static const double _shakeAmplitude = 3.5;
  static const double _flashDurationSeconds = 0.12;
  static const double _shakeAngularSpeedX = 42;
  static const double _shakeAngularSpeedY = 31;

  double _shakeTimeRemaining = 0;
  double _shakeStrength = 0;
  double _flashTimeRemaining = 0;
  double _phase = 0;
  double _offsetX = 0;
  double _offsetY = 0;

  bool get isShaking => _shakeTimeRemaining > 0 && _shakeStrength > 0;
  double get flashTimeRemaining => _flashTimeRemaining;
  double get flashRatio => pow(
        (_flashTimeRemaining / _flashDurationSeconds).clamp(0, 1),
        1.6,
      ).toDouble();
  double get shakeOffsetX => _offsetX;
  double get shakeOffsetY => _offsetY;

  void addShakeImpulse(double amount) {
    _shakeTimeRemaining = _shakeDurationSeconds;
    _shakeStrength = (_shakeStrength + amount).clamp(0, 1);
  }

  void triggerFlash() {
    _flashTimeRemaining = _flashDurationSeconds;
  }

  void update(double dt) {
    if (_shakeTimeRemaining > 0) {
      _shakeTimeRemaining -= dt;
      if (_shakeTimeRemaining < 0) {
        _shakeTimeRemaining = 0;
      }
    }
    if (_shakeStrength > 0) {
      _shakeStrength = (_shakeStrength - (dt * 3)).clamp(0, 1);
    }
    if (isShaking) {
      _phase += dt;
      final double normalizedShakeTime =
          (_shakeTimeRemaining / _shakeDurationSeconds).clamp(0, 1);
      final double amplitude =
          _shakeAmplitude * _shakeStrength * normalizedShakeTime;
      _offsetX = sin(_phase * _shakeAngularSpeedX) * amplitude;
      _offsetY = cos(_phase * _shakeAngularSpeedY) * amplitude;
    } else {
      _offsetX = 0;
      _offsetY = 0;
    }
    if (_flashTimeRemaining > 0) {
      _flashTimeRemaining -= dt;
      if (_flashTimeRemaining < 0) {
        _flashTimeRemaining = 0;
      }
    }
  }

  void reset() {
    _shakeTimeRemaining = 0;
    _shakeStrength = 0;
    _flashTimeRemaining = 0;
    _phase = 0;
    _offsetX = 0;
    _offsetY = 0;
  }
}

class _ParticleEngine {
  _ParticleEngine() {
    for (int i = 0; i < _maxActiveParticles; i += 1) {
      _particles.add(_Particle.inactive());
    }
  }

  static const int _maxActiveParticles = 420;
  static const double _minLifetime = 0.24;
  static const double _maxLifetime = 0.62;
  final List<_Particle> _particles = <_Particle>[];
  final Random _random = Random();

  void spawnExplosionBurst({
    required double x,
    required double y,
    required int particleCount,
    required double baseSpeed,
  }) {
    int remaining = particleCount;
    if (remaining <= 0) {
      return;
    }
    while (remaining > 0) {
      final int slot = _findReusableSlot();
      if (slot < 0) {
        return;
      }
      final _Particle p = _particles[slot];
      final double theta = _random.nextDouble() * pi * 2;
      final double speed = baseSpeed * (0.65 + (_random.nextDouble() * 0.75));
      p
        ..active = true
        ..x = x
        ..y = y
        ..vx = cos(theta) * speed
        ..vy = sin(theta) * speed
        ..lifetime = _minLifetime +
            (_random.nextDouble() * (_maxLifetime - _minLifetime))
        ..age = 0
        ..radius = 1.5 + (_random.nextDouble() * 2.4)
        ..warmColor = _random.nextDouble();
      remaining -= 1;
    }
  }

  void update(double dt) {
    if (dt <= 0) {
      return;
    }
    for (int i = 0; i < _particles.length; i += 1) {
      final _Particle p = _particles[i];
      if (!p.active) {
        continue;
      }
      p.age += dt;
      if (p.age >= p.lifetime) {
        p.active = false;
        continue;
      }
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vx *= 0.985;
      p.vy = (p.vy * 0.985) + (7.5 * dt);
    }
  }

  void render({
    required Canvas canvas,
    required Paint paint,
    required Paint glowPaint,
  }) {
    for (int i = 0; i < _particles.length; i += 1) {
      final _Particle p = _particles[i];
      if (!p.active) {
        continue;
      }
      final double life = (1 - (p.age / p.lifetime)).clamp(0, 1);
      final Color core = Color.lerp(
        Colors.deepOrange,
        Colors.yellowAccent,
        p.warmColor,
      )!;
      paint.color = core.withValues(alpha: 0.08 + (life * 0.82));
      glowPaint.color = core.withValues(alpha: 0.06 + (life * 0.28));
      final double size = p.radius * (0.75 + (life * 0.95));
      canvas.drawCircle(Offset(p.x, p.y), size * 1.6, glowPaint);
      canvas.drawCircle(Offset(p.x, p.y), size, paint);
    }
  }

  void reset() {
    for (int i = 0; i < _particles.length; i += 1) {
      _particles[i].active = false;
    }
  }

  int _findReusableSlot() {
    for (int i = 0; i < _particles.length; i += 1) {
      if (!_particles[i].active) {
        return i;
      }
    }
    return -1;
  }
}

class _Particle {
  _Particle.inactive();

  bool active = false;
  double x = 0;
  double y = 0;
  double vx = 0;
  double vy = 0;
  double lifetime = 0;
  double age = 0;
  double radius = 1;
  double warmColor = 0;
}
