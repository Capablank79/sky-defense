import 'package:sky_defense/game/entities/explosion.dart';
import 'package:sky_defense/game/entities/missile.dart';

class CollisionResult {
  const CollisionResult({
    required this.missileId,
    required this.explosionId,
    required this.distanceSquared,
  });

  final String missileId;
  final String explosionId;
  final double distanceSquared;
}

class CollisionSystem {
  const CollisionSystem();

  List<CollisionResult> checkCollisions(
    List<Missile> missiles,
    List<Explosion> explosions,
  ) {
    final List<CollisionResult> results = <CollisionResult>[];

    for (final Missile missile in missiles) {
      if (!missile.isActive) {
        continue;
      }

      for (final Explosion explosion in explosions) {
        if (!explosion.isActive) {
          continue;
        }

        final double dx = missile.x - explosion.x;
        final double dy = missile.y - explosion.y;
        final double squaredDistance = (dx * dx) + (dy * dy);
        final double radiusSquared = explosion.radius * explosion.radius;
        if (squaredDistance <= radiusSquared) {
          results.add(
            CollisionResult(
              missileId: missile.id,
              explosionId: explosion.id,
              distanceSquared: squaredDistance,
            ),
          );
        }
      }
    }

    return results;
  }
}
