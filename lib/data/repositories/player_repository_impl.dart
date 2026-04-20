import 'package:sky_defense/data/datasources/local_storage_datasource.dart';
import 'package:sky_defense/data/models/player_profile_model.dart';
import 'package:sky_defense/domain/entities/player_profile.dart';
import 'package:sky_defense/domain/entities/result.dart';
import 'package:sky_defense/domain/repositories/player_repository.dart';

class PlayerRepositoryImpl implements PlayerRepository {
  const PlayerRepositoryImpl(this._dataSource);

  final LocalStorageDataSource _dataSource;

  @override
  Future<Result<PlayerProfile>> getPlayerProfile() async {
    try {
      final Map<String, dynamic> map = _dataSource.readPlayerData();
      return Success<PlayerProfile>(PlayerProfileModel.fromMap(map));
    } catch (error) {
      return Failure<PlayerProfile>(
        'Unable to read player profile',
        error: error,
      );
    }
  }

  @override
  Future<Result<void>> savePlayerProfile(PlayerProfile profile) async {
    final bool ok = await _dataSource.writePlayerData(
      PlayerProfileModel.fromEntity(profile).toMap(),
    );
    if (!ok) {
      return const Failure<void>('Atomic player persistence failed');
    }
    return const Success<void>(null);
  }
}
