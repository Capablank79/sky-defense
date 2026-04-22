import 'package:sky_defense/core/config/config_base.dart';

class BossAttackPatternConfig {
  const BossAttackPatternConfig({
    required this.enabled,
    required this.cooldownSeconds,
    required this.windupSeconds,
    required this.shots,
    required this.shotSpacingSeconds,
    required this.speedMultiplier,
  });

  final bool enabled;
  final double cooldownSeconds;
  final double windupSeconds;
  final int shots;
  final double shotSpacingSeconds;
  final double speedMultiplier;

  bool isValid() {
    return cooldownSeconds > 0 &&
        windupSeconds >= 0 &&
        shots > 0 &&
        shotSpacingSeconds >= 0 &&
        speedMultiplier > 0;
  }
}

class BossSupportWaveConfig {
  const BossSupportWaveConfig({
    required this.enabled,
    required this.spawnIntervalSeconds,
    required this.maxConcurrentThreatsDuringBoss,
  });

  final bool enabled;
  final double spawnIntervalSeconds;
  final int maxConcurrentThreatsDuringBoss;

  bool isValid() {
    return spawnIntervalSeconds > 0 && maxConcurrentThreatsDuringBoss > 0;
  }
}

class BossConfig {
  const BossConfig({
    required this.phaseBossWaveNumber,
    required this.hpBase,
    required this.moveSpeedX,
    required this.baseFireCooldownSeconds,
    required this.targetedBurst,
    required this.fanSweep,
    required this.supportWave,
    required this.bossKillScore,
  });

  final int phaseBossWaveNumber;
  final int hpBase;
  final double moveSpeedX;
  final double baseFireCooldownSeconds;
  final BossAttackPatternConfig targetedBurst;
  final BossAttackPatternConfig fanSweep;
  final BossSupportWaveConfig supportWave;
  final int bossKillScore;

  bool isValid() {
    return phaseBossWaveNumber >= 5 &&
        hpBase > 0 &&
        moveSpeedX > 0 &&
        baseFireCooldownSeconds > 0 &&
        targetedBurst.isValid() &&
        fanSweep.isValid() &&
        supportWave.isValid() &&
        bossKillScore >= 0;
  }

  factory BossConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return defaults;
    }
    final Map<String, dynamic> targetedBurstRaw =
        (json['attackPatterns'] as Map<String, dynamic>?)?['targetedBurst']
                as Map<String, dynamic>? ??
            const <String, dynamic>{};
    final Map<String, dynamic> fanSweepRaw =
        (json['attackPatterns'] as Map<String, dynamic>?)?['fanSweep']
                as Map<String, dynamic>? ??
            const <String, dynamic>{};
    final Map<String, dynamic> supportWaveRaw =
        json['supportWave'] as Map<String, dynamic>? ??
            const <String, dynamic>{};
    final BossConfig parsed = BossConfig(
      phaseBossWaveNumber:
          (json['phaseBossWaveNumber'] as num?)?.toInt() ??
              defaults.phaseBossWaveNumber,
      hpBase: (json['hpBase'] as num?)?.toInt() ?? defaults.hpBase,
      moveSpeedX:
          (json['moveSpeedX'] as num?)?.toDouble() ?? defaults.moveSpeedX,
      baseFireCooldownSeconds:
          (json['baseFireCooldownSeconds'] as num?)?.toDouble() ??
              defaults.baseFireCooldownSeconds,
      targetedBurst: BossAttackPatternConfig(
        enabled: (targetedBurstRaw['enabled'] as bool?) ??
            defaults.targetedBurst.enabled,
        cooldownSeconds: (targetedBurstRaw['cooldownSeconds'] as num?)
                ?.toDouble() ??
            defaults.targetedBurst.cooldownSeconds,
        windupSeconds: (targetedBurstRaw['windupSeconds'] as num?)?.toDouble() ??
            defaults.targetedBurst.windupSeconds,
        shots:
            (targetedBurstRaw['shots'] as num?)?.toInt() ?? defaults.targetedBurst.shots,
        shotSpacingSeconds:
            (targetedBurstRaw['shotSpacingSeconds'] as num?)?.toDouble() ??
                defaults.targetedBurst.shotSpacingSeconds,
        speedMultiplier:
            (targetedBurstRaw['speedMultiplier'] as num?)?.toDouble() ??
                defaults.targetedBurst.speedMultiplier,
      ),
      fanSweep: BossAttackPatternConfig(
        enabled: (fanSweepRaw['enabled'] as bool?) ?? defaults.fanSweep.enabled,
        cooldownSeconds: (fanSweepRaw['cooldownSeconds'] as num?)?.toDouble() ??
            defaults.fanSweep.cooldownSeconds,
        windupSeconds: (fanSweepRaw['windupSeconds'] as num?)?.toDouble() ??
            defaults.fanSweep.windupSeconds,
        shots: (fanSweepRaw['shots'] as num?)?.toInt() ?? defaults.fanSweep.shots,
        shotSpacingSeconds:
            (fanSweepRaw['shotSpacingSeconds'] as num?)?.toDouble() ??
                defaults.fanSweep.shotSpacingSeconds,
        speedMultiplier:
            (fanSweepRaw['speedMultiplier'] as num?)?.toDouble() ??
                defaults.fanSweep.speedMultiplier,
      ),
      supportWave: BossSupportWaveConfig(
        enabled: (supportWaveRaw['enabled'] as bool?) ?? defaults.supportWave.enabled,
        spawnIntervalSeconds:
            (supportWaveRaw['spawnIntervalSeconds'] as num?)?.toDouble() ??
                defaults.supportWave.spawnIntervalSeconds,
        maxConcurrentThreatsDuringBoss:
            (supportWaveRaw['maxConcurrentThreatsDuringBoss'] as num?)?.toInt() ??
                defaults.supportWave.maxConcurrentThreatsDuringBoss,
      ),
      bossKillScore:
          ((json['rewards'] as Map<String, dynamic>?)?['bossKillScore'] as num?)
                  ?.toInt() ??
              defaults.bossKillScore,
    );
    return parsed.isValid() ? parsed : defaults;
  }

  static const BossConfig defaults = BossConfig(
    phaseBossWaveNumber: 5,
    hpBase: 18,
    moveSpeedX: 82.0,
    baseFireCooldownSeconds: 2.2,
    targetedBurst: BossAttackPatternConfig(
      enabled: true,
      cooldownSeconds: 3.4,
      windupSeconds: 0.45,
      shots: 3,
      shotSpacingSeconds: 0.18,
      speedMultiplier: 0.95,
    ),
    fanSweep: BossAttackPatternConfig(
      enabled: true,
      cooldownSeconds: 5.2,
      windupSeconds: 0.6,
      shots: 5,
      shotSpacingSeconds: 0.12,
      speedMultiplier: 0.88,
    ),
    supportWave: BossSupportWaveConfig(
      enabled: true,
      spawnIntervalSeconds: 1.55,
      maxConcurrentThreatsDuringBoss: 6,
    ),
    bossKillScore: 120,
  );
}

