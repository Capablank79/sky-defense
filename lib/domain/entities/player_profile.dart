import 'package:sky_defense/domain/entities/player_economy.dart';
import 'package:sky_defense/domain/entities/player_progress.dart';
import 'package:sky_defense/domain/entities/player_settings.dart';

class PlayerSanitizationRules {
  const PlayerSanitizationRules({
    required this.maxCredits,
    required this.maxPremiumCredits,
    required this.maxHighScore,
    required this.maxProgressLevel,
    required this.maxStreakDay,
  });

  final int maxCredits;
  final int maxPremiumCredits;
  final int maxHighScore;
  final int maxProgressLevel;
  final int maxStreakDay;

  static const PlayerSanitizationRules defaults = PlayerSanitizationRules(
    maxCredits: 9999999,
    maxPremiumCredits: 99999,
    maxHighScore: 9999999,
    maxProgressLevel: 999,
    maxStreakDay: 365,
  );
}

class PlayerProfile {
  const PlayerProfile({
    required this.progress,
    required this.economy,
    required this.settings,
  });

  final PlayerProgress progress;
  final PlayerEconomy economy;
  final PlayerSettings settings;

  bool isValid({
    required PlayerSanitizationRules rules,
  }) {
    return progress.isValid(
          maxHighScore: rules.maxHighScore,
          maxProgressLevel: rules.maxProgressLevel,
          maxStreakDay: rules.maxStreakDay,
        ) &&
        economy.isValid(
          maxCredits: rules.maxCredits,
          maxPremiumCredits: rules.maxPremiumCredits,
        );
  }

  PlayerProfile toSanitized({
    PlayerSanitizationRules rules = PlayerSanitizationRules.defaults,
  }) {
    return PlayerProfile(
      progress: progress.toSanitized(
        maxHighScore: rules.maxHighScore,
        maxProgressLevel: rules.maxProgressLevel,
        maxStreakDay: rules.maxStreakDay,
      ),
      economy: economy.toSanitized(
        maxCredits: rules.maxCredits,
        maxPremiumCredits: rules.maxPremiumCredits,
      ),
      settings: settings,
    );
  }

  PlayerProfile copyWith({
    PlayerProgress? progress,
    PlayerEconomy? economy,
    PlayerSettings? settings,
  }) {
    return PlayerProfile(
      progress: progress ?? this.progress,
      economy: economy ?? this.economy,
      settings: settings ?? this.settings,
    );
  }
}
