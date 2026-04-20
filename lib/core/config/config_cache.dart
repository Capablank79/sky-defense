import 'package:sky_defense/core/config/game_config_facade.dart';

class ConfigCache {
  GameConfigFacade? _cachedFacade;

  GameConfigFacade? get facade => _cachedFacade;

  bool get hasValue => _cachedFacade != null;

  void setFacade(GameConfigFacade value) {
    _cachedFacade = value;
  }

  void clear() {
    _cachedFacade = null;
  }
}
