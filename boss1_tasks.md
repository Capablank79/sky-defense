# Boss 1 - Tasks De Implementacion

> Objetivo: implementar el boss de fase 1 con flujo obligatorio `1-1 -> 1-2 -> 1-3 -> 1-4 -> Boss -> 2-1`.
> Referencia funcional completa: `boss1.md`.

## 0) Preparacion
- [ ] Confirmar baseline estable en `main`.
- [ ] Crear rama de trabajo: `feature/boss-phase1`.
- [ ] Correr smoke actual: `flutter test` y `flutter run -d windows`.
- [ ] Validar que no hay regresiones abiertas antes de tocar boss.

## 1) Flujo De Oleadas (Gate Critico)
### Archivos
- `lib/game/engine/wave_manager.dart`
- `test/wave_manager_test.dart`

### Tareas
- [ ] Asegurar regla dura `1-4 -> boss` siempre.
- [ ] Bloquear avance a `2-1` hasta `onBossDefeated()`.
- [ ] Mantener metadata consistente (`waveJustStarted`, `waveJustEnded`, `completedBossWave`).
- [ ] Verificar `currentWave` logica en boss como `x-5`.

### DoD
- [ ] Test: no existe salto directo `1-4 -> 2-1`.
- [ ] Test: tras `onBossDefeated()` avanza a `2-1`.
- [ ] Test: boss inicia solo despues de cerrar `1-4`.

## 2) Modelo De Boss Y Configuracion
### Archivos
- `lib/game/entities/boss.dart`
- `lib/game/entities/wave.dart`
- `lib/core/config/game_balance_config.dart`
- `assets/config/game_balance.json`

### Tareas
- [ ] Extender `Boss` con estado interno (`intro`, `attackA`, `attackB`, `enrage`).
- [ ] Agregar campos de timing y control de patrones.
- [ ] Definir `bossConfig` tipado en `GameBalanceConfig`.
- [ ] Parsear y validar `bossConfig` desde JSON local.
- [ ] Incluir defaults seguros y fallback.

### DoD
- [ ] Parseo robusto de `bossConfig` con tests de fallback.
- [ ] Ningun valor magico de boss queda hardcodeado en manager.

## 3) IA Del Boss Y Patrones
### Archivo
- `lib/game/engine/game_manager.dart`

### Tareas
- [ ] Spawnear boss solo cuando `waveTick.bossWave == true`.
- [ ] Implementar scheduler de patrones:
  - [ ] `targeted_burst`
  - [ ] `fan_sweep`
- [ ] Implementar `enrage` por umbral de vida.
- [ ] Mantener oleada complementaria durante boss con limite de amenazas.
- [ ] Definir rewards de boss separadas.
- [ ] Asegurar notificacion de derrota: `onBossDefeated()`.

### DoD
- [ ] Boss no permite avanzar fase si sigue vivo.
- [ ] Boss muere y desbloquea `2-1` correctamente.
- [ ] Duracion media del encuentro cae en rango objetivo.

## 4) Misiles Especiales Del Boss
### Archivos
- `lib/game/entities/missile.dart`
- `lib/game/systems/missile_system.dart`

### Tareas
- [ ] Soportar spawn consistente para patrones multi-disparo.
- [ ] Diferenciar tipos/metadata de misiles especiales del boss.
- [ ] Validar limites de mapa y retarget con ataques del boss.
- [ ] Verificar que el dano por tipo no rompe balance base.

### DoD
- [ ] Sin fugas de misiles fuera de bounds.
- [ ] Sin sobrepasar `maxConcurrentThreatsDuringBoss`.

## 5) UI Y Feedback Del Encuentro
### Archivos
- `lib/game/engine/sky_defense_game.dart`
- `lib/presentation/screens/game_screen.dart`
- `assets/lang/es.json`
- `assets/lang/en.json`

### Tareas
- [ ] Mejorar representacion visual del boss (HP, enrage, telegraph).
- [ ] Mostrar estado boss en overlay de forma clara.
- [ ] Agregar textos localizados ES/EN:
  - [ ] entrada de boss
  - [ ] estado enrage
  - [ ] aviso de patron (opcional)
  - [ ] boss derrotado

### DoD
- [ ] Ningun texto hardcodeado nuevo.
- [ ] Overlay informa boss activo sin confundir countdown normal.

## 6) Tests De Regresion Y Cobertura
### Archivos
- `test/wave_manager_test.dart`
- `test/attack_defense_systems_test.dart`
- `test/` (nuevo archivo para boss/game_manager si aplica)

### Tareas
- [ ] Test de flujo completo fase 1 con boss.
- [ ] Test de ataques del boss por timer/estado.
- [ ] Test de transicion `boss defeated -> 2-1`.
- [ ] Test de rewards separadas (`1-4` vs boss clear).
- [ ] Test de persistencia minima en restart/continue durante boss.

### DoD
- [ ] `flutter test` verde.
- [ ] Sin degradar tests previos de oleadas 1-1..1-4.

## 7) Balance Pass (Iterativo)
### Referencia
- valores iniciales definidos en `boss1.md`.

### Tareas
- [ ] Ejecutar probe y/o telemetria de boss:
  - [ ] `timeToKillBoss`
  - [ ] `basesLostDuringBoss`
  - [ ] `bossShotsHit`
- [ ] Ajustar HP/cooldowns/spawn hasta rango objetivo.
- [ ] Validar que dificultad se siente superior a `1-4` pero legible.

### DoD
- [ ] TTK promedio ~`40-55s`.
- [ ] No hay picos injustos de muerte en los primeros segundos.

## 8) QA Final Windows
- [ ] `flutter clean`
- [ ] `flutter run -d windows`
- [ ] Playtest completo de fase 1:
  - [ ] `1-1`
  - [ ] `1-2`
  - [ ] `1-3`
  - [ ] `1-4`
  - [ ] `Boss`
  - [ ] transicion a `2-1`
- [ ] Verificar overlays, audio (si aplica), score y creditos.

## 9) Entrega Y Git
- [ ] Commit 1: flujo + config + modelo.
- [ ] Commit 2: IA boss + misiles especiales.
- [ ] Commit 3: UI + localizacion + tests.
- [ ] Push a rama y PR con checklist marcado.

## Riesgos A Vigilar
- [ ] Saturacion de amenazas durante boss (dificultad injusta).
- [ ] Inconsistencia de estado en pause/restart/continue.
- [ ] Reward duplicada por mala lectura de metadata.
- [ ] Acoplamiento fuerte entre boss y sistema de oleadas.
