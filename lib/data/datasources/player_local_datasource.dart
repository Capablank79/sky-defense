import 'package:sky_defense/core/constants/app_constants.dart';
import 'package:sky_defense/core/storage/key_value_storage.dart';
import 'package:sky_defense/data/models/player_profile_model.dart';

class PlayerLocalDataSource {
  const PlayerLocalDataSource(this._storage);

  final KeyValueStorage _storage;

  Future<PlayerProfileModel> getPlayerProfile() async {
    final Map<dynamic, dynamic>? rawMap =
        _storage.read<Map<dynamic, dynamic>>(AppConstants.playerDataKey);

    if (rawMap == null) {
      return PlayerProfileModel.empty();
    }

    return PlayerProfileModel.fromMap(rawMap);
  }

  Future<void> savePlayerProfile(PlayerProfileModel model) async {
    await _storage.writeAll(<String, dynamic>{
      AppConstants.playerDataKey: model.toMap(),
    });
  }
}
