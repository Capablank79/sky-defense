import 'dart:math';

import 'package:sky_defense/game/entities/wave.dart';
import 'package:sky_defense/game/debug/debug_flags.dart';

enum WaveState {
  spawning,
  waitingClear,
  countdown,
  boss,
}

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
    required this.phaseNumber,
    required this.waveNumber,
    required this.bossWave,
    required this.waveJustEnded,
    required this.waveJustStarted,
    required this.slowWeight,
    required this.mediumWeight,
    required this.fastWeight,
    required this.bossHitPoints,
    required this.splitProbability,
    required this.zigzagProbability,
    required this.heavyProbability,
    required this.bossFireCooldown,
    required this.completedPhaseNumber,
    required this.completedWaveNumber,
    required this.completedBossWave,
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
  final int phaseNumber;
  final int waveNumber;
  final bool bossWave;
  final bool waveJustEnded;
  final bool waveJustStarted;
  final double slowWeight;
  final double mediumWeight;
  final double fastWeight;
  final int bossHitPoints;
  final double splitProbability;
  final double zigzagProbability;
  final double heavyProbability;
  final double bossFireCooldown;
  final int? completedPhaseNumber;
  final int? completedWaveNumber;
  final bool? completedBossWave;
}

class WaveManager {
  WaveManager({
    this.sessionDurationSeconds = 120,
    this.startSpawnIntervalSeconds = 3.0,
    this.endSpawnIntervalSeconds = 1.2,
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
  static const double _baseIntervalSeconds = 3.0;
  static const int _baseMissilesPerWave = 6;
  int currentWave = 1;
  int phase = 1;
  int waveInPhase = 1;
  bool isBossPhase = false;
  WaveState _waveState = WaveState.spawning;
  int missilesSpawned = 0;
  int missilesDestroyed = 0;
  bool isWaveActive = true;
  double interWaveTimer = 0;
  double _elapsedSeconds = 0;
  double _spawnTimer = 0;
  double _spawnInterval = _baseIntervalSeconds;
  int _missilesPerWave = _baseMissilesPerWave;
  double _countdownTimer = 1.0;
  int _countdown = 3;
  double _adaptiveSpeedScale = 1.0;
  bool _bossDefeatedPending = false;
  WaveState? _lastLoggedState;
  List<double> _spawnPattern = <double>[];
  int _spawnPatternIndex = 0;

  int get phaseNumber => phase;
  int get waveNumber => waveInPhase;
  bool get bossWave => isBossPhase;

  double get initialEnemySpeed => baseEnemySpeed;
  double get initialInterceptorSpeed => baseEnemySpeed * 3;

  Wave get currentWaveConfig => _buildWave(currentWave);

  void setAdaptiveTuning({
    required double accuracy,
    required double basesLostRatio,
  }) {
    final double safeAccuracy = accuracy.clamp(0, 1);
    final double safeBasesLost = basesLostRatio.clamp(0, 1);
    _adaptiveSpeedScale =
        (1 + (safeAccuracy * 0.14) - (safeBasesLost * 0.08)).clamp(0.85, 1.3);
  }

  void setWaveForDebugStart(int wave) {
    if (!kDebugFastFail) {
      return;
    }
    final int safeWave = wave < 1 ? 1 : wave;
    final int phaseIndex = (safeWave - 1) ~/ 5;
    final int phaseStep = ((safeWave - 1) % 5) + 1;
    phase = phaseIndex + 1;
    // In debug fast-fail we always start from a spawnable wave.
    waveInPhase = phaseStep.clamp(1, 4);
    isBossPhase = false;
    _syncLegacyWaveIndex();
    _startWave();
  }

  void onBossDefeated() {
    _bossDefeatedPending = true;
  }

  WaveTick update({
    required double dtSeconds,
    required int activeMissiles,
    required int maxConcurrentThreats,
    required bool Function(WaveTick tick) spawnMissile,
  }) {
    if (dtSeconds <= 0) {
      return _snapshot(
        spawnCount: 0,
        waveJustEnded: false,
        waveJustStarted: false,
      );
    }

    _elapsedSeconds += dtSeconds;

    if (_elapsedSeconds >= sessionDurationSeconds) {
      return _snapshot(
        spawnCount: 0,
        sessionEnded: true,
        waveJustEnded: false,
        waveJustStarted: false,
      );
    }

    int spawnCount = 0;
    bool waveJustEnded = false;
    bool waveJustStarted = false;
    int? completedPhaseNumber;
    int? completedWaveNumber;
    bool? completedBossWave;

    _logStateIfChanged();
    switch (_waveState) {
      case WaveState.spawning:
        spawnCount = _updateSpawning(
          dtSeconds: dtSeconds,
          activeMissiles: activeMissiles,
          maxConcurrentThreats: maxConcurrentThreats,
          spawnMissile: spawnMissile,
        );
        break;
      case WaveState.waitingClear:
        final bool waveCompleted = missilesSpawned >= _missilesPerWave;
        final bool noThreatsLeft = activeMissiles == 0;
        if (waveCompleted && noThreatsLeft) {
          completedPhaseNumber = phase;
          completedWaveNumber = waveInPhase;
          completedBossWave = false;
          _startCountdown();
          _logStateIfChanged();
          waveJustEnded = true;
        }
        break;
      case WaveState.countdown:
        _updateCountdown(dtSeconds);
        if (interWaveTimer <= 0) {
          _startNextWaveOrBoss();
          _logStateIfChanged();
          waveJustStarted = true;
        }
        break;
      case WaveState.boss:
        if (_bossDefeatedPending) {
          _bossDefeatedPending = false;
          completedPhaseNumber = phase;
          completedWaveNumber = waveInPhase;
          completedBossWave = true;
          _onBossDefeated();

          // 🔥 FIX: prevent false wave start after boss death
          waveJustStarted = false;
          waveJustEnded = true;
        }
        break;
    }

    return _snapshot(
      spawnCount: spawnCount,
      waveJustEnded: waveJustEnded,
      waveJustStarted: waveJustStarted,
      completedPhaseNumber: completedPhaseNumber,
      completedWaveNumber: completedWaveNumber,
      completedBossWave: completedBossWave,
    );
  }

  void onMissilesDestroyed(int count) {
    if (count <= 0) {
      return;
    }
    missilesDestroyed += count;
  }

  void reset() {
    currentWave = 1;
    phase = 1;
    waveInPhase = 1;
    isBossPhase = false;
    _waveState = WaveState.spawning;
    missilesSpawned = 0;
    missilesDestroyed = 0;
    isWaveActive = true;
    interWaveTimer = 0;
    _elapsedSeconds = 0;
    _spawnTimer = 0;
    _spawnInterval = _baseIntervalSeconds;
    _missilesPerWave = _baseMissilesPerWave;
    _countdownTimer = 1.0;
    _countdown = 3;
    _bossDefeatedPending = false;
    _lastLoggedState = null;
    _spawnPattern = <double>[];
    _spawnPatternIndex = 0;
    _startWave();
  }

  WaveTick _snapshot({
    required int spawnCount,
    bool sessionEnded = false,
    required bool waveJustEnded,
    required bool waveJustStarted,
    int? completedPhaseNumber,
    int? completedWaveNumber,
    bool? completedBossWave,
  }) {
    final Wave wave = currentWaveConfig;
    return WaveTick(
      spawnTrigger: spawnCount > 0,
      spawnCount: spawnCount,
      currentDifficulty: (_elapsedSeconds / sessionDurationSeconds).clamp(0, 1),
      spawnIntervalSeconds: wave.spawnInterval,
      enemyMissileSpeed:
          _currentEnemySpeed() * wave.baseSpeedMultiplier * _adaptiveSpeedScale,
      interceptorMissileSpeed: (_currentEnemySpeed() *
              wave.baseSpeedMultiplier *
              _adaptiveSpeedScale) *
          3,
      multiTargetProbability: 0,
      elapsedSeconds: _elapsedSeconds,
      sessionEnded: sessionEnded,
      currentWave: currentWave,
      isWaveActive: isWaveActive,
      interWaveTimer: interWaveTimer,
      missilesSpawned: missilesSpawned,
      missilesDestroyed: missilesDestroyed,
      waveMissileCount: wave.missileCount,
      phaseNumber: wave.phaseNumber,
      waveNumber: wave.waveNumber,
      bossWave: wave.bossWave,
      waveJustEnded: waveJustEnded,
      waveJustStarted: waveJustStarted,
      slowWeight: wave.slowWeight,
      mediumWeight: wave.mediumWeight,
      fastWeight: wave.fastWeight,
      bossHitPoints: wave.bossHitPoints,
      splitProbability: wave.splitProbability,
      zigzagProbability: wave.zigzagProbability,
      heavyProbability: wave.heavyProbability,
      bossFireCooldown: wave.bossFireCooldown,
      completedPhaseNumber: completedPhaseNumber,
      completedWaveNumber: completedWaveNumber,
      completedBossWave: completedBossWave,
    );
  }

  double _currentEnemySpeed() {
    final double stepSpan = max(1.0, speedStepSeconds);
    final double steps = (currentWave - 1) / stepSpan;
    final double speedMultiplier = pow(1 + speedStepRatio, steps).toDouble();
    final double speed = baseEnemySpeed * speedMultiplier;
    return min(speed, maxEnemySpeed);
  }

  Wave _buildWave(int _) {
    if (kDebugFastFail) {
      // DEBUG MODE SHOULD NOT FORCE BOSS
      return Wave(
        phaseNumber: phase,
        waveNumber: waveInPhase,
        bossWave: false,
        missileCount: 4,
        spawnInterval: 2.5,
        slowWeight: 0.6,
        mediumWeight: 0.3,
        fastWeight: 0.1,
        splitProbability: 0,
        zigzagProbability: 0,
        heavyProbability: 0,
        baseSpeedMultiplier: 1,
        bossHitPoints: 5,
        bossFireCooldown: 2.5,
      );
    }
    if (isBossPhase) {
      return Wave(
        phaseNumber: phase,
        waveNumber: waveInPhase,
        bossWave: true,
        missileCount: 0,
        spawnInterval: 9999,
        slowWeight: 0.15,
        mediumWeight: 0.45,
        fastWeight: 0.4,
        splitProbability: min(0.35, 0.1 + (phase * 0.03)),
        zigzagProbability: min(0.3, 0.08 + (phase * 0.025)),
        heavyProbability: min(0.26, 0.06 + (phase * 0.02)),
        baseSpeedMultiplier: 1 + ((phase - 1) * 0.08),
        bossHitPoints: 7 + phase,
        bossFireCooldown: max(0.9, 2.2 - ((phase - 1) * 0.12)),
      );
    }
    final int safeWave = waveInPhase.clamp(1, 4);
    final double waveSpeedMultiplier = 1 + ((safeWave - 1) * 0.12);
    final double phaseSpeedMultiplier = 1 + ((phase - 1) * 0.08);
    final double baseSpeedMultiplier = waveSpeedMultiplier * phaseSpeedMultiplier;
    final double slowWeight = max(0.3, 0.62 - ((safeWave - 1) * 0.10));
    final double fastWeight = min(0.34, 0.10 + ((safeWave - 1) * 0.08));
    final double mediumWeight = max(0.1, 1 - slowWeight - fastWeight);
    final double splitProbability = min(0.22, 0.02 + ((safeWave - 1) * 0.02));
    final double zigzagProbability =
        min(0.2, 0.01 + ((safeWave - 1) * 0.03));
    final double heavyProbability =
        min(0.16, 0.01 + ((safeWave - 1) * 0.015) + ((phase - 1) * 0.012));
    return Wave(
      phaseNumber: phase,
      waveNumber: waveInPhase,
      bossWave: false,
      missileCount: _missilesPerWave,
      spawnInterval: _spawnInterval,
      slowWeight: slowWeight,
      mediumWeight: mediumWeight,
      fastWeight: fastWeight,
      splitProbability: splitProbability,
      zigzagProbability: zigzagProbability,
      heavyProbability: heavyProbability,
      baseSpeedMultiplier: baseSpeedMultiplier,
      bossHitPoints: 7 + phase,
      bossFireCooldown: max(0.9, 2.2 - ((phase - 1) * 0.12)),
    );
  }

  void _configureWave() {
    const int baseMissiles = _baseMissilesPerWave;

    const int wavesPerPhase = 4;
    final double withinPhaseProgress = wavesPerPhase <= 1
        ? 0
        : (waveInPhase - 1) / (wavesPerPhase - 1);
    final double intervalRange =
        (startSpawnIntervalSeconds - endSpawnIntervalSeconds);
    _spawnInterval =
        (startSpawnIntervalSeconds - (intervalRange * withinPhaseProgress))
            .clamp(endSpawnIntervalSeconds, startSpawnIntervalSeconds);
    _missilesPerWave = baseMissiles + ((waveInPhase - 1) * 3);

    final double phaseMultiplier = 1 + ((phase - 1) * speedStepRatio);
    _spawnInterval = (_spawnInterval / phaseMultiplier).clamp(
      endSpawnIntervalSeconds,
      startSpawnIntervalSeconds,
    );
  }

  int _updateSpawning({
    required double dtSeconds,
    required int activeMissiles,
    required int maxConcurrentThreats,
    required bool Function(WaveTick tick) spawnMissile,
  }) {
    final double safeDt = dtSeconds.clamp(0, 0.1);
    final double currentInterval = _currentSpawnInterval();
    if (activeMissiles >= maxConcurrentThreats) {
      // Keep cadence stable while blocked by cap, without triggering burst spawns.
      _spawnTimer = min(_spawnTimer, currentInterval * 0.95);
      return 0;
    }
    _spawnTimer += safeDt;
    if (_spawnTimer >= currentInterval && missilesSpawned < _missilesPerWave) {
      final bool spawned = spawnMissile(
        _snapshot(
          spawnCount: 1,
          waveJustEnded: false,
          waveJustStarted: false,
        ),
      );
      if (spawned) {
        missilesSpawned += 1;
        _spawnTimer = 0;
        _spawnPatternIndex += 1;
        if (missilesSpawned >= _missilesPerWave) {
          _waveState = WaveState.waitingClear;
          _logStateIfChanged();
        }
        return 1;
      }
    }
    return 0;
  }

  void _startNextWaveOrBoss() {
    // 🔥 FIX REAL

    // Si venimos de wave 4 → SIEMPRE boss
    if (waveInPhase >= 4 && !isBossPhase) {
      isBossPhase = true;
      _syncLegacyWaveIndex();
      _startBoss();
      return;
    }

    // Si estamos en boss → avanzar fase
    if (isBossPhase) {
      return; // el boss se maneja con onBossDefeated()
    }

    // Normal wave progression
    waveInPhase += 1;

    if (waveInPhase > 4) {
      waveInPhase = 4; // seguridad
    }

    _syncLegacyWaveIndex();
    _startWave();
  }

  void _startBoss() {
    _waveState = WaveState.boss;
    _logStateIfChanged();
    isWaveActive = true;
    interWaveTimer = 0;
    _spawnTimer = 0;
  }

  void _onBossDefeated() {
    phase += 1;
    waveInPhase = 1;
    isBossPhase = false;
    _syncLegacyWaveIndex();
    _startWave();
  }

  void _startWave() {
    _configureWave(); // 🔥 CRITICAL
    _spawnTimer = 0;
    missilesSpawned = 0;
    missilesDestroyed = 0;
    _spawnPattern = _generateSpawnPattern();
    _spawnPatternIndex = 0;
    _waveState = WaveState.spawning;
    _logStateIfChanged();
    isWaveActive = true;
    interWaveTimer = 0;
  }

  double _currentSpawnInterval() {
    if (_spawnPattern.isEmpty || _spawnPatternIndex >= _spawnPattern.length) {
      return _spawnInterval;
    }
    return _spawnPattern[_spawnPatternIndex].clamp(0.2, 8.0);
  }

  List<double> _generateSpawnPattern() {
    final List<double> pattern = <double>[];

    final int count = _missilesPerWave;
    final Random r = Random();
    final int safeWave = waveInPhase.clamp(1, 4);
    final double longPauseFactor = (1.8 - ((safeWave - 1) * 0.15)).clamp(1.2, 1.8);
    final double quickBurstChance = (0.3 + ((safeWave - 1) * 0.05)).clamp(0.3, 0.5);

    for (int i = 0; i < count; i++) {
      if (i % 5 == 0) {
        // pausa dramática
        pattern.add(_spawnInterval * longPauseFactor);
      } else if (r.nextDouble() < quickBurstChance) {
        // ráfaga rápida
        pattern.add(_spawnInterval * 0.4);
      } else {
        // normal variable
        pattern.add(_spawnInterval * (0.7 + r.nextDouble() * 0.8));
      }
    }

    return pattern;
  }

  void _startCountdown() {
    _waveState = WaveState.countdown;
    _logStateIfChanged();
    isWaveActive = false;
    _countdown = 3;
    _countdownTimer = 1.0;
    interWaveTimer = 3.0;
  }

  void _updateCountdown(double dtSeconds) {
    _countdownTimer -= dtSeconds;
    if (_countdownTimer <= 0) {
      _countdown -= 1;
      if (_countdown <= 0) {
        interWaveTimer = 0;
      } else {
        _countdownTimer = 1.0;
        interWaveTimer = _countdown.toDouble();
      }
    }
  }

  void _syncLegacyWaveIndex() {
    currentWave = ((phase - 1) * 5) + (isBossPhase ? 5 : waveInPhase);
  }

  void _logStateIfChanged() {
    if (_lastLoggedState == _waveState) {
      return;
    }
    _lastLoggedState = _waveState;
  }
}
