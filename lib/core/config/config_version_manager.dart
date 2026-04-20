import 'package:sky_defense/core/config/config_base.dart';

class ConfigVersionManager {
  const ConfigVersionManager();

  bool isCompatible({
    required int expectedVersion,
    required int actualVersion,
  }) {
    return expectedVersion == actualVersion;
  }

  T resolveOrFallback<T extends VersionedConfig>({
    required T parsed,
    required T fallback,
  }) {
    if (!isCompatible(expectedVersion: fallback.version, actualVersion: parsed.version)) {
      return fallback;
    }
    return parsed;
  }
}
