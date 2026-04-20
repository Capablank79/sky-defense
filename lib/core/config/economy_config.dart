import 'package:sky_defense/core/config/config_base.dart';

class EconomyConfig implements VersionedConfig {
  const EconomyConfig({
    required this.version,
    required this.baseRewardPerSession,
    required this.comboMultiplierStep,
    required this.maxComboMultiplier,
    required this.maxCredits,
    required this.maxPremiumCredits,
    required this.maxHighScore,
    required this.maxProgressLevel,
    required this.initialCredits,
    required this.upgradeCostPerLevel,
  });

  @override
  final int version;
  final int baseRewardPerSession;
  final double comboMultiplierStep;
  final double maxComboMultiplier;
  final int maxCredits;
  final int maxPremiumCredits;
  final int maxHighScore;
  final int maxProgressLevel;
  final int initialCredits;
  final int upgradeCostPerLevel;

  bool isValid() {
    return version > 0 &&
        baseRewardPerSession > 0 &&
        comboMultiplierStep > 0 &&
        maxComboMultiplier >= 1 &&
        maxCredits > 0 &&
        maxPremiumCredits >= 0 &&
        maxHighScore > 0 &&
        maxProgressLevel > 0 &&
        initialCredits >= 0 &&
        upgradeCostPerLevel > 0;
  }

  EconomyConfig validateConfig() {
    if (isValid()) {
      return this;
    }
    return defaults;
  }

  factory EconomyConfig.fromJson(Map<String, dynamic> json) {
    final EconomyConfig parsed = EconomyConfig(
      version: (json['version'] as num?)?.toInt() ?? defaults.version,
      baseRewardPerSession:
          (json['baseRewardPerSession'] as num?)?.toInt() ?? defaults.baseRewardPerSession,
      comboMultiplierStep:
          (json['comboMultiplierStep'] as num?)?.toDouble() ?? defaults.comboMultiplierStep,
      maxComboMultiplier:
          (json['maxComboMultiplier'] as num?)?.toDouble() ?? defaults.maxComboMultiplier,
      maxCredits: (json['maxCredits'] as num?)?.toInt() ?? defaults.maxCredits,
      maxPremiumCredits:
          (json['maxPremiumCredits'] as num?)?.toInt() ?? defaults.maxPremiumCredits,
      maxHighScore: (json['maxHighScore'] as num?)?.toInt() ?? defaults.maxHighScore,
      maxProgressLevel:
          (json['maxProgressLevel'] as num?)?.toInt() ?? defaults.maxProgressLevel,
      initialCredits: (json['initialCredits'] as num?)?.toInt() ?? defaults.initialCredits,
      upgradeCostPerLevel:
          (json['upgradeCostPerLevel'] as num?)?.toInt() ?? defaults.upgradeCostPerLevel,
    );
    return parsed.validateConfig();
  }

  static const EconomyConfig defaults = EconomyConfig(
    version: 1,
    baseRewardPerSession: 100,
    comboMultiplierStep: 0.25,
    maxComboMultiplier: 3.0,
    maxCredits: 9999999,
    maxPremiumCredits: 99999,
    maxHighScore: 9999999,
    maxProgressLevel: 999,
    initialCredits: 1000,
    upgradeCostPerLevel: 200,
  );
}
