import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sky_defense/core/config/config_cache.dart';
import 'package:sky_defense/core/config/config_loader.dart';
import 'package:sky_defense/core/config/game_config_facade.dart';

class ConfigRuntime extends StateNotifier<AsyncValue<GameConfigFacade>> {
  ConfigRuntime({
    required ConfigLoader loader,
    required ConfigCache cache,
  })  : _loader = loader,
        _cache = cache,
        super(AsyncData(cache.facade ?? GameConfigFacade.defaults())) {
    if (!_cache.hasValue) {
      load();
    }
  }

  final ConfigLoader _loader;
  final ConfigCache _cache;

  Future<void> load({bool forceReload = false}) async {
    if (!forceReload && _cache.hasValue) {
      state = AsyncData(_cache.facade!);
      return;
    }

    state = const AsyncLoading();
    try {
      final GameConfigFacade facade =
          await _loader.loadFacade(forceReload: forceReload);
      _cache.setFacade(facade);
      state = AsyncData(facade);
    } catch (error, stackTrace) {
      debugPrint('ConfigRuntime.load failed: $error');
      state = AsyncError(error, stackTrace);
      final GameConfigFacade fallback = _cache.facade ?? GameConfigFacade.defaults();
      state = AsyncData(fallback);
    }
  }

  Future<void> reload() async {
    _cache.clear();
    await load(forceReload: true);
  }
}
