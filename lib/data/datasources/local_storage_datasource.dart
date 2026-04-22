import 'package:flutter/foundation.dart';
import 'package:sky_defense/core/constants/app_constants.dart';
import 'package:sky_defense/core/storage/key_value_storage.dart';

class LocalStorageDataSource {
  const LocalStorageDataSource(this._storage);

  final KeyValueStorage _storage;

  Map<String, dynamic> readPlayerData() {
    try {
      final Object? raw = _storage.read<Object>(AppConstants.playerDataKey);
      if (raw is! Map) {
        return _fallbackPlayerData();
      }
      final Map<dynamic, dynamic> map = Map<dynamic, dynamic>.from(raw);
      if (!_isValidPlayerMap(map)) {
        return _fallbackPlayerData();
      }
      return _toSafePlayerMap(map);
    } catch (error) {
      debugPrint('LocalStorageDataSource.readPlayerData failed: $error');
      return _fallbackPlayerData();
    }
  }

  Future<bool> writePlayerData(Map<String, dynamic> playerData) async {
    final Map<String, dynamic> safeData = _toSafePlayerMap(playerData);
    safeData['lastUpdatedAt'] = DateTime.now().millisecondsSinceEpoch;
    return writeAtomic(<String, dynamic>{
      AppConstants.playerDataKey: safeData,
    });
  }

  Future<bool> writeAtomic(Map<String, dynamic> values) async {
    try {
      await _storage.writeAll(values);
      return true;
    } catch (error) {
      debugPrint('LocalStorageDataSource.writeAtomic failed: $error');
      return false;
    }
  }

  bool _isValidPlayerMap(Map<dynamic, dynamic> map) {
    return map['progress'] is Map &&
        map['economy'] is Map &&
        map['settings'] is Map;
  }

  Map<String, dynamic> _toSafePlayerMap(Map<dynamic, dynamic> map) {
    return <String, dynamic>{
      'progress': Map<String, dynamic>.from(
          (map['progress'] as Map?) ?? <String, dynamic>{}),
      'economy': Map<String, dynamic>.from(
          (map['economy'] as Map?) ?? <String, dynamic>{}),
      'settings': Map<String, dynamic>.from(
          (map['settings'] as Map?) ?? <String, dynamic>{}),
      'upgrades': <String, dynamic>{
        'ammoLevel': ((map['upgrades'] as Map?)?['ammoLevel'] as int?) ?? 1,
        'reloadLevel': ((map['upgrades'] as Map?)?['reloadLevel'] as int?) ?? 1,
        'explosionRadiusLevel':
            ((map['upgrades'] as Map?)?['explosionRadiusLevel'] as int?) ?? 1,
        'interceptorSpeedLevel':
            ((map['upgrades'] as Map?)?['interceptorSpeedLevel'] as int?) ?? 1,
      },
    };
  }

  Map<String, dynamic> _fallbackPlayerData() {
    return <String, dynamic>{
      'progress': <String, dynamic>{
        'highScore': 0,
        'totalSessions': 0,
        'lastSessionEpochMs': 0,
        'progressLevel': 1,
        'currentStreakDay': 1,
        'lastRewardClaimEpochMs': 0,
      },
      'economy': <String, dynamic>{
        'credits': 0,
        'premiumCredits': 0,
      },
      'settings': <String, dynamic>{
        'soundEnabled': true,
        'hapticEnabled': true,
      },
      'upgrades': <String, dynamic>{
        'ammoLevel': 1,
        'reloadLevel': 1,
        'explosionRadiusLevel': 1,
        'interceptorSpeedLevel': 1,
      },
      'lastUpdatedAt': 0,
    };
  }
}
