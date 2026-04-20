import 'package:sky_defense/core/config/game_balance_config.dart';

class SpawnSystem {
  SpawnSystem(this._config);

  final GameBalanceConfig _config;
  double _elapsedSeconds = 0;

  bool shouldSpawn(double dtSeconds) {
    _elapsedSeconds += dtSeconds;
    if (_elapsedSeconds < _config.baseSpawnIntervalSeconds) {
      return false;
    }
    _elapsedSeconds = 0;
    return true;
  }
}


