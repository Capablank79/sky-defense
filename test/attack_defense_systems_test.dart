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

  test(
      'MissileSystem ensureValidTargets usa trayectoria lineal para retarget',
      () {
    final MissileSystem missileSystem = MissileSystem();
    final Missile missile = missileSystem.spawnMissile(
      startX: 100,
      startY: 10,
      targetBaseId: 'base_missing',
      targetKind: MissileTargetKind.base,
      targetX: 300,
      targetY: 700,
      speed: 80,
      type: MissileType.zigzag,
      zigzagAmplitude: 16,
      zigzagFrequency: 8,
    );
    missile.linearPosition.setValues(110, 680);
    missile.position.setValues(350, 680);

    final bool valid = missileSystem.ensureValidTargets(
      aliveBases: const <Base>[
        Base(id: 'base_near_linear', x: 120, y: 680),
        Base(id: 'base_near_visual', x: 340, y: 680),
      ],
      aliveCities: const <City>[],
    );

    expect(valid, isTrue);
    expect(missile.targetKind, MissileTargetKind.base);
    expect(missile.targetBaseId, 'base_near_linear');
    expect(missile.target.x, 120);
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

  test('Missile fuera de limites no cuenta como llegada', () {
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

    expect(arrived.any((Missile m) => m.id == missile.id), isFalse);
    expect(missileSystem.getMissiles(), isEmpty);
    expect(missileSystem.getActiveThreatCount(), 0);
  });

  test('MissileSystem respeta bounds dinamicos en mundo ancho', () {
    final MissileSystem missileSystem = MissileSystem();
    missileSystem.configureBounds(
      minX: 0,
      maxX: 2200,
      minY: 0,
      maxY: 1200,
    );
    final Missile missile = missileSystem.spawnMissile(
      startX: 1200,
      startY: 120,
      targetBaseId: 'base_1',
      targetKind: MissileTargetKind.base,
      targetX: 1600,
      targetY: 120,
      speed: 80,
    );

    missileSystem.update(0.1);
    final List<Missile> arrived = missileSystem.consumeArrivedMissiles();

    expect(arrived.any((Missile m) => m.id == missile.id), isFalse);
    expect(missileSystem.getMissiles().any((Missile m) => m.id == missile.id), isTrue);
    expect(missileSystem.getActiveThreatCount(), 1);
  });

  test('Missile dentro de bounds completa llegada real', () {
    final MissileSystem missileSystem = MissileSystem(
      minX: -10,
      maxX: 200,
      minY: -10,
      maxY: 200,
    );
    final Missile missile = missileSystem.spawnMissile(
      startX: 0,
      startY: 0,
      targetBaseId: 'base_1',
      targetKind: MissileTargetKind.base,
      targetX: 20,
      targetY: 0,
      speed: 120,
    );

    missileSystem.update(0.2);
    final List<Missile> arrived = missileSystem.consumeArrivedMissiles();

    expect(arrived.any((Missile m) => m.id == missile.id), isTrue);
    expect(missileSystem.getMissiles(), isEmpty);
    expect(missileSystem.getActiveThreatCount(), 0);
  });

  test('Tipos de misil completan ciclo sin estado invalido', () {
    final MissileSystem missileSystem = MissileSystem(
      minX: -50,
      maxX: 400,
      minY: -50,
      maxY: 400,
    );
    final List<MissileType> types = <MissileType>[
      MissileType.slow,
      MissileType.medium,
      MissileType.fast,
      MissileType.split,
      MissileType.zigzag,
      MissileType.heavy,
      MissileType.boss,
    ];
    for (int i = 0; i < types.length; i += 1) {
      final MissileType type = types[i];
      missileSystem.spawnMissile(
        startX: 0,
        startY: i * 8,
        targetBaseId: 'base_$i',
        targetKind: MissileTargetKind.base,
        targetX: 60,
        targetY: i * 8,
        speed: 60,
        type: type,
        splitRemaining: type == MissileType.split ? 1 : 0,
        zigzagAmplitude: type == MissileType.zigzag ? 14 : 0,
        zigzagFrequency: type == MissileType.zigzag ? 7.5 : 0,
      );
    }

    final Set<String> arrivedIds = <String>{};
    for (int step = 0; step < 60; step += 1) {
      missileSystem.update(0.05);
      final List<Missile> arrivedNow = missileSystem.consumeArrivedMissiles();
      for (final Missile missile in arrivedNow) {
        arrivedIds.add(missile.id);
      }
      if (arrivedIds.length == types.length) {
        break;
      }
    }

    expect(arrivedIds.length, types.length);
    expect(missileSystem.getMissiles(), isEmpty);
    expect(missileSystem.getActiveThreatCount(), 0);
  });
}
