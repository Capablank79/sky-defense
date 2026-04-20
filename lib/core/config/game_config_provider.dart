import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sky_defense/core/config/config_cache.dart';
import 'package:sky_defense/core/config/config_loader.dart';
import 'package:sky_defense/core/config/config_runtime.dart';
import 'package:sky_defense/core/config/economy_config.dart';
import 'package:sky_defense/core/config/game_balance_config.dart';
import 'package:sky_defense/core/config/game_config_facade.dart';
import 'package:sky_defense/core/config/retention_config.dart';

final configCacheProvider = Provider<ConfigCache>(
  (Ref ref) => ConfigCache(),
);

final configLoaderProvider = Provider<ConfigLoader>(
  (Ref ref) => ConfigLoader(),
);

final configRuntimeProvider =
    StateNotifierProvider<ConfigRuntime, AsyncValue<GameConfigFacade>>(
  (Ref ref) => ConfigRuntime(
    loader: ref.watch(configLoaderProvider),
    cache: ref.watch(configCacheProvider),
  ),
);

final gameConfigFacadeProvider = Provider<GameConfigFacade>(
  (Ref ref) => ref.watch(configRuntimeProvider).value ?? GameConfigFacade.defaults(),
);

final resolvedGameBalanceConfigProvider = Provider<GameBalanceConfig>(
  (Ref ref) => ref.watch(gameConfigFacadeProvider).gameBalance,
);

final resolvedEconomyConfigProvider = Provider<EconomyConfig>(
  (Ref ref) => ref.watch(gameConfigFacadeProvider).economy,
);

final resolvedRetentionConfigProvider = Provider<RetentionConfig>(
  (Ref ref) => ref.watch(gameConfigFacadeProvider).retention,
);
