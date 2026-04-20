import 'package:sky_defense/core/config/config_base.dart';

class RetentionConfig implements VersionedConfig {
  const RetentionConfig({
    required this.version,
    required this.dailyRewardBase,
    required this.streakBonusStep,
    required this.maxStreakDays,
    required this.maxAllowedTimeJumpDays,
  });

  @override
  final int version;
  final int dailyRewardBase;
  final int streakBonusStep;
  final int maxStreakDays;
  final int maxAllowedTimeJumpDays;

  bool isValid() {
    return version > 0 &&
        dailyRewardBase > 0 &&
        streakBonusStep >= 0 &&
        maxStreakDays > 0 &&
        maxAllowedTimeJumpDays > 0;
  }

  RetentionConfig validateConfig() {
    if (isValid()) {
      return this;
    }
    return defaults;
  }

  factory RetentionConfig.fromJson(Map<String, dynamic> json) {
    final RetentionConfig parsed = RetentionConfig(
      version: (json['version'] as num?)?.toInt() ?? defaults.version,
      dailyRewardBase:
          (json['dailyRewardBase'] as num?)?.toInt() ?? defaults.dailyRewardBase,
      streakBonusStep:
          (json['streakBonusStep'] as num?)?.toInt() ?? defaults.streakBonusStep,
      maxStreakDays: (json['maxStreakDays'] as num?)?.toInt() ?? defaults.maxStreakDays,
      maxAllowedTimeJumpDays:
          (json['maxAllowedTimeJumpDays'] as num?)?.toInt() ??
              defaults.maxAllowedTimeJumpDays,
    );
    return parsed.validateConfig();
  }

  static const RetentionConfig defaults = RetentionConfig(
    version: 1,
    dailyRewardBase: 50,
    streakBonusStep: 25,
    maxStreakDays: 7,
    maxAllowedTimeJumpDays: 21,
  );
}
