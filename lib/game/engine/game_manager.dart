import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sky_defense/core/config/game_balance_config.dart';
import 'package:sky_defense/game/entities/explosion.dart';
import 'package:sky_defense/game/entities/base.dart';
import 'package:sky_defense/game/entities/boss.dart';
import 'package:sky_defense/game/entities/city.dart';
import 'package:sky_defense/game/entities/interceptor_missile.dart';
import 'package:sky_defense/game/entities/missile.dart';
import 'package:sky_defense/domain/entities/player_upgrades.dart';
import 'package:sky_defense/game/debug/debug_flags.dart';
import 'package:sky_defense/game/engine/wave_manager.dart';
import 'package:sky_defense/game/systems/collision_system.dart';
import 'package:sky_defense/game/systems/base_system.dart';
import 'package:sky_defense/game/systems/city_system.dart';
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
    required this.creditsEarned,
    required this.waveRewardCounter,
    required this.lastWaveRewardCredits,
    required this.phaseNumber,
    required this.waveNumber,
    required this.bossWave,
    required this.interWaveTimerSeconds,
    required this.phaseOneDemoCompleted,
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
  final int creditsEarned;
  final int waveRewardCounter;
  final int lastWaveRewardCredits;
  final int phaseNumber;
  final int waveNumber;
  final bool bossWave;
  final double interWaveTimerSeconds;
  final bool phaseOneDemoCompleted;

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
    int? creditsEarned,
    int? waveRewardCounter,
    int? lastWaveRewardCredits,
    int? phaseNumber,
    int? waveNumber,
    bool? bossWave,
    double? interWaveTimerSeconds,
    bool? phaseOneDemoCompleted,
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
      creditsEarned: creditsEarned ?? this.creditsEarned,
      waveRewardCounter: waveRewardCounter ?? this.waveRewardCounter,
      lastWaveRewardCredits:
          lastWaveRewardCredits ?? this.lastWaveRewardCredits,
      phaseNumber: phaseNumber ?? this.phaseNumber,
      waveNumber: waveNumber ?? this.waveNumber,
      bossWave: bossWave ?? this.bossWave,
      interWaveTimerSeconds:
          interWaveTimerSeconds ?? this.interWaveTimerSeconds,
      phaseOneDemoCompleted:
          phaseOneDemoCompleted ?? this.phaseOneDemoCompleted,
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
      creditsEarned: 0,
      waveRewardCounter: 0,
      lastWaveRewardCredits: 0,
      phaseNumber: 1,
      waveNumber: 1,
      bossWave: false,
      interWaveTimerSeconds: 0,
      phaseOneDemoCompleted: false,
    );
  }
}

class GameManager extends StateNotifier<GameSession> {
  GameManager({
    required BaseSystem baseSystem,
    required CitySystem citySystem,
    required MissileSystem missileSystem,
    required InterceptorSystem interceptorSystem,
    required ExplosionSystem explosionSystem,
    required CollisionSystem collisionSystem,
    required WaveManager waveManager,
    required int maxConcurrentThreats,
    required BossConfig bossConfig,
  })  : _baseSystem = baseSystem,
        _citySystem = citySystem,
        _missileSystem = missileSystem,
        _interceptorSystem = interceptorSystem,
        _explosionSystem = explosionSystem,
        _collisionSystem = collisionSystem,
        _waveManager = waveManager,
        _maxConcurrentThreats = maxConcurrentThreats,
        _bossConfig = bossConfig,
        _currentInterceptorSpeed = waveManager.initialInterceptorSpeed,
        super(GameSession.initial());

