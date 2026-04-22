import 'package:sky_defense/game/entities/explosion.dart';

class ExplosionSystem {
  ExplosionSystem({
    required double defaultRadius,
    required double defaultLifetime,
  })  : _defaultRadius = defaultRadius,
        _defaultLifetime = defaultLifetime,
        _configuredRadius = defaultRadius;

  final double _defaultRadius;
  final double _defaultLifetime;
  double _configuredRadius;
  static const double _minLifetimeSeconds = 0.016;
  List<Explosion> _explosions = <Explosion>[];
  int _counter = 0;
  
  double get baseRadius => _defaultRadius;

  Explosion createExplosion(
    ({double x, double y}) position, {
    double? radius,
    double? lifetime,
  }) {
    final double requestedLifetime = lifetime ?? _defaultLifetime;
    final double safeLifetime = requestedLifetime < _minLifetimeSeconds
        ? _minLifetimeSeconds
        : requestedLifetime;
    final Explosion explosion = Explosion(
      id: 'explosion_${_counter++}',
      x: position.x,
      y: position.y,
      radius: radius ?? _configuredRadius,
      lifetime: safeLifetime,
      maxLifetime: safeLifetime,
      isActive: true,
    );
    _explosions.add(explosion);
    return explosion;
  }

  void update(double dtSeconds) {
    for (int i = 0; i < _explosions.length; i += 1) {
      final Explosion current = _explosions[i];
      if (!current.isActive) {
        continue;
      }
      final double nextLifetime = current.lifetime - dtSeconds;
      _explosions[i] = current.copyWith(
        lifetime: nextLifetime < 0 ? 0 : nextLifetime,
        isActive: nextLifetime > 0,
      );
    }
    _explosions.removeWhere((Explosion explosion) => !explosion.isActive);
  }

  List<Explosion> getExplosions() {
    return List<Explosion>.unmodifiable(_explosions);
  }

  void clearAll() {
    _explosions = <Explosion>[];
  }

  void reset() {
    _explosions = <Explosion>[];
    _counter = 0;
  }

  void clear() {
    clearAll();
  }

  void setExplosionRadius(double value) {
    _configuredRadius = value < 1 ? 1 : value;
  }
}
