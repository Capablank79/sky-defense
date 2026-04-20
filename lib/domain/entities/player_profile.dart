import 'package:sky_defense/core/config/economy_config.dart';
import 'package:sky_defense/core/config/retention_config.dart';
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

  factory PlayerSanitizationRules.fromConfig({
    required EconomyConfig economy,
    required RetentionConfig retention,
  }) {
    return PlayerSanitizationRules(
      maxCredits: economy.maxCredits,
      maxPremiumCredits: economy.maxPremiumCredits,
      maxHighScore: economy.maxHighScore,
      maxProgressLevel: economy.maxProgressLevel,
      maxStreakDay: retention.maxStreakDays,
    );
  }

  static final PlayerSanitizationRules defaults =
      PlayerSanitizationRules.fromConfig(
    economy: EconomyConfig.defaults,
    retention: RetentionConfig.defaults,
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
    PlayerSanitizationRules? rules,
  }) {
    final PlayerSanitizationRules safeRules =
        rules ?? PlayerSanitizationRules.defaults;
    return PlayerProfile(
      progress: progress.toSanitized(
        maxHighScore: safeRules.maxHighScore,
        maxProgressLevel: safeRules.maxProgressLevel,
        maxStreakDay: safeRules.maxStreakDay,
      ),
      economy: economy.toSanitized(
        maxCredits: safeRules.maxCredits,
        maxPremiumCredits: safeRules.maxPremiumCredits,
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
