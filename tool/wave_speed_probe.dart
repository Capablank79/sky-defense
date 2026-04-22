import 'dart:io';

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
  while (!predicate(tick) && guard < 2000) {
    tick = _step(manager);
    guard += 1;
  }
  if (guard >= 2000) {
    throw StateError('advanceUntil exceeded guard');
  }
  return tick;
}

void _printWaveSnapshot(WaveTick tick) {
  stdout.writeln(
    'Wave ${tick.phaseNumber}-${tick.waveNumber} | '
    'enemySpeed=${tick.enemyMissileSpeed.toStringAsFixed(3)} | '
    'interceptorSpeed=${tick.interceptorMissileSpeed.toStringAsFixed(3)} | '
    'missiles=${tick.waveMissileCount} | '
    'spawnInterval=${tick.spawnIntervalSeconds.toStringAsFixed(3)}',
  );
}

void main() {
  final WaveManager manager = WaveManager(
    sessionDurationSeconds: 9999,
    startSpawnIntervalSeconds: 1.25,
    endSpawnIntervalSeconds: 0.85,
    baseEnemySpeed: 50,
    speedStepSeconds: 2.0,
    speedStepRatio: 0.10,
  )..reset();

  stdout.writeln('--- Wave Speed Probe (Phase 1) ---');

  final WaveTick wave11 = _step(manager, dt: 0.01);
  _printWaveSnapshot(wave11);

  _advanceUntil(manager, (WaveTick tick) => tick.waveJustEnded);
  _advanceUntil(manager, (WaveTick tick) => tick.waveJustStarted);
  final WaveTick wave12 = _step(manager, dt: 0.01);
  _printWaveSnapshot(wave12);

  _advanceUntil(manager, (WaveTick tick) => tick.waveJustEnded);
  _advanceUntil(manager, (WaveTick tick) => tick.waveJustStarted);
  final WaveTick wave13 = _step(manager, dt: 0.01);
  _printWaveSnapshot(wave13);

  _advanceUntil(manager, (WaveTick tick) => tick.waveJustEnded);
  _advanceUntil(manager, (WaveTick tick) => tick.waveJustStarted);
  final WaveTick wave14 = _step(manager, dt: 0.01);
  _printWaveSnapshot(wave14);

  final double ratio = wave14.enemyMissileSpeed / wave11.enemyMissileSpeed;
  stdout.writeln('Speed ratio 1-4 / 1-1 = ${ratio.toStringAsFixed(3)}x');
}
