# Analisis de Fases y Plan de Mejora

## Objetivo
Este documento recopila los hallazgos del analisis del sistema de fases/oleadas del proyecto, con foco en congruencia logica, sincronizacion entre sistemas y oportunidades de mejora.  
No incluye implementacion, solo diagnostico y plan.

## Hallazgos Criticos

### 1) Recompensa de jefe mal atribuida
- **Problema:** al morir el boss, `WaveManager` avanza de inmediato a la siguiente fase antes de consolidar el snapshot que consume `GameManager`.
- **Impacto:** la recompensa puede calcularse con datos de la siguiente oleada/fase en lugar del boss derrotado, afectando economia y progresion.
- **Referencias:**
  - `lib/game/engine/wave_manager.dart` (transicion boss -> siguiente fase)
  - `lib/game/engine/game_manager.dart` (`waveJustEnded` + `_awardWaveCredits`)

### 2) Indice de oleada ambiguo (global vs dentro de fase)
- **Problema:** `WaveTick.currentWave` expone `wave.waveNumber` (oleada interna), pero se consume como si fuera oleada global en varias partes.
- **Impacto:** HUD, logs y recompensas pueden mostrar/usar valores ambiguos.
- **Referencias:**
  - `lib/game/engine/wave_manager.dart` (construccion de `WaveTick`)
  - `lib/game/engine/game_manager.dart` (sincronizacion de estado interno)
  - `lib/presentation/screens/game_screen.dart` (render de oleada en HUD)

## Hallazgos Importantes

### 3) Limite de amenazas no aplicado estrictamente
- **Problema:** aunque existe `maxConcurrentThreats`, el flujo permite seguir avanzando el spawn con un ajuste de timer en vez de bloquear.
- **Impacto:** picos de amenaza pueden romper la intencion de balance por fase.
- **Referencias:**
  - `lib/game/engine/wave_manager.dart` (`_updateSpawning`)

### 4) Responsabilidad economica fragmentada (dominio/UI)
- **Problema:** parte de la logica de recompensas se refleja tambien mediante listeners en UI.
- **Impacto:** riesgo de duplicidades y acoplamiento innecesario entre presentacion y economia.
- **Referencias:**
  - `lib/game/engine/game_manager.dart` (`_awardWaveCredits`)
  - `lib/presentation/screens/game_screen.dart` (listener de `waveRewardCounter`)

### 5) Parametros de tuning definidos pero no gobernando el flujo real
- **Problema:** hay parametros de configuracion en `WaveManager` que no se usan como fuente principal al calcular spawn/ritmo.
- **Impacto:** dificulta calibrar fases con consistencia y predecibilidad.
- **Referencias:**
  - `lib/game/engine/wave_manager.dart` (constructor y `_configureWave`)

## Hallazgos de Coherencia de Producto

### 6) Textos hardcodeados en gameplay
- **Problema:** existen strings directos en HUD/overlay/game over.
- **Impacto:** contradice requisito de localizacion ES/EN con cambio en tiempo real.
- **Referencias:**
  - `lib/presentation/screens/game_screen.dart`
  - recursos de idioma en `assets/lang/es.json` y `assets/lang/en.json`

### 7) Cobertura de pruebas insuficiente para fases
- **Problema:** no hay pruebas enfocadas en la maquina de estados de oleadas/boss.
- **Impacto:** alta probabilidad de regresiones en transiciones criticas.
- **Referencias:**
  - carpeta `test/` (sin pruebas especificas del ciclo de fases)

## Plan de Mejora (Sin Desarrollar)

### Fase 1 - Contrato de estado unico
- Definir claramente: `globalWave`, `phaseNumber`, `waveInPhase`, `isBossWave`, `transitionEvent`.
- Separar estado actual de evento de cierre para evitar premios/UX desfasados.

### Fase 2 - Maquina de estados formal
- Establecer eventos explicitos: `WaveCleared`, `BossSpawned`, `BossDefeated`, `CountdownFinished`.
- Documentar reglas de entrada/salida por estado (`spawning`, `waitingClear`, `countdown`, `boss`).

### Fase 3 - Balance centralizado por configuracion
- Unificar parametros de spawn, conteo, pesos y boss en fuente de configuracion versionada.
- Hacer que `WaveManager` consuma esa fuente de forma directa y consistente.

### Fase 4 - Economia en dominio (sin logica de negocio en UI)
- Mantener recompensas y validaciones en capa de dominio/game manager.
- Dejar UI solo como consumidor de estado ya consolidado.

### Fase 5 - UX de fases y localizacion
- Definir mensajes de transicion claros y breves (`Inicio fase`, `Boss incoming`, `Fase completada`).
- Migrar todos los textos de gameplay a claves de localizacion ES/EN.

### Fase 6 - Suite de regresion para fases
- Diseñar pruebas para:
  - `1-4 -> countdown -> boss`
  - `boss defeated -> fase+1`
  - recompensas correctas por oleada y por boss
  - no bloqueo con amenazas activas
  - no duplicacion de creditos

## Preguntas de Producto Antes de Implementar
- ¿La UI debe mostrar oleada global (`1..N`) o oleada por fase (`1..4 + boss`)?
- ¿El boss debe tener recompensa separada del cierre de oleada normal?
- ¿Debe existir countdown visual tambien al pasar de boss derrotado a nueva fase?

## Cierre
El sistema ha mejorado en estabilidad respecto a iteraciones previas, pero aun existen puntos de fragilidad en semantica de estado, economia y coherencia UI/localizacion.  
Este plan prioriza primero consistencia funcional y luego experiencia/jugabilidad para escalar fases con menor riesgo de regresion.
