import 'package:sky_defense/domain/entities/player_profile.dart';
import 'package:sky_defense/domain/entities/result.dart';
import 'package:sky_defense/domain/repositories/player_repository.dart';

class SavePlayerDataUseCase {
  SavePlayerDataUseCase(
    this._repository, {
    PlayerSanitizationRules? rules,
  }) : rules = rules ?? PlayerSanitizationRules.defaults;

  final PlayerRepository _repository;
  final PlayerSanitizationRules rules;

  Future<Result<void>> call(PlayerProfile profile) async {
    final PlayerProfile sanitized = profile.toSanitized(rules: rules);
    if (!sanitized.isValid(rules: rules)) {
      return const Failure<void>('Player data is invalid after sanitization');
    }
    return _repository.savePlayerProfile(sanitized);
  }
}
