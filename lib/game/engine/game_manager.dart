import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sky_defense/game/entities/explosion.dart';
import 'package:sky_defense/game/entities/base.dart';
import 'package:sky_defense/game/entities/interceptor_missile.dart';
import 'package:sky_defense/game/entities/missile.dart';
import 'package:sky_defense/game/debug/debug_flags.dart';
import 'package:sky_defense/game/engine/wave_manager.dart';
import 'package:sky_defense/game/systems/collision_system.dart';
import 'package:sky_defense/game/systems/base_system.dart';
import 'package:sky_defense/game/systems/explosion_system.dart';
import 'package:sky_defense/game/systems/interceptor_system.dart';
import 'package:sky_defense/game/systems/missile_system.dart';

enum GameState {
  initializing,
  ready,
  running,
  paused,
  gameOver,
}

class GameSession {
  const GameSession({
    required this.gameState,
    required this.score,
    required this.missilesAlive,
    required this.remainingBases,
    required this.remainingInterceptors,
    required this.interceptorsPerBase,
    required this.currentWave,
    required this.isWaveActive,
    required this.isGameOver,
  });

  final GameState gameState;
  final int score;
  final int missilesAlive;
  final int remainingBases;
  final int remainingInterceptors;
  final List<int> interceptorsPerBase;
  final int currentWave;
  final bool isWaveActive;
  final bool isGameOver;

  GameSession copyWith({
    GameState? gameState,
    int? score,
    int? missilesAlive,
    int? remainingBases,
    int? remainingInterceptors,
    List<int>? interceptorsPerBase,
    int? currentWave,
    bool? isWaveActive,
    bool? isGameOver,
  }) {
    return GameSession(
      gameState: gameState ?? this.gameState,
      score: score ?? this.score,
      missilesAlive: missilesAlive ?? this.missilesAlive,
      remainingBases: remainingBases ?? this.remainingBases,
      remainingInterceptors:
          remainingInterceptors ?? this.remainingInterceptors,
      interceptorsPerBase: interceptorsPerBase ?? this.interceptorsPerBase,
      currentWave: currentWave ?? this.currentWave,
      isWaveActive: isWaveActive ?? this.isWaveActive,
      isGameOver: isGameOver ?? this.isGameOver,
    );
  }

  static const GameSession initial = GameSession(
    gameState: GameState.initializing,
    score: 0,
    missilesAlive: 0,
    remainingBases: 0,
    remainingInterceptors: 0,
    interceptorsPerBase: <int>[],
    currentWave: 1,
    isWaveActive: true,
    isGameOver: false,
  );
}

class GameManager extends StateNotifier<GameSession> {
  GameManager({
    required BaseSystem baseSystem,
    required MissileSystem missileSystem,
    required InterceptorSystem interceptorSystem,
    required ExplosionSystem explosionSystem,
    required CollisionSystem collisionSystem,
    required WaveManager waveManager,
    required int maxConcurrentThreats,
  })  : _baseSystem = baseSystem,
        _missileSystem = missileSystem,
        _interceptorSystem = interceptorSystem,
        _explosionSystem = explosionSystem,
        _collisionSystem = collisionSystem,
        _waveManager = waveManager,
        _maxConcurrentThreats = maxConcurrentThreats,
        _currentEnemySpeed = waveManager.initialEnemySpeed,
        _currentInterceptorSpeed = waveManager.initialInterceptorSpeed,
        super(GameSession.initial);

  final BaseSystem _baseSystem;
  final MissileSystem _missileSystem;
  final InterceptorSystem _interceptorSystem;
  final ExplosionSystem _explosionSystem;
  final CollisionSystem _collisionSystem;
  final WaveManager _waveManager;
  final int _maxConcurrentThreats;
  double _currentEnemySpeed;
  double _currentInterceptorSpeed;
  List<InterceptorMissile> _activeInterceptors = <InterceptorMissile>[];
  final Random _spawnRandom = Random();
  double _worldWidth = 0;
  double _worldHeight = 0;
  double _elapsedTime = 0;
  int _baseHitCounter = 0;
  int _explosionImpactCounter = 0;
  bool _debugWavePrimed = false;

