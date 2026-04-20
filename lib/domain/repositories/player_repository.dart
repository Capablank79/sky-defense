import 'package:sky_defense/domain/entities/player_profile.dart';
import 'package:sky_defense/domain/entities/result.dart';

abstract class PlayerRepository {
  Future<Result<PlayerProfile>> getPlayerProfile();
  Future<Result<void>> savePlayerProfile(PlayerProfile profile);
}
