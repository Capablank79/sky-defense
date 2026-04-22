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
  final Set<String> _arrivedMissileIds = <String>{};

  Missile spawnMissile({
    required double startX,
    required double startY,
    required String targetBaseId,
    required MissileTargetKind targetKind,
    required double targetX,
    required double targetY,
    required double speed,
    MissileType type = MissileType.medium,
    int hitPoints = 1,
    int splitRemaining = 0,
    double zigzagAmplitude = 0,
    double zigzagFrequency = 0,
  }) {
    final int safeHitPoints = hitPoints < 1 ? 1 : hitPoints;
    final Missile missile = Missile(
      id: 'missile_${_counter++}',
      targetBaseId: targetBaseId,
      targetKind: targetKind,
      type: type,
      origin: Vector2(startX, startY),
      target: Vector2(targetX, targetY),
      speed: speed,
      hitPoints: safeHitPoints,
      maxHitPoints: safeHitPoints,
      isActive: true,
      splitRemaining: splitRemaining,
      zigzagAmplitude: zigzagAmplitude,
      zigzagFrequency: zigzagFrequency,
    );
    _missiles.add(missile);
    return missile;
  }

  void update(double dtSeconds) {
    if (dtSeconds <= 0) return;

    for (int i = 0; i < _missiles.length; i++) {
      final Missile missile = _missiles[i];
      if (!missile.isActive) continue;

      final double dx = missile.target.x - missile.position.x;
      final double dy = missile.target.y - missile.position.y;
      final double distSq = dx * dx + dy * dy;

      if (distSq <= 0.0001) {
        missile.position.setFrom(missile.target);
        missile.hasArrived = true; // 🔥 CLAVE
        missile.isActive = false; // 🔥 FIX REAL
        _arrivedMissileIds.add(missile.id);
        continue;
      }

      final double stepX = missile.velocity.x * dtSeconds;
      final double stepY = missile.velocity.y * dtSeconds;
      final double stepSq = stepX * stepX + stepY * stepY;

      if (stepSq >= distSq) {
        missile.position.setFrom(missile.target);
        missile.hasArrived = true; // 🔥 CLAVE
        missile.isActive = false; // 🔥 FIX REAL
        _arrivedMissileIds.add(missile.id);
        continue;
      }

      missile.update(dtSeconds);

      if (missile.type == MissileType.split &&
          !missile.hasSplit &&
          missile.splitRemaining > 0) {
        // Split missiles are kept as a visual type only to avoid
        // secondary spawn sources outside the wave controller.
        missile.hasSplit = true;
      }
    }

    _missiles.removeWhere(
      (Missile m) =>
          (!m.isActive && !_arrivedMissileIds.contains(m.id)) ||
          m.x < _minX ||
          m.x > _maxX ||
          m.y < _minY ||
          m.y > _maxY,
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
        (Missile missile) => _arrivedMissileIds.contains(missile.id),
      ),
    );
  }

  List<Missile> consumeArrivedMissiles() {
    if (_arrivedMissileIds.isEmpty) {
      return const <Missile>[];
    }
    final List<Missile> arrived = _missiles
        .where(
          (Missile missile) => _arrivedMissileIds.contains(missile.id),
        )
        .toList(growable: false);
    if (arrived.isEmpty) {
      return const <Missile>[];
    }
    final Set<String> ids = arrived.map((Missile m) => m.id).toSet();
    _missiles.removeWhere((Missile missile) => ids.contains(missile.id));
    _arrivedMissileIds.removeAll(ids);
    return arrived;
  }

  int getActiveThreatCount() {
    return _missiles
        .where(
          (Missile missile) =>
              missile.isActive && !missile.hasArrived && !missile.isDestroyed,
        )
        .length;
  }

  void clearAll() {
    _missiles = <Missile>[];
  }

  void reset() {
    _missiles = <Missile>[];
    _counter = 0;
  }

  void clear() {
    clearAll();
  }

  bool applyDamage(String id, {int damage = 1}) {
    if (damage <= 0) {
      return false;
    }
    for (int i = 0; i < _missiles.length; i += 1) {
      final Missile missile = _missiles[i];
      if (missile.id != id) {
        continue;
      }
      final int nextHp = missile.hitPoints - damage;
      if (nextHp <= 0) {
        _missiles.removeAt(i);
        _arrivedMissileIds.remove(id);
        return true;
      }
      missile.hitPoints = nextHp;
      return false;
    }
    return false;
  }

  bool ensureValidTargets(List<Base> aliveBases) {
    if (aliveBases.isEmpty) {
      return false;
    }
    for (int i = 0; i < _missiles.length; i += 1) {
      final Missile missile = _missiles[i];
      if (missile.targetKind != MissileTargetKind.base) {
        continue;
      }
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
      missile.retarget(
        nextTargetBaseId: nearest.id,
        nextTargetKind: MissileTargetKind.base,
        nextTarget: Vector2(nearest.x, nearest.y),
      );
    }
    return true;
  }
}
