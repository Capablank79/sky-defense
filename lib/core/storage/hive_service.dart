import 'package:hive_flutter/hive_flutter.dart';
import 'package:sky_defense/core/constants/app_constants.dart';
import 'package:sky_defense/core/storage/key_value_storage.dart';
import 'package:sky_defense/core/storage/migration_manager.dart';

class HiveService implements KeyValueStorage {
  HiveService._(this._box);

  final Box<dynamic> _box;

  static Future<HiveService> initialize() async {
    await Hive.initFlutter();
    final Box<dynamic> box =
        await Hive.openBox<dynamic>(AppConstants.hiveBoxName);
    await const MigrationManager().applyMigrations(box);
    return HiveService._(box);
  }

  @override
  T? read<T>(String key) {
    return _box.get(key) as T?;
  }

  @override
  Future<void> write<T>(String key, T value) async {
    await _box.put(key, value);
  }

  @override
  Future<void> writeAll(Map<String, dynamic> values) async {
    await _box.putAll(values);
  }
}
