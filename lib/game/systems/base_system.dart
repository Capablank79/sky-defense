import 'package:sky_defense/game/entities/base.dart';
import 'package:sky_defense/game/debug/debug_flags.dart';

class BaseSystem {
  List<Base> _bases = <Base>[];
  double _lastWorldWidth = 0;
  double _lastWorldHeight = 0;

  void initializeBases({
    required double worldWidth,
    required double worldHeight,
    int baseCount = 4,
    double horizontalMargin = 56,
    double bottomOffset = 48,
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
        ammoMax: kDebugFastFail ? 3 : 10,
        ammoCurrent: kDebugFastFail ? 3 : 10,
        ammoRegenRate: kDebugFastFail ? 0.3 : 0.6,
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

  void damageBaseAtTarget({
    required double targetX,
    required double targetY,
    int damage = 1,
  }) {
    if (damage <= 0) {
      return;
    }

    int index = -1;
    for (int i = 0; i < _bases.length; i += 1) {
      final Base base = _bases[i];
      if (base.isDestroyed) {
        continue;
      }
      final bool matchesTarget =
          (base.x - targetX).abs() < 0.01 && (base.y - targetY).abs() < 0.01;
      if (matchesTarget) {
        index = i;
        break;
      }
    }

    if (index < 0) {
      return;
    }

    final Base current = _bases[index];
    final int nextHealth =
        (current.health - damage) < 0 ? 0 : (current.health - damage);
    _bases[index] = current.copyWith(
      health: nextHealth,
      isDestroyed: nextHealth <= 0,
    );
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
}
