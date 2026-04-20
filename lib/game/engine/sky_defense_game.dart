import 'package:flame/game.dart';
import 'package:sky_defense/game/engine/game_manager.dart';

class SkyDefenseGame extends FlameGame {
  SkyDefenseGame(this._gameManager);

  final GameManager _gameManager;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _gameManager.init();
    _gameManager.start();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _gameManager.update(dt);
  }

  @override
  void onRemove() {
    _gameManager.end();
    super.onRemove();
  }
}
