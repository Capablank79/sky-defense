import 'package:flutter_test/flutter_test.dart';
import 'package:sky_defense/game/debug/debug_flags.dart';
import 'package:sky_defense/game/engine/wave_manager.dart';

WaveTick _step(
  WaveManager manager, {
  double dt = 1,
  int activeMissiles = 0,
  int maxConcurrentThreats = 999,
}) {
  return manager.update(
    dtSeconds: dt,
    activeMissiles: activeMissiles,
    maxConcurrentThreats: maxConcurrentThreats,
    spawnMissile: (_) => true,
  );
}

WaveTick _advanceUntil(
  WaveManager manager,
  bool Function(WaveTick tick) predicate,
) {
  WaveTick tick = _step(manager);
  int guard = 0;
  while (!predicate(tick) && guard < 1000) {
    tick = _step(manager);
    guard += 1;
  }
  expect(guard < 1000, isTrue, reason: 'advanceUntil exceeded safety guard');
  return tick;
}

WaveManager _buildStableWaveManager() {
  return WaveManager(
    sessionDurationSeconds: 9999,
    startSpawnIntervalSeconds: 0.2,
    endSpawnIntervalSeconds: 0.2,
  )..reset();
}

void main() {
  test('normal wave emits completion metadata before transitioning', () {
    final WaveManager manager = _buildStableWaveManager();

    final WaveTick ended =
        _advanceUntil(manager, (WaveTick tick) => tick.waveJustEnded);

    expect(ended.completedPhaseNumber, 1);
    expect(ended.completedWaveNumber, 1);
    expect(ended.completedBossWave, isFalse);
  });

  test(
    'boss defeat emits boss completion metadata and advances phase',
    () {
      final WaveManager manager = _buildStableWaveManager();

      // Complete wave 1, 2 and 3 and start the next one each time.
      for (int i = 0; i < 3; i += 1) {
        _advanceUntil(manager, (WaveTick tick) => tick.waveJustEnded);
        _advanceUntil(manager, (WaveTick tick) => tick.waveJustStarted);
      }

      // Complete wave 4 and wait for boss start.
      _advanceUntil(manager, (WaveTick tick) => tick.waveJustEnded);
      final WaveTick bossStarted = _advanceUntil(
        manager,
        (WaveTick tick) => tick.waveJustStarted && tick.bossWave,
      );
      expect(bossStarted.phaseNumber, 1);
      expect(bossStarted.bossWave, isTrue);

      manager.onBossDefeated();
      final WaveTick bossEnded = _advanceUntil(
        manager,
        (WaveTick tick) =>
            tick.waveJustEnded && (tick.completedBossWave ?? false),
      );

      expect(bossEnded.completedPhaseNumber, 1);
      expect(bossEnded.completedWaveNumber, 4);
      expect(bossEnded.completedBossWave, isTrue);
      expect(bossEnded.phaseNumber, 2);
      expect(bossEnded.waveNumber, 1);
    },
    skip: kDebugFastFail,
  );

  test('fase 1 incrementa misiles y velocidad de 1-1 a 1-4', () {
    final WaveManager manager = _buildStableWaveManager();

    final WaveTick wave11 = _step(manager, dt: 0.01);
    final double speed11 = wave11.enemyMissileSpeed;
    final int missiles11 = wave11.waveMissileCount;

    _advanceUntil(manager, (WaveTick tick) => tick.waveJustEnded);
    _advanceUntil(manager, (WaveTick tick) => tick.waveJustStarted);
    final WaveTick wave12 = _step(manager, dt: 0.01);

    _advanceUntil(manager, (WaveTick tick) => tick.waveJustEnded);
    _advanceUntil(manager, (WaveTick tick) => tick.waveJustStarted);
    final WaveTick wave13 = _step(manager, dt: 0.01);

    _advanceUntil(manager, (WaveTick tick) => tick.waveJustEnded);
    _advanceUntil(manager, (WaveTick tick) => tick.waveJustStarted);
    final WaveTick wave14 = _step(manager, dt: 0.01);

    if (kDebugFastFail) {
      expect(missiles11, 4);
      expect(wave12.waveMissileCount, 4);
      expect(wave13.waveMissileCount, 4);
      expect(wave14.waveMissileCount, 4);
    } else {
      expect(missiles11, 6);
      expect(wave12.waveMissileCount, 9);
      expect(wave13.waveMissileCount, 12);
      expect(wave14.waveMissileCount, 15);
    }

    expect(wave12.enemyMissileSpeed, greaterThanOrEqualTo(speed11));
    expect(wave13.enemyMissileSpeed,
        greaterThanOrEqualTo(wave12.enemyMissileSpeed));
    expect(wave14.enemyMissileSpeed,
        greaterThanOrEqualTo(wave13.enemyMissileSpeed));
  });
}
