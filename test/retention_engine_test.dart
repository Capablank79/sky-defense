import 'package:flutter_test/flutter_test.dart';
import 'package:sky_defense/core/config/retention_config.dart';
import 'package:sky_defense/core/retention/daily_reward_engine.dart';
import 'package:sky_defense/core/retention/streak_engine.dart';

void main() {
  test('Daily reward increases with streak and clamps at max', () {
    const RetentionConfig config = RetentionConfig.defaults;
    final DailyRewardEngine engine = DailyRewardEngine(config);

    expect(engine.calculateDailyReward(1), config.dailyRewardBase);
    expect(
      engine.calculateDailyReward(config.maxStreakDays + 10),
      config.dailyRewardBase + ((config.maxStreakDays - 1) * config.streakBonusStep),
    );
  });

  test('Streak engine blocks multiple claims in same day', () {
    const RetentionConfig config = RetentionConfig.defaults;
    final StreakEngine engine = StreakEngine(config);
    final DateTime now = DateTime(2026, 1, 10, 12);

    expect(engine.canClaimToday(lastClaimDate: now, now: now), false);
    expect(
      engine.canClaimToday(
        lastClaimDate: now.subtract(const Duration(days: 1)),
        now: now,
      ),
      true,
    );
  });

  test('Streak engine detects suspicious rollback and jump', () {
    const RetentionConfig config = RetentionConfig.defaults;
    final StreakEngine engine = StreakEngine(config);
    final DateTime now = DateTime(2026, 1, 10, 12);

    expect(
      engine.validateTimeIntegrity(
        now: now.subtract(const Duration(days: 1)),
        lastClaimDate: now,
        lastSessionDate: now,
      ),
      TimeValidationResult.suspiciousClockRollback,
    );

    expect(
      engine.validateTimeIntegrity(
        now: now.add(Duration(days: config.maxStreakDays * 4)),
        lastClaimDate: now,
        lastSessionDate: now,
      ),
      TimeValidationResult.suspiciousClockJump,
    );
  });
}