  GameState get lifecycleState => state.gameState;
  bool get isGameOver => state.isGameOver;
  List<Missile> get visibleMissiles => _missileSystem.getMissiles();
  List<InterceptorMissile> get visibleInterceptors =>
      List<InterceptorMissile>.unmodifiable(_activeInterceptors);
  List<Base> get visibleBases => _baseSystem.getBases();
  List<Explosion> get visibleExplosions => _explosionSystem.getExplosions();
  double get elapsedTimeSeconds => _elapsedTime;
  int get baseHitCounter => _baseHitCounter;
  int get explosionImpactCounter => _explosionImpactCounter;
  static const int continueCostCredits = 100;

  void configureWorldBounds({
    required double width,
    required double height,
  }) {
    if (width <= 0 || height <= 0) {
      return;
    }
    _worldWidth = width;
    _worldHeight = height;
    if (_baseSystem.getBases().isEmpty) {
      _baseSystem.initializeBases(
        worldWidth: _worldWidth,
        worldHeight: _worldHeight,
      );
    }
  }

  bool launchInterceptorTo({
    required double x,
    required double y,
  }) {
    final Base? base = _baseSystem.getNearestActiveBase(x: x, y: y);
    if (base == null) {
      return false;
    }
    final bool consumed = _baseSystem.consumeInterceptor(base.id);
    if (!consumed) {
      return false;
    }
    _interceptorSystem.launch(
      baseId: base.id,
      startX: base.x,
      startY: base.y,
      targetX: x,
      targetY: y,
      speed: _currentInterceptorSpeed,
    );
    _activeInterceptors = _interceptorSystem.getInterceptors();
    return true;
  }

  void init() {
    _waveManager.reset();
    if (kDebugFastFail && !_debugWavePrimed) {
      _waveManager.setWaveForDebugStart(5);
      _debugWavePrimed = true;
    }
    _elapsedTime = 0;
    _baseHitCounter = 0;
    _explosionImpactCounter = 0;
    _activeInterceptors = <InterceptorMissile>[];
    state = state.copyWith(
      gameState: GameState.ready,
      score: 0,
      missilesAlive: 0,
      remainingBases: _baseSystem.getAliveBases().length,
      remainingInterceptors: _totalRemainingInterceptors(),
      interceptorsPerBase: _interceptorsPerBase(),
      currentWave: _waveManager.currentWave,
      isWaveActive: _waveManager.isWaveActive,
      isGameOver: false,
    );
    if (_worldWidth > 0 && _worldHeight > 0) {
      _baseSystem.initializeBases(
        worldWidth: _worldWidth,
        worldHeight: _worldHeight,
      );
    }
  }

  void start() {
    if (state.gameState == GameState.ready ||
        state.gameState == GameState.paused) {
      state = state.copyWith(gameState: GameState.running, isGameOver: false);
    }
  }

  void pause() {
    if (state.gameState == GameState.running) {
      state = state.copyWith(gameState: GameState.paused);
    }
  }

  void resume() {
    if (state.gameState == GameState.paused) {
      state = state.copyWith(gameState: GameState.running);
    }
  }

  void end() {
    state = state.copyWith(gameState: GameState.gameOver, isGameOver: true);
  }

  void continueGame() {
    if (!_canContinue()) {
      return;
    }
    _baseSystem.restoreBasesForContinue(healthRatio: 0.5);
    _activeInterceptors.clear();
    _missileSystem.reset();
    _interceptorSystem.reset();
    _explosionSystem.reset();
    state = state.copyWith(
      isGameOver: false,
      missilesAlive: 0,
      remainingBases: _baseSystem.getAliveBases().length,
      remainingInterceptors: _totalRemainingInterceptors(),
      interceptorsPerBase: _interceptorsPerBase(),
    );
    start();
  }

  void continueAfterGameOver() {
    continueGame();
  }

  void restartGame() {
    // Reset only internal systems/state; keep same GameManager/GameWidget instance.
    _waveManager.reset();
    _missileSystem.reset();
    _explosionSystem.reset();
    _interceptorSystem.reset();
    _baseSystem.reset();
    _activeInterceptors.clear();
    _elapsedTime = 0;
    _baseHitCounter = 0;
    _explosionImpactCounter = 0;
    state = GameSession.initial;
    init();
    start();
  }

