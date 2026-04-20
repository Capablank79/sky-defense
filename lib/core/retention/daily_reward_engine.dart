import 'package:sky_defense/core/config/retention_config.dart';

class DailyRewardEngine {
  const DailyRewardEngine(this._config);

  final RetentionConfig _config;

  int calculateDailyReward(int streakDay) {
    final int normalizedDay = streakDay.clamp(1, _config.maxStreakDays);
    return _config.dailyRewardBase + ((normalizedDay - 1) * _config.streakBonusStep);
  }

  int clampStreak(int streakDay) {
    return streakDay.clamp(1, _config.maxStreakDays);
  }
}

