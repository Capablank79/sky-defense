import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sky_defense/game/entities/base.dart';
import 'package:sky_defense/game/entities/missile.dart';
import 'package:sky_defense/game/engine/game_manager.dart';

class SkyDefenseGame extends FlameGame with TapCallbacks {
  SkyDefenseGame(this._gameManager);

  static const String hudOverlayId = 'hud';
  static const String gameOverOverlayId = 'game_over';

  final GameManager _gameManager;
  final Paint _missilePaint = Paint()..color = Colors.red;
  final Paint _missileTrailHeadPaint = Paint()
    ..color = Colors.white70
    ..strokeWidth = 1.8
    ..style = PaintingStyle.stroke;
  final Paint _missileTrailTailPaint = Paint()
    ..color = Colors.white30
    ..strokeWidth = 1.2
    ..style = PaintingStyle.stroke;
  final List<Paint> _smokePaintLut = List<Paint>.generate(
    8,
    (int i) => Paint()
      ..color = Colors.white.withValues(alpha: 0.04 + (i * 0.04))
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke,
  );
  final Paint _interceptorPaint = Paint()..color = Colors.lightBlueAccent;
  final Paint _interceptorTrailPaint = Paint()
    ..color = Colors.lightBlueAccent.withValues(alpha: 0.55)
    ..strokeWidth = 1.2
    ..style = PaintingStyle.stroke;
  final Paint _explosionPaint = Paint()..color = Colors.orange;
  final Paint _basePaint = Paint();
  final List<Paint> _crosshairPaintLut = List<Paint>.generate(
    8,
    (int i) => Paint()
      ..color = Colors.white.withValues(alpha: 0.08 + (i * 0.1))
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke,
  );
  final Random _shakeRandom = Random();
  static const double _missileRadius = 5;
  static const double _interceptorRadius = 3.5;
  static const double _baseRadius = 14;
  static const double _smokePersistenceSeconds = 0.5;
  static const double _crosshairPersistenceSeconds = 0.4;
  static const double _crosshairHalfSize = 10;
  final Map<String, Missile> _previousMissilesById = <String, Missile>{};
  final List<_SmokeTrail> _smokeTrails = <_SmokeTrail>[];
  final List<_CrosshairPreview> _crosshairPreviews = <_CrosshairPreview>[];
  int _lastBaseHitCounter = 0;
  int _lastExplosionImpactCounter = 0;
  double _shakeTimeRemaining = 0;
  static const double _shakeDurationSeconds = 0.22;
  static const double _shakeAmplitude = 4;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _gameManager.init();
    _gameManager.start();
    _gameManager.configureWorldBounds(width: size.x, height: size.y);
    overlays.add(hudOverlayId);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _gameManager.configureWorldBounds(width: size.x, height: size.y);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final missiles = _gameManager.visibleMissiles;
    final interceptors = _gameManager.visibleInterceptors;
    final bases = _gameManager.visibleBases;
    final explosions = _gameManager.visibleExplosions;
    if (missiles.isEmpty &&
        interceptors.isEmpty &&
        explosions.isEmpty &&
        bases.isEmpty &&
        _smokeTrails.isEmpty &&
        _crosshairPreviews.isEmpty) {
      return;
    }

    final bool isShaking = _shakeTimeRemaining > 0;
    if (isShaking) {
      final double dx = (_shakeRandom.nextDouble() * 2 - 1) * _shakeAmplitude;
      final double dy = (_shakeRandom.nextDouble() * 2 - 1) * _shakeAmplitude;
      canvas.save();
      canvas.translate(dx, dy);
    }

    // TODO(PHASE_3_5_MIGRATION): Replace manual canvas rendering with Flame
    // components (e.g. add(MissileComponent()), add(ExplosionComponent())).
    // The component pipeline is required for scalable spatial partitioning,
    // lifecycle management, and future collision optimizations.
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
        _missileRadius,
        _missilePaint,
      );
    }

    for (final interceptor in interceptors) {
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
      if (base.isDestroyed) {
        _basePaint.color = Colors.grey;
      } else if (base.health >= 3) {
        _basePaint.color = Colors.green;
      } else if (base.health == 2) {
        _basePaint.color = Colors.amber;
      } else {
        _basePaint.color = Colors.deepOrange;
      }
      canvas.drawCircle(
        Offset(base.x, base.y),
        _baseRadius,
        _basePaint,
      );
    }

    for (final explosion in explosions) {
      canvas.drawCircle(
        Offset(explosion.x, explosion.y),
        explosion.radius,
        _explosionPaint,
      );
    }
    if (isShaking) {
      canvas.restore();
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
    if (_shakeTimeRemaining > 0) {
      _shakeTimeRemaining -= dt;
      if (_shakeTimeRemaining < 0) {
        _shakeTimeRemaining = 0;
      }
    }
    if (_gameManager.baseHitCounter > _lastBaseHitCounter) {
      _lastBaseHitCounter = _gameManager.baseHitCounter;
      _shakeTimeRemaining = _shakeDurationSeconds;
    }
    if (_gameManager.explosionImpactCounter > _lastExplosionImpactCounter) {
      _lastExplosionImpactCounter = _gameManager.explosionImpactCounter;
      _shakeTimeRemaining = _shakeDurationSeconds;
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
