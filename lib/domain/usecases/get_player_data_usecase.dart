import 'package:sky_defense/domain/entities/player_profile.dart';
import 'package:sky_defense/domain/repositories/player_repository.dart';

class GetPlayerDataUseCase {
  const GetPlayerDataUseCase(
    this._repository, {
    this.rules = PlayerSanitizationRules.defaults,
  });

  final PlayerRepository _repository;
  final PlayerSanitizationRules rules;

  Future<PlayerProfile> call() async {
    final PlayerProfile profile = await _repository.getPlayerProfile();
    return profile.toSanitized(rules: rules);
  }
}
