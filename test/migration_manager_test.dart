import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sky_defense/core/constants/app_constants.dart';
import 'package:sky_defense/core/storage/migration_manager.dart';

void main() {
  test('MigrationManager migrates schema from v0 to v2 safely', () async {
    final Directory temp = await Directory.systemTemp.createTemp('sky_defense_migration_test');
    Hive.init(temp.path);

    final Box<dynamic> box = await Hive.openBox<dynamic>('migration_test_box');
    await box.put(
      AppConstants.playerDataKey,
      <dynamic, dynamic>{
        'progress': <dynamic, dynamic>{'highScore': -10},
        'economy': <dynamic, dynamic>{'credits': -5},
      },
    );
    await box.put(AppConstants.schemaVersionKey, 0);

    await const MigrationManager().applyMigrations(box);

    final int schema = (box.get(AppConstants.schemaVersionKey) as int?) ?? -1;
    final Map<dynamic, dynamic> migrated =
        Map<dynamic, dynamic>.from(box.get(AppConstants.playerDataKey) as Map<dynamic, dynamic>);
    final Map<dynamic, dynamic> progress =
        Map<dynamic, dynamic>.from(migrated['progress'] as Map<dynamic, dynamic>);
    final Map<dynamic, dynamic> economy =
        Map<dynamic, dynamic>.from(migrated['economy'] as Map<dynamic, dynamic>);
    final Map<dynamic, dynamic> backup = Map<dynamic, dynamic>.from(
      box.get(AppConstants.playerDataBackupKey) as Map<dynamic, dynamic>,
    );

    expect(schema, MigrationManager.currentSchemaVersion);
    expect(progress['currentStreakDay'], 1);
    expect(progress['lastRewardClaimEpochMs'], 0);
    expect(economy['credits'], 0);
    expect(backup.isNotEmpty, true);

    await box.close();
    await temp.delete(recursive: true);
  });

  test('MigrationManager handles corrupted stored payload without crash', () async {
    final Directory temp = await Directory.systemTemp.createTemp('sky_defense_migration_corrupt_test');
    Hive.init(temp.path);

    final Box<dynamic> box = await Hive.openBox<dynamic>('migration_corrupt_box');
    await box.put(AppConstants.playerDataKey, 'corrupted');
    await box.put(AppConstants.schemaVersionKey, 0);

    await const MigrationManager().applyMigrations(box);

    final int schema = (box.get(AppConstants.schemaVersionKey) as int?) ?? -1;
    final Object? payload = box.get(AppConstants.playerDataKey);

    expect(schema, MigrationManager.currentSchemaVersion);
    expect(payload is Map, true);

    await box.close();
    await temp.delete(recursive: true);
  });

  test('MigrationManager restores backup when migration step fails', () async {
    final Directory temp = await Directory.systemTemp.createTemp('sky_defense_migration_rollback_test');
    Hive.init(temp.path);

    final Box<dynamic> box = await Hive.openBox<dynamic>('migration_rollback_box');
    final Map<dynamic, dynamic> original = <dynamic, dynamic>{
      'progress': 'invalid-progress-shape',
      'economy': <dynamic, dynamic>{'credits': 50},
      'settings': <dynamic, dynamic>{'soundEnabled': true},
    };
    await box.put(AppConstants.playerDataKey, original);
    await box.put(AppConstants.schemaVersionKey, 0);

    await const MigrationManager().applyMigrations(box);

    final int schema = (box.get(AppConstants.schemaVersionKey) as int?) ?? -1;
    final Map<dynamic, dynamic> restored =
        Map<dynamic, dynamic>.from(box.get(AppConstants.playerDataKey) as Map<dynamic, dynamic>);
    final bool migrationInProgress =
        (box.get(AppConstants.migrationInProgressKey) as bool?) ?? true;

    expect(schema, 0);
    expect(restored['progress'], 'invalid-progress-shape');
    expect(migrationInProgress, false);

    await box.close();
    await temp.delete(recursive: true);
  });
}
