import 'package:sky_defense/domain/entities/player_economy.dart';
import 'package:sky_defense/domain/entities/player_profile.dart';
import 'package:sky_defense/domain/entities/player_progress.dart';
import 'package:sky_defense/domain/entities/player_settings.dart';
import 'package:sky_defense/domain/entities/player_upgrades.dart';

class PlayerProfileModel extends PlayerProfile {
  const PlayerProfileModel({
    required super.progress,
    required super.economy,
    required super.settings,
    required super.upgrades,
  });

  factory PlayerProfileModel.empty() {
    return const PlayerProfileModel(
      progress: PlayerProgress(
        highScore: 0,
        totalSessions: 0,
        lastSessionEpochMs: 0,
        progressLevel: 1,
        currentStreakDay: 1,
        lastRewardClaimEpochMs: 0,
      ),
      economy: PlayerEconomy(
        credits: 0,
        premiumCredits: 0,
      ),
      settings: PlayerSettings(
        soundEnabled: true,
        hapticEnabled: true,
      ),
      upgrades: PlayerUpgrades.defaults,
    );
  }

  factory PlayerProfileModel.fromMap(Map<dynamic, dynamic> map) {
    final Map<dynamic, dynamic> progressMap =
        (map['progress'] as Map<dynamic, dynamic>?) ?? <dynamic, dynamic>{};
    final Map<dynamic, dynamic> economyMap =
        (map['economy'] as Map<dynamic, dynamic>?) ?? <dynamic, dynamic>{};
    final Map<dynamic, dynamic> settingsMap =
        (map['settings'] as Map<dynamic, dynamic>?) ?? <dynamic, dynamic>{};
    final Map<dynamic, dynamic> upgradesMap =
        (map['upgrades'] as Map<dynamic, dynamic>?) ?? <dynamic, dynamic>{};

    return PlayerProfileModel(
      progress: PlayerProgress(
        highScore: (progressMap['highScore'] as int?) ?? 0,
        totalSessions: (progressMap['totalSessions'] as int?) ?? 0,
        lastSessionEpochMs: (progressMap['lastSessionEpochMs'] as int?) ?? 0,
        progressLevel: (progressMap['progressLevel'] as int?) ?? 1,
        currentStreakDay: (progressMap['currentStreakDay'] as int?) ?? 1,
        lastRewardClaimEpochMs:
            (progressMap['lastRewardClaimEpochMs'] as int?) ?? 0,
      ),
      economy: PlayerEconomy(
        credits: (economyMap['credits'] as int?) ?? 0,
        premiumCredits: (economyMap['premiumCredits'] as int?) ?? 0,
      ),
      settings: PlayerSettings(
        soundEnabled: (settingsMap['soundEnabled'] as bool?) ?? true,
        hapticEnabled: (settingsMap['hapticEnabled'] as bool?) ?? true,
      ),
      upgrades: PlayerUpgrades(
        ammoLevel: (upgradesMap['ammoLevel'] as int?) ?? 1,
        reloadLevel: (upgradesMap['reloadLevel'] as int?) ?? 1,
        explosionRadiusLevel: (upgradesMap['explosionRadiusLevel'] as int?) ?? 1,
        interceptorSpeedLevel:
            (upgradesMap['interceptorSpeedLevel'] as int?) ?? 1,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'progress': <String, dynamic>{
        'highScore': progress.highScore,
        'totalSessions': progress.totalSessions,
        'lastSessionEpochMs': progress.lastSessionEpochMs,
        'progressLevel': progress.progressLevel,
        'currentStreakDay': progress.currentStreakDay,
        'lastRewardClaimEpochMs': progress.lastRewardClaimEpochMs,
      },
      'economy': <String, dynamic>{
        'credits': economy.credits,
        'premiumCredits': economy.premiumCredits,
      },
      'settings': <String, dynamic>{
        'soundEnabled': settings.soundEnabled,
        'hapticEnabled': settings.hapticEnabled,
      },
      'upgrades': <String, dynamic>{
        'ammoLevel': upgrades.ammoLevel,
        'reloadLevel': upgrades.reloadLevel,
        'explosionRadiusLevel': upgrades.explosionRadiusLevel,
        'interceptorSpeedLevel': upgrades.interceptorSpeedLevel,
      },
      'lastUpdatedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  factory PlayerProfileModel.fromEntity(PlayerProfile profile) {
    return PlayerProfileModel(
      progress: profile.progress,
      economy: profile.economy,
      settings: profile.settings,
      upgrades: profile.upgrades,
    );
  }
}