class GameBalanceConfig implements VersionedConfig {
  const GameBalanceConfig({
    required this.version,
    required this.baseSpawnIntervalSeconds,
    required this.maxConcurrentThreats,
    required this.baseThreatSpeed,
    required this.endSpawnIntervalSeconds,
    required this.speedStepEveryWaves,
    required this.speedStepFactor,
    required this.baseExplosionRadius,
    required this.collisionTolerance,
    required this.boss,
  });

  @override
  final int version;
  final double baseSpawnIntervalSeconds;
  final int maxConcurrentThreats;
  final double baseThreatSpeed;
  final double endSpawnIntervalSeconds;
  final double speedStepEveryWaves;
  final double speedStepFactor;
  final double baseExplosionRadius;
  final double collisionTolerance;
  final BossConfig boss;

  bool isValid() {
    return version > 0 &&
        baseSpawnIntervalSeconds > 0 &&
        endSpawnIntervalSeconds > 0 &&
        endSpawnIntervalSeconds <= baseSpawnIntervalSeconds &&
        maxConcurrentThreats > 0 &&
        baseThreatSpeed > 0 &&
        speedStepEveryWaves > 0 &&
        speedStepFactor >= 0 &&
        baseExplosionRadius > 0 &&
        collisionTolerance > 0 &&
        boss.isValid();
  }

  GameBalanceConfig validateConfig() {
    if (isValid()) {
      return this;
    }
    return defaults;
  }

  factory GameBalanceConfig.fromJson(Map<String, dynamic> json) {
    final GameBalanceConfig parsed = GameBalanceConfig(
      version: (json['version'] as num?)?.toInt() ?? defaults.version,
      baseSpawnIntervalSeconds:
          (json['baseSpawnIntervalSeconds'] as num?)?.toDouble() ??
              defaults.baseSpawnIntervalSeconds,
      maxConcurrentThreats: (json['maxConcurrentThreats'] as num?)?.toInt() ??
          defaults.maxConcurrentThreats,
      baseThreatSpeed: (json['baseThreatSpeed'] as num?)?.toDouble() ??
          defaults.baseThreatSpeed,
      endSpawnIntervalSeconds:
          (json['endSpawnIntervalSeconds'] as num?)?.toDouble() ??
              defaults.endSpawnIntervalSeconds,
      speedStepEveryWaves: (json['speedStepEveryWaves'] as num?)?.toDouble() ??
          defaults.speedStepEveryWaves,
      speedStepFactor: (json['speedStepFactor'] as num?)?.toDouble() ??
          defaults.speedStepFactor,
      baseExplosionRadius: (json['baseExplosionRadius'] as num?)?.toDouble() ??
          defaults.baseExplosionRadius,
      collisionTolerance: (json['collisionTolerance'] as num?)?.toDouble() ??
          defaults.collisionTolerance,
      boss: BossConfig.fromJson(json['bossConfig'] as Map<String, dynamic>?),
    );
    return parsed.validateConfig();
  }

  static const GameBalanceConfig defaults = GameBalanceConfig(
    version: 1,
    baseSpawnIntervalSeconds: 1.25,
    maxConcurrentThreats: 8,
    baseThreatSpeed: 1.0,
    endSpawnIntervalSeconds: 0.85,
    speedStepEveryWaves: 2.0,
    speedStepFactor: 0.10,
    baseExplosionRadius: 24.0,
    collisionTolerance: 8.0,
    boss: BossConfig.defaults,
  );
}
