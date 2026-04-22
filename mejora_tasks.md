# Tablero de Mejoras (Secuencial)

## Checklist
- [x] Mejora 1: Corregir atribucion de cierre de oleada/boss para recompensas.
- [x] Mejora 2: Unificar semantica de oleada (global vs por fase) en HUD/estado.
- [x] Mejora 3: Aplicar limite estricto de amenazas concurrentes en spawn.
- [x] Mejora 4: Consolidar economia en dominio (sin dependencia de listeners UI).
- [x] Mejora 5: Centralizar tuning real de fases desde configuracion versionada.
- [x] Mejora 6: Migrar textos hardcodeados de gameplay a localizacion ES/EN.
- [x] Mejora 7: Crear suite de pruebas de regresion de fases/oleadas/boss.

## Reportes por Mejora

### Reporte 1 - Atribucion de recompensa boss/oleada
- Estado: Completada
- Objetivo: evitar que la recompensa se calcule con la fase/oleada ya avanzada tras derrota de boss.
- Cambios:
  - Se agregaron metadatos de cierre en `WaveTick`: `completedPhaseNumber`, `completedWaveNumber`, `completedBossWave`.
  - Se capturan esos valores antes de la transicion en `WaveManager` para `waitingClear` y `boss`.
  - `GameManager` ahora premia usando metadatos de cierre, con fallback al estado actual.
- Validacion:
  - `flutter analyze`: falla por error previo en `test/widget_test.dart` (`MyApp` inexistente).
  - `flutter run -d windows`: compila y abre, luego se corta conexion por advertencias del plugin `audioplayers` en hilo no plataforma.
- Riesgo residual:
  - Pendiente limpiar error heredado de test para dejar `analyze` en verde.

### Reporte 2 - Semantica de oleada unificada
- Estado: Completada
- Objetivo: separar claramente oleada global vs oleada dentro de fase para evitar ambiguedad en HUD y estado.
- Cambios:
  - `WaveTick.currentWave` ahora representa oleada global.
  - Se agregaron getters explicitos en `GameManager`: `globalWave` y `waveInPhase`.
  - `phaseWaveLabel` se alinea a formato de fase + oleada en fase.
  - HUD superior ahora muestra `Fase`, `Oleada` (por fase) y `Global` de forma explicita.
  - Overlay de game over muestra `Phase` y `Wave` tomando `session.phaseNumber` y `session.waveNumber`.
- Validacion:
  - `flutter analyze`: sigue fallando por error previo en `test/widget_test.dart` (`MyApp` inexistente).
  - `flutter run -d windows`: compila y ejecuta; persisten advertencias del plugin `audioplayers` y luego se pierde conexion al dispositivo.
- Riesgo residual:
  - Queda pendiente resolver el test heredado para recuperar validacion estatica completa.

### Reporte 3 - Limite estricto de amenazas concurrentes
- Estado: Completada
- Objetivo: impedir spawns cuando se alcance `maxConcurrentThreats`, en vez de permitirlos con retraso.
- Cambios:
  - En `_updateSpawning`, si `activeMissiles >= maxConcurrentThreats` se bloquea el spawn.
  - Se estabiliza `_spawnTimer` para evitar explosiones de spawn al liberar el cap.
  - Se elimino el comportamiento previo que permitia spawn "mas lento" aun excediendo el limite.
- Validacion:
  - `flutter analyze`: sigue fallando por error previo en `test/widget_test.dart` (`MyApp` inexistente).
  - `flutter run -d windows`: compila y levanta en Windows correctamente (sesion detenida manualmente tras validar arranque).
- Riesgo residual:
  - Pendiente corregir test heredado para dejar `flutter analyze` en verde.

### Reporte 4 - Economia consolidada en dominio
- Estado: Completada
- Objetivo: retirar logica de recompensa por oleada desde UI para evitar acoplamiento de negocio en presentacion.
- Cambios:
  - Se elimino el listener por `waveRewardCounter` en `GameScreen`.
  - Se agrego `syncCredits(int credits)` en `PlayerNotifier` para sincronizacion de saldo por valor final.
  - UI ahora solo refleja y sincroniza el saldo consolidado de `GameManager` (`playerCredits`) sin calcular recompensas.
- Validacion:
  - `flutter analyze`: sigue fallando por error previo en `test/widget_test.dart` (`MyApp` inexistente).
  - `flutter run -d windows`: compila y ejecuta; siguen advertencias de `audioplayers` por hilo no plataforma.
- Riesgo residual:
  - Pendiente corregir test heredado y revisar advertencias nativas del plugin de audio.

### Reporte 5 - Tuning de fases centralizado por configuracion
- Estado: Completada
- Objetivo: eliminar dependencias de valores hardcodeados para ritmo de oleadas y escalar dificultad desde configuracion.
- Cambios:
  - `GameBalanceConfig` incorpora `endSpawnIntervalSeconds`, `speedStepEveryWaves`, `speedStepFactor`.
  - `assets/config/game_balance.json` agrega esas claves para tuning explicito.
  - `waveManagerProvider` ahora construye `WaveManager` con parametros del config resuelto.
  - `WaveManager._configureWave()` usa interpolacion `start -> end` por progreso de oleada y acelera por fase con `speedStepFactor`.
  - `WaveManager._currentEnemySpeed()` usa rampa exponencial por oleada global basada en `speedStepEveryWaves` y `speedStepFactor`.
- Validacion:
  - `flutter analyze`: sigue fallando por error previo en `test/widget_test.dart` (`MyApp` inexistente).
  - `flutter run -d windows`: compila y ejecuta en Windows.
- Riesgo residual:
  - Falta estabilizar `analyze` corrigiendo test heredado fuera del flujo de gameplay.

### Reporte 6 - Localizacion de gameplay ES/EN
- Estado: Completada
- Objetivo: eliminar textos hardcodeados en HUD y overlays para soportar cambio de idioma en tiempo real.
- Cambios:
  - `game_screen.dart` ahora usa `AppLocalizations` en HUD superior, overlay de boss y game over.
  - Se añadieron claves nuevas en `es.json` y `en.json`: `game_phase_value`, `game_global_wave_value`, `game_phase_wave_compact`, `game_ammo_bases_value`, `game_boss_alert`.
  - Se reutilizaron claves existentes de score/creditos/bases/interceptores para evitar duplicidad.
- Validacion:
  - `flutter analyze`: sigue fallando por error previo en `test/widget_test.dart` (`MyApp` inexistente).
  - `flutter run -d windows`: compila y ejecuta en Windows.
- Riesgo residual:
  - Se mantiene pendiente resolver el test heredado para validacion estatica completamente limpia.

### Reporte 7 - Suite de regresion de fases/oleadas/boss
- Estado: Completada
- Objetivo: cubrir transiciones criticas del ciclo de fases para reducir regresiones.
- Cambios:
  - Nuevo test `test/wave_manager_test.dart` con casos de:
    - cierre de oleada normal con metadata correcta (`completedPhaseNumber`, `completedWaveNumber`, `completedBossWave`),
    - derrota de boss con metadata de cierre y avance de fase confirmado.
  - Se corrigio `test/widget_test.dart` heredado que referenciaba `MyApp` inexistente, reemplazandolo por un scaffold valido.
- Validacion:
  - `flutter analyze`: sin issues.
  - `flutter run -d windows`: compila y ejecuta en Windows.
- Riesgo residual:
  - Recomendado agregar en siguiente iteracion pruebas de economia (`_awardWaveCredits`) y cap de amenazas con asserts de conteo para blindaje adicional.
