import 'dart:math';

import 'package:sky_defense/game/entities/wave.dart';
import 'package:sky_defense/game/debug/debug_flags.dart';

class WaveTick {
  const WaveTick({
    required this.spawnTrigger,
    required this.spawnCount,
    required this.currentDifficulty,
    required this.spawnIntervalSeconds,
    required this.enemyMissileSpeed,
    required this.interceptorMissileSpeed,
    required this.multiTargetProbability,
    required this.elapsedSeconds,
    required this.sessionEnded,
    required this.currentWave,
    required this.isWaveActive,
    required this.interWaveTimer,
    required this.missilesSpawned,
    required this.missilesDestroyed,
    required this.waveMissileCount,
  });

  final bool spawnTrigger;
  final int spawnCount;
  final double currentDifficulty;
  final double spawnIntervalSeconds;
  final double enemyMissileSpeed;
  final double interceptorMissileSpeed;
  final double multiTargetProbability;
  final double elapsedSeconds;
  final bool sessionEnded;
  final int currentWave;
  final bool isWaveActive;
  final double interWaveTimer;
  final int missilesSpawned;
  final int missilesDestroyed;
  final int waveMissileCount;
}

class WaveManager {
  WaveManager({
    this.sessionDurationSeconds = 120,
    this.startSpawnIntervalSeconds = 2.8,
    this.endSpawnIntervalSeconds = 0.45,
    this.baseEnemySpeed = 50,
    this.maxEnemySpeed = 350,
    this.speedStepSeconds = 15,
    this.speedStepRatio = 0.05,
  });

  final double sessionDurationSeconds;
  final double startSpawnIntervalSeconds;
  final double endSpawnIntervalSeconds;
  final double baseEnemySpeed;
  final double maxEnemySpeed;
  final double speedStepSeconds;
  final double speedStepRatio;
  int currentWave = 1;
  int missilesSpawned = 0;
  int missilesDestroyed = 0;
  bool isWaveActive = true;
  double interWaveTimer = 0;
  double _elapsedSeconds = 0;
  double _spawnAccumulator = 0;

  double get initialEnemySpeed => baseEnemySpeed;
  double get initialInterceptorSpeed => baseEnemySpeed * 3;

  Wave get currentWaveConfig => _buildWave(currentWave);

  void setWaveForDebugStart(int wave) {
    if (!kDebugFastFail) {
      return;
    }
    currentWave = wave < 1 ? 1 : wave;
    missilesSpawned = 0;
    missilesDestroyed = 0;
    isWaveActive = true;
    interWaveTimer = 0;
    _spawnAccumulator = 0;
  }

  WaveTick update({
    required double dtSeconds,
    required int activeMissiles,
    required int maxConcurrentThreats,
  }) {
    if (dtSeconds <= 0) {
      return _snapshot(spawnCount: 0);
    }

    _elapsedSeconds += dtSeconds;
    if (isWaveActive) {
      _spawnAccumulator += dtSeconds;
    }

    if (_elapsedSeconds >= sessionDurationSeconds) {
      return _snapshot(spawnCount: 0, sessionEnded: true);
    }

    int spawnCount = 0;
    final Wave wave = currentWaveConfig;

    if (isWaveActive) {
      while (_spawnAccumulator >= wave.spawnInterval &&
          missilesSpawned < wave.missileCount &&
          (activeMissiles + spawnCount) < maxConcurrentThreats) {
        _spawnAccumulator -= wave.spawnInterval;
        spawnCount += 1;
      }
      missilesSpawned += spawnCount;
      if (missilesSpawned >= wave.missileCount && activeMissiles == 0) {
        isWaveActive = false;
        interWaveTimer = 2.0;
      }
    } else {
      interWaveTimer -= dtSeconds;
      if (interWaveTimer <= 0) {
        _startNextWave();
      }
    }

    return _snapshot(spawnCount: spawnCount);
  }

  void onMissilesDestroyed(int count) {
    if (count <= 0) {
      return;
    }
    missilesDestroyed += count;
  }

  void reset() {
    currentWave = 1;
    missilesSpawned = 0;
    missilesDestroyed = 0;
    isWaveActive = true;
    interWaveTimer = 0;
    _elapsedSeconds = 0;
    _spawnAccumulator = 0;
  }

  WaveTick _snapshot({
    required int spawnCount,
    bool sessionEnded = false,
  }) {
    return WaveTick(
      spawnTrigger: spawnCount > 0,
      spawnCount: spawnCount,
      currentDifficulty: (_elapsedSeconds / sessionDurationSeconds).clamp(0, 1),
      spawnIntervalSeconds: currentWaveConfig.spawnInterval,
      enemyMissileSpeed:
          _currentEnemySpeed() * currentWaveConfig.speedMultiplier,
      interceptorMissileSpeed:
          (_currentEnemySpeed() * currentWaveConfig.speedMultiplier) * 3,
      multiTargetProbability:
          max(currentWaveConfig.splitProbability, _currentMirvProbability()),
      elapsedSeconds: _elapsedSeconds,
      sessionEnded: sessionEnded,
      currentWave: currentWave,
      isWaveActive: isWaveActive,
      interWaveTimer: interWaveTimer,
      missilesSpawned: missilesSpawned,
      missilesDestroyed: missilesDestroyed,
      waveMissileCount: currentWaveConfig.missileCount,
    );
  }

  double _currentEnemySpeed() {
    if (_elapsedSeconds <= 30) {
      return baseEnemySpeed;
    }
    final int level = ((_elapsedSeconds - 30) / speedStepSeconds).floor();
    final double speedMultiplier = baseEnemySpeed * speedStepRatio;
    final double speed = baseEnemySpeed + (level * speedMultiplier);
    return min(speed, maxEnemySpeed);
  }

  double _currentMirvProbability() {
    if (_elapsedSeconds < 60) {
      return 0;
    }
    final double ratio = ((_elapsedSeconds - 60) / 60).clamp(0, 1);
    return 0.2 * ratio;
  }

  Wave _buildWave(int waveNumber) {
    if (kDebugFastFail) {
      return const Wave(
        missileCount: 25,
        spawnInterval: 0.6,
        speedMultiplier: 1.5,
        splitProbability: 0.2,
      );
    }
    final int safeWave = waveNumber < 1 ? 1 : waveNumber;
    final int missileCount = 8 + (safeWave * 3);
    final double spawnInterval =
        max(0.35, startSpawnIntervalSeconds - ((safeWave - 1) * 0.12));
    final double speedMultiplier = 1 + ((safeWave - 1) * 0.1);
    final double splitProbability = min(0.2, (safeWave - 1) * 0.02);
    return Wave(
      missileCount: missileCount,
      spawnInterval: spawnInterval,
      speedMultiplier: speedMultiplier,
      splitProbability: splitProbability,
    );
  }

  void _startNextWave() {
    currentWave += 1;
    missilesSpawned = 0;
    missilesDestroyed = 0;
    isWaveActive = true;
    interWaveTimer = 0;
    _spawnAccumulator = 0;
  }
}
