import 'package:flutter/foundation.dart';
import 'package:sky_defense/core/constants/app_constants.dart';
import 'package:sky_defense/core/config/game_config_facade.dart';
import 'package:sky_defense/core/storage/key_value_storage.dart';
import 'package:sky_defense/domain/entities/player_economy.dart';
import 'package:sky_defense/domain/entities/player_profile.dart';
import 'package:sky_defense/domain/entities/player_progress.dart';
import 'package:sky_defense/domain/entities/player_settings.dart';

class SystemValidator {
  const SystemValidator(this._storage);

  final KeyValueStorage _storage;

  Future<bool> validate({
    required GameConfigFacade config,
  }) async {
    final bool migrationInProgress =
        (_storage.read<bool>(AppConstants.migrationInProgressKey)) ?? false;
    if (migrationInProgress) {
      debugPrint('SystemValidator: migration still in progress');
      return false;
    }

    if (!config.economy.isValid() ||
        !config.gameBalance.isValid() ||
        !config.retention.isValid()) {
      debugPrint('SystemValidator: invalid config facade');
      return false;
    }

    final Map<dynamic, dynamic> raw = _readMap(
      _storage.read<Map<dynamic, dynamic>>(AppConstants.playerDataKey),
    );
    if (raw.isEmpty) {
      return true;
    }

    final Map<dynamic, dynamic> progress = _readMap(raw['progress']);
    final Map<dynamic, dynamic> economy = _readMap(raw['economy']);
    final Map<dynamic, dynamic> settings = _readMap(raw['settings']);
    final PlayerProfile profile = PlayerProfile(
      progress: PlayerProgress(
        highScore: (progress['highScore'] as int?) ?? 0,
        totalSessions: (progress['totalSessions'] as int?) ?? 0,
        lastSessionEpochMs: (progress['lastSessionEpochMs'] as int?) ?? 0,
        progressLevel: (progress['progressLevel'] as int?) ?? 1,
        currentStreakDay: (progress['currentStreakDay'] as int?) ?? 1,
        lastRewardClaimEpochMs: (progress['lastRewardClaimEpochMs'] as int?) ?? 0,
      ),
      economy: PlayerEconomy(
        credits: (economy['credits'] as int?) ?? 0,
        premiumCredits: (economy['premiumCredits'] as int?) ?? 0,
      ),
      settings: PlayerSettings(
        soundEnabled: (settings['soundEnabled'] as bool?) ?? true,
        hapticEnabled: (settings['hapticEnabled'] as bool?) ?? true,
      ),
    );

    final bool isValid = profile.isValid(
      rules: PlayerSanitizationRules(
        maxCredits: config.economy.maxCredits,
        maxPremiumCredits: config.economy.maxPremiumCredits,
        maxHighScore: config.economy.maxHighScore,
        maxProgressLevel: config.economy.maxProgressLevel,
        maxStreakDay: config.retention.maxStreakDays,
      ),
    );

    if (!isValid) {
      debugPrint('SystemValidator: persisted player profile is outside valid ranges');
    }
    return isValid;
  }

  Map<dynamic, dynamic> _readMap(Object? value) {
    if (value is Map<dynamic, dynamic>) {
      return Map<dynamic, dynamic>.from(value);
    }
    if (value is Map) {
      return Map<dynamic, dynamic>.from(value);
    }
    return <dynamic, dynamic>{};
  }
}
