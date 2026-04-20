import 'package:flutter_test/flutter_test.dart';
import 'package:sky_defense/core/storage/key_value_storage.dart';
import 'package:sky_defense/data/datasources/player_local_datasource.dart';
import 'package:sky_defense/data/repositories/player_repository_impl.dart';
import 'package:sky_defense/domain/entities/player_economy.dart';
import 'package:sky_defense/domain/entities/player_profile.dart';
import 'package:sky_defense/domain/entities/player_progress.dart';
import 'package:sky_defense/domain/entities/player_settings.dart';

class _InMemoryStorage implements KeyValueStorage {
  final Map<String, Object?> _data = <String, Object?>{};

  @override
  T? read<T>(String key) {
    return _data[key] as T?;
  }

  @override
  Future<void> write<T>(String key, T value) async {
    _data[key] = value;
  }

  @override
  Future<void> writeAll(Map<String, dynamic> values) async {
    _data.addAll(values);
  }
}

void main() {
  test('PlayerRepository saves and reads player profile', () async {
    final _InMemoryStorage storage = _InMemoryStorage();
    final PlayerLocalDataSource dataSource = PlayerLocalDataSource(storage);
    final PlayerRepositoryImpl repository = PlayerRepositoryImpl(dataSource);

    const PlayerProfile profile = PlayerProfile(
      progress: PlayerProgress(
        highScore: 10,
        totalSessions: 2,
        lastSessionEpochMs: 1700000000000,
        progressLevel: 3,
        currentStreakDay: 2,
        lastRewardClaimEpochMs: 1700000000000,
      ),
      economy: PlayerEconomy(credits: 1500, premiumCredits: 5),
      settings: PlayerSettings(soundEnabled: true, hapticEnabled: false),
    );

    await repository.savePlayerProfile(profile);
    final PlayerProfile loaded = await repository.getPlayerProfile();

    expect(loaded.progress.highScore, 10);
    expect(loaded.progress.progressLevel, 3);
    expect(loaded.progress.currentStreakDay, 2);
    expect(loaded.economy.credits, 1500);
    expect(loaded.settings.hapticEnabled, false);
  });
}