  final BaseSystem _baseSystem;
  final CitySystem _citySystem;
  final MissileSystem _missileSystem;
  final InterceptorSystem _interceptorSystem;
  final ExplosionSystem _explosionSystem;
  final CollisionSystem _collisionSystem;
  final WaveManager _waveManager;
  final int _maxConcurrentThreats;
  final BossConfig _bossConfig;
  double _currentInterceptorSpeed;
  List<InterceptorMissile> _activeInterceptors = <InterceptorMissile>[];
  Boss? _boss;
  final Set<String> _bossDamagedByExplosionIds = <String>{};
  final Random _spawnRandom = Random();
  final Random _baseOrderRandom = Random();
  List<int> _baseOrder = <int>[];
  int _currentOrderIndex = 0;
  double _worldWidth = 0;
  double _worldHeight = 0;
  double minX = 0;
  double maxX = 0;
  double minY = 0;
  double maxY = 0;
  double hudLeftWidth = 100;
  double _hudTopInset = 0;
  static const double sidePadding = 8;
  static const double bottomPadding = 40;
  double _elapsedTime = 0;
  int _baseHitCounter = 0;
  int _explosionImpactCounter = 0;
  int _explosionCreatedCounter = 0;
  int _interceptorLaunchCounter = 0;
  double _interWaveTimerInternal = 0;
  int _restartVersion = 0;
  int _lastRewardedWave = 0;
  int _sessionCreditsEarned = 0;
  int _waveRewardCounter = 0;
  int _lastWaveRewardCredits = 0;
  double _hudSyncAccumulator = 0;
  PlayerUpgrades _appliedUpgrades = PlayerUpgrades.defaults;
  bool _debugWavePrimed = false;
  int _score = 0;
  int _shotsFired = 0;
  int _shotsHit = 0;
  int _initialBaseCount = 4;
  bool _isGameOverInternal = false;
  bool _phaseOneDemoCompletedInternal = false;
  int _currentWaveInternal = 1;
  int _phaseNumberInternal = 1;
  int _waveNumberInternal = 1;
  bool _bossWaveInternal = false;
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
  List<City> get visibleCities => _citySystem.getAliveCities();
  List<Explosion> get visibleExplosions => _explosionSystem.getExplosions();
  Boss? get visibleBoss => _boss;
  double get elapsedTimeSeconds => _elapsedTime;
  int get baseHitCounter => _baseHitCounter;
  int get explosionImpactCounter => _explosionImpactCounter;
  int get explosionCreatedCounter => _explosionCreatedCounter;
  int get interceptorLaunchCounter => _interceptorLaunchCounter;
  double get interWaveTimerSeconds => _interWaveTimerInternal;
  bool get isWaveActive => _isWaveActiveInternal;
  int get phaseNumber => _phaseNumberInternal;
  int get waveNumber => _waveNumberInternal;
  bool get bossWave => _bossWaveInternal;
  bool get phaseOneDemoCompleted => _phaseOneDemoCompletedInternal;
  int get score => _score;
  int get globalWave => _currentWaveInternal;
  int get waveInPhase => _waveNumberInternal;
  int get wave => _currentWaveInternal;
  int get phase => _phaseNumberInternal;
  int get credits => state.playerCredits;
  int get aliveBasesCount => _baseSystem.getAliveBases().length;
  int get activeInterceptorsCount => _activeInterceptors.length;
  List<int> get ammoPerBase => List<int>.unmodifiable(
        _baseSystem.getBases().map((Base base) => base.ammoCurrent.floor()),
      );
  String get phaseWaveLabel => 'Fase $phase - Oleada $waveInPhase';
  int get restartVersion => _restartVersion;
  int get waveRewardCounter => _waveRewardCounter;
  int get lastWaveRewardCredits => _lastWaveRewardCredits;
  int get totalAmmo {
    int sum = 0;
    for (final Base base in _baseSystem.getBases()) {
      if (!base.isDestroyed) {
        sum += base.ammoCurrent.floor();
      }
    }
    return sum;
  }

  String get waveLabel => '$_phaseNumberInternal-$_waveNumberInternal';
  static const int continueCostCredits = 100;
  static const int _waveRewardBase = 50;
  static const int _waveRewardMultiplier = 20;
  static const int _baseAmmoMax = 10;
  static const int _debugAmmoMax = 3;
  static const double _baseReloadSpeed = 0.6;
  static const double _debugReloadSpeed = 0.3;
  static const double _ammoPerLevelStep = 2;
  static const double _reloadPerLevelStep = 0.15;
  static const double _explosionRadiusPerLevelStep = 0.1;
  static const double _interceptorSpeedPerLevelStep = 0.12;

  int get ammoMax {
    if (kDebugFastFail) {
      return _debugAmmoMax;
    }
    return (_baseAmmoMax +
            ((_appliedUpgrades.ammoLevel - 1) * _ammoPerLevelStep))
        .round();
  }

  double get reloadSpeed {
    if (kDebugFastFail) {
      return _debugReloadSpeed;
    }
    final double multiplier =
        1 + ((_appliedUpgrades.reloadLevel - 1) * _reloadPerLevelStep);
    return _baseReloadSpeed * multiplier;
  }

  double get explosionRadius {
    final double multiplier = 1 +
        ((_appliedUpgrades.explosionRadiusLevel - 1) *
            _explosionRadiusPerLevelStep);
    return _explosionSystem.baseRadius * multiplier;
  }

  double get interceptorSpeed {
    final double multiplier = 1 +
        ((_appliedUpgrades.interceptorSpeedLevel - 1) *
            _interceptorSpeedPerLevelStep);
    return _currentInterceptorSpeed * multiplier;
  }

  void syncPlayerCredits(int credits) {
    final int safeCredits = credits < 0 ? 0 : credits;
    if (safeCredits == state.playerCredits) {
      return;
    }
    state = state.copyWith(playerCredits: safeCredits);
  }

  void setHudWidth(double width) {
    if ((hudLeftWidth - width).abs() < 1) {
      return;
    }
    hudLeftWidth = width;
    if (_worldWidth <= 0 || _worldHeight <= 0) {
      return;
    }
    configureWorldBounds(
      width: _worldWidth,
      height: _worldHeight,
    );
  }

