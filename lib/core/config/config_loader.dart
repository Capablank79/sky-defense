import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sky_defense/core/config/config_base.dart';
import 'package:sky_defense/core/config/config_version_manager.dart';
import 'package:sky_defense/core/config/economy_config.dart';
import 'package:sky_defense/core/config/game_balance_config.dart';
import 'package:sky_defense/core/config/game_config_facade.dart';
import 'package:sky_defense/core/config/retention_config.dart';

typedef JsonAssetReader = Future<String> Function(String assetPath);

class ConfigLoader {
  ConfigLoader({
    JsonAssetReader? reader,
    ConfigVersionManager? versionManager,
  })  : _reader = reader ?? rootBundle.loadString,
        _versionManager = versionManager ?? const ConfigVersionManager();

  final JsonAssetReader _reader;
  final ConfigVersionManager _versionManager;
  final Map<String, Object> _cache = <String, Object>{};

  Future<GameConfigFacade> loadFacade({bool forceReload = false}) async {
    final EconomyConfig economy = await loadEconomy(forceReload: forceReload);
    final GameBalanceConfig gameBalance =
        await loadGameBalance(forceReload: forceReload);
    final RetentionConfig retention = await loadRetention(forceReload: forceReload);
    return GameConfigFacade(
      economy: economy,
      gameBalance: gameBalance,
      retention: retention,
    );
  }

  Future<EconomyConfig> loadEconomy({bool forceReload = false}) async {
    const String key = 'economy';
    final Object? cached = _cache[key];
    if (!forceReload && cached is EconomyConfig) {
      return cached;
    }

    final EconomyConfig loaded = await _readConfig<EconomyConfig>(
      path: 'assets/config/economy.json',
      fallback: EconomyConfig.defaults,
      parser: (Map<String, dynamic> map) => EconomyConfig.fromJson(map),
    );
    _cache[key] = loaded;
    return loaded;
  }

  Future<GameBalanceConfig> loadGameBalance({bool forceReload = false}) async {
    const String key = 'gameBalance';
    final Object? cached = _cache[key];
    if (!forceReload && cached is GameBalanceConfig) {
      return cached;
    }

    final GameBalanceConfig loaded = await _readConfig<GameBalanceConfig>(
      path: 'assets/config/game_balance.json',
      fallback: GameBalanceConfig.defaults,
      parser: (Map<String, dynamic> map) => GameBalanceConfig.fromJson(map),
    );
    _cache[key] = loaded;
    return loaded;
  }

  Future<RetentionConfig> loadRetention({bool forceReload = false}) async {
    const String key = 'retention';
    final Object? cached = _cache[key];
    if (!forceReload && cached is RetentionConfig) {
      return cached;
    }

    final RetentionConfig loaded = await _readConfig<RetentionConfig>(
      path: 'assets/config/retention.json',
      fallback: RetentionConfig.defaults,
      parser: (Map<String, dynamic> map) => RetentionConfig.fromJson(map),
    );
    _cache[key] = loaded;
    return loaded;
  }

  Future<T> _readConfig<T extends VersionedConfig>({
    required String path,
    required T fallback,
    required T Function(Map<String, dynamic> map) parser,
  }) async {
    try {
      final String raw = await _reader(path);
      final dynamic decoded = json.decode(raw);
      if (decoded is! Map<String, dynamic>) {
        return fallback;
      }
      final T parsed = parser(decoded);
      return _versionManager.resolveOrFallback(
        parsed: parsed,
        fallback: fallback,
      );
    } catch (error) {
      debugPrint('ConfigLoader._readConfig failed for $path: $error');
      return fallback;
    }
  }

  void clearCache() {
    _cache.clear();
  }
}
