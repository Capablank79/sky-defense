import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sky_defense/core/config/game_config_provider.dart';
import 'package:sky_defense/core/retention/daily_reward_engine.dart';
import 'package:sky_defense/core/retention/streak_engine.dart';
import 'package:sky_defense/core/localization/localization_service.dart';
import 'package:sky_defense/core/storage/hive_service.dart';
import 'package:sky_defense/core/storage/key_value_storage.dart';
import 'package:sky_defense/core/storage/preferences_service.dart';
import 'package:sky_defense/core/system/system_validator.dart';
import 'package:sky_defense/data/datasources/language_local_datasource.dart';
import 'package:sky_defense/data/datasources/player_local_datasource.dart';
import 'package:sky_defense/data/repositories/language_repository_impl.dart';
import 'package:sky_defense/data/repositories/player_repository_impl.dart';
import 'package:sky_defense/domain/repositories/language_repository.dart';
import 'package:sky_defense/domain/repositories/player_repository.dart';
import 'package:sky_defense/domain/entities/player_profile.dart';
import 'package:sky_defense/domain/usecases/get_player_data_usecase.dart';
import 'package:sky_defense/domain/usecases/get_saved_language_usecase.dart';
import 'package:sky_defense/domain/usecases/save_player_data_usecase.dart';
import 'package:sky_defense/domain/usecases/set_saved_language_usecase.dart';
import 'package:sky_defense/game/engine/game_manager.dart';
import 'package:sky_defense/game/systems/collision_system.dart';
import 'package:sky_defense/game/systems/explosion_system.dart';
import 'package:sky_defense/game/systems/missile_system.dart';
import 'package:sky_defense/game/systems/spawn_system.dart';

final keyValueStorageProvider = Provider<KeyValueStorage>(
  (Ref ref) => throw UnimplementedError('keyValueStorageProvider must be overridden'),
);

final preferencesServiceProvider = Provider<PreferencesService>(
  (Ref ref) => PreferencesService(ref.watch(keyValueStorageProvider)),
);

final hiveServiceProvider = Provider<HiveService>(
  (Ref ref) => ref.watch(keyValueStorageProvider) as HiveService,
);

final localizationServiceProvider = Provider<LocalizationService>(
  (Ref ref) => const LocalizationService(),
);

final systemValidatorProvider = Provider<SystemValidator>(
  (Ref ref) => SystemValidator(ref.watch(keyValueStorageProvider)),
);

final playerLocalDataSourceProvider = Provider<PlayerLocalDataSource>(
  (Ref ref) => PlayerLocalDataSource(ref.watch(keyValueStorageProvider)),
);

final languageLocalDataSourceProvider = Provider<LanguageLocalDataSource>(
  (Ref ref) => LanguageLocalDataSource(ref.watch(preferencesServiceProvider)),
);

final playerRepositoryProvider = Provider<PlayerRepository>(
  (Ref ref) => PlayerRepositoryImpl(ref.watch(playerLocalDataSourceProvider)),
);

final languageRepositoryProvider = Provider<LanguageRepository>(
  (Ref ref) => LanguageRepositoryImpl(ref.watch(languageLocalDataSourceProvider)),
);

final getPlayerDataUseCaseProvider = Provider<GetPlayerDataUseCase>(
  (Ref ref) {
    final economy = ref.watch(resolvedEconomyConfigProvider);
    final retention = ref.watch(resolvedRetentionConfigProvider);
    return GetPlayerDataUseCase(
      ref.watch(playerRepositoryProvider),
      rules: PlayerSanitizationRules(
        maxCredits: economy.maxCredits,
        maxPremiumCredits: economy.maxPremiumCredits,
        maxHighScore: economy.maxHighScore,
        maxProgressLevel: economy.maxProgressLevel,
        maxStreakDay: retention.maxStreakDays,
      ),
    );
  },
);

final savePlayerDataUseCaseProvider = Provider<SavePlayerDataUseCase>(
  (Ref ref) {
    final economy = ref.watch(resolvedEconomyConfigProvider);
    final retention = ref.watch(resolvedRetentionConfigProvider);
    return SavePlayerDataUseCase(
      ref.watch(playerRepositoryProvider),
      rules: PlayerSanitizationRules(
        maxCredits: economy.maxCredits,
        maxPremiumCredits: economy.maxPremiumCredits,
        maxHighScore: economy.maxHighScore,
        maxProgressLevel: economy.maxProgressLevel,
        maxStreakDay: retention.maxStreakDays,
      ),
    );
  },
);

final getSavedLanguageUseCaseProvider = Provider<GetSavedLanguageUseCase>(
  (Ref ref) => GetSavedLanguageUseCase(ref.watch(languageRepositoryProvider)),
);

final setSavedLanguageUseCaseProvider = Provider<SetSavedLanguageUseCase>(
  (Ref ref) => SetSavedLanguageUseCase(ref.watch(languageRepositoryProvider)),
);

final spawnSystemProvider = Provider<SpawnSystem>(
  (Ref ref) => SpawnSystem(ref.watch(resolvedGameBalanceConfigProvider)),
);

final missileSystemProvider = Provider<MissileSystem>(
  (Ref ref) => MissileSystem(ref.watch(resolvedGameBalanceConfigProvider)),
);

final explosionSystemProvider = Provider<ExplosionSystem>(
  (Ref ref) => ExplosionSystem(ref.watch(resolvedGameBalanceConfigProvider)),
);

final collisionSystemProvider = Provider<CollisionSystem>(
  (Ref ref) => CollisionSystem(ref.watch(resolvedGameBalanceConfigProvider)),
);

final gameManagerProvider = StateNotifierProvider<GameManager, GameState>(
  (Ref ref) => GameManager(
    spawnSystem: ref.watch(spawnSystemProvider),
    missileSystem: ref.watch(missileSystemProvider),
    explosionSystem: ref.watch(explosionSystemProvider),
    collisionSystem: ref.watch(collisionSystemProvider),
  ),
);

final dailyRewardEngineProvider = Provider<DailyRewardEngine>(
  (Ref ref) => DailyRewardEngine(ref.watch(resolvedRetentionConfigProvider)),
);

final streakEngineProvider = Provider<StreakEngine>(
  (Ref ref) => StreakEngine(ref.watch(resolvedRetentionConfigProvider)),
);
