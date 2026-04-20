import 'package:sky_defense/core/config/retention_config.dart';

class DailyRewardClaimResult {
  const DailyRewardClaimResult({
    required this.claimed,
    required this.reward,
    required this.nextStreakDay,
  });

  final bool claimed;
  final int reward;
  final int nextStreakDay;
}

class DailyRewardEngine {
  const DailyRewardEngine(this._config);

  final RetentionConfig _config;

  bool isRewardAvailable({
    required DateTime now,
    required DateTime? lastClaimDate,
  }) {
    if (lastClaimDate == null) {
      return true;
    }
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime lastDay = DateTime(
      lastClaimDate.year,
      lastClaimDate.month,
      lastClaimDate.day,
    );
    return today.difference(lastDay).inDays >= 1;
  }

  DailyRewardClaimResult claimReward({
    required int currentStreakDay,
    required DateTime now,
    required DateTime? lastClaimDate,
    required int maxStreakDays,
  }) {
    if (!isRewardAvailable(now: now, lastClaimDate: lastClaimDate)) {
      return DailyRewardClaimResult(
        claimed: false,
        reward: 0,
        nextStreakDay: currentStreakDay.clamp(1, maxStreakDays),
      );
    }
    final int safeStreak = currentStreakDay.clamp(1, maxStreakDays);
    final int reward = calculateDailyReward(safeStreak);
    return DailyRewardClaimResult(
      claimed: true,
      reward: reward,
      nextStreakDay: safeStreak,
    );
  }

  int calculateDailyReward(int streakDay) {
    final int normalizedDay = streakDay.clamp(1, _config.maxStreakDays);
    return _config.dailyRewardBase + ((normalizedDay - 1) * _config.streakBonusStep);
  }

  int clampStreak(int streakDay) {
    return streakDay.clamp(1, _config.maxStreakDays);
  }
}

