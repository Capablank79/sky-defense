import 'package:sky_defense/domain/entities/player_profile.dart';
import 'package:sky_defense/domain/entities/player_settings.dart';
import 'package:sky_defense/domain/entities/player_progress.dart';
import 'package:sky_defense/domain/entities/player_economy.dart';
import 'package:sky_defense/domain/entities/result.dart';
import 'package:sky_defense/domain/repositories/player_repository.dart';

class GetPlayerDataUseCase {
  GetPlayerDataUseCase(
    this._repository, {
    PlayerSanitizationRules? rules,
  }) : rules = rules ?? PlayerSanitizationRules.defaults;

  final PlayerRepository _repository;
  final PlayerSanitizationRules rules;

  Future<PlayerProfile> call() async {
    final Result<PlayerProfile> result = await _repository.getPlayerProfile();
    if (result is Failure<PlayerProfile>) {
      return const PlayerProfile(
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
      ).toSanitized(rules: rules);
    }
    final PlayerProfile profile = (result as Success<PlayerProfile>).value ??
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
        );
    return profile.toSanitized(rules: rules);
  }
}
