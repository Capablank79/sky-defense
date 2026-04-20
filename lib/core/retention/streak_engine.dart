import 'package:sky_defense/core/config/retention_config.dart';

enum TimeValidationResult {
  valid,
  suspiciousClockRollback,
  suspiciousClockJump,
}

class StreakEngine {
  const StreakEngine(this._config);

  final RetentionConfig _config;

  bool canClaimToday({
    required DateTime? lastClaimDate,
    required DateTime now,
  }) {
    if (lastClaimDate == null) {
      return true;
    }

    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime last = DateTime(
      lastClaimDate.year,
      lastClaimDate.month,
      lastClaimDate.day,
    );
    return today.difference(last).inDays >= 1;
  }

  TimeValidationResult validateTimeIntegrity({
    required DateTime now,
    required DateTime? lastClaimDate,
    required DateTime? lastSessionDate,
  }) {
    if (lastClaimDate != null && now.isBefore(lastClaimDate)) {
      return TimeValidationResult.suspiciousClockRollback;
    }
    if (lastSessionDate != null && now.isBefore(lastSessionDate)) {
      return TimeValidationResult.suspiciousClockRollback;
    }

    if (lastSessionDate != null) {
      final int sessionDeltaDays = now
          .difference(DateTime(lastSessionDate.year, lastSessionDate.month, lastSessionDate.day))
          .inDays;
      if (sessionDeltaDays > _config.maxAllowedTimeJumpDays) {
        return TimeValidationResult.suspiciousClockJump;
      }
    }

    if (lastClaimDate != null) {
      final int claimDeltaDays = now
          .difference(DateTime(lastClaimDate.year, lastClaimDate.month, lastClaimDate.day))
          .inDays;
      if (claimDeltaDays > _config.maxAllowedTimeJumpDays) {
        return TimeValidationResult.suspiciousClockJump;
      }
    }

    return TimeValidationResult.valid;
  }

  int updateStreak({
    required int currentStreakDay,
    required DateTime now,
    required DateTime? lastClaimDate,
  }) {
    if (lastClaimDate == null) {
      return 1;
    }

    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime lastDay = DateTime(
      lastClaimDate.year,
      lastClaimDate.month,
      lastClaimDate.day,
    );
    final int dayDelta = today.difference(lastDay).inDays;
    if (dayDelta <= 0) {
      return currentStreakDay.clamp(1, _config.maxStreakDays);
    }
    if (dayDelta == 1) {
      final int incremented = currentStreakDay + 1;
      return incremented.clamp(1, _config.maxStreakDays);
    }
    return 1;
  }

  int nextStreakDay({
    required int currentStreakDay,
    required DateTime? lastClaimDate,
    required DateTime now,
  }) {
    return updateStreak(
      currentStreakDay: currentStreakDay,
      now: now,
      lastClaimDate: lastClaimDate,
    );
  }
}
