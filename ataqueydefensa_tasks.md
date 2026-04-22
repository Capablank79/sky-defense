# Checklist de Ejecucion - Ataque y Defensa

Basado en `ataqueydefensa.md`.

## Tareas principales
- [x] T1 - Diagnostico controlado de misiles completado.
- [x] T2 - Contrato formal de mision del misil definido y validado.
- [x] T3 - Resolucion robusta de impacto en objetivo implementada.
- [x] T4 - Fallback determinista de objetivo implementado.
- [x] T5 - Limpieza anti-fantasmas por frame validada.
- [x] T6 - Gate de cierre de oleada validado sin bloqueos.
- [x] T7 - Reinicio correcto de contadores por oleada confirmado.
- [x] T8 - Curva de dificultad de fase 1-1 a 1-4 ajustada.
- [x] T9 - Pruebas automatizadas y regresion ampliadas y en verde.
- [ ] T10 - Criterios de aceptacion final cumplidos.

## Criterios de aceptacion (check final)
- [x] Cero misiles fantasma al finalizar cada oleada.
- [x] Transicion estable entre 1-1, 1-2, 1-3 y 1-4.
- [x] Reinicio consistente de contadores por oleada.
- [x] Incremento perceptible de cantidad y velocidad en cada oleada.
- [ ] Fase lista para transicion a boss sin bloqueos.

## Riesgos controlados (check de calidad)
- [x] Tolerancias de impacto calibradas sin falsos positivos.
- [x] Sin doble resolucion de impacto/destruccion por misil.
- [x] Estado visual y estado logico sincronizados.
- [x] Progresion de dificultad estable en toda la fase 1.
