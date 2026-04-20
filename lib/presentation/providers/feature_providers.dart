import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sky_defense/core/config/game_config_provider.dart';
import 'package:sky_defense/core/retention/daily_reward_engine.dart';
import 'package:sky_defense/core/retention/streak_engine.dart';
import 'package:sky_defense/core/config/economy_config.dart';
import 'package:sky_defense/domain/entities/player_economy.dart';
import 'package:sky_defense/domain/entities/player_profile.dart';
import 'package:sky_defense/domain/entities/player_progress.dart';
import 'package:sky_defense/domain/entities/result.dart';
import 'package:sky_defense/domain/entities/player_settings.dart';
import 'package:sky_defense/domain/usecases/get_player_data_usecase.dart';
import 'package:sky_defense/domain/usecases/save_player_data_usecase.dart';
import 'package:sky_defense/game/engine/game_manager.dart';
import 'package:sky_defense/game/engine/sky_defense_game.dart';
import 'package:sky_defense/presentation/providers/system_providers.dart';

final skyDefenseGameProvider = Provider<SkyDefenseGame>((Ref ref) {
  final GameManager gameManager = ref.watch(gameManagerProvider.notifier);
  return SkyDefenseGame(gameManager);
});

final playerProvider =
    StateNotifierProvider<PlayerController, AsyncValue<PlayerProfile>>(
  (Ref ref) => PlayerController(
    getPlayerDataUseCase: ref.watch(getPlayerDataUseCaseProvider),
    savePlayerDataUseCase: ref.watch(savePlayerDataUseCaseProvider),
    dailyRewardEngine: ref.watch(dailyRewardEngineProvider),
    streakEngine: ref.watch(streakEngineProvider),
    economyConfig: ref.watch(resolvedEconomyConfigProvider),
  ),
);

class PlayerController extends StateNotifier<AsyncValue<PlayerProfile>> {
  PlayerController({
    required GetPlayerDataUseCase getPlayerDataUseCase,
    required SavePlayerDataUseCase savePlayerDataUseCase,
    required DailyRewardEngine dailyRewardEngine,
    required StreakEngine streakEngine,
    required EconomyConfig economyConfig,
  })  : _getPlayerDataUseCase = getPlayerDataUseCase,
        _savePlayerDataUseCase = savePlayerDataUseCase,
        _dailyRewardEngine = dailyRewardEngine,
        _streakEngine = streakEngine,
        _economyConfig = economyConfig,
        super(const AsyncLoading());

  final GetPlayerDataUseCase _getPlayerDataUseCase;
  final SavePlayerDataUseCase _savePlayerDataUseCase;
  final DailyRewardEngine _dailyRewardEngine;
  final StreakEngine _streakEngine;
  final EconomyConfig _economyConfig;
  bool _initialized = false;

