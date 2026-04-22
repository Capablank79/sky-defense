import 'package:flame/components.dart';

class Boss {
  Boss({
    required this.position,
    required this.health,
    required this.maxHealth,
    required this.velocityX,
    required this.fireCooldownSeconds,
  });

  Vector2 position;
  int health;
  int maxHealth;
  double velocityX;
  double fireCooldownSeconds;
  double fireTimerSeconds = 0;

  bool get isAlive => health > 0;
}
