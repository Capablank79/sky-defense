# Plan de Mejora: Ataque y Defensa (Fase 1-1 a 1-4)

## Objetivo
Corregir el ciclo de vida de los misiles enemigos para que cada misil cumpla su misión de forma determinista:

- impactar un objetivo válido (base o ciudad), o
- ser destruido por intercepción.

Evitar misiles "fantasma" o perdidos que bloqueen el avance de oleadas y asegurar la progresión completa de la fase 1 (`1-1` a `1-4`) con aumento progresivo de cantidad y velocidad.

## Alcance
- Sin implementar código en este documento.
- Definición de tareas secuenciales para ejecución técnica.
- Validación funcional y de regresión enfocada en estabilidad de oleadas.

## Archivos .dart involucrados
- `lib/game/engine/game_manager.dart`
- `lib/game/engine/wave_manager.dart`
- `lib/game/systems/missile_system.dart`
- `lib/game/entities/missile.dart`
- `lib/game/systems/base_system.dart`
- `lib/game/systems/city_system.dart`
- `lib/core/config/game_balance_config.dart`
- `test/wave_manager_test.dart`

## Plan Secuencial de Mejora

### T1. Diagnóstico controlado de misiles
- Reproducir el bug de misiles perdidos/fantasma en escenarios de oleada real.
- Registrar trazabilidad por `id` de misil: spawn -> vuelo -> llegada -> impacto/destrucción -> eliminación.
- Confirmar en qué punto se pierde el contrato de misión.

### T2. Contrato formal de misión del misil
- Establecer una regla única de ciclo de vida:
  - Todo misil debe terminar en `impactó` o `destruido`.
  - No debe existir expiración silenciosa sin resultado de combate.
- Definir estados terminales permitidos y sus transiciones válidas.

### T3. Resolución robusta de impacto en objetivo
- Ajustar el criterio de impacto para que no dependa de coincidencia milimétrica de coordenadas.
- Incluir tolerancia de impacto consistente para bases y ciudades.
- Evitar casos donde un misil llega visualmente pero no aplica daño.

### T4. Fallback determinista de objetivo
- Si no existe match exacto en el objetivo esperado, aplicar fallback controlado:
  - priorizar `targetBaseId` si sigue vivo,
  - en su defecto, seleccionar el objetivo válido más cercano.
- Garantizar que el misil arribado siempre resuelva efecto final.

### T5. Limpieza anti-fantasmas por frame
- Definir una política única de limpieza para misiles:
  - inactivos,
  - arribados y consumidos,
  - destruidos.
- Asegurar que no queden entidades residuales que cuenten como amenaza activa.

### T6. Gate de cierre de oleada
- Verificar que una oleada solo cierre cuando:
  - `missilesSpawned == missilesPerWave`, y
  - `activeThreats == 0`.
- Asegurar que `waitingClear` no quede bloqueado por residuos de estado.

### T7. Reinicio correcto de contadores por oleada
- Confirmar reinicio al iniciar cada oleada de:
  - contador de misiles spawneados,
  - temporizadores de spawn,
  - patrón de spawn.
- Mantener persistencia solo en variables globales que corresponda (score/créditos/progreso).

### T8. Curva de dificultad para fase 1-1 a 1-4
- Definir objetivos por oleada:
  - `1-1`: ritmo base estable y sin bloqueos.
  - `1-2`: aumento de cantidad.
  - `1-3`: aumento de velocidad efectiva.
  - `1-4`: presión máxima previa a boss sin residuos al cierre.
- Alinear tuning con configuración local de balance.

### T9. Validación automatizada y regresión
- Expandir pruebas para cubrir secuencia completa `1-1 -> 1-4`.
- Incluir casos de:
  - cierre correcto de oleada,
  - ausencia de misiles colgados,
  - progresión de dificultad esperada.
- Asegurar que no existan regresiones en transición a boss.

### T10. Criterios de aceptación final
- Criterio 1: cero misiles fantasma al finalizar cada oleada.
- Criterio 2: transición estable entre `1-1`, `1-2`, `1-3`, `1-4`.
- Criterio 3: reinicio consistente de contadores por oleada.
- Criterio 4: incremento perceptible de cantidad y velocidad en cada paso.
- Criterio 5: fase lista para continuar hacia boss sin bloqueos de flujo.

## Riesgos a controlar
- Sobrecorrección de tolerancias que produzca impactos no deseados.
- Doble resolución de impacto/destrucción en el mismo misil.
- Desalineación entre estado visual y estado lógico de amenaza.
- Ajustes de dificultad que rompan la progresión esperada en fase 1.

## Entregables esperados al ejecutar este plan
- Flujo de misiles estable, sin expiraciones silenciosas.
- Oleadas que cierran correctamente al limpiar amenazas.
- Progresión completa y verificable de fase `1-1` a `1-4`.
- Base sólida para transición a boss y siguientes fases.
