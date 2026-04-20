abstract class KeyValueStorage {
  T? read<T>(String key);
  Future<void> write<T>(String key, T value);
  Future<void> writeAll(Map<String, dynamic> values);
}
