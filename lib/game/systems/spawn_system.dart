import 'dart:math';

class SpawnTrigger {
  const SpawnTrigger({
    required this.shouldSpawn,
    required this.count,
  });

  final bool shouldSpawn;
  final int count;
}

class SpawnSystem {
  SpawnSystem({
    required double spawnIntervalSeconds,
    required int maxConcurrentThreats,
    bool enableRandomness = false,
    double randomnessChance = 0.0,
    Random? random,
  })  : _spawnIntervalSeconds = spawnIntervalSeconds,
        _maxConcurrentThreats = maxConcurrentThreats,
        _enableRandomness = enableRandomness,
        _randomnessChance = randomnessChance,
        _random = random ?? Random();

  final double _spawnIntervalSeconds;
  final int _maxConcurrentThreats;
  final bool _enableRandomness;
  final double _randomnessChance;
  final Random _random;
  double _elapsedSeconds = 0;

  SpawnTrigger update(double dtSeconds, int activeMissiles) {
    if (dtSeconds <= 0) {
      return const SpawnTrigger(shouldSpawn: false, count: 0);
    }
    if (activeMissiles >= _maxConcurrentThreats) {
      return const SpawnTrigger(shouldSpawn: false, count: 0);
    }

    _elapsedSeconds += dtSeconds;
    if (_elapsedSeconds < _spawnIntervalSeconds) {
      return const SpawnTrigger(shouldSpawn: false, count: 0);
    }

    final int rawSpawnCount = _elapsedSeconds ~/ _spawnIntervalSeconds;
    _elapsedSeconds -= (rawSpawnCount * _spawnIntervalSeconds);
    final int availableSlots = _maxConcurrentThreats - activeMissiles;
    int spawnCount = rawSpawnCount > availableSlots ? availableSlots : rawSpawnCount;
    if (_enableRandomness &&
        spawnCount > 0 &&
        spawnCount < availableSlots &&
        _randomnessChance > 0 &&
        _random.nextDouble() < _randomnessChance) {
      spawnCount += 1;
    }
    return SpawnTrigger(shouldSpawn: spawnCount > 0, count: spawnCount);
  }
}
