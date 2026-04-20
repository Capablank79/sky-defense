import 'package:flame/components.dart';

class InterceptorMissile {
  const InterceptorMissile({
    required this.id,
    required this.x,
    required this.y,
    required this.origin,
    required this.target,
    required this.progress,
    required this.speed,
    required this.isActive,
    required this.baseId,
  });

  final String id;
  final double x;
  final double y;
  final Vector2 origin;
  final Vector2 target;
  final double progress;
  final double speed;
  final bool isActive;
  final String baseId;

  InterceptorMissile copyWith({
    String? id,
    double? x,
    double? y,
    Vector2? origin,
    Vector2? target,
    double? progress,
    double? speed,
    bool? isActive,
    String? baseId,
  }) {
    return InterceptorMissile(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      origin: origin ?? this.origin,
      target: target ?? this.target,
      progress: progress ?? this.progress,
      speed: speed ?? this.speed,
      isActive: isActive ?? this.isActive,
      baseId: baseId ?? this.baseId,
    );
  }
}
