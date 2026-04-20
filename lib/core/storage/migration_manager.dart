import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
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
    if (inProgress) {
      await box.putAll(<dynamic, dynamic>{
        AppConstants.playerDataKey: backupMap.isEmpty ? _fallbackPlayerMap() : backupMap,
        AppConstants.schemaVersionKey: storedVersion,
        AppConstants.migrationInProgressKey: false,
      });
    }
    final Map<dynamic, dynamic> original = _readMap(
      box.get(AppConstants.playerDataKey),
    );
    try {
      if (storedVersion >= currentSchemaVersion) {
        await box.put(AppConstants.migrationInProgressKey, false);
        return;
      }
      await box.putAll(<dynamic, dynamic>{
        AppConstants.migrationInProgressKey: true,
        AppConstants.playerDataBackupKey: original,
      });
      Map<dynamic, dynamic> migrated = Map<dynamic, dynamic>.from(original);

      final Map<int, Map<dynamic, dynamic> Function(Map<dynamic, dynamic>)> steps =
          <int, Map<dynamic, dynamic> Function(Map<dynamic, dynamic>)>{
        0: _migrateToV1,
        1: _migrateToV2,
      };

      int version = storedVersion;
      while (version < currentSchemaVersion) {
        final step = steps[version];
        if (step == null) {
          break;
        }
        migrated = Map<dynamic, dynamic>.from(step(migrated));
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
        AppConstants.playerDataBackupKey: original,
        AppConstants.playerDataKey: original.isEmpty
            ? (backupMap.isEmpty ? _fallbackPlayerMap() : backupMap)
            : original,
        AppConstants.schemaVersionKey: storedVersion,
        AppConstants.migrationInProgressKey: false,
      });
    }
  }

  Map<dynamic, dynamic> _migrateToV1(Map<dynamic, dynamic> source) {
    final Map<dynamic, dynamic> progress =
        (source['progress'] as Map<dynamic, dynamic>?) ??
            <dynamic, dynamic>{};
    final Map<dynamic, dynamic> economy =
        (source['economy'] as Map<dynamic, dynamic>?) ??
            <dynamic, dynamic>{};
    final Map<dynamic, dynamic> settings =
        (source['settings'] as Map<dynamic, dynamic>?) ??
            <dynamic, dynamic>{};

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
        (source['progress'] as Map<dynamic, dynamic>?) ??
            <dynamic, dynamic>{};
    progress['currentStreakDay'] = progress['currentStreakDay'] ?? 1;
    progress['lastRewardClaimEpochMs'] = progress['lastRewardClaimEpochMs'] ?? 0;

    return <dynamic, dynamic>{
      ...source,
      'progress': progress,
    };
  }

  Map<dynamic, dynamic> _sanitizeMigratedMap(Map<dynamic, dynamic> source) {
    final Map<dynamic, dynamic> progress =
        Map<dynamic, dynamic>.from(
          (source['progress'] as Map<dynamic, dynamic>?) ??
              <dynamic, dynamic>{},
        );
    final Map<dynamic, dynamic> economy =
        Map<dynamic, dynamic>.from(
          (source['economy'] as Map<dynamic, dynamic>?) ??
              <dynamic, dynamic>{},
        );
    final Map<dynamic, dynamic> settings =
        Map<dynamic, dynamic>.from(
          (source['settings'] as Map<dynamic, dynamic>?) ??
              <dynamic, dynamic>{},
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
    ).toSanitized();

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
