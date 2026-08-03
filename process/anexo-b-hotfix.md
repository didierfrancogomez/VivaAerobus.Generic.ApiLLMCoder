# Anexo B — Ruta comprimida para hotfix / incidente en producción

> El proceso completo no aplica a un incendio, pero **nada se elimina: se posterga**.
> Aun en incidente, la regla de evidencia se mantiene: el fix se basa en lo que el código y los
> logs prueban, no en la primera hipótesis que encaja.

## Durante el incidente (minutos)

1. **Mitigar primero** (flag off / config part del Admin Portal, rollback, escalar recursos) antes
   de arreglar la causa raíz.
2. **Impacto:** quién está afectado, desde cuándo, cuántos, si hay corrupción de datos.
3. **Comunicar:** canal de incidente, un responsable de comunicación, soporte informado.
4. **Fix mínimo, quirúrgico y reversible.** Nada de refactors.
5. **Radio de impacto express:** solo lo que puede empeorar la situación (consultar el índice
   reverso del dependency-map del repo LLM si el módulo tocado es compartido — 2 minutos que
   evitan un segundo incidente).
6. **Un test que cubra el caso**, si el tiempo lo permite. Si no, queda como deuda inmediata.
7. **Revisión por al menos una persona**, así sea de 5 minutos. Nunca merge sin ojos ajenos.
8. **Despliegue con verificación explícita y monitoreo continuo.**

## Dentro de las siguientes 48 horas (obligatorio, no opcional)

9. **Ticket con el análisis completo**, postmortem sin culpables.
10. **Tests que faltaron, alertas que no existían, causa raíz real arreglada.**
11. **Acciones preventivas convertidas en tickets priorizados.**
12. **Actualizar el proceso o el checklist con lo aprendido** (cambio en `process/` de este repo).
13. **Re-sincronizar los docs del ApiLLM** (doc-sync) — el hotfix también cambió el código.