  Future<void> loadPlayerData() async {
    try {
      final PlayerProfile data = await _getPlayerDataUseCase();
      state = AsyncData(data);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> initializeIfNeeded() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    await loadPlayerData();
    final PlayerProfile current = state.value ?? _defaultProfile();
    if (current.progress.totalSessions == 0 &&
        current.progress.lastSessionEpochMs == 0 &&
        current.economy.credits == 0) {
      final PlayerProfile seeded = _defaultProfile();
      final Result<void> result = await _savePlayerDataUseCase(seeded);
      if (!result.isSuccess) {
        state = AsyncError(
          (result as Failure<void>).message,
          StackTrace.current,
        );
        return;
      }
      state = AsyncData(seeded);
    }
  }

  Future<void> savePlayerData(PlayerProfile profile) async {
    final Result<void> result = await _savePlayerDataUseCase(profile);
    if (result.isSuccess) {
      state = AsyncData(profile.toSanitized());
    } else {
      state = AsyncError((result as Failure<void>).message, StackTrace.current);
    }
  }

  Future<void> registerSession() async {
    final PlayerProfile current = state.value ?? _defaultProfile();

    final PlayerProfile updated = current.copyWith(
      progress: current.progress.copyWith(
        totalSessions: current.progress.totalSessions + 1,
        lastSessionEpochMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    final Result<void> result = await _savePlayerDataUseCase(updated);
    if (result.isSuccess) {
      state = AsyncData(updated.toSanitized());
    } else {
      state = AsyncError((result as Failure<void>).message, StackTrace.current);
    }
  }

  bool isDailyRewardAvailable(PlayerProfile profile, DateTime now) {
    final DateTime? lastClaim = profile.progress.lastRewardClaimEpochMs <= 0
        ? null
        : DateTime.fromMillisecondsSinceEpoch(profile.progress.lastRewardClaimEpochMs);
    final DateTime? lastSession = profile.progress.lastSessionEpochMs <= 0
        ? null
        : DateTime.fromMillisecondsSinceEpoch(profile.progress.lastSessionEpochMs);
    final TimeValidationResult validation = _streakEngine.validateTimeIntegrity(
      now: now,
      lastClaimDate: lastClaim,
      lastSessionDate: lastSession,
    );
    if (validation != TimeValidationResult.valid) {
      return false;
    }
    return _streakEngine.canClaimToday(lastClaimDate: lastClaim, now: now);
  }

  Future<int> claimDailyReward() async {
    final PlayerProfile current = state.value ?? _defaultProfile();
    final DateTime now = DateTime.now();
    final DateTime? lastClaim = current.progress.lastRewardClaimEpochMs <= 0
        ? null
        : DateTime.fromMillisecondsSinceEpoch(current.progress.lastRewardClaimEpochMs);
    final DateTime? lastSession = current.progress.lastSessionEpochMs <= 0
        ? null
        : DateTime.fromMillisecondsSinceEpoch(current.progress.lastSessionEpochMs);
    final TimeValidationResult validation = _streakEngine.validateTimeIntegrity(
      now: now,
      lastClaimDate: lastClaim,
      lastSessionDate: lastSession,
    );
    if (validation != TimeValidationResult.valid) {
      final PlayerProfile reset = current.copyWith(
        progress: current.progress.copyWith(currentStreakDay: 1),
      );
      final Result<void> resetResult = await _savePlayerDataUseCase(reset);
      if (resetResult.isSuccess) {
        state = AsyncData(reset.toSanitized());
      } else {
        state = AsyncError((resetResult as Failure<void>).message, StackTrace.current);
      }
      return 0;
    }

    if (!isDailyRewardAvailable(current, now)) {
      return 0;
    }

    final int streakDay = _streakEngine.nextStreakDay(
      currentStreakDay: current.progress.currentStreakDay,
      lastClaimDate: lastClaim,
      now: now,
    );
    final int safeStreak = _dailyRewardEngine.clampStreak(streakDay);
    final int reward = _dailyRewardEngine.calculateDailyReward(safeStreak);

    final PlayerProfile updated = current.copyWith(
      progress: current.progress.copyWith(
        currentStreakDay: safeStreak,
        lastRewardClaimEpochMs: now.millisecondsSinceEpoch,
      ),
      economy: current.economy.copyWith(
        credits: current.economy.credits + reward,
      ),
    );
    final Result<void> result = await _savePlayerDataUseCase(updated);
    if (result.isSuccess) {
      state = AsyncData(updated.toSanitized());
    } else {
      state = AsyncError((result as Failure<void>).message, StackTrace.current);
      return 0;
    }
    return reward;
  }

  Future<bool> spendCredits(int amount) async {
    if (amount <= 0) {
      return false;
    }
    final PlayerProfile current = state.value ?? _defaultProfile();
    if (current.economy.credits < amount) {
      return false;
    }
    final PlayerProfile updated = current.copyWith(
      economy: current.economy.copyWith(
        credits: current.economy.credits - amount,
      ),
    );
    final Result<void> result = await _savePlayerDataUseCase(updated);
    if (!result.isSuccess) {
      state = AsyncError((result as Failure<void>).message, StackTrace.current);
      return false;
    }
    state = AsyncData(updated.toSanitized());
    return true;
  }

  Future<bool> upgradeProgress() async {
    final PlayerProfile current = state.value ?? _defaultProfile();
    final int cost = _economyConfig.upgradeCostPerLevel;
    if (current.economy.credits < cost) {
      return false;
    }
    final PlayerProfile updated = current.copyWith(
      progress: current.progress.copyWith(
        progressLevel: current.progress.progressLevel + 1,
      ),
      economy: current.economy.copyWith(
        credits: current.economy.credits - cost,
      ),
    );
    final Result<void> result = await _savePlayerDataUseCase(updated);
    if (!result.isSuccess) {
      state = AsyncError((result as Failure<void>).message, StackTrace.current);
      return false;
    }
    state = AsyncData(updated.toSanitized());
    return true;
  }

  PlayerProfile _defaultProfile() {
    return PlayerProfile(
      progress: const PlayerProgress(
        highScore: 0,
        totalSessions: 0,
        lastSessionEpochMs: 0,
        progressLevel: 1,
        currentStreakDay: 1,
        lastRewardClaimEpochMs: 0,
      ),
      economy: PlayerEconomy(credits: _economyConfig.initialCredits, premiumCredits: 0),
      settings: const PlayerSettings(soundEnabled: true, hapticEnabled: true),
    );
  }
}
