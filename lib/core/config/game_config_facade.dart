import 'package:sky_defense/core/config/economy_config.dart';
import 'package:sky_defense/core/config/game_balance_config.dart';
import 'package:sky_defense/core/config/retention_config.dart';

class GameConfigFacade {
  const GameConfigFacade({
    required this.economy,
    required this.gameBalance,
    required this.retention,
  });

  final EconomyConfig economy;
  final GameBalanceConfig gameBalance;
  final RetentionConfig retention;

  factory GameConfigFacade.defaults() {
    return const GameConfigFacade(
      economy: EconomyConfig.defaults,
      gameBalance: GameBalanceConfig.defaults,
      retention: RetentionConfig.defaults,
    );
  }
}
