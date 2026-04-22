import 'dart:math';

import 'package:flame/components.dart';

enum MissileType {
  slow,
  medium,
  fast,
  split,
  zigzag,
  heavy,
  boss,
}

enum MissileTargetKind {
  base,
  city,
}

class Missile {
  Missile({
    required this.id,
    required this.targetBaseId,
    required this.targetKind,
    required this.type,
    required this.origin,
    required this.target,
    required this.speed,
    required this.hitPoints,
    required this.maxHitPoints,
    required this.isActive,
    this.splitRemaining = 0,
    this.hasSplit = false,
    this.hasArrived = false,
    this.zigzagAmplitude = 0,
    this.zigzagFrequency = 0,
  })  : position = origin.clone(),
        linearPosition = origin.clone(),
        velocity =
            _computeVelocity(origin: origin, target: target, speed: speed);

  final String id;
  String targetBaseId;
  MissileTargetKind targetKind;
  MissileType type;
  Vector2 origin;
  Vector2 target;
  Vector2 position;
  Vector2 linearPosition;
  Vector2 velocity;
  final double speed;
  int hitPoints;
  final int maxHitPoints;
  bool isActive;
  double ageSeconds = 0;
  int splitRemaining;
  bool hasSplit;
  bool hasArrived;
  double zigzagAmplitude;
  double zigzagFrequency;

  double get x => position.x;
  double get y => position.y;
  bool get isDestroyed => hitPoints <= 0;

  void update(double dtSeconds) {
    ageSeconds += dtSeconds;
    linearPosition.x += velocity.x * dtSeconds;
    linearPosition.y += velocity.y * dtSeconds;
    position.setFrom(linearPosition);
    if (type == MissileType.zigzag &&
        zigzagAmplitude > 0 &&
        zigzagFrequency > 0 &&
        velocity.length2 > 0.000001) {
      final Vector2 direction = velocity.normalized();
      final Vector2 perpendicular = Vector2(-direction.y, direction.x);
      final double offset = zigzagAmplitude * sin(ageSeconds * zigzagFrequency);
      position.x += perpendicular.x * offset;
      position.y += perpendicular.y * offset;
    }
  }

  void retarget({
    required String nextTargetBaseId,
    required MissileTargetKind nextTargetKind,
    required Vector2 nextTarget,
  }) {
    targetBaseId = nextTargetBaseId;
    targetKind = nextTargetKind;
    origin = linearPosition.clone();
    target = nextTarget.clone();
    linearPosition = origin.clone();
    position.setFrom(linearPosition);
    ageSeconds = 0;
    hasArrived = false;
    velocity =
        _computeVelocity(origin: linearPosition, target: target, speed: speed);
  }

  static Vector2 _computeVelocity({
    required Vector2 origin,
    required Vector2 target,
    required double speed,
  }) {
    final Vector2 direction = target - origin;
    if (direction.length2 <= 0.000001) {
      return Vector2.zero();
    }
    direction.normalize();
    return direction * speed;
  }
}
