import 'dart:math';

import 'package:flame/components.dart';
import 'package:sky_defense/game/entities/interceptor_missile.dart';

class InterceptorSystem {
  List<InterceptorMissile> _interceptors = <InterceptorMissile>[];
  int _counter = 0;

  InterceptorMissile launch({
    required String baseId,
    required double startX,
    required double startY,
    required double targetX,
    required double targetY,
    required double speed,
  }) {
    final InterceptorMissile interceptor = InterceptorMissile(
      id: 'interceptor_${_counter++}',
      x: startX,
      y: startY,
      origin: Vector2(startX, startY),
      target: Vector2(targetX, targetY),
      progress: 0,
      speed: speed,
      isActive: true,
      baseId: baseId,
    );
    _interceptors.add(interceptor);
    return interceptor;
  }

  void update(double dtSeconds) {
    for (int i = 0; i < _interceptors.length; i += 1) {
      final InterceptorMissile current = _interceptors[i];
      if (!current.isActive) {
        continue;
      }
      final double pathDx = current.target.x - current.origin.x;
      final double pathDy = current.target.y - current.origin.y;
      final double pathDistance = sqrt((pathDx * pathDx) + (pathDy * pathDy));
      if (pathDistance <= 0.0001) {
        _interceptors[i] = current.copyWith(
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
      _interceptors[i] = current.copyWith(
        progress: nextProgress,
        x: arrived ? current.target.x : nextX,
        y: arrived ? current.target.y : nextY,
      );
    }
  }

  List<InterceptorMissile> getInterceptors() {
    return List<InterceptorMissile>.unmodifiable(_interceptors);
  }

  List<InterceptorMissile> getArrivedInterceptors() {
    return List<InterceptorMissile>.unmodifiable(
      _interceptors
          .where((InterceptorMissile i) => i.isActive && i.progress >= 1),
    );
  }

  void removeInterceptor(String id) {
    _interceptors.removeWhere((InterceptorMissile i) => i.id == id);
  }

  void clearAll() {
    _interceptors = <InterceptorMissile>[];
  }

  void reset() {
    clearAll();
  }

  void clear() {
    clearAll();
  }
}
