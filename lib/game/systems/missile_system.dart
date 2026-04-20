import 'package:sky_defense/core/config/game_balance_config.dart';

class MissileSystem {
  MissileSystem(this._config);

  final GameBalanceConfig _config;
  int _activeMissiles = 0;
  double _simulatedDistance = 0;

  int get activeMissiles => _activeMissiles;

  void spawnMissile() {
    if (_activeMissiles >= _config.maxConcurrentThreats) {
      return;
    }
    _activeMissiles += 1;
  }

  void clearOneMissile() {
    if (_activeMissiles == 0) {
      return;
    }
    _activeMissiles -= 1;
  }

  void update(double dtSeconds) {
    _simulatedDistance += _config.baseThreatSpeed * dtSeconds;
  }

  double get simulatedDistance => _simulatedDistance;
}


