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
      if (sessionDeltaDays > _config.maxStreakDays * 3) {
        return TimeValidationResult.suspiciousClockJump;
      }
    }

    if (lastClaimDate != null) {
      final int claimDeltaDays = now
          .difference(DateTime(lastClaimDate.year, lastClaimDate.month, lastClaimDate.day))
          .inDays;
      if (claimDeltaDays > _config.maxStreakDays * 3) {
        return TimeValidationResult.suspiciousClockJump;
      }
    }

    return TimeValidationResult.valid;
  }

  int nextStreakDay({
    required int currentStreakDay,
    required DateTime? lastClaimDate,
    required DateTime now,
  }) {
    if (lastClaimDate == null) {
      return 1;
    }

    final int dayDelta = DateTime(now.year, now.month, now.day)
        .difference(DateTime(lastClaimDate.year, lastClaimDate.month, lastClaimDate.day))
        .inDays;

    if (dayDelta <= 0) {
      return currentStreakDay.clamp(1, _config.maxStreakDays);
    }

    if (dayDelta == 1) {
      final int candidate = currentStreakDay + 1;
      return candidate > _config.maxStreakDays ? 1 : candidate;
    }

    return 1;
  }
}
