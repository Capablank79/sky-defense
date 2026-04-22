import 'package:flutter_test/flutter_test.dart';
import 'package:sky_defense/domain/entities/player_economy.dart';
import 'package:sky_defense/domain/entities/player_profile.dart';
import 'package:sky_defense/domain/entities/player_progress.dart';
import 'package:sky_defense/domain/entities/result.dart';
import 'package:sky_defense/domain/entities/player_settings.dart';
import 'package:sky_defense/domain/entities/player_upgrades.dart';
import 'package:sky_defense/domain/repositories/player_repository.dart';
import 'package:sky_defense/domain/usecases/get_player_data_usecase.dart';

class _FakePlayerRepository implements PlayerRepository {
  _FakePlayerRepository(this._profile);

  final PlayerProfile _profile;

  @override
  Future<Result<PlayerProfile>> getPlayerProfile() async {
    return Success<PlayerProfile>(_profile);
  }

  @override
  Future<Result<void>> savePlayerProfile(PlayerProfile profile) async {
    return const Success<void>(null);
  }
}

void main() {
  test('GetPlayerDataUseCase sanitizes invalid values', () async {
    const PlayerProfile invalid = PlayerProfile(
      progress: PlayerProgress(
        highScore: -1,
        totalSessions: -2,
        lastSessionEpochMs: -3,
        progressLevel: 0,
        currentStreakDay: 0,
        lastRewardClaimEpochMs: -4,
      ),
      economy: PlayerEconomy(credits: -100, premiumCredits: -1),
      settings: PlayerSettings(soundEnabled: true, hapticEnabled: true),
      upgrades: PlayerUpgrades.defaults,
    );
    final GetPlayerDataUseCase useCase =
        GetPlayerDataUseCase(_FakePlayerRepository(invalid));

    final PlayerProfile safe = await useCase();

    expect(safe.progress.highScore, 0);
    expect(safe.progress.totalSessions, 0);
    expect(safe.progress.lastSessionEpochMs, 0);
    expect(safe.progress.progressLevel, 1);
    expect(safe.progress.currentStreakDay, 1);
    expect(safe.progress.lastRewardClaimEpochMs, 0);
    expect(safe.economy.credits, 0);
    expect(safe.economy.premiumCredits, 0);
  });
}
