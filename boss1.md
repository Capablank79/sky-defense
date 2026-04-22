# Boss Fase 1 (Despues de 1-4)

## Objetivo
- Definir una implementacion clara del boss de fase 1.
- Regla dura: secuencia obligatoria `1-1 -> 1-2 -> 1-3 -> 1-4 -> Boss`.
- No desarrollar aqui; este documento es guia tecnica para implementar.

## Reglas Funcionales Cerradas
1. El boss aparece solo al terminar `1-4`.
2. No puede iniciar `2-1` hasta que el boss sea derrotado.
3. El trigger de boss ocurre solo cuando `1-4` termina y no quedan amenazas activas.
4. Al entrar al boss, el estado de wave debe ser `boss` hasta `boss defeated` o `game over`.
5. La condicion de victoria del boss es `boss.health <= 0`.
6. Al iniciar boss se limpia estado transicional para evitar arrastres visuales/logicos.
7. La UI debe mostrar claramente estado `BOSS` durante todo el encuentro.
8. Recompensa de boss separada de recompensa normal de `1-4`.
9. Si hay pausa/restart/continue, el estado boss debe conservar consistencia.
10. El boss debe sentirse evento especial, no solo otra oleada.

## Criterios de Aceptacion
- Caso A: completar `1-4` inicia boss.
- Caso B: sin matar boss, no hay avance a `2-1`.
- Caso C: al matar boss, inicia `2-1`.
- Caso D: HUD/overlay muestra boss activo correctamente.
- Caso E: restart/continue durante boss mantiene flujo coherente.

## Archivos Dart Involucrados
- `lib/game/engine/wave_manager.dart`
- `lib/game/engine/game_manager.dart`
- `lib/game/entities/boss.dart`
- `lib/game/entities/wave.dart`
- `lib/game/entities/missile.dart`
- `lib/game/systems/missile_system.dart`
- `lib/game/engine/sky_defense_game.dart`
- `lib/presentation/screens/game_screen.dart`
- `lib/presentation/providers/system_providers.dart`
- `lib/core/config/game_balance_config.dart`

## Checklist Tecnica Por Archivo

### `wave_manager.dart`
- Forzar flujo `1-4 -> boss` sin excepciones.
- Bloquear avance de fase durante boss hasta `onBossDefeated()`.
- Emitir metadata correcta (`waveJustStarted`, `completedBossWave`).
- Agregar test anti-regresion para impedir salto `1-4 -> 2-1`.

### `game_manager.dart`
- Spawnear boss solo cuando `waveTick.bossWave == true`.
- Implementar maquina de estados del boss (`intro`, `attackA`, `attackB`, `enrage`).
- Programar ataques especiales por timers.
- Mantener oleada complementaria con limite de amenazas.
- Cerrar boss solo por muerte y notificar `onBossDefeated()`.
- Separar recompensas de `1-4` y `boss clear`.

### `boss.dart`
- Extender entidad con estado, timers y flag de enrage.
- Mantener compatibilidad con vida, cooldown y movimiento actual.

### `wave.dart`
- Agregar parametros de boss para tuning (cooldowns, enrage, patrones).
- Evitar valores magicos en `GameManager`.

### `missile.dart` y `missile_system.dart`
- Definir soporte para patrones de ataque del boss (rafaga/abanico).
- Asegurar legibilidad y telegraph de ataques.
- Respetar limites de spawn y bounds del mapa.

### `sky_defense_game.dart`
- Mejorar feedback visual de boss (barra HP, enrage, telegraph).
- Diferenciar claramente misiles de boss.

### `game_screen.dart`
- Mostrar overlay boss con estado y alertas.
- Mantener textos localizados ES/EN.

### `game_balance_config.dart`
- Incluir `bossConfig` tipado y validado.
- Leer desde JSON local y fallback seguro.

## Tabla Inicial De Balance (Boss de Fase 1)

### Objetivo de combate
- Duracion esperada: `40-55s`.
- Sensacion: mas tenso que `1-4`, pero legible.

### Stats base
- `bossHp`: `18`
- `moveSpeedX`: `82`
- `contactRadius`: `24`
- `baseFireCooldown`: `2.20s`
- `enrageHpThreshold`: `35%` (HP <= `6`)
- `enrageMoveMultiplier`: `1.20x`
- `enrageCooldownMultiplier`: `0.78x`

