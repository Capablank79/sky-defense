import 'package:sky_defense/core/config/game_balance_config.dart';

class CollisionSystem {
  const CollisionSystem(this._config);

  final GameBalanceConfig _config;

  bool hasCollision({
    required double sourceX,
    required double sourceY,
    required double targetX,
    required double targetY,
    double? customTolerance,
  }) {
    return checkCircularCollision(
      sourceX - targetX,
      sourceY - targetY,
      customTolerance ?? _config.collisionTolerance,
    );
  }

  bool hasCollisionByDistance(
    double distance, {
    double? customTolerance,
  }) {
    final double tolerance = customTolerance ?? _config.collisionTolerance;
    final double squaredDistance = distance * distance;
    return squaredDistance <= (tolerance * tolerance);
  }

  bool checkCircularCollision(
    double dx,
    double dy,
    double tolerance,
  ) {
    final double squaredDistance = (dx * dx) + (dy * dy);
    return squaredDistance <= (tolerance * tolerance);
  }
}

