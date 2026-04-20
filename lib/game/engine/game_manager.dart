import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sky_defense/game/systems/collision_system.dart';
import 'package:sky_defense/game/systems/explosion_system.dart';
import 'package:sky_defense/game/systems/missile_system.dart';
import 'package:sky_defense/game/systems/spawn_system.dart';

enum GameState {
  initializing,
  ready,
  running,
  paused,
  gameOver,
}

class GameManager extends StateNotifier<GameState> {
  GameManager({
    required SpawnSystem spawnSystem,
    required MissileSystem missileSystem,
    required ExplosionSystem explosionSystem,
    required CollisionSystem collisionSystem,
  })  : _spawnSystem = spawnSystem,
        _missileSystem = missileSystem,
        _explosionSystem = explosionSystem,
        _collisionSystem = collisionSystem,
        super(GameState.initializing);

  final SpawnSystem _spawnSystem;
  final MissileSystem _missileSystem;
  final ExplosionSystem _explosionSystem;
  final CollisionSystem _collisionSystem;

  GameState get lifecycleState => state;

  void init() {
    state = GameState.initializing;
    state = GameState.ready;
  }

  void start() {
    if (state == GameState.ready || state == GameState.paused) {
      state = GameState.running;
    }
  }

  void pause() {
    if (state == GameState.running) {
      state = GameState.paused;
    }
  }

  void resume() {
    if (state == GameState.paused) {
      state = GameState.running;
    }
  }

  void end() {
    state = GameState.gameOver;
  }

  void update(double dtSeconds) {
    if (state != GameState.running) {
      return;
    }

    if (_spawnSystem.shouldSpawn(dtSeconds)) {
      _missileSystem.spawnMissile();
    }

    _missileSystem.update(dtSeconds);

    if (_collisionSystem.hasCollisionByDistance(_missileSystem.simulatedDistance)) {
      _missileSystem.clearOneMissile();
      _explosionSystem.createExplosionRadius();
      _explosionSystem.clearExplosion();
    }
  }
}
