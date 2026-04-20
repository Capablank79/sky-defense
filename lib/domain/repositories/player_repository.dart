import 'package:sky_defense/domain/entities/player_profile.dart';

abstract class PlayerRepository {
  Future<PlayerProfile> getPlayerProfile();
  Future<void> savePlayerProfile(PlayerProfile profile);
}
