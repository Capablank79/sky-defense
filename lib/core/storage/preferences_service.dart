import 'package:sky_defense/core/storage/key_value_storage.dart';

class PreferencesService {
  const PreferencesService(this._storage);

  final KeyValueStorage _storage;

  String? readString(String key) {
    return _storage.read<String>(key);
  }

  Future<void> writeString(String key, String value) {
    return _storage.write<String>(key, value);
  }
}
