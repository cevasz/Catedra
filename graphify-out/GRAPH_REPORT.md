# Graph Report - /home/sebas/Documentos/Catedra  (2026-09-06)

## Corpus Check
- 60 files · ~25,573 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 885 nodes · 1217 edges · 48 communities (43 shown, 5 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 15 edges (avg confidence: 0.9)
- Token cost: 11,200 input · 5,400 output

## Community Hubs (Navigation)
- Generador de tokens
- Columnas del esquema Drift
- Tiempo y plan de salida
- Hojas de formulario de clase y evaluacion
- Erizogenes: poses y dibujo
- Notas y calculadora inversa
- Movimiento, haptica y ambiente
- Asistencia y semaforo de faltas
- combineLatest4 en core
- Providers de materias y detalle
- Pantalla de calculadora
- Tema M3 y decisiones de diseno
- Check mark y cascada
- Formulario de materia
- DAO de materias (CRUD)
- Providers raiz y base de datos
- Anillo de cuenta atras
- Lista de materias
- Anillo de faltas
- Pantalla Hoy
- DAO de horario y dia
- Pestana de asistencia
- Odometro y selector de color
- Pantalla de detalle de materia
- Pestana de notas
- Hosts permitidos de la mascota
- Apertura y migracion de la BD
- Timeline del dia
- Vista de horario semanal
- Shell de navegacion
- Widgets Riverpod con estado
- Hoja de detalle de materia
- Tablas del modelo de datos
- Arranque de la app
- Widgets Riverpod de consumo
- Entrada main y locale es_CO
- CustomPainters de la app
- Formato de notas y porcentajes
- Provider del dia de hoy
- MainActivity de Android
- Materializacion de sesiones
- Minutos desde medianoche
- Semaforo partido en dos capas
- Microcopy gap-fill
- Token text.onUrgent

## God Nodes (most connected - your core abstractions)
1. `subjectsDaoProvider` - 10 edges
2. `CatedraDatabase` - 7 edges
3. `subjectDetailProvider` - 7 edges
4. `_List` - 7 edges
5. `Catedra` - 6 edges
6. `SubjectsDao` - 6 edges
7. `Contrato de tokens` - 6 edges
8. `Prototipo Catedra (Claude Design)` - 6 edges
9. `ScheduleDao` - 5 edges
10. `MascotView` - 5 edges

## Surprising Connections (you probably didn't know these)
- `Importar horario desde PDF` --references--> `materialize`  [INFERRED]
  README.md → lib/core/db/daos/schedule_dao.dart
- `Nota necesaria en el final` --references--> `TargetCalculator`  [EXTRACTED]
  README.md → lib/domain/grades/grades.dart
- `Compuerta de host de la mascota` --rationale_for--> `MascotView`  [EXTRACTED]
  ARCHITECTURE.md → lib/features/mascot/mascot_view.dart
- `Stack Riverpod + Drift + go_router` --rationale_for--> `CatedraDatabase`  [INFERRED]
  pubspec.yaml → lib/core/db/database.dart
- `Contrato de tokens` --rationale_for--> `main`  [EXTRACTED]
  ARCHITECTURE.md → tool/gen_tokens.dart

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Cadena de generacion desde el contrato** — architecture_token_contract, tool_gen_tokens, lib_theme_app_theme, absencestate, scripts_setup [EXTRACTED 1.00]
- **Contrato de movimiento reducido** — architecture_reduced_motion_degradation, lib_theme_motion_motionguard, lib_features_today_presentation_widgets_countdown_ring, lib_features_today_presentation_widgets_day_timeline, lib_features_today_presentation_widgets_odometer_minutes, lib_features_mascot_mascot_view, lib_theme_cascade [EXTRACTED 1.00]
- **Captura manual: pantallas y tokens gap-fill** — design_decisions_manual_capture_screens, design_decisions_gap_fill_microcopy, design_decisions_color_picker_swatch, lib_features_subjects_presentation_subject_form_screen, lib_features_subjects_presentation_widgets_session_form_sheet, lib_features_subject_detail_presentation_widgets_evaluation_form_sheet, lib_features_subjects_presentation_widgets_subject_color_picker [EXTRACTED 1.00]

## Communities (48 total, 5 thin omitted)

### Community 0 - "Generador de tokens"
Cohesion: 0.03
Nodes (76): dart:convert, a, ai, amb, b, blink, blur, _buildAbsenceState (+68 more)

### Community 1 - "Columnas del esquema Drift"
Cohesion: 0.04
Nodes (49): BoolColumn get, DateTimeColumn get, IntColumn get, activo, archivada, bufferMinutos, campusId, codigo (+41 more)

### Community 2 - "Tiempo y plan de salida"
Cohesion: 0.04
Nodes (46): AsyncValue, bool get, ../../../domain/departure/departure.dart, int get, const, difference, hhmm, hour (+38 more)

### Community 3 - "Hojas de formulario de clase y evaluacion"
Cohesion: 0.05
Nodes (45): Evaluation?, FormState, subjectsDaoProvider, build, createState, dispose, _EvaluationForm, _EvaluationFormState (+37 more)

### Community 4 - "Erizogenes: poses y dibujo"
Cohesion: 0.05
Nodes (41): bool breathes, rolls, speedLines,, Duration get, _blink, _blinkTimer, build, contractName, createState, didChangeDependencies (+33 more)

### Community 5 - "Notas y calculadora inversa"
Cohesion: 0.05
Nodes (39): Las cifras de la calculadora del prototipo son maqueta, double?, accumulated, date, earned, Evaluation, GradeCalculator, gradedWeight (+31 more)

### Community 6 - "Movimiento, haptica y ambiente"
Cohesion: 0.05
Nodes (34): Degradacion por movimiento reducido, Temperatura ambiental solo en tema oscuro, Ambient, base, card, enabledFor, warmthAt, enteredUrgent (+26 more)

### Community 7 - "Asistencia y semaforo de faltas"
Cohesion: 0.06
Nodes (32): absence_state.g.dart, AbsenceState, Dominio en Dart puro, asistio,
  falto,
  canceladaProfe,
  justificada,, Umbrales del semaforo de faltas, El plan de salida del prototipo se contradice, Pantallas de captura manual escritas fuera del prototipo, Prototipo Catedra (Claude Design) (+24 more)

### Community 8 - "combineLatest4 en core"
Cohesion: 0.06
Nodes (28): A?, combineLatest4 vive en core, no en una feature, B?, C?, D?, dart:async, controller, done (+20 more)

### Community 9 - "Providers de materias y detalle"
Cohesion: 0.08
Nodes (27): AbsenceTally, Cuatro consultas, no N+1, ../../../core/db/daos/subjects_dao.dart, ../../../../core/db/database.dart, ../../../domain/grades/grades.dart, GradeSummary, SubjectDetail, detail (+19 more)

### Community 10 - "Pantalla de calculadora"
Cohesion: 0.09
Nodes (26): _askCustom, createState, _Current, date, evaluations, label, onChanged, onPick (+18 more)

### Community 11 - "Tema M3 y decisiones de diseno"
Cohesion: 0.08
Nodes (24): Los .g.dart quedan fuera del analizador, Reglas de lint del proyecto, Regla de cero literales en UI, Contrato de tokens, BuildContext, Swatch de 34 px del selector de color, Cinco medidas dibujadas sin token, Sombras del tema claro con alfa reducido (+16 more)

### Community 12 - "Check mark y cascada"
Cohesion: 0.08
Nodes (24): Color, easeOutExpo para cascada y PDF, Duration, build, checked, CheckMark, child, color (+16 more)

### Community 13 - "Formulario de materia"
Cohesion: 0.08
Nodes (24): _addSession, child, _colorIndex, createState, _creditos, dispose, _fechaLimite, _formKey (+16 more)

### Community 14 - "DAO de materias (CRUD)"
Cohesion: 0.08
Nodes (23): ../../async/combine_latest.dart, createSubject, deleteEvaluation, deleteSession, deleteSubject, ensureActiveSemester, ensureRoom, evaluations (+15 more)

### Community 15 - "Providers raiz y base de datos"
Cohesion: 0.11
Nodes (22): @DriftAccessor, @DriftDatabase, Offline primero, DatabaseAccessor, DateTime, db/daos/schedule_dao.dart, db/daos/subjects_dao.dart, db/database.dart (+14 more)

### Community 16 - "Anillo de cuenta atras"
Cohesion: 0.10
Nodes (20): Unica animacion en loop, Radios del anillo urgente 45-43, active, _breathe, build, child, createState, didChangeDependencies (+12 more)

### Community 17 - "Lista de materias"
Cohesion: 0.12
Nodes (17): ../application/subjects_providers.dart, Arquitectura por features, ../../../core/format/numbers.dart, subjectsOverviewProvider, build, card, color, _Dot (+9 more)

### Community 18 - "Anillo de faltas"
Cohesion: 0.12
Nodes (16): AnimationController, dart:math, build, color, createState, didUpdateWidget, dispose, filled (+8 more)

### Community 19 - "Pantalla Hoy"
Cohesion: 0.12
Nodes (16): ../application/today_providers.dart, _capitalize, createState, day, _EmptyDay, _Header, _NextClassCard, _progress (+8 more)

### Community 20 - "DAO de horario y dia"
Cohesion: 0.12
Nodes (16): Dia de semana ISO 8601, ClassSession, ../database.dart, clearStatus, DayClass, instance, room, session (+8 more)

### Community 21 - "Pestana de asistencia"
Cohesion: 0.12
Nodes (15): absence_ring.dart, check_mark.dart, _Badge, build, color, _HistoryRow, instance, _isFuture (+7 more)

### Community 22 - "Odometro y selector de color"
Cohesion: 0.13
Nodes (14): Odometro a 320 ms, build, onChanged, selected, SubjectColorPicker, build, color, minutes (+6 more)

### Community 23 - "Pantalla de detalle de materia"
Cohesion: 0.13
Nodes (14): ../application/subject_detail_providers.dart, Fase 2 cerrada: notas, asistencia, calculadora, mascota, Fase 3 pendiente: importar PDF, Hoja de fases F0-F6, ../../../../core/time/minutes_of_day.dart, Huecos sin especificacion visual (F4 y F6), SubjectDetailState, accent (+6 more)

### Community 24 - "Pestana de notas"
Cohesion: 0.13
Nodes (14): ../../../calculator/presentation/calculator_screen.dart, evaluation_form_sheet.dart, build, _EmptyGrades, evaluation, _EvaluationRow, GradesTab, onTap (+6 more)

### Community 25 - "Hosts permitidos de la mascota"
Cohesion: 0.19
Nodes (14): Compuerta de host de la mascota, Mascota de esquina urgente a 62 px, MascotView, _MascotViewState, AppShell, _AppShellState, AbsenceRing, _AbsenceRingState (+6 more)

### Community 26 - "Apertura y migracion de la BD"
Cohesion: 0.14
Nodes (13): daos/schedule_dao.dart, daos/subjects_dao.dart, dart:io, migration, _open, schemaVersion, MigrationStrategy get, package:drift/drift.dart (+5 more)

### Community 27 - "Timeline del dia"
Cohesion: 0.14
Nodes (13): int?, _List, build, cancelled, classes, DayTimeline, highlighted, highlightId (+5 more)

### Community 28 - "Vista de horario semanal"
Cohesion: 0.18
Nodes (12): build, classes, day, _DayColumn, item, label, watch, _WeekBlock (+4 more)

### Community 29 - "Shell de navegacion"
Cohesion: 0.17
Nodes (11): ../../../../l10n/strings.g.dart, build, createState, _index, label, _Placeholder, _screens, ../../schedule/presentation/week_screen.dart (+3 more)

### Community 30 - "Widgets Riverpod con estado"
Cohesion: 0.22
Nodes (11): ConsumerState, ConsumerStatefulWidget, build, CalculatorScreen, _CalculatorScreenState, subjectDetailProvider, build, build (+3 more)

### Community 31 - "Hoja de detalle de materia"
Cohesion: 0.20
Nodes (9): ../../../../core/db/daos/schedule_dao.dart, DayClass, ../../../../domain/attendance/attendance.dart, build, heroTag, item, String?, ../../../subject_detail/presentation/subject_detail_screen.dart (+1 more)

### Community 32 - "Tablas del modelo de datos"
Cohesion: 0.22
Nodes (9): Color de materia por indice, Campuses, ClassSessions, Evaluations, Rooms, Semesters, Subjects, UserSettings (+1 more)

### Community 33 - "Arranque de la app"
Cohesion: 0.29
Nodes (7): ../../../core/providers.dart, features/shell/presentation/app_shell.dart, build, CatedraApp, themeModeProvider, package:flutter_localizations/flutter_localizations.dart, package:flutter/material.dart

### Community 34 - "Widgets Riverpod de consumo"
Cohesion: 0.33
Nodes (7): ConsumerWidget, scheduleDaoProvider, _mark, SubjectSheet, SubjectDetailScreen, AttendanceTab, _pickStatus

### Community 35 - "Entrada main y locale es_CO"
Cohesion: 0.33
Nodes (5): app.dart, initializeDateFormatting, main, package:flutter_riverpod/flutter_riverpod.dart, package:intl/date_symbol_data_local.dart

### Community 36 - "CustomPainters de la app"
Cohesion: 0.40
Nodes (5): CustomPainter, _ErizogenesPainter, _AbsenceRingPainter, _CheckPainter, _RingPainter

### Community 37 - "Formato de notas y porcentajes"
Cohesion: 0.40
Nodes (4): grade, Numbers, percent, package:intl/intl.dart

### Community 38 - "Provider del dia de hoy"
Cohesion: 0.67
Nodes (4): todayProvider, build, _TodayScreenState, todayStateProvider

### Community 40 - "Materializacion de sesiones"
Cohesion: 0.67
Nodes (3): Sesiones materializadas, materialize, SessionInstances

## Knowledge Gaps
- **518 isolated node(s):** `instance`, `session`, `subject`, `room`, `status` (+513 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `_List` connect `Timeline del dia` to `Providers de materias y detalle`, `Pantalla de calculadora`, `DAO de materias (CRUD)`, `Lista de materias`, `Vista de horario semanal`?**
  _High betweenness centrality (0.025) - this node is a cross-community bridge._
- **Why does `CatedraDatabase` connect `Providers raiz y base de datos` to `Apertura y migracion de la BD`?**
  _High betweenness centrality (0.018) - this node is a cross-community bridge._
- **What connects `instance`, `session`, `subject` to the rest of the system?**
  _518 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Generador de tokens` be split into smaller, more focused modules?**
  _Cohesion score 0.025974025974025976 - nodes in this community are weakly interconnected._
- **Should `Columnas del esquema Drift` be split into smaller, more focused modules?**
  _Cohesion score 0.04 - nodes in this community are weakly interconnected._
- **Should `Tiempo y plan de salida` be split into smaller, more focused modules?**
  _Cohesion score 0.041666666666666664 - nodes in this community are weakly interconnected._
- **Should `Hojas de formulario de clase y evaluacion` be split into smaller, more focused modules?**
  _Cohesion score 0.04902867715078631 - nodes in this community are weakly interconnected._