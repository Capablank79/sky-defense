import 'package:flutter_test/flutter_test.dart';
import 'package:sky_defense/domain/entities/player_economy.dart';
import 'package:sky_defense/domain/entities/player_profile.dart';
import 'package:sky_defense/domain/entities/player_progress.dart';
import 'package:sky_defense/domain/entities/player_settings.dart';
import 'package:sky_defense/domain/entities/player_upgrades.dart';
import 'package:sky_defense/domain/entities/result.dart';
import 'package:sky_defense/domain/repositories/player_repository.dart';
import 'package:sky_defense/domain/usecases/save_player_data_usecase.dart';

class _CaptureRepository implements PlayerRepository {
  PlayerProfile? lastSaved;

  @override
  Future<Result<PlayerProfile>> getPlayerProfile() async {
    return Success<PlayerProfile>(lastSaved ??
        const PlayerProfile(
          progress: PlayerProgress(
            highScore: 0,
            totalSessions: 0,
            lastSessionEpochMs: 0,
            progressLevel: 1,
            currentStreakDay: 1,
            lastRewardClaimEpochMs: 0,
          ),
          economy: PlayerEconomy(credits: 0, premiumCredits: 0),
          settings: PlayerSettings(soundEnabled: true, hapticEnabled: true),
          upgrades: PlayerUpgrades.defaults,
        ));
  }

  @override
  Future<Result<void>> savePlayerProfile(PlayerProfile profile) async {
    lastSaved = profile;
    return const Success<void>(null);
  }
}

void main() {
  test('SavePlayerDataUseCase sanitizes invalid values and returns success', () async {
    final _CaptureRepository repo = _CaptureRepository();
    final SavePlayerDataUseCase useCase = SavePlayerDataUseCase(repo);
    const PlayerProfile invalid = PlayerProfile(
      progress: PlayerProgress(
        highScore: -10,
        totalSessions: -5,
        lastSessionEpochMs: -1,
        progressLevel: -2,
        currentStreakDay: -1,
        lastRewardClaimEpochMs: -1,
      ),
      economy: PlayerEconomy(credits: -999, premiumCredits: -2),
      settings: PlayerSettings(soundEnabled: true, hapticEnabled: true),
      upgrades: PlayerUpgrades.defaults,
    );

    final Result<void> result = await useCase(invalid);

    expect(result is Success<void>, true);
    expect(repo.lastSaved?.economy.credits, 0);
    expect(repo.lastSaved?.progress.progressLevel, 1);
    expect(repo.lastSaved?.progress.currentStreakDay, 1);
  });

  test('SavePlayerDataUseCase clamps values beyond domain limits', () async {
    final _CaptureRepository repo = _CaptureRepository();
    final SavePlayerDataUseCase useCase = SavePlayerDataUseCase(repo);
    const PlayerProfile invalid = PlayerProfile(
      progress: PlayerProgress(
        highScore: 999999999,
        totalSessions: 10,
        lastSessionEpochMs: 1,
        progressLevel: 5000,
        currentStreakDay: 999,
        lastRewardClaimEpochMs: 1,
      ),
      economy: PlayerEconomy(credits: 999999999, premiumCredits: 999999),
      settings: PlayerSettings(soundEnabled: true, hapticEnabled: true),
      upgrades: PlayerUpgrades.defaults,
    );

    final Result<void> result = await useCase(invalid);

    expect(result is Success<void>, true);
    expect(repo.lastSaved?.economy.credits, lessThanOrEqualTo(9999999));
    expect(repo.lastSaved?.progress.progressLevel, lessThanOrEqualTo(999));
  });

  test('SavePlayerDataUseCase enforces logical timestamp consistency', () async {
    final _CaptureRepository repo = _CaptureRepository();
    final SavePlayerDataUseCase useCase = SavePlayerDataUseCase(
      repo,
      rules: const PlayerSanitizationRules(
        maxCredits: 1000,
        maxPremiumCredits: 100,
        maxHighScore: 10000,
        maxProgressLevel: 50,
        maxStreakDay: 7,
      ),
    );
    const PlayerProfile invalid = PlayerProfile(
      progress: PlayerProgress(
        highScore: 100,
        totalSessions: 10,
        lastSessionEpochMs: 1000,
        progressLevel: 2,
        currentStreakDay: 3,
        lastRewardClaimEpochMs: 2000,
      ),
      economy: PlayerEconomy(credits: 10, premiumCredits: 0),
      settings: PlayerSettings(soundEnabled: true, hapticEnabled: true),
      upgrades: PlayerUpgrades.defaults,
    );

    final Result<void> result = await useCase(invalid);

    expect(result is Success<void>, true);
    expect(
      repo.lastSaved?.progress.lastSessionEpochMs,
      greaterThanOrEqualTo(repo.lastSaved?.progress.lastRewardClaimEpochMs ?? 0),
    );
  });
}
