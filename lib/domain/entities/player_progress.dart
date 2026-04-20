class PlayerProgress {
  const PlayerProgress({
    required this.highScore,
    required this.totalSessions,
    required this.lastSessionEpochMs,
    required this.progressLevel,
    required this.currentStreakDay,
    required this.lastRewardClaimEpochMs,
  });

  final int highScore;
  final int totalSessions;
  final int lastSessionEpochMs;
  final int progressLevel;
  final int currentStreakDay;
  final int lastRewardClaimEpochMs;

  bool isValid({
    required int maxHighScore,
    required int maxProgressLevel,
    required int maxStreakDay,
  }) {
    return highScore >= 0 &&
        totalSessions >= 0 &&
        lastSessionEpochMs >= 0 &&
        progressLevel > 0 &&
        progressLevel <= maxProgressLevel &&
        currentStreakDay > 0 &&
        currentStreakDay <= maxStreakDay &&
        lastRewardClaimEpochMs >= 0 &&
        lastSessionEpochMs >= lastRewardClaimEpochMs &&
        highScore <= maxHighScore;
  }

  PlayerProgress toSanitized({
    required int maxHighScore,
    required int maxProgressLevel,
    required int maxStreakDay,
  }) {
    final int safeLastSessionEpochMs = lastSessionEpochMs < 0 ? 0 : lastSessionEpochMs;
    final int safeLastRewardEpochMs = lastRewardClaimEpochMs < 0
        ? 0
        : (lastRewardClaimEpochMs > safeLastSessionEpochMs
            ? safeLastSessionEpochMs
            : lastRewardClaimEpochMs);
    return PlayerProgress(
      highScore: highScore.clamp(0, maxHighScore),
      totalSessions: totalSessions < 0 ? 0 : totalSessions,
      lastSessionEpochMs: safeLastSessionEpochMs,
      progressLevel: progressLevel.clamp(1, maxProgressLevel),
      currentStreakDay: currentStreakDay.clamp(1, maxStreakDay),
      lastRewardClaimEpochMs: safeLastRewardEpochMs,
    );
  }

  PlayerProgress copyWith({
    int? highScore,
    int? totalSessions,
    int? lastSessionEpochMs,
    int? progressLevel,
    int? currentStreakDay,
    int? lastRewardClaimEpochMs,
  }) {
    return PlayerProgress(
      highScore: highScore ?? this.highScore,
      totalSessions: totalSessions ?? this.totalSessions,
      lastSessionEpochMs: lastSessionEpochMs ?? this.lastSessionEpochMs,
      progressLevel: progressLevel ?? this.progressLevel,
      currentStreakDay: currentStreakDay ?? this.currentStreakDay,
      lastRewardClaimEpochMs: lastRewardClaimEpochMs ?? this.lastRewardClaimEpochMs,
    );
  }
}
