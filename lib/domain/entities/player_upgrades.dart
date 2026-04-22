enum UpgradeType {
  ammo,
  reload,
  explosionRadius,
  interceptorSpeed,
}

class PlayerUpgrades {
  const PlayerUpgrades({
    required this.ammoLevel,
    required this.reloadLevel,
    required this.explosionRadiusLevel,
    required this.interceptorSpeedLevel,
  });

  static const int minLevel = 1;
  static const int maxLevel = 25;

  static const PlayerUpgrades defaults = PlayerUpgrades(
    ammoLevel: 1,
    reloadLevel: 1,
    explosionRadiusLevel: 1,
    interceptorSpeedLevel: 1,
  );

  final int ammoLevel;
  final int reloadLevel;
  final int explosionRadiusLevel;
  final int interceptorSpeedLevel;

  bool isValid() {
    return _isValidLevel(ammoLevel) &&
        _isValidLevel(reloadLevel) &&
        _isValidLevel(explosionRadiusLevel) &&
        _isValidLevel(interceptorSpeedLevel);
  }

  PlayerUpgrades toSanitized() {
    return PlayerUpgrades(
      ammoLevel: _sanitizeLevel(ammoLevel),
      reloadLevel: _sanitizeLevel(reloadLevel),
      explosionRadiusLevel: _sanitizeLevel(explosionRadiusLevel),
      interceptorSpeedLevel: _sanitizeLevel(interceptorSpeedLevel),
    );
  }

  PlayerUpgrades copyWith({
    int? ammoLevel,
    int? reloadLevel,
    int? explosionRadiusLevel,
    int? interceptorSpeedLevel,
  }) {
    return PlayerUpgrades(
      ammoLevel: ammoLevel ?? this.ammoLevel,
      reloadLevel: reloadLevel ?? this.reloadLevel,
      explosionRadiusLevel: explosionRadiusLevel ?? this.explosionRadiusLevel,
      interceptorSpeedLevel:
          interceptorSpeedLevel ?? this.interceptorSpeedLevel,
    );
  }

  int levelFor(UpgradeType type) {
    switch (type) {
      case UpgradeType.ammo:
        return ammoLevel;
      case UpgradeType.reload:
        return reloadLevel;
      case UpgradeType.explosionRadius:
        return explosionRadiusLevel;
      case UpgradeType.interceptorSpeed:
        return interceptorSpeedLevel;
    }
  }

  PlayerUpgrades incrementLevel(UpgradeType type) {
    switch (type) {
      case UpgradeType.ammo:
        return copyWith(ammoLevel: ammoLevel + 1);
      case UpgradeType.reload:
        return copyWith(reloadLevel: reloadLevel + 1);
      case UpgradeType.explosionRadius:
        return copyWith(explosionRadiusLevel: explosionRadiusLevel + 1);
      case UpgradeType.interceptorSpeed:
        return copyWith(interceptorSpeedLevel: interceptorSpeedLevel + 1);
    }
  }

  bool _isValidLevel(int value) {
    return value >= minLevel && value <= maxLevel;
  }

  int _sanitizeLevel(int value) {
    return value.clamp(minLevel, maxLevel);
  }
}
