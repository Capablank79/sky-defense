import 'package:sky_defense/core/config/config_base.dart';

class GameBalanceConfig implements VersionedConfig {
  const GameBalanceConfig({
    required this.version,
    required this.baseSpawnIntervalSeconds,
    required this.maxConcurrentThreats,
    required this.baseThreatSpeed,
    required this.baseExplosionRadius,
    required this.collisionTolerance,
  });

  @override
  final int version;
  final double baseSpawnIntervalSeconds;
  final int maxConcurrentThreats;
  final double baseThreatSpeed;
  final double baseExplosionRadius;
  final double collisionTolerance;

  bool isValid() {
    return version > 0 &&
        baseSpawnIntervalSeconds > 0 &&
        maxConcurrentThreats > 0 &&
        baseThreatSpeed > 0 &&
        baseExplosionRadius > 0 &&
        collisionTolerance > 0;
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
      maxConcurrentThreats:
          (json['maxConcurrentThreats'] as num?)?.toInt() ?? defaults.maxConcurrentThreats,
      baseThreatSpeed:
          (json['baseThreatSpeed'] as num?)?.toDouble() ?? defaults.baseThreatSpeed,
      baseExplosionRadius:
          (json['baseExplosionRadius'] as num?)?.toDouble() ?? defaults.baseExplosionRadius,
      collisionTolerance:
          (json['collisionTolerance'] as num?)?.toDouble() ?? defaults.collisionTolerance,
    );
    return parsed.validateConfig();
  }

  static const GameBalanceConfig defaults = GameBalanceConfig(
    version: 1,
    baseSpawnIntervalSeconds: 1.25,
    maxConcurrentThreats: 8,
    baseThreatSpeed: 1.0,
    baseExplosionRadius: 24.0,
    collisionTolerance: 8.0,
  );
}
