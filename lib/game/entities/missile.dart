import 'package:flame/components.dart';

class Missile {
  const Missile({
    required this.id,
    required this.x,
    required this.y,
    required this.origin,
    required this.target,
    required this.progress,
    required this.speed,
    required this.isActive,
  });

  final String id;
  final double x;
  final double y;
  final Vector2 origin;
  final Vector2 target;
  final double progress;
  final double speed;
  final bool isActive;

  Missile copyWith({
    String? id,
    double? x,
    double? y,
    Vector2? origin,
    Vector2? target,
    double? progress,
    double? speed,
    bool? isActive,
  }) {
    return Missile(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      origin: origin ?? this.origin,
      target: target ?? this.target,
      progress: progress ?? this.progress,
      speed: speed ?? this.speed,
      isActive: isActive ?? this.isActive,
    );
  }
}
