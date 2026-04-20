import 'package:sky_defense/domain/entities/player_profile.dart';
import 'package:sky_defense/domain/repositories/player_repository.dart';

class SavePlayerProfileUseCase {
  const SavePlayerProfileUseCase(this._repository);

  final PlayerRepository _repository;

  Future<void> call(PlayerProfile profile) {
    return _repository.savePlayerProfile(profile);
  }
}
