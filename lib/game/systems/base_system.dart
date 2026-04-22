import 'dart:math';

import 'package:sky_defense/game/entities/base.dart';

class BaseSystem {
  List<Base> _bases = <Base>[];
  double _lastWorldWidth = 0;
  double _lastWorldHeight = 0;
  int _ammoMax = 10;
  double _reloadSpeed = 0.6;

  void initializeBases({
    required double worldWidth,
    required double worldHeight,
    int baseCount = 4,
    double horizontalMargin = 56,
    double bottomOffset = 110,
  }) {
    if (worldWidth <= 0 || worldHeight <= 0 || baseCount <= 0) {
      return;
    }
    _lastWorldWidth = worldWidth;
    _lastWorldHeight = worldHeight;

    final double usableWidth = worldWidth - (horizontalMargin * 2);
    final double spacing = baseCount == 1
        ? 0
        : (usableWidth > 0 ? usableWidth / (baseCount - 1) : 0);
    final double baseY = worldHeight - bottomOffset;

    _bases = List<Base>.generate(baseCount, (int index) {
      final double x = horizontalMargin + (spacing * index);
      return Base(
        id: 'base_$index',
        x: x,
        y: baseY,
        ammoMax: _ammoMax,
        ammoCurrent: _ammoMax.toDouble(),
        ammoRegenRate: _reloadSpeed,
      );
    });
  }

  List<Base> getBases() {
    return List<Base>.unmodifiable(_bases);
  }

  List<Base> getAliveBases() {
    return List<Base>.unmodifiable(
      _bases.where((Base base) => !base.isDestroyed && base.health > 0),
    );
  }

  Base? getRandomAliveBase([Random? random]) {
    final Random safeRandom = random ?? Random();
    final List<Base> alive = _bases
        .where((Base base) => !base.isDestroyed && base.health > 0)
        .toList(growable: false);
    if (alive.isEmpty) {
      return null;
    }
    return alive[safeRandom.nextInt(alive.length)];
  }

  Base? getNearestActiveBase({
    required double x,
    required double y,
  }) {
    Base? nearest;
    double nearestDistanceSquared = double.infinity;
    for (final Base base in _bases) {
      if (base.isDestroyed || base.ammoCurrent < 1) {
        continue;
      }
      final double dx = base.x - x;
      final double dy = base.y - y;
      final double distanceSquared = (dx * dx) + (dy * dy);
      if (distanceSquared < nearestDistanceSquared) {
        nearestDistanceSquared = distanceSquared;
        nearest = base;
      }
    }
    return nearest;
  }

  bool consumeInterceptor(String baseId) {
    for (int i = 0; i < _bases.length; i += 1) {
      final Base base = _bases[i];
      if (base.id != baseId || base.isDestroyed || base.ammoCurrent < 1) {
        continue;
      }
      _bases[i] = base.copyWith(
        ammoCurrent: (base.ammoCurrent - 1).clamp(0, base.ammoMax.toDouble()),
      );
      return true;
    }
    return false;
  }

  void updateAmmo(double dtSeconds) {
    if (dtSeconds <= 0) {
      return;
    }
    for (int i = 0; i < _bases.length; i += 1) {
      final Base base = _bases[i];
      if (base.isDestroyed) {
        continue;
      }
      final double nextAmmo =
          (base.ammoCurrent + (base.ammoRegenRate * dtSeconds))
              .clamp(0, base.ammoMax.toDouble());
      _bases[i] = base.copyWith(ammoCurrent: nextAmmo);
    }
  }

