import 'package:sky_defense/core/config/game_balance_config.dart';

class ExplosionSystem {
  ExplosionSystem(this._config);

  final GameBalanceConfig _config;
  int _activeExplosions = 0;

  int get activeExplosions => _activeExplosions;

  double createExplosionRadius() {
    _activeExplosions += 1;
    return _config.baseExplosionRadius;
  }

  void clearExplosion() {
    if (_activeExplosions == 0) {
      return;
    }
    _activeExplosions -= 1;
  }
}

