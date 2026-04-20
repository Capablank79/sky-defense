class Wave {
  const Wave({
    required this.missileCount,
    required this.spawnInterval,
    required this.speedMultiplier,
    required this.splitProbability,
  });

  final int missileCount;
  final double spawnInterval;
  final double speedMultiplier;
  final double splitProbability;
}
