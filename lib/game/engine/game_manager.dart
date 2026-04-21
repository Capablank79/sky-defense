import 'dart:math';

import 'package:flutter/scheduler.dart';
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
    required this.playerCredits,
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
  final int playerCredits;

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
    int? playerCredits,
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
      playerCredits: playerCredits ?? this.playerCredits,
    );
  }

  static GameSession initial() {
    return const GameSession(
      gameState: GameState.initializing,
      score: 0,
      missilesAlive: 0,
      remainingBases: 0,
      remainingInterceptors: 0,
      interceptorsPerBase: <int>[],
      currentWave: 1,
      isWaveActive: true,
      isGameOver: false,
      playerCredits: 0,
    );
  }
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
        super(GameSession.initial());

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
  int _score = 0;
  bool _isGameOverInternal = false;
  int _currentWaveInternal = 1;
  bool _isWaveActiveInternal = true;
  int _missilesAliveInternal = 0;
  int _remainingBasesInternal = 0;
  int _remainingInterceptorsInternal = 0;
  List<int> _interceptorsPerBaseInternal = <int>[];
  GameSession? _pendingSessionState;
  bool _isDeferredSessionCommitScheduled = false;

  GameState get lifecycleState => state.gameState;
  bool get isGameOver => _isGameOverInternal;
  List<Missile> get visibleMissiles => _missileSystem.getMissiles();
  List<InterceptorMissile> get visibleInterceptors =>
      List<InterceptorMissile>.unmodifiable(_activeInterceptors);
  List<Base> get visibleBases => _baseSystem.getBases();
  List<Explosion> get visibleExplosions => _explosionSystem.getExplosions();
  double get elapsedTimeSeconds => _elapsedTime;
  int get baseHitCounter => _baseHitCounter;
  int get explosionImpactCounter => _explosionImpactCounter;
  static const int continueCostCredits = 100;

  void syncPlayerCredits(int credits) {
    final int safeCredits = credits < 0 ? 0 : credits;
    if (safeCredits == state.playerCredits) {
      return;
    }
    state = state.copyWith(playerCredits: safeCredits);
  }

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
    _score = 0;
    _isGameOverInternal = false;
    _currentWaveInternal = _waveManager.currentWave;
    _isWaveActiveInternal = _waveManager.isWaveActive;
    _activeInterceptors = <InterceptorMissile>[];
    _remainingBasesInternal = _baseSystem.getAliveBases().length;
    _remainingInterceptorsInternal = _totalRemainingInterceptors();
    _interceptorsPerBaseInternal = _interceptorsPerBase();
    _missilesAliveInternal = 0;
    state = state.copyWith(
      gameState: GameState.ready,
      score: _score,
      missilesAlive: _missilesAliveInternal,
      remainingBases: _remainingBasesInternal,
      remainingInterceptors: _remainingInterceptorsInternal,
      interceptorsPerBase: _interceptorsPerBaseInternal,
      currentWave: _currentWaveInternal,
      isWaveActive: _isWaveActiveInternal,
      isGameOver: _isGameOverInternal,
      playerCredits: state.playerCredits,
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
        state.gameState == GameState.paused ||
        state.gameState == GameState.gameOver) {
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

  void end({bool deferStateSync = false}) {
    _isGameOverInternal = true;
    _currentWaveInternal = _waveManager.currentWave;
    _isWaveActiveInternal = _waveManager.isWaveActive;
    _remainingBasesInternal = _baseSystem.getAliveBases().length;
    _remainingInterceptorsInternal = _totalRemainingInterceptors();
    _interceptorsPerBaseInternal = _interceptorsPerBase();
    _missilesAliveInternal = _missileSystem.getMissiles().length;
    _setSessionState(
      state.copyWith(
        gameState: GameState.gameOver,
        score: _score,
        missilesAlive: _missilesAliveInternal,
        remainingBases: _remainingBasesInternal,
        remainingInterceptors: _remainingInterceptorsInternal,
        interceptorsPerBase: _interceptorsPerBaseInternal,
        currentWave: _currentWaveInternal,
        isWaveActive: _isWaveActiveInternal,
        isGameOver: true,
      ),
      deferToNextFrame: deferStateSync,
    );
  }

  void continueGame() {
    if (!_canContinue() || state.playerCredits < continueCostCredits) {
      return;
    }
    final int updatedCredits = state.playerCredits - continueCostCredits;
    _baseSystem.restorePartial();
    _baseSystem.restoreAmmo();
    _activeInterceptors = <InterceptorMissile>[];
    _missileSystem.clear();
    _interceptorSystem.clear();
    _explosionSystem.clear();
    _isGameOverInternal = false;
    _missilesAliveInternal = 0;
    _remainingBasesInternal = _baseSystem.getAliveBases().length;
    _remainingInterceptorsInternal = _totalRemainingInterceptors();
    _interceptorsPerBaseInternal = _interceptorsPerBase();
    state = state.copyWith(
      gameState: GameState.ready,
      isGameOver: false,
      missilesAlive: _missilesAliveInternal,
      remainingBases: _remainingBasesInternal,
      remainingInterceptors: _remainingInterceptorsInternal,
      interceptorsPerBase: _interceptorsPerBaseInternal,
      score: _score,
      playerCredits: updatedCredits,
    );
    start();
  }

  void continueAfterGameOver() {
    continueGame();
  }

  void restartGame() {
    _waveManager.reset();
    _missileSystem.clear();
    _explosionSystem.clear();
    _interceptorSystem.clear();
    _baseSystem.reset();
    _activeInterceptors = <InterceptorMissile>[];
    _elapsedTime = 0;
    _baseHitCounter = 0;
    _explosionImpactCounter = 0;
    _score = 0;
    _isGameOverInternal = false;
    final int credits = state.playerCredits;
    state = GameSession.initial().copyWith(playerCredits: credits);
    init();
    start();
  }

  void update(double dtSeconds) {
    if (_isGameOverInternal) {
      return;
    }
    if (state.gameState != GameState.running) {
      return;
    }
    _elapsedTime += dtSeconds;
    _baseSystem.updateAmmo(dtSeconds);
    final List<Base> aliveBasesAtStart = _baseSystem.getAliveBases();
    if (aliveBasesAtStart.isEmpty) {
      end(deferStateSync: true);
      return;
    }
    if (!_missileSystem.ensureValidTargets(aliveBasesAtStart)) {
      end(deferStateSync: true);
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
      _score += collidedMissileIds.length;
    }

    _missilesAliveInternal = _missileSystem.getMissiles().length;
    _remainingBasesInternal = _baseSystem.getAliveBases().length;
    _remainingInterceptorsInternal = _totalRemainingInterceptors();
    _interceptorsPerBaseInternal = _interceptorsPerBase();

    final bool waveChanged = tick.currentWave != _currentWaveInternal ||
        tick.isWaveActive != _isWaveActiveInternal;
    _currentWaveInternal = tick.currentWave;
    _isWaveActiveInternal = tick.isWaveActive;

    final bool isGameOver = _remainingBasesInternal == 0;
    if (isGameOver) {
      end(deferStateSync: true);
      return;
    }

    if (waveChanged) {
      _setSessionState(
        state.copyWith(
          score: _score,
          missilesAlive: _missilesAliveInternal,
          remainingBases: _remainingBasesInternal,
          remainingInterceptors: _remainingInterceptorsInternal,
          interceptorsPerBase: _interceptorsPerBaseInternal,
          currentWave: _currentWaveInternal,
          isWaveActive: _isWaveActiveInternal,
        ),
        deferToNextFrame: true,
      );
    }
  }

  void _setSessionState(
    GameSession nextState, {
    bool deferToNextFrame = false,
  }) {
    if (!deferToNextFrame) {
      state = nextState;
      return;
    }
    _pendingSessionState = nextState;
    if (_isDeferredSessionCommitScheduled) {
      return;
    }
    _isDeferredSessionCommitScheduled = true;
    try {
      SchedulerBinding.instance.addPostFrameCallback((Duration _) {
        _flushDeferredSessionCommit();
      });
    } catch (_) {
      Future<void>.microtask(_flushDeferredSessionCommit);
    }
  }

  void _flushDeferredSessionCommit() {
    _isDeferredSessionCommitScheduled = false;
    if (!mounted) {
      _pendingSessionState = null;
      return;
    }
    final GameSession? pending = _pendingSessionState;
    _pendingSessionState = null;
    if (pending != null) {
      state = pending;
    }
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
      targetBaseId: targetBase.id,
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
    return _isGameOverInternal;
  }
}
