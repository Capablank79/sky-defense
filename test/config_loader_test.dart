import 'package:flutter_test/flutter_test.dart';
import 'package:sky_defense/core/config/config_loader.dart';
import 'package:sky_defense/core/config/economy_config.dart';
import 'package:sky_defense/core/config/game_balance_config.dart';
import 'package:sky_defense/core/config/retention_config.dart';

void main() {
  test('ConfigLoader validates invalid config and falls back to defaults', () async {
    final Map<String, String> assets = <String, String>{
      'assets/config/economy.json': '{"version":999,"baseRewardPerSession":-1}',
      'assets/config/game_balance.json': '{"version":1,"collisionTolerance":8.0}',
      'assets/config/retention.json':
          '{"version":1,"dailyRewardBase":50,"streakBonusStep":25,"maxStreakDays":7,"maxAllowedTimeJumpDays":0}',
    };
    final ConfigLoader loader = ConfigLoader(
      reader: (String path) async => assets[path] ?? '{}',
    );

    final EconomyConfig economy = await loader.loadEconomy();
    final GameBalanceConfig gameBalance = await loader.loadGameBalance();
    final RetentionConfig retention = await loader.loadRetention();

    expect(economy.version, EconomyConfig.defaults.version);
    expect(economy.baseRewardPerSession, EconomyConfig.defaults.baseRewardPerSession);
    expect(gameBalance.collisionTolerance, 8.0);
    expect(retention.maxStreakDays, RetentionConfig.defaults.maxStreakDays);
    expect(
      retention.maxAllowedTimeJumpDays,
      RetentionConfig.defaults.maxAllowedTimeJumpDays,
    );
  });
}
