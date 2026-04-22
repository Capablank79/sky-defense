import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sky_defense/game/entities/base.dart';
import 'package:sky_defense/game/entities/city.dart';
import 'package:sky_defense/game/entities/missile.dart';
import 'package:sky_defense/game/systems/base_system.dart';
import 'package:sky_defense/game/systems/city_system.dart';
import 'package:sky_defense/game/systems/missile_system.dart';

void main() {
  test('BaseSystem damageBaseAtTarget prioriza targetBaseId cuando existe', () {
    final BaseSystem baseSystem = BaseSystem();
    baseSystem.initializeBases(
      worldWidth: 400,
      worldHeight: 800,
      baseCount: 3,
    );
    final List<Base> before = baseSystem.getBases();
    final Base target = before.first;

    final bool impacted = baseSystem.damageBaseAtTarget(
      targetBaseId: target.id,
      targetX: target.x + 150,
      targetY: target.y + 60,
      damage: 1,
    );

    final List<Base> after = baseSystem.getBases();
    final Base updated = after.firstWhere((Base b) => b.id == target.id);
    expect(impacted, isTrue);
    expect(updated.health, target.health - 1);
  });

  test('CitySystem destroyCityAtTarget destruye por targetCityId', () {
    final CitySystem citySystem = CitySystem();
    final List<Base> bases = <Base>[
      const Base(id: 'base_0', x: 50, y: 700),
      const Base(id: 'base_1', x: 150, y: 700),
      const Base(id: 'base_2', x: 250, y: 700),
    ];
    citySystem.positionBetweenBases(bases);
    final City city = citySystem.getCities().first;

    final bool destroyed = citySystem.destroyCityAtTarget(
      targetCityId: city.id,
      targetX: city.x + 100,
      targetY: city.y + 40,
    );

    final City updated =
        citySystem.getCities().firstWhere((City c) => c.id == city.id);
    expect(destroyed, isTrue);
    expect(updated.isAlive, isFalse);
  });

  test(
      'MissileSystem ensureValidTargets retargetea ciudad invalida a ciudad viva',
      () {
    final MissileSystem missileSystem = MissileSystem();
    missileSystem.spawnMissile(
      startX: 100,
      startY: 10,
      targetBaseId: 'city_missing',
      targetKind: MissileTargetKind.city,
      targetX: 200,
      targetY: 700,
      speed: 80,
    );

    final bool valid = missileSystem.ensureValidTargets(
      aliveBases: const <Base>[],
      aliveCities: <City>[
        City(
          id: 'city_1',
          position: Vector2(180, 680),
          isAlive: true,
        ),
      ],
    );

    final Missile missile = missileSystem.getMissiles().first;
    expect(valid, isTrue);
    expect(missile.targetKind, MissileTargetKind.city);
    expect(missile.targetBaseId, 'city_1');
    expect(missile.target.x, 180);
    expect(missile.target.y, 680);
  });

  test('Missile zigzag completa ciclo y llega a destino', () {
    final MissileSystem missileSystem = MissileSystem();
    final Missile missile = missileSystem.spawnMissile(
      startX: 0,
      startY: 0,
      targetBaseId: 'base_1',
      targetKind: MissileTargetKind.base,
      targetX: 100,
      targetY: 0,
      speed: 40,
      type: MissileType.zigzag,
      zigzagAmplitude: 16,
      zigzagFrequency: 8,
    );

    bool arrived = false;
    for (int i = 0; i < 200; i += 1) {
      missileSystem.update(0.05);
      final List<Missile> arrivedNow = missileSystem.consumeArrivedMissiles();
      if (arrivedNow.any((Missile m) => m.id == missile.id)) {
        arrived = true;
        break;
      }
    }

    expect(arrived, isTrue);
    expect(missileSystem.getActiveThreatCount(), 0);
  });

  test('Missile fuera de limites no se elimina en silencio', () {
    final MissileSystem missileSystem = MissileSystem(
      minX: -10,
      maxX: 10,
      minY: -10,
      maxY: 10,
    );
    final Missile missile = missileSystem.spawnMissile(
      startX: 0,
      startY: 0,
      targetBaseId: 'base_1',
      targetKind: MissileTargetKind.base,
      targetX: 200,
      targetY: 0,
      speed: 120,
    );

    missileSystem.update(0.2);
    final List<Missile> arrived = missileSystem.consumeArrivedMissiles();

    expect(arrived.any((Missile m) => m.id == missile.id), isTrue);
    expect(missileSystem.getMissiles(), isEmpty);
    expect(missileSystem.getActiveThreatCount(), 0);
  });
}
