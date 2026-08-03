# Fase 9 — Pre-review (auto-revisión antes de pedir revisión)

> **Pregunta que responde:** ¿está listo para gastar el tiempo de otra persona?
> **Gate OBLIGATORIO con el repo LLM:** correr
> `../VivaAerobus.Generic.ApiLLM/llm/REVIEW-CODE.md` sobre el diff — el validador local que aplica
> la misma vara que los revisores humanos (`guidelines/**`, propósito de la tarea, blast radius).
> El veredicto debe ser **APPROVED**: cualquier hallazgo 🐛/❗ bloquea el paso a la Fase 10. Para
> cambios de nivel *riesgoso*, correr además una pasada independiente de verificación (subagente
> `evidence-auditor` del ApiLLM).

**Objetivo:** no gastar el tiempo de un compañero en cosas que tú podías ver. Revisa tu diff como
si fuera de otra persona a quien no le tienes cariño.

## 9.1 Revisión del diff completo

1. **Leer el diff entero, archivo por archivo, línea por línea**, en la interfaz de comparación (no
   en el editor). Es sorprendente lo que aparece.
2. **Eliminar ruido:** código de depuración, `console.log`, prints, comentarios de prueba, código
   comentado, TODOs sin ticket, cambios de formato no relacionados, archivos temporales,
   dependencias que agregaste y ya no usas.
3. **Verificar que no se colaron:** archivos de configuración local, `.env`, credenciales, tokens,
   rutas absolutas de tu máquina, datos reales de clientes, archivos binarios grandes, dependencias
   no aprobadas.
4. **Verificar que no hay cambios accidentales:** archivos que tocaste por error, cambios de
   lockfile no intencionales, reversiones involuntarias de código de otros.
5. **Pasada de legibilidad:** nombres, funciones demasiado largas, anidamiento profundo,
   duplicación introducida, magia sin explicar. ¿Lo entenderías en seis meses?
6. **Pasada de robustez:** casos nulos, errores no manejados, valores por defecto peligrosos,
   operaciones sin límite, consultas sin paginación.
7. **Pasada de seguridad:** validación en servidor, autorización en cada endpoint nuevo, datos
   sensibles fuera de logs y respuestas.

## 9.2 Cierre del ciclo con las fases anteriores

1. **Criterios de aceptación:** recorrerlos uno por uno y marcar cada uno con la evidencia de cómo
   se cumple.
2. **Matriz de impacto (Fase 2):** recorrerla completa y confirmar que cada fila está atendida o
   explícitamente descartada. **Este es el paso que más incidentes previene.**
3. **Registro de supuestos (Fase 4):** cada supuesto está validado, o está anotado en el PR para
   que el revisor lo confirme.
4. **Plan (Fase 5):** ¿lo implementado corresponde al plan aprobado? Si te desviaste, documentar
   por qué.
5. **Anti-alcance:** verificar que no se colaron cambios fuera del alcance acordado.

## 9.3 Higiene técnica final

1. **Correr todo localmente en limpio:** linter, formateo, tipos, análisis estático, suite completa
   de tests, build de producción.
2. **Clonar/construir desde cero** (o borrar dependencias y reinstalar) para detectar que algo
   funciona solo en tu máquina.
3. **Verificar migraciones:** aplicar y revertir sobre base limpia y sobre base con datos.
4. **Limpiar el historial de commits:** rebase interactivo, mensajes claros, sin commits tipo
   "fix", "wip", "ya casi". Un commit lógico por cambio lógico.
5. **Actualizar con la rama base** y volver a correr los tests después del merge/rebase (los
   conflictos semánticos no dan conflicto de git).
6. **Evaluar el tamaño del PR:** si es grande, partirlo. Un PR de 1.000 líneas no se revisa, se
   aprueba.
7. **Auto-verificación de tests:** confirmar que fallan sin el cambio.

## 9.4 Gate del validador local (REVIEW-CODE.md)

1. Ejecutar `llm/REVIEW-CODE.md` del ApiLLM con: (a) el diff (`git -C ../VivaAerobus.Generic.Api
   diff master...<branch>`), y (b) el ticket + el análisis de la Etapa A.
2. Cada hallazgo cita la regla (`STY-NN`/`ARC-NN`/`ROB-NN`/`PRC-NN`) y la ubicación exacta.
3. **APPROVED** → continuar. **CHANGES_REQUESTED** → corregir y volver a correr el gate. Un
   hallazgo 🐛/❗ nunca se difiere "para el PR".

---

**Artefactos:** diff limpio, checklist de auto-revisión completo, y
`work/<CLAVE>/fase-09-pre-review.md` con el resultado del validador — DEBE contener la línea
literal `REVIEW-CODE: APPROVED` (los hooks bloquean `git push` / `gh pr create` sin ella). Se
escribe solo cuando `REVIEW-CODE.md` realmente devolvió APPROVED.

**Criterio de salida:** estarías cómodo si este diff se mostrara en una revisión pública del
equipo, y `REVIEW-CODE.md` devolvió APPROVED.

**Siguiente:** [Fase 10 — Crear el PR y gestionar la revisión](fase-10-pr-revision.md)
