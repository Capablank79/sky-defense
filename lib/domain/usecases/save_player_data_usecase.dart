import 'package:sky_defense/domain/entities/player_profile.dart';
import 'package:sky_defense/domain/entities/result.dart';
import 'package:sky_defense/domain/repositories/player_repository.dart';

class SavePlayerDataUseCase {
  const SavePlayerDataUseCase(
    this._repository, {
    this.rules = PlayerSanitizationRules.defaults,
  });

  final PlayerRepository _repository;
  final PlayerSanitizationRules rules;

  Future<Result<void>> call(PlayerProfile profile) async {
    try {
      final PlayerProfile sanitized = profile.toSanitized(rules: rules);
      await _repository.savePlayerProfile(sanitized);
      return const Success<void>(null);
    } catch (error) {
      return Failure<void>('Unable to save player data', error: error);
    }
  }
}
