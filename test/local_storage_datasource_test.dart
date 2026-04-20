import 'package:flutter_test/flutter_test.dart';
import 'package:sky_defense/core/constants/app_constants.dart';
import 'package:sky_defense/core/storage/key_value_storage.dart';
import 'package:sky_defense/data/datasources/local_storage_datasource.dart';

class _InMemoryStorage implements KeyValueStorage {
  final Map<String, Object?> _values = <String, Object?>{};

  void seed(String key, Object? value) {
    _values[key] = value;
  }

  @override
  T? read<T>(String key) => _values[key] as T?;

  @override
  Future<void> write<T>(String key, T value) async {
    _values[key] = value;
  }

  @override
  Future<void> writeAll(Map<String, dynamic> values) async {
    _values.addAll(values);
  }
}

void main() {
  test('LocalStorageDataSource returns fallback map for corrupted payload', () {
    final _InMemoryStorage storage = _InMemoryStorage();
    storage.seed(AppConstants.playerDataKey, 'corrupted-string');
    final LocalStorageDataSource dataSource = LocalStorageDataSource(storage);

    final Map<String, dynamic> result = dataSource.readPlayerData();

    expect(result['progress'] is Map<String, dynamic>, true);
    expect(result['economy'] is Map<String, dynamic>, true);
    expect(result['settings'] is Map<String, dynamic>, true);
  });

  test('LocalStorageDataSource writes atomically and returns true', () async {
    final _InMemoryStorage storage = _InMemoryStorage();
    final LocalStorageDataSource dataSource = LocalStorageDataSource(storage);

    final bool ok = await dataSource.writePlayerData(<String, dynamic>{
      'progress': <String, dynamic>{'highScore': 1},
      'economy': <String, dynamic>{'credits': 5},
      'settings': <String, dynamic>{'soundEnabled': true},
    });

    expect(ok, true);
    expect(storage.read<Object>(AppConstants.playerDataKey) is Map, true);
  });
}
