class Wave {
  const Wave({
    required this.phaseNumber,
    required this.waveNumber,
    required this.bossWave,
    required this.missileCount,
    required this.spawnInterval,
    required this.slowWeight,
    required this.mediumWeight,
    required this.fastWeight,
    required this.splitProbability,
    required this.zigzagProbability,
    required this.heavyProbability,
    required this.baseSpeedMultiplier,
    required this.bossHitPoints,
    required this.bossFireCooldown,
  });

  final int phaseNumber;
  final int waveNumber;
  final bool bossWave;
  final int missileCount;
  final double spawnInterval;
  final double slowWeight;
  final double mediumWeight;
  final double fastWeight;
  final double splitProbability;
  final double zigzagProbability;
  final double heavyProbability;
  final double baseSpeedMultiplier;
  final int bossHitPoints;
  final double bossFireCooldown;
}
