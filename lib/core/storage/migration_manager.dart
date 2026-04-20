import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:sky_defense/core/config/economy_config.dart';
import 'package:sky_defense/core/config/retention_config.dart';
import 'package:sky_defense/core/constants/app_constants.dart';
import 'package:sky_defense/domain/entities/player_economy.dart';
import 'package:sky_defense/domain/entities/player_profile.dart';
import 'package:sky_defense/domain/entities/player_progress.dart';
import 'package:sky_defense/domain/entities/player_settings.dart';

class MigrationManager {
  const MigrationManager();

  static const int currentSchemaVersion = 2;

  Future<void> applyMigrations(Box<dynamic> box) async {
    final int storedVersion =
        (box.get(AppConstants.schemaVersionKey) as int?) ?? 0;
    final bool inProgress =
        (box.get(AppConstants.migrationInProgressKey) as bool?) ?? false;
    final Map<dynamic, dynamic> backupMap = _readMap(
      box.get(AppConstants.playerDataBackupKey),
    );
    Map<dynamic, dynamic> rollbackBackup =
        _isValidBackup(backupMap) ? backupMap : _fallbackPlayerMap();
    try {
      if (inProgress) {
        final Map<dynamic, dynamic> recovered =
            _isValidBackup(backupMap) ? backupMap : _fallbackPlayerMap();
        rollbackBackup = recovered;
        await box.putAll(<dynamic, dynamic>{
          AppConstants.playerDataKey: recovered,
          AppConstants.schemaVersionKey: storedVersion,
          AppConstants.migrationInProgressKey: false,
        });
      }

      final Map<dynamic, dynamic> original = _readMap(
        box.get(AppConstants.playerDataKey),
      );

      if (storedVersion >= currentSchemaVersion) {
        await box.putAll(<dynamic, dynamic>{
          AppConstants.playerDataKey: _sanitizeMigratedMap(
            _isValidBackup(original) ? original : _fallbackPlayerMap(),
          ),
          AppConstants.migrationInProgressKey: false,
        });
        return;
      }

      final Map<dynamic, dynamic> backup =
          _isValidBackup(original) ? original : _fallbackPlayerMap();
      rollbackBackup = backup;
      await box.putAll(<dynamic, dynamic>{
        AppConstants.migrationInProgressKey: true,
        AppConstants.playerDataBackupKey: backup,
      });

      Map<dynamic, dynamic> migrated = Map<dynamic, dynamic>.from(backup);
      int version = storedVersion;
      while (version < currentSchemaVersion) {
        switch (version) {
          case 0:
            migrated = _migrateToV1(migrated);
            break;
          case 1:
            migrated = _migrateToV2(migrated);
            break;
          default:
            throw StateError('Missing migration step for version $version');
        }
        version += 1;
      }

      final Map<dynamic, dynamic> sanitized = _sanitizeMigratedMap(migrated);
      await box.putAll(<dynamic, dynamic>{
        AppConstants.playerDataKey: sanitized,
        AppConstants.schemaVersionKey: currentSchemaVersion,
        AppConstants.migrationInProgressKey: false,
      });
    } catch (error) {
      debugPrint('MigrationManager.applyMigrations failed: $error');
      await box.putAll(<dynamic, dynamic>{
        AppConstants.playerDataBackupKey: rollbackBackup,
        AppConstants.playerDataKey: rollbackBackup,
        AppConstants.schemaVersionKey: storedVersion,
        AppConstants.migrationInProgressKey: false,
      });
    }
  }

  Map<dynamic, dynamic> _migrateToV1(Map<dynamic, dynamic> source) {
    final Object? progressRaw = source['progress'];
    final Object? economyRaw = source['economy'];
    final Object? settingsRaw = source['settings'];
    if (progressRaw != null && progressRaw is! Map) {
      throw const FormatException('Invalid progress payload');
    }
    if (economyRaw != null && economyRaw is! Map) {
      throw const FormatException('Invalid economy payload');
    }
    if (settingsRaw != null && settingsRaw is! Map) {
      throw const FormatException('Invalid settings payload');
    }

    final Map<dynamic, dynamic> progress =
        (progressRaw as Map<dynamic, dynamic>?) ?? <dynamic, dynamic>{};
    final Map<dynamic, dynamic> economy =
        (economyRaw as Map<dynamic, dynamic>?) ?? <dynamic, dynamic>{};
    final Map<dynamic, dynamic> settings =
        (settingsRaw as Map<dynamic, dynamic>?) ?? <dynamic, dynamic>{};

    return <dynamic, dynamic>{
      'progress': <dynamic, dynamic>{
        'highScore': progress['highScore'] ?? 0,
        'totalSessions': progress['totalSessions'] ?? 0,
        'lastSessionEpochMs': progress['lastSessionEpochMs'] ?? 0,
        'progressLevel': progress['progressLevel'] ?? 1,
      },
      'economy': <dynamic, dynamic>{
        'credits': economy['credits'] ?? 0,
        'premiumCredits': economy['premiumCredits'] ?? 0,
      },
      'settings': <dynamic, dynamic>{
        'soundEnabled': settings['soundEnabled'] ?? true,
        'hapticEnabled': settings['hapticEnabled'] ?? true,
      },
    };
  }