  void setHudTopInset(double inset) {
    final double safeInset = inset < 0 ? 0 : inset;
    if ((_hudTopInset - safeInset).abs() < 1) {
      return;
    }
    _hudTopInset = safeInset;
    if (_worldWidth <= 0 || _worldHeight <= 0) {
      return;
    }
    configureWorldBounds(
      width: _worldWidth,
      height: _worldHeight,
    );
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
    minX = hudLeftWidth + sidePadding;
    maxX = width - sidePadding;
    minY = (_hudTopInset + sidePadding).clamp(0, height - bottomPadding - 80);
    maxY = height - bottomPadding;
    _missileSystem.configureBounds(
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
    );
    _positionBases();
    _generateBaseOrder(_baseSystem.getAliveBases().length);
  }

  bool launchInterceptorTo({
    required double x,
    required double y,
  }) {
    if (!_isWaveActiveInternal) {
      return false;
    }
    if (!_isInsideGameArea(Vector2(x, y))) {
      return false;
    }
    final Base? base = _selectBase(Vector2(x, y));
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
      speed: interceptorSpeed,
    );
    _interceptorLaunchCounter += 1;
    _shotsFired += 1;
    _activeInterceptors = _interceptorSystem.getInterceptors();
    _remainingInterceptorsInternal = _totalRemainingInterceptors();
    _interceptorsPerBaseInternal = _interceptorsPerBase();
    if (state.gameState == GameState.running ||
        state.gameState == GameState.ready) {
      state = state.copyWith(
        remainingInterceptors: _remainingInterceptorsInternal,
        interceptorsPerBase: _interceptorsPerBaseInternal,
      );
    }
    return true;
  }

  Base? _selectBase(Vector2 target) {
    final List<Base> bases = _baseSystem.getAliveBases();
    if (bases.isEmpty) {
      return null;
    }

    Base? closest;
    double minDist = double.infinity;
    for (final Base base in bases) {
      final double dx = base.x - target.x;
      final double dy = base.y - target.y;
      final double d = sqrt((dx * dx) + (dy * dy));
      if (d < minDist) {
        minDist = d;
        closest = base;
      }
    }

    const double dangerRadius = 120.0;
    if (closest != null &&
        minDist < dangerRadius &&
        !closest.isDestroyed &&
        closest.ammoCurrent >= 1) {
      return closest;
    }

    if (_baseOrder.length != bases.length) {
      _generateBaseOrder(bases.length);
    }
    for (int i = 0; i < bases.length; i += 1) {
      final int index = _baseOrder[_currentOrderIndex];
      final Base base = bases[index];
      _currentOrderIndex = (_currentOrderIndex + 1) % bases.length;
      if (!base.isDestroyed && base.ammoCurrent >= 1) {
        return base;
      }
    }
    return null;
  }

  void init() {
    _waveManager.reset();
    if (kDebugFastFail && !_debugWavePrimed) {
      _waveManager.setWaveForDebugStart(1);
      _debugWavePrimed = true;
    }
    _elapsedTime = 0;
    _baseHitCounter = 0;
    _explosionImpactCounter = 0;
    _explosionCreatedCounter = 0;
    _interceptorLaunchCounter = 0;
    _interWaveTimerInternal = 0;
    _hudSyncAccumulator = 0;
    _score = 0;
    _isGameOverInternal = false;
    _phaseOneDemoCompletedInternal = false;
    _currentWaveInternal = _waveManager.currentWave;
    _phaseNumberInternal = _waveManager.phaseNumber;
    _waveNumberInternal = _waveManager.waveNumber;
    _bossWaveInternal = _waveManager.bossWave;
    _isWaveActiveInternal = _waveManager.isWaveActive;
    _interWaveTimerInternal = _waveManager.interWaveTimer;
    _activeInterceptors = <InterceptorMissile>[];
    _citySystem.reset();
    _boss = null;
    _bossDamagedByExplosionIds.clear();
    _shotsFired = 0;
    _shotsHit = 0;
    _applyDynamicGameplayValues();
    _generateBaseOrder(_baseSystem.getAliveBases().length);
    _remainingBasesInternal = _baseSystem.getAliveBases().length;
    _initialBaseCount = _baseSystem.getBases().length.clamp(1, 99);
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
      creditsEarned: _sessionCreditsEarned,
      waveRewardCounter: _waveRewardCounter,
      lastWaveRewardCredits: _lastWaveRewardCredits,
      phaseNumber: _phaseNumberInternal,
      waveNumber: _waveNumberInternal,
      bossWave: _bossWaveInternal,
      interWaveTimerSeconds: _interWaveTimerInternal,
      phaseOneDemoCompleted: _phaseOneDemoCompletedInternal,
    );
    if (_worldWidth > 0 && _worldHeight > 0) {
      _positionBases();
      _generateBaseOrder(_baseSystem.getAliveBases().length);
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
    _phaseNumberInternal = _waveManager.phaseNumber;
    _waveNumberInternal = _waveManager.waveNumber;
    _bossWaveInternal = _waveManager.bossWave;
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
        phaseNumber: _phaseNumberInternal,
        waveNumber: _waveNumberInternal,
        bossWave: _bossWaveInternal,
        interWaveTimerSeconds: _interWaveTimerInternal,
        isWaveActive: _isWaveActiveInternal,
        isGameOver: true,
        phaseOneDemoCompleted: _phaseOneDemoCompletedInternal,
      ),
      deferToNextFrame: deferStateSync,
    );
  }

  void continueGame() {
    if (!_canContinue() || state.playerCredits < continueCostCredits) {
      return;
    }
    _baseSystem.restorePartial();
    _baseSystem.restoreAmmo();
    _activeInterceptors = <InterceptorMissile>[];
    _citySystem.restoreForContinue();
    _boss = null;
    _bossDamagedByExplosionIds.clear();
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
      playerCredits: state.playerCredits,
      creditsEarned: _sessionCreditsEarned,
      waveRewardCounter: _waveRewardCounter,
      lastWaveRewardCredits: _lastWaveRewardCredits,
      phaseOneDemoCompleted: false,
    );
    start();
  }

  void continueAfterGameOver() {
    continueGame();
  }

  void restartGame() {
    _waveManager.reset();
    _missileSystem.reset();
    _explosionSystem.reset();
    _interceptorSystem.reset();
    _baseSystem.reset();
    _citySystem.reset();
    _activeInterceptors = <InterceptorMissile>[];
    _elapsedTime = 0;
    _baseHitCounter = 0;
    _explosionImpactCounter = 0;
    _explosionCreatedCounter = 0;
    _interceptorLaunchCounter = 0;
    _interWaveTimerInternal = 0;
    _lastRewardedWave = 0;
    _sessionCreditsEarned = 0;
    _waveRewardCounter = 0;
    _lastWaveRewardCredits = 0;
    _hudSyncAccumulator = 0;
    _score = 0;
    _shotsFired = 0;
    _shotsHit = 0;
    _isGameOverInternal = false;
    _phaseOneDemoCompletedInternal = false;
    _baseOrder = <int>[];
    _currentOrderIndex = 0;
    _restartVersion += 1;
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
    final List<City> aliveCitiesAtStart = _citySystem.getAliveCities();
    if ((aliveBasesAtStart.isNotEmpty || aliveCitiesAtStart.isNotEmpty) &&
        !_missileSystem.ensureValidTargets(
          aliveBases: aliveBasesAtStart,
          aliveCities: aliveCitiesAtStart,
        )) {
      end(deferStateSync: true);
      return;
    }
    final double accuracy = _shotsFired <= 0 ? 0.5 : (_shotsHit / _shotsFired);
    final double basesLostRatio =
        ((_initialBaseCount - aliveBasesAtStart.length) / _initialBaseCount)
            .clamp(0, 1);
    _waveManager.setAdaptiveTuning(
      accuracy: accuracy,
      basesLostRatio: basesLostRatio,
    );
    final int activeThreats = _missileSystem.getActiveThreatCount();
    final WaveTick waveTick = _waveManager.update(
      dtSeconds: dtSeconds,
      activeMissiles: activeThreats,
      maxConcurrentThreats: _maxConcurrentThreats,
      spawnMissile: _spawnMissileControlled,
    );
    _currentInterceptorSpeed = waveTick.interceptorMissileSpeed;
    _isWaveActiveInternal = waveTick.isWaveActive;
    _interWaveTimerInternal = waveTick.interWaveTimer;
    _currentWaveInternal = waveTick.currentWave;
    _phaseNumberInternal = waveTick.phaseNumber;
    _waveNumberInternal = waveTick.waveNumber;
    _bossWaveInternal = waveTick.bossWave;

    if (waveTick.waveJustEnded) {
      _explosionSystem.clear();
      _interceptorSystem.clear();
      _activeInterceptors = <InterceptorMissile>[];
      _baseSystem.restoreAmmo();

      final int rewardPhase =
          waveTick.completedPhaseNumber ?? waveTick.phaseNumber;
      final int rewardWave =
          waveTick.completedWaveNumber ?? waveTick.waveNumber;
      final bool rewardBossWave =
          waveTick.completedBossWave ?? waveTick.bossWave;
      _awardWaveCredits(
        phaseNumber: rewardPhase,
        waveNumber: rewardWave,
        bossWave: rewardBossWave,
      );

      // 🔥 DO NOT remove boss if we are entering boss phase
      if (!waveTick.bossWave) {
        _boss = null;
        _bossDamagedByExplosionIds.clear();
      }
    }
    if (waveTick.waveJustStarted) {
      _baseSystem.restoreAmmo();
      _generateBaseOrder(_baseSystem.getAliveBases().length);

      // Reset boss actor at wave start.
      _boss = null;
      _bossDamagedByExplosionIds.clear();
    }
    // Ensure boss exists whenever we are inside boss phase.
    if (waveTick.bossWave && _boss == null) {
      _spawnBoss(waveTick);
    }

    _updateBoss(dtSeconds, waveTick);

    _missileSystem.update(dtSeconds);
    final List<Missile> arrivedMissiles =
        _missileSystem.consumeArrivedMissiles();
    bool baseDamaged = false;
    for (final Missile missile in arrivedMissiles) {
      if (missile.targetKind == MissileTargetKind.city) {
        final bool cityDestroyed = _citySystem.destroyCityAtTarget(
          targetCityId: missile.targetBaseId,
          targetX: missile.target.x,
          targetY: missile.target.y,
        );
        if (cityDestroyed) {
          baseDamaged = true;
        }
      } else {
        final bool impactedBase = _baseSystem.damageBaseAtTarget(
          targetBaseId: missile.targetBaseId,
          targetX: missile.target.x,
          targetY: missile.target.y,
          damage: missile.type == MissileType.boss ? 2 : 1,
        );
        if (impactedBase) {
          baseDamaged = true;
        }
      }
    }

    _interceptorSystem.update(dtSeconds);
    _activeInterceptors = _interceptorSystem.getInterceptors();
    final List<InterceptorMissile> arrivedInterceptors =
        _interceptorSystem.getArrivedInterceptors();
    for (final InterceptorMissile interceptor in arrivedInterceptors) {
      _explosionSystem.createExplosion(
        (x: interceptor.target.x, y: interceptor.target.y),
      );
      _explosionCreatedCounter += 1;
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
      final Map<String, int> damageByMissileId = <String, int>{};
      for (final collision in collisions) {
        damageByMissileId[collision.missileId] =
            (damageByMissileId[collision.missileId] ?? 0) + 1;
      }
      int destroyedCount = 0;
      for (final MapEntry<String, int> entry in damageByMissileId.entries) {
        final bool destroyed = _missileSystem.applyDamage(
          entry.key,
          damage: entry.value,
        );
        if (destroyed) {
          destroyedCount += 1;
        }
      }
      if (destroyedCount > 0) {
        _shotsHit += destroyedCount;
        _score += destroyedCount;
        _waveManager.onMissilesDestroyed(destroyedCount); // 🔥 FIX REAL
      }
    }
    _updateBossDamageFromExplosions(explosions);

    _missilesAliveInternal = _missileSystem.getMissiles().length;
    _remainingBasesInternal = _baseSystem.getAliveBases().length;
    _remainingInterceptorsInternal = _totalRemainingInterceptors();
    _interceptorsPerBaseInternal = _interceptorsPerBase();

    final int previousWave = state.currentWave;
    final bool previousWaveActive = state.isWaveActive;
    final bool waveChanged = previousWave != _currentWaveInternal ||
        previousWaveActive != _isWaveActiveInternal;

    final bool hasCities = _citySystem.getCities().isNotEmpty;
    final bool isGameOver = hasCities && _citySystem.getAliveCities().isEmpty;
    if (isGameOver) {
      end(deferStateSync: true);
      return;
    }

    _hudSyncAccumulator += dtSeconds;
    if (waveChanged || _hudSyncAccumulator >= 0.2) {
      _hudSyncAccumulator = 0;
      _setSessionState(
        state.copyWith(
          score: _score,
          missilesAlive: _missilesAliveInternal,
          remainingBases: _remainingBasesInternal,
          remainingInterceptors: _remainingInterceptorsInternal,
          interceptorsPerBase: _interceptorsPerBaseInternal,
          currentWave: _currentWaveInternal,
          phaseNumber: _phaseNumberInternal,
          waveNumber: _waveNumberInternal,
          bossWave: _bossWaveInternal,
          interWaveTimerSeconds: _interWaveTimerInternal,
          isWaveActive: _isWaveActiveInternal,
          creditsEarned: _sessionCreditsEarned,
          waveRewardCounter: _waveRewardCounter,
          lastWaveRewardCredits: _lastWaveRewardCredits,
          phaseOneDemoCompleted: _phaseOneDemoCompletedInternal,
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

  bool _spawnMissileControlled(WaveTick tick) {
    final ({String id, double x, double y, MissileTargetKind kind})? target =
        _pickEnemyTarget();
    if (target == null) {
      return false;
    }
    final Vector2 spawnPos = _getValidSpawnPosition();
    final MissileType missileType = _pickMissileType(tick: tick);
    final int hitPoints = missileType == MissileType.heavy
        ? 3
        : (tick.bossWave ? tick.bossHitPoints : 1);
    final int splitRemaining = missileType == MissileType.split ? 1 : 0;
    final double zigzagAmplitude = missileType == MissileType.zigzag ? 14 : 0;
    final double zigzagFrequency = missileType == MissileType.zigzag ? 7.5 : 0;
    _missileSystem.spawnMissile(
      startX: spawnPos.x,
      startY: spawnPos.y,
      targetBaseId: target.id,
      targetKind: target.kind,
      targetX: target.x.clamp(minX, maxX),
      targetY: target.y.clamp(minY, maxY),
      speed:
          _speedForType(baseSpeed: tick.enemyMissileSpeed, type: missileType),
      type: missileType,
      hitPoints: hitPoints,
      splitRemaining: splitRemaining,
      zigzagAmplitude: zigzagAmplitude,
      zigzagFrequency: zigzagFrequency,
    );
    return true;
  }

  Vector2 _getValidSpawnPosition() {
    final double safeMinX = minX;
    final double safeMaxX = maxX > minX ? maxX : (minX + 1);
    final double x =
        safeMinX + (_spawnRandom.nextDouble() * (safeMaxX - safeMinX));
    return Vector2(x, minY);
  }

  bool _isInsideGameArea(Vector2 pos) {
    return pos.x >= minX && pos.x <= maxX && pos.y >= minY && pos.y <= maxY;
  }

  void _positionBases() {
    if (_worldWidth <= 0 || _worldHeight <= 0) {
      return;
    }
    final int baseCount =
        _baseSystem.getBases().isEmpty ? 4 : _baseSystem.getBases().length;
    final double safeMinX = minX.clamp(0, _worldWidth);
    final double safeMaxX = maxX.clamp(0, _worldWidth);
    if (_baseSystem.getBases().isEmpty) {
      final double horizontalMargin = safeMinX;
      final double bottomOffset =
          (_worldHeight - (maxY - 20)).clamp(0, _worldHeight);
      _baseSystem.initializeBases(
        worldWidth: _worldWidth,
        worldHeight: _worldHeight,
        baseCount: baseCount,
        horizontalMargin: horizontalMargin,
        bottomOffset: bottomOffset,
      );
    }
    final double baseY = (maxY - 20).clamp(minY, maxY);
    _baseSystem.positionBasesInArea(
      minX: safeMinX,
      maxX: safeMaxX,
      y: baseY,
    );
    _citySystem.positionBetweenBases(_baseSystem.getBases());
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
    return _isGameOverInternal && !_phaseOneDemoCompletedInternal;
  }

  void configurePlayerUpgrades(PlayerUpgrades upgrades) {
    _appliedUpgrades = upgrades.toSanitized();
    _applyDynamicGameplayValues();
    _remainingInterceptorsInternal = _totalRemainingInterceptors();
    _interceptorsPerBaseInternal = _interceptorsPerBase();
    state = state.copyWith(
      remainingInterceptors: _remainingInterceptorsInternal,
      interceptorsPerBase: _interceptorsPerBaseInternal,
    );
  }

  void _awardWaveCredits({
    required int phaseNumber,
    required int waveNumber,
    required bool bossWave,
  }) {
    final int waveKey = (phaseNumber * 10) + (bossWave ? 5 : waveNumber);
    if (waveKey <= _lastRewardedWave) {
      return;
    }
    final int rewardWave =
        bossWave ? _bossConfig.phaseBossWaveNumber : waveNumber;
    final int reward = bossWave
        ? _bossConfig.bossKillScore
        : (_waveRewardBase + (rewardWave * _waveRewardMultiplier));
    _lastRewardedWave = waveKey;
    _lastWaveRewardCredits = reward;
    _waveRewardCounter += 1;
    _sessionCreditsEarned += reward;
    state = state.copyWith(
      playerCredits: state.playerCredits + reward,
      creditsEarned: _sessionCreditsEarned,
      waveRewardCounter: _waveRewardCounter,
      lastWaveRewardCredits: _lastWaveRewardCredits,
    );
  }

  void _applyDynamicGameplayValues() {
    _baseSystem.setAmmoConfig(
      ammoMax: ammoMax,
      reloadSpeed: reloadSpeed,
    );
    _explosionSystem.setExplosionRadius(explosionRadius);
    _interceptorSystem.setGlobalSpeed(interceptorSpeed);
    _activeInterceptors = _interceptorSystem.getInterceptors();
  }

  MissileType _pickMissileType({required WaveTick tick}) {
    if (tick.bossWave && _boss != null) {
      return MissileType.heavy;
    }
    final double baseTotal =
        tick.slowWeight + tick.mediumWeight + tick.fastWeight;
    final double specialTotal =
        tick.splitProbability + tick.zigzagProbability + tick.heavyProbability;
    final double total = baseTotal + specialTotal;
    if (total <= 0) {
      return MissileType.medium;
    }
    final double roll = _spawnRandom.nextDouble() * total;
    if (roll < tick.slowWeight) {
      return MissileType.slow;
    }
    if (roll < tick.slowWeight + tick.mediumWeight) {
      return MissileType.medium;
    }
    if (roll < tick.slowWeight + tick.mediumWeight + tick.fastWeight) {
      return MissileType.fast;
    }
    final double specialRoll = roll - baseTotal;
    if (specialRoll < tick.splitProbability) {
      return MissileType.split;
    }
    if (specialRoll < tick.splitProbability + tick.zigzagProbability) {
      return MissileType.zigzag;
    }
    return MissileType.heavy;
  }

  double _speedForType({
    required double baseSpeed,
    required MissileType type,
  }) {
    switch (type) {
      case MissileType.slow:
        return baseSpeed * 0.8;
      case MissileType.medium:
        return baseSpeed;
      case MissileType.fast:
        return baseSpeed * 1.28;
      case MissileType.split:
        return baseSpeed * 1.02;
      case MissileType.zigzag:
        return baseSpeed * 1.08;
      case MissileType.heavy:
        return baseSpeed * 0.88;
      case MissileType.boss:
        return baseSpeed * 0.72;
    }
  }

  void _spawnBoss(WaveTick tick) {
    if (_boss != null) {
      return;
    }
    final double centerX = (minX + maxX) * 0.5;
    final int scaledHp = _bossConfig.hpBase + ((tick.phaseNumber - 1) * 2);
    final int bossHp = max(scaledHp, tick.bossHitPoints);
    final double baseCooldown =
        min(_bossConfig.baseFireCooldownSeconds, tick.bossFireCooldown);
    _boss = Boss(
      position: Vector2(centerX, minY + 56),
      health: bossHp,
      maxHealth: bossHp,
      velocityX: _bossConfig.moveSpeedX,
      fireCooldownSeconds: baseCooldown,
    );
    _bossDamagedByExplosionIds.clear();
  }

  void _updateBoss(double dtSeconds, WaveTick tick) {
    final Boss? boss = _boss;
    if (boss == null || !boss.isAlive) {
      return;
    }
    boss.position.x += boss.velocityX * dtSeconds;
    final double left = minX + 28;
    final double right = maxX - 28;
    if (boss.position.x < left) {
      boss.position.x = left;
      boss.velocityX = boss.velocityX.abs();
    } else if (boss.position.x > right) {
      boss.position.x = right;
      boss.velocityX = -boss.velocityX.abs();
    }

    if (!tick.bossWave) {
      return;
    }

    _updateBossCombatState(boss: boss, dtSeconds: dtSeconds, tick: tick);
  }

  void _updateBossCombatState({
    required Boss boss,
    required double dtSeconds,
    required WaveTick tick,
  }) {
    boss.stateTimerSeconds += dtSeconds;
    boss.targetedBurstTimerSeconds += dtSeconds;
    boss.fanSweepTimerSeconds += dtSeconds;
    boss.supportWaveTimerSeconds += dtSeconds;

    if (_bossConfig.targetedBurst.enabled &&
        boss.targetedBurstTimerSeconds >=
            _bossConfig.targetedBurst.cooldownSeconds) {
      boss.targetedBurstTimerSeconds = 0;
      boss.state = BossState.attackA;
      _fireTargetedBurst(tick: tick, boss: boss);
    }

    if (_bossConfig.fanSweep.enabled &&
        boss.fanSweepTimerSeconds >= _bossConfig.fanSweep.cooldownSeconds) {
      boss.fanSweepTimerSeconds = 0;
      boss.state = BossState.attackB;
      _fireFanSweep(tick: tick, boss: boss);
    }

    if (_bossConfig.supportWave.enabled &&
        boss.supportWaveTimerSeconds >=
            _bossConfig.supportWave.spawnIntervalSeconds &&
        _missileSystem.getActiveThreatCount() <
            _bossConfig.supportWave.maxConcurrentThreatsDuringBoss) {
      boss.supportWaveTimerSeconds = 0;
      _spawnMissileControlled(tick);
    }
  }

  void _fireTargetedBurst({
    required WaveTick tick,
    required Boss boss,
  }) {
    final ({String id, double x, double y, MissileTargetKind kind})? target =
        _pickCenterPriorityTarget();
    if (target == null) {
      return;
    }
    final double speed = _speedForType(
      baseSpeed:
          tick.enemyMissileSpeed * _bossConfig.targetedBurst.speedMultiplier,
      type: MissileType.boss,
    );
    final int shots = _bossConfig.targetedBurst.shots;
    for (int i = 0; i < shots; i += 1) {
      final double offsetX = (i - ((shots - 1) / 2)) * 10;
      _spawnBossMissile(
        startX: boss.position.x + offsetX,
        startY: boss.position.y,
        target: target,
        speed: speed,
        type: MissileType.boss,
        hitPoints: 2,
      );
    }
  }

  void _fireFanSweep({
    required WaveTick tick,
    required Boss boss,
  }) {
    final ({String id, double x, double y, MissileTargetKind kind})? target =
        _pickEnemyTarget();
    if (target == null) {
      return;
    }
    final int shots = _bossConfig.fanSweep.shots;
    final double speed = _speedForType(
      baseSpeed: tick.enemyMissileSpeed * _bossConfig.fanSweep.speedMultiplier,
      type: MissileType.heavy,
    );
    for (int i = 0; i < shots; i += 1) {
      final double factor = shots <= 1 ? 0 : ((i / (shots - 1)) * 2) - 1;
      final double offsetX = factor * 48;
      _spawnBossMissile(
        startX: boss.position.x,
        startY: boss.position.y,
        target: (
          id: target.id,
          x: (target.x + offsetX).clamp(minX, maxX),
          y: target.y,
          kind: target.kind,
        ),
        speed: speed,
        type: MissileType.heavy,
        hitPoints: 3,
      );
    }
  }

  void _spawnBossMissile({
    required double startX,
    required double startY,
    required ({String id, double x, double y, MissileTargetKind kind}) target,
    required double speed,
    required MissileType type,
    required int hitPoints,
  }) {
    _missileSystem.spawnMissile(
      startX: startX.clamp(minX, maxX),
      startY: startY.clamp(minY, maxY),
      targetBaseId: target.id,
      targetKind: target.kind,
      targetX: target.x.clamp(minX, maxX),
      targetY: target.y.clamp(minY, maxY),
      speed: speed,
      type: type,
      hitPoints: hitPoints,
    );
  }

  void _updateBossDamageFromExplosions(List<Explosion> explosions) {
    final Boss? boss = _boss;
    if (boss == null || !boss.isAlive) {
      return;
    }
    for (final Explosion explosion in explosions) {
      if (!explosion.isActive) {
        continue;
      }
      if (_bossDamagedByExplosionIds.contains(explosion.id)) {
        continue;
      }
      final double dx = boss.position.x - explosion.x;
      final double dy = boss.position.y - explosion.y;
      final double impactRadius = explosion.radius + 24;
      if ((dx * dx) + (dy * dy) <= (impactRadius * impactRadius)) {
        _bossDamagedByExplosionIds.add(explosion.id);
        boss.health -= 1;
        if (boss.health <= 0) {
          _score += _bossConfig.bossKillScore;
          _boss = null;
          _bossDamagedByExplosionIds.clear();
          if (_waveManager.phaseNumber == 1 && _waveManager.bossWave) {
            _phaseOneDemoCompletedInternal = true;
            _isGameOverInternal = true;
            _currentWaveInternal = _waveManager.currentWave;
            _phaseNumberInternal = _waveManager.phaseNumber;
            _waveNumberInternal = _waveManager.waveNumber;
            _bossWaveInternal = _waveManager.bossWave;
            _isWaveActiveInternal = false;
            _interWaveTimerInternal = 0;
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
                phaseNumber: _phaseNumberInternal,
                waveNumber: _waveNumberInternal,
                bossWave: _bossWaveInternal,
                interWaveTimerSeconds: _interWaveTimerInternal,
                isWaveActive: _isWaveActiveInternal,
                isGameOver: true,
                phaseOneDemoCompleted: true,
              ),
              deferToNextFrame: true,
            );
          } else {
            _waveManager.onBossDefeated();
          }
          break;
        }
      }
    }
  }

  ({String id, double x, double y, MissileTargetKind kind})?
      _pickEnemyTarget() {
    final List<Base> aliveBases = _baseSystem.getAliveBases();
    final List<City> aliveCities = _citySystem.getAliveCities();
    final int totalTargets = aliveBases.length + aliveCities.length;
    if (totalTargets == 0) {
      return null;
    }
    final int pick = _spawnRandom.nextInt(totalTargets);
    if (pick < aliveBases.length) {
      final Base base = aliveBases[pick];
      return (
        id: base.id,
        x: base.x,
        y: base.y,
        kind: MissileTargetKind.base,
      );
    }
    final City city = aliveCities[pick - aliveBases.length];
    return (
      id: city.id,
      x: city.x,
      y: city.y,
      kind: MissileTargetKind.city,
    );
  }

  ({String id, double x, double y, MissileTargetKind kind})?
      _pickCenterPriorityTarget() {
    final List<Base> aliveBases = _baseSystem.getAliveBases();
    if (aliveBases.isNotEmpty) {
      final double centerX = (minX + maxX) * 0.5;
      Base selected = aliveBases.first;
      double bestDx = (selected.x - centerX).abs();
      for (int i = 1; i < aliveBases.length; i += 1) {
        final Base candidate = aliveBases[i];
        final double dx = (candidate.x - centerX).abs();
        if (dx < bestDx) {
          selected = candidate;
          bestDx = dx;
        }
      }
      return (
        id: selected.id,
        x: selected.x,
        y: selected.y,
        kind: MissileTargetKind.base,
      );
    }
    final List<City> aliveCities = _citySystem.getAliveCities();
    if (aliveCities.isEmpty) {
      return null;
    }
    final City city = aliveCities[_spawnRandom.nextInt(aliveCities.length)];
    return (
      id: city.id,
      x: city.x,
      y: city.y,
      kind: MissileTargetKind.city,
    );
  }

  void _generateBaseOrder(int count) {
    if (count <= 0) {
      _baseOrder = <int>[];
      _currentOrderIndex = 0;
      return;
    }
    _baseOrder = List<int>.generate(count, (int i) => i);
    _baseOrder.shuffle(_baseOrderRandom);
    _currentOrderIndex = 0;
  }
}
