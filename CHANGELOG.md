# Changelog

## [Unreleased] - 2026-04-22

### Mejora 1 - Atribucion correcta de cierre de oleada/boss
- Se agregaron metadatos de cierre en `WaveTick` para distinguir el evento que termina de estado ya avanzado.
- `GameManager` ahora calcula recompensas usando datos de cierre (`completedPhaseNumber`, `completedWaveNumber`, `completedBossWave`).
- Se corrige inconsistencia donde la recompensa del boss podia asignarse a la fase siguiente.

### Mejora 2 - Semantica de oleadas unificada
- Se separa explicitamente `globalWave` y `waveInPhase` en `GameManager`.
- `WaveTick.currentWave` representa oleada global.
- HUD y overlay reflejan fase + oleada de fase de forma consistente.

### Mejora 3 - Limite estricto de amenazas concurrentes
- En `WaveManager`, el spawn se bloquea al alcanzar `maxConcurrentThreats`.
- Se elimina el comportamiento anterior que permitia spawn "mas lento" aun sobre el limite.
- Se estabiliza `spawnTimer` para evitar rafagas al liberar el cap.

### Mejora 4 - Economia consolidada en dominio
- Se retiro en UI la logica de aplicar recompensa por `waveRewardCounter`.
- Se agrega `syncCredits(int credits)` en `PlayerNotifier` para sincronizar saldo final consolidado.
- La UI queda como consumidora de estado, sin logica economica de negocio.

### Mejora 5 - Tuning de fases centralizado por configuracion
- `GameBalanceConfig` incorpora:
  - `endSpawnIntervalSeconds`
  - `speedStepEveryWaves`
  - `speedStepFactor`
- Se actualiza `assets/config/game_balance.json` con estos parametros.
- `waveManagerProvider` inyecta tuning desde config resuelta.
- `WaveManager` usa los parametros para ritmo de spawn y rampa de velocidad por oleada global.

### Mejora 6 - Localizacion de gameplay ES/EN
- Se eliminaron textos hardcodeados en HUD y overlays de juego.
- Se añadieron claves nuevas en `assets/lang/es.json` y `assets/lang/en.json`:
  - `game_phase_value`
  - `game_global_wave_value`
  - `game_phase_wave_compact`
  - `game_ammo_bases_value`
  - `game_boss_alert`
- Se mantiene soporte de cambio de idioma en tiempo real.

### Mejora 7 - Suite inicial de regresion
- Se agrega `test/wave_manager_test.dart` con pruebas de:
  - cierre de oleada normal con metadata de cierre correcta.
  - derrota de boss con metadata de cierre y avance de fase esperado.
- Se corrige `test/widget_test.dart` heredado para eliminar referencia a `MyApp` inexistente.
- El proyecto queda con `flutter analyze` en verde.

### Verificacion
- `flutter analyze`: sin issues.
- `flutter run -d windows`: compila y ejecuta correctamente.
