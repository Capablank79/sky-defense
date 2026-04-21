import 'dart:math';

import 'package:flame/components.dart';
import 'package:sky_defense/game/entities/base.dart';
import 'package:sky_defense/game/entities/missile.dart';

class MissileSystem {
  MissileSystem({
    double minX = -1000,
    double maxX = 1000,
    double minY = -100,
    double maxY = 2000,
  })  : _minX = minX,
        _maxX = maxX,
        _minY = minY,
        _maxY = maxY;

  List<Missile> _missiles = <Missile>[];
  final double _minX;
  final double _maxX;
  final double _minY;
  final double _maxY;
  int _counter = 0;

  Missile spawnMissile({
    required double startX,
    required double startY,
    required String targetBaseId,
    required double targetX,
    required double targetY,
    required double speed,
  }) {
    final Missile missile = Missile(
      id: 'missile_${_counter++}',
      targetBaseId: targetBaseId,
      x: startX,
      y: startY,
      origin: Vector2(startX, startY),
      target: Vector2(targetX, targetY),
      progress: 0,
      speed: speed,
      isActive: true,
    );
    _missiles.add(missile);
    return missile;
  }

  void update(double dtSeconds) {
    for (int i = 0; i < _missiles.length; i += 1) {
      final Missile current = _missiles[i];
      if (!current.isActive) {
        continue;
      }
      final double pathDx = current.target.x - current.origin.x;
      final double pathDy = current.target.y - current.origin.y;
      final double pathDistance = sqrt((pathDx * pathDx) + (pathDy * pathDy));
      if (pathDistance <= 0.0001) {
        _missiles[i] = current.copyWith(
          progress: 1,
          x: current.target.x,
          y: current.target.y,
        );
        continue;
      }

      // Normalize direction so speed is constant regardless of angle.
      final double dirX = pathDx / pathDistance;
      final double dirY = pathDy / pathDistance;
      final double nextX = current.x + (dirX * current.speed * dtSeconds);
      final double nextY = current.y + (dirY * current.speed * dtSeconds);

      final double travelledDx = nextX - current.origin.x;
      final double travelledDy = nextY - current.origin.y;
      final double travelledDistance =
          sqrt((travelledDx * travelledDx) + (travelledDy * travelledDy));
      final double nextProgress =
          (travelledDistance / pathDistance).clamp(0, 1);
      final bool arrived = nextProgress >= 1;
      _missiles[i] = current.copyWith(
        progress: nextProgress,
        x: arrived ? current.target.x : nextX,
        y: arrived ? current.target.y : nextY,
      );
    }
    _missiles.removeWhere(
      (Missile missile) =>
          !missile.isActive ||
          missile.x < _minX ||
          missile.x > _maxX ||
          missile.y < _minY ||
          missile.y > _maxY,
    );
  }

  void removeMissile(String id) {
    _missiles.removeWhere((Missile missile) => missile.id == id);
  }

  List<Missile> getMissiles() {
    return List<Missile>.unmodifiable(_missiles);
  }

  List<Missile> getArrivedMissiles() {
    return List<Missile>.unmodifiable(
      _missiles.where(
          (Missile missile) => missile.isActive && missile.progress >= 1),
    );
  }

  void clearAll() {
    _missiles = <Missile>[];
  }

  void reset() {
    clearAll();
  }

  void clear() {
    clearAll();
  }

  bool ensureValidTargets(List<Base> aliveBases) {
    if (aliveBases.isEmpty) {
      return false;
    }
    for (int i = 0; i < _missiles.length; i += 1) {
      final Missile missile = _missiles[i];
      final bool targetIsAlive = aliveBases.any(
        (Base base) => base.id == missile.targetBaseId,
      );
      if (targetIsAlive) {
        continue;
      }
      Base nearest = aliveBases.first;
      double nearestDistance = double.infinity;
      for (final Base base in aliveBases) {
        final double dx = missile.x - base.x;
        final double dy = missile.y - base.y;
        final double distance = (dx * dx) + (dy * dy);
        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearest = base;
        }
      }
      _missiles[i] = missile.copyWith(
        targetBaseId: nearest.id,
        origin: Vector2(missile.x, missile.y),
        target: Vector2(nearest.x, nearest.y),
        progress: 0,
      );
    }
    return true;
  }
}
