import 'package:sky_defense/game/entities/base.dart';
import 'package:sky_defense/game/entities/city.dart';
import 'package:flame/components.dart';

class CitySystem {
  List<City> _cities = <City>[];
  List<City> get cities => List<City>.unmodifiable(_cities);
  List<City> get aliveCities => List<City>.unmodifiable(
        _cities.where((City city) => city.isAlive),
      );

  List<City> getCities() {
    return cities;
  }

  List<City> getAliveCities() {
    return aliveCities;
  }

  void positionBetweenBases(List<Base> bases) {
    if (bases.length < 2) {
      _cities = <City>[];
      return;
    }
    final List<Base> sorted = List<Base>.from(bases)
      ..sort((Base a, Base b) => a.x.compareTo(b.x));
    final List<City> next = <City>[];
    for (int i = 0; i < sorted.length - 1; i += 1) {
      final Base left = sorted[i];
      final Base right = sorted[i + 1];
      final String id = 'city_$i';
      City? existing;
      for (final City city in _cities) {
        if (city.id == id) {
          existing = city;
          break;
        }
      }
      next.add(
        City(
          id: id,
          position: Vector2(
            (left.x + right.x) * 0.5,
            (left.y + right.y) * 0.5,
          ),
          isAlive: existing?.isAlive ?? true,
        ),
      );
    }
    _cities = next;
  }

  bool destroyCityAtTarget({
    String? targetCityId,
    required double targetX,
    required double targetY,
    double hitRadius = 24,
  }) {
    if (targetCityId != null && targetCityId.isNotEmpty) {
      final bool byIdDestroyed = destroyCity(targetCityId);
      if (byIdDestroyed) {
        return true;
      }
    }

    final double hitRadiusSquared = hitRadius * hitRadius;
    int closestIndexInRadius = -1;
    double nearestDistanceInRadius = double.infinity;
    for (int i = 0; i < _cities.length; i += 1) {
      final City city = _cities[i];
      if (!city.isAlive) {
        continue;
      }
      final double dx = city.x - targetX;
      final double dy = city.y - targetY;
      final double distanceSquared = (dx * dx) + (dy * dy);
      if (distanceSquared <= hitRadiusSquared &&
          distanceSquared < nearestDistanceInRadius) {
        nearestDistanceInRadius = distanceSquared;
        closestIndexInRadius = i;
      }
    }

    if (closestIndexInRadius >= 0) {
      return destroyCity(_cities[closestIndexInRadius].id);
    }

    // Fallback determinista: destruye la ciudad viva mas cercana.
    int closestAliveIndex = -1;
    double nearestDistance = double.infinity;
    for (int i = 0; i < _cities.length; i += 1) {
      final City city = _cities[i];
      if (!city.isAlive) {
        continue;
      }
      final double dx = city.x - targetX;
      final double dy = city.y - targetY;
      final double distanceSquared = (dx * dx) + (dy * dy);
      if (distanceSquared < nearestDistance) {
        nearestDistance = distanceSquared;
        closestAliveIndex = i;
      }
    }
    if (closestAliveIndex < 0) {
      return false;
    }
    return destroyCity(_cities[closestAliveIndex].id);
  }

  bool destroyCity(String cityId) {
    for (int i = 0; i < _cities.length; i += 1) {
      final City city = _cities[i];
      if (city.id != cityId || !city.isAlive) {
        continue;
      }
      _cities[i] = city.copyWith(isAlive: false);
      return true;
    }
    return false;
  }

  void restoreForContinue() {
    if (_cities.isEmpty) {
      return;
    }
    bool restored = false;
    for (int i = 0; i < _cities.length; i += 1) {
      final City city = _cities[i];
      if (!city.isAlive) {
        _cities[i] = city.copyWith(isAlive: true);
        restored = true;
        break;
      }
    }
    if (!restored) {
      _cities =
          _cities.map((City city) => city.copyWith(isAlive: true)).toList();
    }
  }

  void reset() {
    _cities = _cities.map((City city) => city.copyWith(isAlive: true)).toList();
  }
}
