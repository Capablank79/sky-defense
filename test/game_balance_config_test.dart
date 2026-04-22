import 'package:flutter_test/flutter_test.dart';
import 'package:sky_defense/core/config/game_balance_config.dart';

void main() {
  test('GameBalanceConfig usa BossConfig defaults cuando no existe bossConfig', () {
    final GameBalanceConfig parsed = GameBalanceConfig.fromJson(
      <String, dynamic>{
        'version': 2,
        'baseSpawnIntervalSeconds': 1.25,
        'endSpawnIntervalSeconds': 0.85,
        'maxConcurrentThreats': 8,
        'baseThreatSpeed': 1.0,
        'speedStepEveryWaves': 2.0,
        'speedStepFactor': 0.10,
        'baseExplosionRadius': 24.0,
        'collisionTolerance': 8.0,
      },
    );

    expect(parsed.boss.hpBase, BossConfig.defaults.hpBase);
    expect(parsed.boss.phaseBossWaveNumber, BossConfig.defaults.phaseBossWaveNumber);
  });

  test('GameBalanceConfig parsea bossConfig valido', () {
    final GameBalanceConfig parsed = GameBalanceConfig.fromJson(
      <String, dynamic>{
        'version': 2,
        'baseSpawnIntervalSeconds': 1.25,
        'endSpawnIntervalSeconds': 0.85,
        'maxConcurrentThreats': 8,
        'baseThreatSpeed': 1.0,
        'speedStepEveryWaves': 2.0,
        'speedStepFactor': 0.10,
        'baseExplosionRadius': 24.0,
        'collisionTolerance': 8.0,
        'bossConfig': <String, dynamic>{
          'phaseBossWaveNumber': 5,
          'hpBase': 24,
          'moveSpeedX': 90.0,
          'baseFireCooldownSeconds': 2.1,
          'attackPatterns': <String, dynamic>{
            'targetedBurst': <String, dynamic>{
              'enabled': true,
              'cooldownSeconds': 3.0,
              'windupSeconds': 0.4,
              'shots': 4,
              'shotSpacingSeconds': 0.15,
              'speedMultiplier': 1.0,
            },
            'fanSweep': <String, dynamic>{
              'enabled': true,
              'cooldownSeconds': 4.5,
              'windupSeconds': 0.5,
              'shots': 5,
              'shotSpacingSeconds': 0.1,
              'speedMultiplier': 0.9,
            },
          },
          'supportWave': <String, dynamic>{
            'enabled': true,
            'spawnIntervalSeconds': 1.4,
            'maxConcurrentThreatsDuringBoss': 5,
          },
          'rewards': <String, dynamic>{
            'bossKillScore': 180,
          },
        },
      },
    );

    expect(parsed.boss.hpBase, 24);
    expect(parsed.boss.moveSpeedX, 90.0);
    expect(parsed.boss.targetedBurst.shots, 4);
    expect(parsed.boss.bossKillScore, 180);
  });
}