  bool damageBaseAtTarget({
    String? targetBaseId,
    required double targetX,
    required double targetY,
    int damage = 1,
    double hitRadius = 24,
  }) {
    if (damage <= 0) {
      return false;
    }

    int index = -1;
    if (targetBaseId != null && targetBaseId.isNotEmpty) {
      for (int i = 0; i < _bases.length; i += 1) {
        final Base base = _bases[i];
        if (base.id == targetBaseId && !base.isDestroyed) {
          index = i;
          break;
        }
      }
    }

    if (index < 0) {
      final double hitRadiusSquared = hitRadius * hitRadius;
      double nearestDistanceSquared = double.infinity;
      for (int i = 0; i < _bases.length; i += 1) {
        final Base base = _bases[i];
        if (base.isDestroyed) {
          continue;
        }
        final double dx = base.x - targetX;
        final double dy = base.y - targetY;
        final double distanceSquared = (dx * dx) + (dy * dy);
        if (distanceSquared <= hitRadiusSquared &&
            distanceSquared < nearestDistanceSquared) {
          nearestDistanceSquared = distanceSquared;
          index = i;
        }
      }
    }

    // Fallback determinista: si no hay match por id ni por radio, daña la base viva mas cercana.
    if (index < 0) {
      double nearestDistanceSquared = double.infinity;
      for (int i = 0; i < _bases.length; i += 1) {
        final Base base = _bases[i];
        if (base.isDestroyed) {
          continue;
        }
        final double dx = base.x - targetX;
        final double dy = base.y - targetY;
        final double distanceSquared = (dx * dx) + (dy * dy);
        if (distanceSquared < nearestDistanceSquared) {
          nearestDistanceSquared = distanceSquared;
          index = i;
        }
      }
    }

    if (index < 0) {
      return false;
    }

    final Base current = _bases[index];
    final int nextHealth =
        (current.health - damage) < 0 ? 0 : (current.health - damage);
    _bases[index] = current.copyWith(
      health: nextHealth,
      isDestroyed: nextHealth <= 0,
    );
    return true;
  }

  void restoreBasesForContinue({double healthRatio = 0.5}) {
    for (int i = 0; i < _bases.length; i += 1) {
      final Base base = _bases[i];
      final int restoredHealth =
          (base.healthMax * healthRatio).ceil().clamp(1, base.healthMax);
      _bases[i] = base.copyWith(
        health: base.isDestroyed ? restoredHealth : base.health,
        isDestroyed: false,
        ammoCurrent: base.ammoMax.toDouble(),
      );
    }
  }

  void restorePartial() {
    restoreBasesForContinue(healthRatio: 0.5);
  }

  void restoreAmmo() {
    for (int i = 0; i < _bases.length; i += 1) {
      final Base base = _bases[i];
      if (base.isDestroyed) {
        continue;
      }
      _bases[i] = base.copyWith(ammoCurrent: base.ammoMax.toDouble());
    }
  }

  void resetAllBases() {
    if (_lastWorldWidth <= 0 || _lastWorldHeight <= 0) {
      return;
    }
    initializeBases(
      worldWidth: _lastWorldWidth,
      worldHeight: _lastWorldHeight,
    );
  }

  void reset() {
    resetAllBases();
  }

  void positionBasesInArea({
    required double minX,
    required double maxX,
    required double y,
  }) {
    if (_bases.isEmpty) {
      return;
    }
    final double clampedMinX = minX < maxX ? minX : maxX;
    final double clampedMaxX = maxX > minX ? maxX : minX;
    final double width = clampedMaxX - clampedMinX;
    final double spacing = _bases.length <= 1 ? 0 : width / (_bases.length - 1);
    for (int i = 0; i < _bases.length; i += 1) {
      final Base base = _bases[i];
      _bases[i] = base.copyWith(
        x: clampedMinX + (spacing * i),
        y: y,
      );
    }
  }

  void setAmmoConfig({
    required int ammoMax,
    required double reloadSpeed,
  }) {
    _ammoMax = ammoMax < 1 ? 1 : ammoMax;
    _reloadSpeed = reloadSpeed <= 0 ? 0.1 : reloadSpeed;
    if (_bases.isEmpty) {
      return;
    }
    for (int i = 0; i < _bases.length; i += 1) {
      final Base base = _bases[i];
      _bases[i] = base.copyWith(
        ammoMax: _ammoMax,
        ammoCurrent: base.ammoCurrent.clamp(0, _ammoMax.toDouble()),
        ammoRegenRate: _reloadSpeed,
      );
    }
  }
}
