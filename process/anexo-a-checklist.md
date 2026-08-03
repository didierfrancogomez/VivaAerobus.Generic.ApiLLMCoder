# Anexo A — Checklist de una página (uso diario)

> Versión comprimida del proceso completo. Cada bloque mapea a su fase (`fase-NN-*.md`).
> El gate sigue vivo aquí: si el bloque **Bloqueantes** no queda limpio, no se pasa a **Planear**.

**Entender** (Fase 0)
- [ ] Leí ticket, comentarios, historial, adjuntos y epic
- [ ] Sé el problema de negocio y el resultado observable esperado
- [ ] El ticket cumple la Definition of Ready
- [ ] Busqué tickets relacionados, duplicados e intentos previos
- [ ] Clasifiqué tipo de trabajo y nivel de rigor (trivial/normal/riesgoso)

**Contrastar con el código** (Fase 1)
- [ ] Sincronicé el repo LLM (SYNC.md) y declaré el estado de los docs
- [ ] Ubiqué y leí el código real y sus tests
- [ ] Lo ejecuté / reproduje el bug
- [ ] Revisé el historial (por qué está así)
- [ ] Documenté las discrepancias entre ticket y realidad, con citas

**Radio de impacto** (Fase 2)
- [ ] Callers, callees, implementaciones, referencias por texto, código generado
- [ ] Consulté el índice reverso del dependency-map del repo LLM
- [ ] Contratos y consumidores (incl. versiones móviles viejas), eventos, webhooks
- [ ] Datos: esquema, volumen real, índices, datos legados, backfill, cachés, reportes
- [ ] No funcional: rendimiento, concurrencia, seguridad, permisos por rol, observabilidad, i18n,
      accesibilidad
- [ ] Operativo: configuración por entorno, infra, jobs, CI/CD, orden de despliegue, soporte,
      analítica
- [ ] Matriz de impacto escrita y validada por otra persona

**Cobertura y viabilidad** (Fase 3)
- [ ] Cada fila de la matriz: cubierta / ticket hermano / descartada explícitamente
- [ ] Verifiqué que los tickets hermanos realmente la cubren
- [ ] Grafo de dependencias y orden de despliegue definidos
- [ ] Conclusión de viabilidad escrita (y alcance renegociado si cambió)

**Bloqueantes — EL GATE** (Fase 4)
- [ ] Preguntas clasificadas y escritas en el ticket con opciones y recomendación
- [ ] Cero bloqueantes duros abiertos
- [ ] Supuestos registrados con su forma de validación
- [ ] Veredicto explícito emitido: ✅ continuar / ⚠️⛔ **DETENERSE**

**Planear** (Fase 5)
- [ ] Dos opciones evaluadas y una elegida con justificación (ADR si aplica)
- [ ] Planes escritos: datos/migración, compatibilidad, flag, observabilidad, pruebas,
      rollout/rollback
- [ ] IDs de guidelines (STY/ARC/ROB/PRC) que el código debe honrar, citados en el plan
- [ ] Trabajo partido en pasos verticales y PRs separados
- [ ] Riesgos y anti-alcance definidos
- [ ] Plan revisado y aprobado

**Implementar** (Fase 6)
- [ ] Suite verde antes de empezar
- [ ] Test que falla primero (bugs)
- [ ] Commits pequeños, estándares y linters aplicados
- [ ] Observabilidad, configuración e i18n actualizados en el mismo cambio
- [ ] Ambos caminos del flag funcionan
- [ ] Hallazgos fuera de alcance → tickets nuevos, no en este diff

**Testear** (Fase 7)
- [ ] Cada criterio de aceptación probado
- [ ] Casos negativos, bordes, concurrencia, idempotencia, roles y permisos
- [ ] Regresión sobre cada punto del radio de impacto
- [ ] Compatibilidad cliente viejo/servidor nuevo y viceversa
- [ ] Migración aplicada y revertida; rendimiento con volumen realista
- [ ] Suite completa y CI verdes; probado en entorno tipo producción
- [ ] Notas de prueba entregadas a QA; aceptación de QA/PO

**Preparar liberación** (Fase 8)
- [ ] Runbook con orden exacto de pasos
- [ ] Configuración y secretos en todos los entornos; flag creado y apagado
- [ ] Paneles y alertas listos antes del despliegue
- [ ] Rollback definido y probado; criterios de abortar claros
- [ ] Notas de liberación y comunicación a soporte/negocio/clientes
- [ ] Ventana y guardia acordadas

**Pre-review** (Fase 9)
- [ ] Leí el diff completo como revisor
- [ ] Sin ruido, sin secretos, sin archivos accidentales
- [ ] Criterios de aceptación y matriz de impacto recorridos uno por uno
- [ ] Build limpio desde cero, historial de commits ordenado
- [ ] Tamaño del PR razonable
- [ ] REVIEW-CODE.md del repo LLM → **APPROVED**

**PR** (Fase 10)
- [ ] Título con clave del ticket; descripción con la plantilla completa
- [ ] Evidencia adjunta; enlaces bidireccionales
- [ ] Revisores correctos; partes no obvias auto-anotadas
- [ ] CI verde antes de pedir revisión
- [ ] Comentarios respondidos; re-solicitud de revisión al terminar

**Post-merge** (Fase 11)
- [ ] Smoke test en producción; monitoreo durante la ventana
- [ ] Migración/backfill verificados; flag activado progresivamente
- [ ] Docs del ApiLLM re-sincronizados (doc-sync) y anchor avanzado
- [ ] Ticket cerrado con evidencia; deuda y limpieza del flag agendadas
- [ ] Aprendizaje documentado
