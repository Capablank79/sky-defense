import 'package:sky_defense/data/datasources/player_local_datasource.dart';
import 'package:sky_defense/data/models/player_profile_model.dart';
import 'package:sky_defense/domain/entities/player_profile.dart';
import 'package:sky_defense/domain/repositories/player_repository.dart';

class PlayerRepositoryImpl implements PlayerRepository {
  const PlayerRepositoryImpl(this._localDataSource);

  final PlayerLocalDataSource _localDataSource;

  @override
  Future<PlayerProfile> getPlayerProfile() {
    return _localDataSource.getPlayerProfile();
  }

  @override
  Future<void> savePlayerProfile(PlayerProfile profile) {
    return _localDataSource
        .savePlayerProfile(PlayerProfileModel.fromEntity(profile));
  }
}