### Patron A: Salva Dirigida (`targeted_burst`)
- `cooldown`: `3.40s`
- `windup`: `0.45s`
- `shots`: `3`
- `shotSpacing`: `0.18s`
- `missileType`: `boss`
- `speedMultiplier`: `0.95x`
- `damagePerHit`: `2`
- `targetRule`: base mas cercana al centro, fallback ciudad viva.

### Patron B: Barrido En Abanico (`fan_sweep`)
- `cooldown`: `5.20s`
- `windup`: `0.60s`
- `shots`: `5`
- `spreadAngle`: `36 grados`
- `missileType`: `heavy`
- `speedMultiplier`: `0.88x`
- `damagePerHit`: `1`

### Oleada Complementaria Durante Boss
- `enabled`: `true`
- `spawnInterval`: `1.55s`
- `maxConcurrentThreatsDuringBoss`: `6`
- `typeWeights`: `slow 0.25 / medium 0.45 / fast 0.20 / zigzag 0.10`
- `heavyProbability`: `0.04`
- `splitProbability`: `0.03`

### Enrage
- `targeted_burst.cooldown`: `3.40s -> 2.50s`
- `fan_sweep.cooldown`: `5.20s -> 3.90s`
- `moveSpeedX`: `82 -> 98`
- `bossMissileSpeedMultiplier`: `+12%`
- `supportWave.spawnInterval`: `1.55s -> 1.35s`

### Recompensas sugeridas
- `bossKillScore`: `+120`
- `bossClearCredits`: `+180`
- `bonusNoBaseLostCredits`: `+40`

## Telemetria Minima
- `timeToKillBoss`
- `basesLostDuringBoss`
- `bossShotsFired`
- `bossShotsHit`
- `playerInterceptorsUsed`
- `attemptsToClearPhase1Boss`

## Bloque JSON De Referencia
```json
{
  "version": 2,
  "baseSpawnIntervalSeconds": 1.25,
  "endSpawnIntervalSeconds": 0.85,
  "maxConcurrentThreats": 8,
  "baseThreatSpeed": 1.0,
  "speedStepEveryWaves": 2.0,
  "speedStepFactor": 0.10,
  "baseExplosionRadius": 24.0,
  "collisionTolerance": 8.0,
  "bossConfig": {
    "phaseBossWaveNumber": 5,
    "hpBase": 18,
    "moveSpeedX": 82.0,
    "contactRadius": 24.0,
    "baseFireCooldownSeconds": 2.20,
    "enrage": {
      "hpThresholdRatio": 0.35,
      "moveSpeedMultiplier": 1.20,
      "fireCooldownMultiplier": 0.78,
      "bossMissileSpeedMultiplier": 1.12,
      "supportWaveSpawnIntervalSeconds": 1.35
    },
    "attackPatterns": {
      "targetedBurst": {
        "enabled": true,
        "cooldownSeconds": 3.40,
        "windupSeconds": 0.45,
        "shots": 3,
        "shotSpacingSeconds": 0.18,
        "missileType": "boss",
        "speedMultiplier": 0.95,
        "damagePerHit": 2,
        "targetPriority": "nearest_base_to_center",
        "fallbackTarget": "alive_city"
      },
      "fanSweep": {
        "enabled": true,
        "cooldownSeconds": 5.20,
        "windupSeconds": 0.60,
        "shots": 5,
        "spreadAngleDegrees": 36.0,
        "missileType": "heavy",
        "speedMultiplier": 0.88,
        "damagePerHit": 1
      }
    },
    "supportWave": {
      "enabled": true,
      "spawnIntervalSeconds": 1.55,
      "maxConcurrentThreatsDuringBoss": 6,
      "typeWeights": {
        "slow": 0.25,
        "medium": 0.45,
        "fast": 0.20,
        "zigzag": 0.10
      },
      "heavyProbability": 0.04,
      "splitProbability": 0.03
    },
    "rewards": {
      "bossKillScore": 120,
      "bossClearCredits": 180,
      "bonusNoBaseLostCredits": 40
    }
  }
}
```

## Orden Recomendado De Implementacion
1. `wave_manager.dart` + tests de flujo `1-4 -> boss -> 2-1`.
2. `boss.dart` / `wave.dart` + estructura de config.
3. `game_manager.dart` (IA, patrones, enrage, rewards).
4. `missile.dart` / `missile_system.dart` para ataques especiales.
5. `sky_defense_game.dart` + `game_screen.dart` + localizacion.
6. Ajuste de balance final + smoke test en Windows.