  void update(double dtSeconds) {
    if (state.gameState != GameState.running || state.isGameOver) {
      return;
    }
    _elapsedTime += dtSeconds;
    _baseSystem.updateAmmo(dtSeconds);
    final List<Base> aliveBasesAtStart = _baseSystem.getAliveBases();
    if (aliveBasesAtStart.isEmpty) {
      end();
      return;
    }

    final WaveTick tick = _waveManager.update(
      dtSeconds: dtSeconds,
      activeMissiles: _missileSystem.getMissiles().length,
      maxConcurrentThreats: _maxConcurrentThreats,
    );
    _currentEnemySpeed = tick.enemyMissileSpeed;
    _currentInterceptorSpeed = tick.interceptorMissileSpeed;
    if (!tick.sessionEnded && tick.spawnCount > 0) {
      for (int i = 0; i < tick.spawnCount; i += 1) {
        _spawnEnemyMissile(_currentEnemySpeed);
        if (_spawnRandom.nextDouble() < tick.multiTargetProbability) {
          _spawnEnemyMissile(_currentEnemySpeed);
          _spawnEnemyMissile(_currentEnemySpeed);
        }
      }
    }

    _missileSystem.update(dtSeconds);
    final List<Missile> arrivedMissiles = _missileSystem.getArrivedMissiles();
    bool baseDamaged = false;
    for (final Missile missile in arrivedMissiles) {
      _baseSystem.damageBaseAtTarget(
        targetX: missile.target.x,
        targetY: missile.target.y,
      );
      _missileSystem.removeMissile(missile.id);
      baseDamaged = true;
    }
    _waveManager.onMissilesDestroyed(arrivedMissiles.length);

    _interceptorSystem.update(dtSeconds);
    _activeInterceptors = _interceptorSystem.getInterceptors();
    final List<InterceptorMissile> arrivedInterceptors =
        _interceptorSystem.getArrivedInterceptors();
    for (final InterceptorMissile interceptor in arrivedInterceptors) {
      _explosionSystem.createExplosion(
        (x: interceptor.target.x, y: interceptor.target.y),
      );
      _explosionImpactCounter += 1;
      _interceptorSystem.removeInterceptor(interceptor.id);
    }
    _activeInterceptors = _interceptorSystem.getInterceptors();

    _explosionSystem.update(dtSeconds);
    if (baseDamaged) {
      _baseHitCounter += 1;
    }

    final List<Missile> missiles = _missileSystem.getMissiles();
    final List<Explosion> explosions = _explosionSystem.getExplosions();

    final List<CollisionResult> collisions = _collisionSystem.checkCollisions(
      missiles,
      explosions,
    );
    if (collisions.isNotEmpty) {
      final Set<String> collidedMissileIds = <String>{};
      for (final collision in collisions) {
        collidedMissileIds.add(collision.missileId);
      }
      for (final String missileId in collidedMissileIds) {
        _missileSystem.removeMissile(missileId);
      }
      _waveManager.onMissilesDestroyed(collidedMissileIds.length);
      state = state.copyWith(score: state.score + collidedMissileIds.length);
    }

    final int missilesAlive = _missileSystem.getMissiles().length;
    final bool isGameOver = _baseSystem.getAliveBases().isEmpty;
    state = state.copyWith(
      missilesAlive: missilesAlive,
      remainingBases: _baseSystem.getAliveBases().length,
      remainingInterceptors: _totalRemainingInterceptors(),
      interceptorsPerBase: _interceptorsPerBase(),
      currentWave: tick.currentWave,
      isWaveActive: tick.isWaveActive,
      isGameOver: isGameOver,
      gameState: isGameOver ? GameState.gameOver : state.gameState,
    );
  }

  void _spawnEnemyMissile(double speed) {
    final List<Base> aliveBases = _baseSystem.getAliveBases();
    if (aliveBases.isEmpty) {
      return;
    }
    final Base targetBase = aliveBases[_spawnRandom.nextInt(aliveBases.length)];
    final double spawnX =
        _worldWidth > 0 ? _spawnRandom.nextDouble() * _worldWidth : 0;
    _missileSystem.spawnMissile(
      startX: spawnX,
      startY: 0,
      targetX: targetBase.x,
      targetY: targetBase.y,
      speed: speed,
    );
  }

  int _totalRemainingInterceptors() {
    int total = 0;
    for (final Base base in _baseSystem.getBases()) {
      if (!base.isDestroyed) {
        total += base.ammoCurrent.floor();
      }
    }
    return total;
  }

  List<int> _interceptorsPerBase() {
    return List<int>.unmodifiable(
      _baseSystem.getBases().map((Base base) => base.ammoCurrent.floor()),
    );
  }

  bool _canContinue() {
    return state.isGameOver;
  }
}