  Map<dynamic, dynamic> _migrateToV2(Map<dynamic, dynamic> source) {
    final Map<dynamic, dynamic> progress =
        (source['progress'] as Map<dynamic, dynamic>?) ?? <dynamic, dynamic>{};
    progress['currentStreakDay'] = progress['currentStreakDay'] ?? 1;
    progress['lastRewardClaimEpochMs'] =
        progress['lastRewardClaimEpochMs'] ?? 0;

    return <dynamic, dynamic>{
      ...source,
      'progress': progress,
    };
  }

  Map<dynamic, dynamic> _sanitizeMigratedMap(Map<dynamic, dynamic> source) {
    final Map<dynamic, dynamic> progress = Map<dynamic, dynamic>.from(
      (source['progress'] as Map<dynamic, dynamic>?) ?? <dynamic, dynamic>{},
    );
    final Map<dynamic, dynamic> economy = Map<dynamic, dynamic>.from(
      (source['economy'] as Map<dynamic, dynamic>?) ?? <dynamic, dynamic>{},
    );
    final Map<dynamic, dynamic> settings = Map<dynamic, dynamic>.from(
      (source['settings'] as Map<dynamic, dynamic>?) ?? <dynamic, dynamic>{},
    );

    final PlayerProfile profile = PlayerProfile(
      progress: PlayerProgress(
        highScore: (progress['highScore'] as int?) ?? 0,
        totalSessions: (progress['totalSessions'] as int?) ?? 0,
        lastSessionEpochMs: (progress['lastSessionEpochMs'] as int?) ?? 0,
        progressLevel: (progress['progressLevel'] as int?) ?? 1,
        currentStreakDay: (progress['currentStreakDay'] as int?) ?? 1,
        lastRewardClaimEpochMs:
            (progress['lastRewardClaimEpochMs'] as int?) ?? 0,
      ),
      economy: PlayerEconomy(
        credits: (economy['credits'] as int?) ?? 0,
        premiumCredits: (economy['premiumCredits'] as int?) ?? 0,
      ),
      settings: PlayerSettings(
        soundEnabled: (settings['soundEnabled'] as bool?) ?? true,
        hapticEnabled: (settings['hapticEnabled'] as bool?) ?? true,
      ),
    ).toSanitized(
      rules: PlayerSanitizationRules.fromConfig(
        economy: EconomyConfig.defaults,
        retention: RetentionConfig.defaults,
      ),
    );

    return <dynamic, dynamic>{
      'progress': <dynamic, dynamic>{
        'highScore': profile.progress.highScore,
        'totalSessions': profile.progress.totalSessions,
        'lastSessionEpochMs': profile.progress.lastSessionEpochMs,
        'progressLevel': profile.progress.progressLevel,
        'currentStreakDay': profile.progress.currentStreakDay,
        'lastRewardClaimEpochMs': profile.progress.lastRewardClaimEpochMs,
      },
      'economy': <dynamic, dynamic>{
        'credits': profile.economy.credits,
        'premiumCredits': profile.economy.premiumCredits,
      },
      'settings': <dynamic, dynamic>{
        'soundEnabled': profile.settings.soundEnabled,
        'hapticEnabled': profile.settings.hapticEnabled,
      },
    };
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

  bool _isValidBackup(Map<dynamic, dynamic> map) {
    if (map.isEmpty) {
      return false;
    }
    return map.containsKey('progress') &&
        map.containsKey('economy') &&
        map.containsKey('settings');
  }

  Map<dynamic, dynamic> _fallbackPlayerMap() {
    return <dynamic, dynamic>{
      'progress': <dynamic, dynamic>{
        'highScore': 0,
        'totalSessions': 0,
        'lastSessionEpochMs': 0,
        'progressLevel': 1,
        'currentStreakDay': 1,
        'lastRewardClaimEpochMs': 0,
      },
      'economy': <dynamic, dynamic>{
        'credits': 0,
        'premiumCredits': 0,
      },
      'settings': <dynamic, dynamic>{
        'soundEnabled': true,
        'hapticEnabled': true,
      },
    };
  }
}
