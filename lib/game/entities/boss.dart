import 'package:flame/components.dart';

enum BossState {
  intro,
  attackA,
  attackB,
}

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
  BossState state = BossState.intro;
  double stateTimerSeconds = 0;
  double targetedBurstTimerSeconds = 0;
  double fanSweepTimerSeconds = 0;
  double supportWaveTimerSeconds = 0;

  bool get isAlive => health > 0;
}
