import 'package:sky_defense/domain/entities/player_profile.dart';
import 'package:sky_defense/domain/entities/result.dart';
import 'package:sky_defense/domain/repositories/player_repository.dart';

class GetPlayerProfileUseCase {
  const GetPlayerProfileUseCase(this._repository);

  final PlayerRepository _repository;

  Future<Result<PlayerProfile>> call() {
    return _repository.getPlayerProfile();
  }
}
