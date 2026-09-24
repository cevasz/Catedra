# Graph Report - Catedra  (2026-09-23)

## Corpus Check
- 148 files · ~133,457 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 3139 nodes · 4640 edges · 143 communities (132 shown, 11 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS · INFERRED: 16 edges (avg confidence: 0.9)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `db2c8243`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

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
- schema_versions.dart
- column_schedule_parser.dart
- schema_v5.dart
- schema_v3.dart
- schema_v4.dart
- schema_v2.dart
- schema_v1.dart
- WidgetData
- Decisiones de diseño
- Table
- map_screen.dart
- settings_screen.dart
- alarm_planner.dart
- import_controller.dart
- schedule_parser.dart
- mascot_voice.dart
- home_widget_sync.dart
- Context
- alarms_controller.dart
- mascot_view_test.dart
- today_providers.dart
- mascot_companion.dart
- tasks_dao.dart
- micro_animations.dart
- home_check_providers.dart
- map_providers.dart
- strike_through.dart
- mascot_tips.dart
- int get
- parsed_session_sheet.dart
- today_state_test.dart
- pdf_text.dart
- mascot_loader.dart
- .build
- next_room_card.dart
- claude_schedule_parser.dart
- import_save_test.dart
- room_sheet.dart
- evaluation_form_sheet.dart
- package:drift/drift.dart
- Arquitectura
- package:flutter_riverpod/flutter_riverpod.dart
- settings_dao.dart
- Funciona
- absence_ring.dart
- update_providers.dart
- claude_decode_test.dart
- settingsProvider
- import_controller_test.dart
- Widget
- .schedule
- bool get
- update_sheet.dart
- subject_detail_providers.dart
- i0.VersionedTable
- Prototipo Catedra (Claude Design)
- update_downloader_test.dart
- subject_detail_providers.dart
- check_mark.dart
- update_channel.dart
- map_style.dart
- schema.dart
- mascot_error.dart
- Erizógenes: interacciones de la mascota
- package:flutter_test/flutter_test.dart
- Color
- ../../core/time/minutes_of_day.dart
- dart:io
- tokens.g.dart
- ImportState
- strike_through_test.dart
- Contrato de tokens
- map_style_test.dart
- build
- update_manifest.dart
- session_fields.dart
- subjectsDaoProvider
- ambient.dart
- GeneratedDatabase
- ambient.dart
- MascotView
- ConsumerState
- i0.VersionedSchema
- Cátedra
- StateNotifier
- update_manifest_test.dart
- Swatch de 34 px del selector de color
- calendar_day.dart
- startReview
- setup.sh
- int?
- Map
- String?

## God Nodes (most connected - your core abstractions)
1. `dart` - 90 edges
2. `Decisiones de diseño` - 50 edges
3. `mascotCornerProvider` - 20 edges
4. `WidgetData` - 18 edges
5. `scheduleDaoProvider` - 16 edges
6. `Arquitectura` - 16 edges
7. `todayProvider` - 14 edges
8. `CatedraDatabase` - 13 edges
9. `settingsProvider` - 12 edges
10. `_List` - 12 edges

## Surprising Connections (you probably didn't know these)
- `Importar horario desde PDF` --references--> `materialize`  [INFERRED]
  README.md → lib/core/db/daos/schedule_dao.dart
- `Stack Riverpod + Drift + go_router` --rationale_for--> `CatedraDatabase`  [INFERRED]
  pubspec.yaml → lib/core/db/database.dart
- `Conteo de faltas contra el limite` --references--> `AttendanceCounter`  [EXTRACTED]
  README.md → lib/domain/attendance/attendance.dart
- `Compuerta de host de la mascota` --rationale_for--> `MascotView`  [EXTRACTED]
  ARCHITECTURE.md → lib/features/mascot/mascot_view.dart
- `Contrato de tokens` --rationale_for--> `main`  [EXTRACTED]
  ARCHITECTURE.md → tool/gen_tokens.dart

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Cadena de generacion desde el contrato** — architecture_token_contract, tool_gen_tokens, lib_theme_app_theme, absencestate, scripts_setup [EXTRACTED 1.00]
- **Contrato de movimiento reducido** — architecture_reduced_motion_degradation, lib_theme_motion_motionguard, lib_features_today_presentation_widgets_countdown_ring, lib_features_today_presentation_widgets_day_timeline, lib_features_today_presentation_widgets_odometer_minutes, lib_features_mascot_mascot_view, lib_theme_cascade [EXTRACTED 1.00]
- **Captura manual: pantallas y tokens gap-fill** — design_decisions_manual_capture_screens, design_decisions_gap_fill_microcopy, design_decisions_color_picker_swatch, lib_features_subjects_presentation_subject_form_screen, lib_features_subjects_presentation_widgets_session_form_sheet, lib_features_subject_detail_presentation_widgets_evaluation_form_sheet, lib_features_subjects_presentation_widgets_subject_color_picker [EXTRACTED 1.00]

## Communities (143 total, 11 thin omitted)

### Community 0 - "Generador de tokens"
Cohesion: 0.02
Nodes (82): dart, a, add, ai, amb, _androidColor, b, blink (+74 more)

### Community 1 - "Columnas del esquema Drift"
Cohesion: 0.03
Nodes (68): BoolColumn get, DateTimeColumn get, IntColumn get, activo, alarmaDespertar, alarmaDespertarMin, alarmaEvaluaciones, alarmaSalir (+60 more)

### Community 2 - "Tiempo y plan de salida"
Cohesion: 0.07
Nodes (28): arrivalMargin, bufferMinutes, classStart, defaultBufferMinutes, DeparturePlan, DepartureUrgency, fallbackTravelMinutes, fromHome (+20 more)

### Community 3 - "Hojas de formulario de clase y evaluacion"
Cohesion: 0.09
Nodes (21): build, createState, _DayChip, _dia, dispose, _edificio, _error, existing (+13 more)

### Community 4 - "Erizogenes: poses y dibujo"
Cohesion: 0.01
Nodes (162): bool breathes, runs,, Brightness, double cy, ryTop,, double lidLeft,, double propRotation, propOpen,, hop,

  
  notice,

  
  celebrate,

  
  sigh,, _activeAntic, _activeBeat (+154 more)

### Community 5 - "Notas y calculadora inversa"
Cohesion: 0.06
Nodes (30): accumulated, bestScore, date, earned, GradeCalculator, gradedWeight, id, isComplete (+22 more)

### Community 6 - "Movimiento, haptica y ambiente"
Cohesion: 0.10
Nodes (19): allows, allowsLoops, breathe, breatheCurve, breatheUrgent, curve, drain, duration (+11 more)

### Community 7 - "Asistencia y semaforo de faltas"
Cohesion: 0.09
Nodes (21): absence_state.g.dart, AbsenceState, Dominio en Dart puro, asistio,
  falto,
  canceladaProfe,
  justificada,, cancelledByProfessor, countsAsAbsence, defaultLimit, isLost (+13 more)

### Community 8 - "combineLatest4 en core"
Cohesion: 0.08
Nodes (29): A?, combineLatest4 vive en core, no en una feature, B?, C?, D?, controller, done, emit (+21 more)

### Community 9 - "Providers de materias y detalle"
Cohesion: 0.14
Nodes (13): AbsenceTally, GradeSummary, buildCard, evaluations, grades, hasGrades, subject, SubjectCard (+5 more)

### Community 10 - "Pantalla de calculadora"
Cohesion: 0.08
Nodes (29): _askCustom, createState, _Current, date, evaluations, label, onChanged, onPick (+21 more)

### Community 11 - "Tema M3 y decisiones de diseno"
Cohesion: 0.12
Nodes (15): BuildContext, Sombras del tema claro con alfa reducido, AppTheme, _build, dark, light, styleOf, _textTheme (+7 more)

### Community 12 - "Check mark y cascada"
Cohesion: 0.15
Nodes (12): Duration, build, checked, CheckMark, child, color, duration, _Fade (+4 more)

### Community 13 - "Formulario de materia"
Cohesion: 0.08
Nodes (25): _addSession, child, _colorIndex, createState, _creditos, dispose, _fechaLimite, _Field (+17 more)

### Community 14 - "DAO de materias (CRUD)"
Cohesion: 0.08
Nodes (24): ../../async/combine_latest.dart, createSubject, deleteEvaluation, deleteSession, deleteSubject, ensureActiveSemester, ensureRoom, evaluations (+16 more)

### Community 15 - "Providers raiz y base de datos"
Cohesion: 0.10
Nodes (28): _, @DriftAccessor, @DriftDatabase, Offline primero, DatabaseAccessor, db/daos/schedule_dao.dart, db/daos/settings_dao.dart, db/daos/subjects_dao.dart (+20 more)

### Community 16 - "Anillo de cuenta atras"
Cohesion: 0.09
Nodes (22): Unica animacion en loop, Radios del anillo urgente 45-43, active, _breathe, build, child, CountdownRing, _CountdownRingState (+14 more)

### Community 17 - "Lista de materias"
Cohesion: 0.09
Nodes (24): ../application/subjects_providers.dart, Arquitectura por features, ../../import/presentation/import_pdf_screen.dart, selectedSubjectProvider, _Badge, build, _cancelledLabel, card (+16 more)

### Community 18 - "Anillo de faltas"
Cohesion: 0.13
Nodes (14): build, color, createState, didUpdateWidget, dispose, filled, initState, limit (+6 more)

### Community 19 - "Pantalla Hoy"
Cohesion: 0.09
Nodes (23): ../application/today_providers.dart, accent, capitalize, _CardStack, child, createState, day, _etaLine (+15 more)

### Community 20 - "DAO de horario y dia"
Cohesion: 0.08
Nodes (23): Dia de semana ISO 8601, ClassSession, Expression, clearStatus, DayClass, instance, _live, room (+15 more)

### Community 21 - "Pestana de asistencia"
Cohesion: 0.11
Nodes (18): absence_ring.dart, check_mark.dart, clockProvider, AttendanceTab, _Badge, build, color, createState (+10 more)

### Community 22 - "Odometro y selector de color"
Cohesion: 0.07
Nodes (30): ../../../../core/format/durations.dart, Odometro a 320 ms, build, onChanged, selected, SubjectColorPicker, build, color (+22 more)

### Community 23 - "Pantalla de detalle de materia"
Cohesion: 0.08
Nodes (29): Fase 2 cerrada: notas, asistencia, calculadora, mascota, Fase 3 pendiente: importar PDF, Hoja de fases F0-F6, Huecos sin especificacion visual (F4 y F6), subjectDetailProvider, build, CalculatorScreen, _CalculatorScreenState (+21 more)

### Community 24 - "Pestana de notas"
Cohesion: 0.06
Nodes (35): ../../application/subject_detail_providers.dart, ../../../calculator/presentation/calculator_screen.dart, ../../../core/format/numbers.dart, evaluation_form_sheet.dart, build, _EmptyGrades, evaluation, _EvaluationRow (+27 more)

### Community 25 - "Hosts permitidos de la mascota"
Cohesion: 0.19
Nodes (17): AbsenceRing, _AbsenceRingState, _Sheet, _SheetState, MascotVase, _MascotVaseState, AbsenceRing, _AbsenceRingState (+9 more)

### Community 26 - "Apertura y migracion de la BD"
Cohesion: 0.14
Nodes (13): daos/schedule_dao.dart, daos/settings_dao.dart, daos/subjects_dao.dart, daos/tasks_dao.dart, migration, _open, schemaVersion, MigrationStrategy get (+5 more)

### Community 27 - "Timeline del dia"
Cohesion: 0.10
Nodes (19): ../../../../domain/schedule/day_gaps.dart, _List, build, cancelled, classes, DayTimeline, formatGapDuration, gap (+11 more)

### Community 28 - "Vista de horario semanal"
Cohesion: 0.06
Nodes (39): ../application/week_providers.dart, ../../core/db/daos/schedule_dao.dart, ../../../../core/time/calendar_day.dart, DateTime, anchor, subtract, watch, weekAnchorProvider (+31 more)

### Community 29 - "Shell de navegacion"
Cohesion: 0.08
Nodes (23): AsyncValue, IconData, createState, icon, _icons, _index, isSelected, label (+15 more)

### Community 30 - "Widgets Riverpod con estado"
Cohesion: 0.33
Nodes (6): ConsumerStatefulWidget, MascotCompanion, SubjectFormScreen, _SubjectFormScreenState, _SessionForm, _SessionFormState

### Community 31 - "Hoja de detalle de materia"
Cohesion: 0.08
Nodes (30): _Home, scheduleDaoProvider, _confirmPlacing, _saveNotes, mascotCornerProvider, build, card, color (+22 more)

### Community 33 - "Arranque de la app"
Cohesion: 0.17
Nodes (15): features/alarms/application/alarms_controller.dart, features/home_check/application/home_check_providers.dart, features/import/presentation/onboarding_screen.dart, features/mascot/mascot_corner.dart, features/shell/presentation/app_shell.dart, features/subjects/application/subjects_providers.dart, features/widgets/home_widget_sync.dart, build (+7 more)

### Community 34 - "Widgets Riverpod de consumo"
Cohesion: 0.07
Nodes (35): ../application/import_controller.dart, ConsumerWidget, ../data/claude_schedule_parser.dart, importControllerProvider, ImportFailure, _AddChip, build, _ClassCard (+27 more)

### Community 35 - "Entrada main y locale es_CO"
Cohesion: 0.14
Nodes (13): app.dart, initializeDateFormatting, main, initializeDateFormatting, main, package:catedra/features/import/application/import_controller.dart, package:catedra/features/import/presentation/import_pdf_screen.dart, package:catedra/features/mascot/mascot_loader.dart (+5 more)

### Community 36 - "CustomPainters de la app"
Cohesion: 0.18
Nodes (11): CustomPainter, _AbsenceRingPainter, _CheckPainter, _Beak, _TailPainter, _ErizogenesPainter, _VasePainter, _AbsenceRingPainter (+3 more)

### Community 37 - "Formato de notas y porcentajes"
Cohesion: 0.22
Nodes (7): grade, Numbers, percent, grade, Numbers, percent, package:intl/intl.dart

### Community 38 - "Provider del dia de hoy"
Cohesion: 0.08
Nodes (32): tasksDaoProvider, todayProvider, _Header, build, createState, d, _day, _delete (+24 more)

### Community 39 - "MainActivity de Android"
Cohesion: 0.25
Nodes (9): Any, Boolean, Int, Intent, Map, String, MainActivity, FlutterActivity (+1 more)

### Community 40 - "Materializacion de sesiones"
Cohesion: 0.22
Nodes (10): Sesiones materializadas, El plan de salida del prototipo se contradice, materialize, SessionInstances, DeparturePlanner, Conteo de faltas contra el limite, Claves de API solo por --dart-define, Catedra (+2 more)

### Community 48 - "schema_versions.dart"
Cohesion: 0.02
Nodes (123): activo, alarmaDespertar, alarmaDespertarMin, alarmaEvaluaciones, alarmaSalir, archivada, avisoEvaluacionMin, bufferMinutos (+115 more)

### Community 49 - "column_schedule_parser.dart"
Cohesion: 0.03
Nodes (66): addText, _Anchor, _anchors, build, _campus, _Cell, _CellBuilder, _classFrom (+58 more)

### Community 50 - "schema_v5.dart"
Cohesion: 0.03
Nodes (66): activo, actualTableName, alarmaDespertar, alarmaDespertarMin, alarmaEvaluaciones, alarmaSalir, _alias, aliasedName (+58 more)

### Community 51 - "schema_v3.dart"
Cohesion: 0.03
Nodes (65): Tasks, activo, actualTableName, alarmaDespertar, alarmaDespertarMin, alarmaEvaluaciones, alarmaSalir, _alias (+57 more)

### Community 52 - "schema_v4.dart"
Cohesion: 0.03
Nodes (65): activo, actualTableName, alarmaDespertar, alarmaDespertarMin, alarmaEvaluaciones, alarmaSalir, _alias, aliasedName (+57 more)

### Community 53 - "schema_v2.dart"
Cohesion: 0.03
Nodes (60): Evaluations, Rooms, Semesters, SessionInstances, activo, actualTableName, _alias, aliasedName (+52 more)

### Community 54 - "schema_v1.dart"
Cohesion: 0.03
Nodes (58): Campuses, ClassSessions, GeneratedColumn, Iterable, Subjects, activo, actualTableName, _alias (+50 more)

### Community 55 - "WidgetData"
Cohesion: 0.07
Nodes (33): Arrival, hhmm(), Context, Int, Map, SharedPreferences, String, mascot() (+25 more)

### Community 56 - "Decisiones de diseño"
Cohesion: 0.04
Nodes (50): 10. Cinco medidas que estaban dibujadas pero no tenían nombre, 11. La mascota de la esquina urgente pasa de 40 a 62 px, 12. La mascota no se limita a los estados vacíos, 13. Cinco tokens más para vaciar de literales el código de pantalla, 14. La calculadora tiene tres respuestas, no dos, 15. El tachado de una cancelada se dibuja, 16. «Ya voy» avanza la card; «Cancelar» la convierte en la B3, 17. Los huecos de la timeline empiezan en 30 minutos (+42 more)

### Community 57 - "Table"
Cohesion: 0.09
Nodes (45): Table, TableInfo, Campuses, ClassSessions, Evaluations, Rooms, Semesters, SessionInstances (+37 more)

### Community 58 - "map_screen.dart"
Cohesion: 0.05
Nodes (43): DraggableScrollableController, controller, createState, dispose, _Empty, _flight, _flyTo, _focus (+35 more)

### Community 59 - "settings_screen.dart"
Cohesion: 0.07
Nodes (39): ../../alarms/application/alarms_controller.dart, ../../home_check/application/home_check_providers.dart, settingsDaoProvider, alarmChannelProvider, createClockAlarmsProvider, backgroundLocationProvider, _AlarmsCard, _AlarmsCardState (+31 more)

### Community 60 - "alarm_planner.dart"
Cohesion: 0.05
Nodes (38): attendance.dart, ../departure/departure.dart, AlarmKind, AlarmPlanner, at, date, DatedEvaluation, end (+30 more)

### Community 61 - "import_controller.dart"
Cohesion: 0.05
Nodes (39): ../data/column_schedule_parser.dart, ../data/pdf_text.dart, cancel, canConfirm, classes, confirm, copyWith, done (+31 more)

### Community 62 - "schedule_parser.dart"
Cohesion: 0.06
Nodes (35): _clean, codigo, copyWith, creditos, _daysIn, _dayTokens, _dayWord, diaSemana (+27 more)

### Community 63 - "mascot_voice.dart"
Cohesion: 0.06
Nodes (33): grade,
  taskAdded,
  taskDone,
  saved,, alarms, antic, _armIdle, beat, dismiss, dispose, _hide (+25 more)

### Community 64 - "home_widget_sync.dart"
Cohesion: 0.07
Nodes (30): pendingProvider, buffer, classes, dateKey, debounce, items, kHomeWidgetDataKey, kHomeWidgetDays (+22 more)

### Community 65 - "Context"
Cohesion: 0.18
Nodes (14): AttendanceBootReceiver, AttendanceCheckReceiver, AttendanceChecks, AttendanceUndoReceiver, Any, Boolean, BroadcastReceiver, Context (+6 more)

### Community 66 - "alarms_controller.dart"
Cohesion: 0.08
Nodes (25): ../../../core/platform/alarm_channel.dart, dart:async, ../../../domain/alarms/alarm_planner.dart, ../../domain/departure/departure.dart, main, AlarmChannel, canSetAlarms, _channel (+17 more)

### Community 67 - "mascot_view_test.dart"
Cohesion: 0.09
Nodes (23): dart:math, package:catedra/features/mascot/application/mascot_voice.dart, package:catedra/features/mascot/mascot_error.dart, package:catedra/features/mascot/mascot_view.dart, package:catedra/l10n/strings.g.dart, package:catedra/theme/app_theme.dart, package:catedra/theme/layout.dart, package:catedra/theme/tokens.g.dart (+15 more)

### Community 68 - "today_providers.dart"
Cohesion: 0.07
Nodes (27): cancelled, _cancelledAhead, classes, clock, day, _fromHome, _gaps, gapsAfter (+19 more)

### Community 69 - "mascot_companion.dart"
Cohesion: 0.07
Nodes (26): application/mascot_tips.dart, active, _antic, _anticLine, _anticSerial, border, child, compact (+18 more)

### Community 70 - "tasks_dao.dart"
Cohesion: 0.08
Nodes (25): DateTime? get, addTask, _byDate, _combine, compareTo, controller, deleteTask, emit (+17 more)

### Community 71 - "micro_animations.dart"
Cohesion: 0.09
Nodes (24): Animation, borderRadius, build, child, color, createState, _ctrl, didUpdateWidget (+16 more)

### Community 72 - "home_check_providers.dart"
Cohesion: 0.09
Nodes (23): ../../../core/platform/attendance_channel.dart, ../../domain/attendance/attendance.dart, ../../../domain/attendance/home_check.dart, AttendanceChannel, _channel, hasBackgroundLocation, HomeCheckItem, schedule (+15 more)

### Community 73 - "map_providers.dart"
Cohesion: 0.08
Nodes (24): LatLng, LatLng? get, colorIndex, dispose, isPlaced, item, later, LocationStatus (+16 more)

### Community 74 - "strike_through.dart"
Cohesion: 0.09
Nodes (22): Degradacion por movimiento reducido, easeOutExpo para cascada y PDF, build, CascadeIn, child, guard, index, rise (+14 more)

### Community 75 - "mascot_tips.dart"
Cohesion: 0.09
Nodes (21): ../../../domain/attendance/absence_state.g.dart, cards, day, examSoon, horizon, kAnticClassSoonMinutes, kTipLookaheadDays, live (+13 more)

### Community 76 - "int get"
Cohesion: 0.10
Nodes (20): const, difference, hhmm, hour, minus, minute, of, onDay (+12 more)

### Community 77 - "parsed_session_sheet.dart"
Cohesion: 0.10
Nodes (20): ../../../../domain/import/schedule_parser.dart, ParsedSession, build, createState, _defaultStart, _dia, _error, existing (+12 more)

### Community 78 - "today_state_test.dart"
Cohesion: 0.10
Nodes (17): main, package:catedra/core/db/daos/schedule_dao.dart, package:catedra/domain/attendance/absence_state.g.dart, package:catedra/domain/attendance/attendance.dart, package:catedra/domain/attendance/home_check.dart, package:catedra/domain/departure/departure.dart, package:catedra/features/today/application/today_providers.dart, main (+9 more)

### Community 79 - "pdf_text.dart"
Cohesion: 0.10
Nodes (20): cause, _exoticSpace, extract, hasText, layout, left, lines, normalizeSpaces (+12 more)

### Community 80 - "mascot_loader.dart"
Cohesion: 0.10
Nodes (20): build, createState, dispose, initState, inline, _line, lines, _long (+12 more)

### Community 81 - ".build"
Cohesion: 0.18
Nodes (14): AppWidgetManager, Bundle, Context, HomeWidgetProvider, Int, IntArray, RemoteViews, SharedPreferences (+6 more)

### Community 82 - "next_room_card.dart"
Cohesion: 0.11
Nodes (18): ../../application/map_providers.dart, MapRoom, accent, child, _Frame, onFocus, onPlace, onTap (+10 more)

### Community 83 - "claude_schedule_parser.dart"
Cohesion: 0.10
Nodes (19): apiKey, ClaudeScheduleParser, _client, decode, _endpoint, _hhmm, isConfigured, message (+11 more)

### Community 84 - "import_save_test.dart"
Cohesion: 0.12
Nodes (17): dart:convert, package:catedra/core/db/daos/subjects_dao.dart, package:catedra/core/providers.dart, package:catedra/features/import/data/column_schedule_parser.dart, package:catedra/features/import/data/pdf_text.dart, ProviderContainer, _fixture, _line (+9 more)

### Community 85 - "room_sheet.dart"
Cohesion: 0.11
Nodes (18): createState, _dirty, dispose, distanceKm, formatDistance, launchUrl, _notes, onMove (+10 more)

### Community 86 - "evaluation_form_sheet.dart"
Cohesion: 0.12
Nodes (17): FormState, Evaluation, build, createState, dispose, _EvaluationForm, _EvaluationFormState, existing (+9 more)

### Community 87 - "package:drift/drift.dart"
Cohesion: 0.12
Nodes (15): ../generated_migrations/schema.dart, package:catedra/core/db/database.dart, package:catedra/core/db/schema_versions.dart, package:drift_dev/api/migrations_native.dart, package:drift/drift.dart, package:drift/native.dart, SchemaVerifier, main (+7 more)

### Community 88 - "Arquitectura"
Cohesion: 0.12
Nodes (16): Ajustes, Arquitectura, Capas, Cuatro consultas, no N+1, Datos, Erizógenes, Fases, Importar PDF (+8 more)

### Community 89 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.14
Nodes (14): ../../../core/db/daos/tasks_dao.dart, ../../../core/db/database.dart, ../../core/providers.dart, child, cancelling, _confirm, dao, messenger (+6 more)

### Community 90 - "settings_dao.dart"
Cohesion: 0.12
Nodes (16): ../database.dart, setBuffer, setDefaultAbsenceLimit, setDetectHome, setEvalAlarm, setEvalReminderMinute, setHome, setLeaveAlarm (+8 more)

### Community 91 - "Funciona"
Cohesion: 0.12
Nodes (16): Ajustes, Bienvenida e importar PDF (Fase 3), Cimientos, Deuda conocida, Erizógenes, Estado del programa · 22 de septiembre de 2026 (tarde), Funciona, Hoy (+8 more)

### Community 92 - "absence_ring.dart"
Cohesion: 0.12
Nodes (15): AnimationController, build, color, createState, didUpdateWidget, dispose, filled, initState (+7 more)

### Community 93 - "update_providers.dart"
Cohesion: 0.16
Nodes (15): ../../../core/platform/update_channel.dart, double?, channel, installed, latest, progress, reachable, start (+7 more)

### Community 94 - "claude_decode_test.dart"
Cohesion: 0.13
Nodes (12): Exception, ClaudeParseException, PdfUnreadableException, package:catedra/core/time/minutes_of_day.dart, package:catedra/domain/import/schedule_parser.dart, package:catedra/domain/schedule/day_gaps.dart, package:catedra/features/import/data/claude_schedule_parser.dart, main (+4 more)

### Community 95 - "settingsProvider"
Cohesion: 0.17
Nodes (16): settingsProvider, locationProvider, mapRoomsProvider, nextRoomProvider, build, _locate, MapScreen, _MapScreenState (+8 more)

### Community 96 - "import_controller_test.dart"
Cohesion: 0.13
Nodes (14): dart:typed_data, package:syncfusion_flutter_pdf/pdf.dart, return, bytes, container, doc, font, main (+6 more)

### Community 97 - "Widget"
Cohesion: 0.14
Nodes (13): Alignment, Duration get, alignment, build, child, FadeRiseTransitionsBuilder, rise, StateSwitcher (+5 more)

### Community 98 - ".schedule"
Cohesion: 0.20
Nodes (10): EvalReminderReceiver, EvalReminders, Any, BroadcastReceiver, Context, Int, Intent, Map (+2 more)

### Community 99 - "bool get"
Cohesion: 0.14
Nodes (13): bool get, compact,
  medium,, build, child, ContentWidth, expanded, forWidth, hasRail (+5 more)

### Community 100 - "update_sheet.dart"
Cohesion: 0.18
Nodes (12): ../application/update_providers.dart, ../../../domain/updates/update_manifest.dart, updateBannerDismissedProvider, updateDownloadProvider, build, close, messenger, openUpdateSheet (+4 more)

### Community 101 - "subject_detail_providers.dart"
Cohesion: 0.15
Nodes (12): ../../../../core/db/daos/subjects_dao.dart, ../../../domain/grades/grades.dart, SubjectDetail, detail, evaluations, grades, hasGrades, SubjectDetailState (+4 more)

### Community 102 - "i0.VersionedTable"
Cohesion: 0.15
Nodes (13): i0.VersionedTable, Shape0, Shape1, Shape10, Shape11, Shape2, Shape3, Shape4 (+5 more)

### Community 103 - "Prototipo Catedra (Claude Design)"
Cohesion: 0.17
Nodes (11): Umbrales del semaforo de faltas, Las cifras de la calculadora del prototipo son maqueta, Pantallas de captura manual escritas fuera del prototipo, Prototipo Catedra (Claude Design), AttendanceCounter, TargetCalculator, package:catedra/domain/grades/grades.dart, Nota necesaria en el final (+3 more)

### Community 104 - "update_downloader_test.dart"
Cohesion: 0.17
Nodes (11): Directory, package:catedra/core/platform/update_channel.dart, package:catedra/features/updates/application/update_providers.dart, download, downloads, install, installs, main (+3 more)

### Community 105 - "subject_detail_providers.dart"
Cohesion: 0.17
Nodes (11): double get, detail, evaluations, grades, hasGrades, SubjectDetailState, tally, totalWeight (+3 more)

### Community 106 - "check_mark.dart"
Cohesion: 0.17
Nodes (11): build, checked, CheckMark, child, color, duration, _Fade, paint (+3 more)

### Community 107 - "update_channel.dart"
Cohesion: 0.17
Nodes (11): HttpClient, _channel, _chunkTimeout, _client, download, fetchManifest, install, kUpdateManifestUrl (+3 more)

### Community 108 - "map_style.dart"
Cohesion: 0.17
Nodes (11): _compose, filter, _invert, MapTileStyle, _remap, _saturation, _saturationDark, _saturationLight (+3 more)

### Community 109 - "schema.dart"
Cohesion: 0.17
Nodes (11): package:drift/internal/migrations.dart, schema_v1.dart, schema_v2.dart, schema_v3.dart, schema_v4.dart, schema_v5.dart, SchemaInstantiationHelper, static const (+3 more)

### Community 110 - "mascot_error.dart"
Cohesion: 0.20
Nodes (10): application/mascot_voice.dart, build, createState, _details, error, MascotError, _MascotErrorState, onRetry (+2 more)

### Community 111 - "Erizógenes: interacciones de la mascota"
Cohesion: 0.18
Nodes (10): Antes de tocar nada, Comprobar, Erizógenes: interacciones de la mascota, Frases nuevas o variantes, La voz, Moverlo, Piezas, Ponerlo en una pantalla nueva (+2 more)

### Community 112 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.18
Nodes (8): package:catedra/core/format/durations.dart, package:catedra/core/time/calendar_day.dart, package:catedra/domain/alarms/alarm_planner.dart, package:flutter_test/flutter_test.dart, main, main, classes, main

### Community 113 - "Color"
Cohesion: 0.20
Nodes (9): Color, EdgeInsetsGeometry?, accent, AccentCard, build, child, color, padding (+1 more)

### Community 114 - "../../core/time/minutes_of_day.dart"
Cohesion: 0.20
Nodes (9): ../../core/time/minutes_of_day.dart, afterIndex, DayGap, DayGaps, find, hours, minimumMinutes, minutes (+1 more)

### Community 115 - "dart:io"
Cohesion: 0.20
Nodes (9): dart:io, File?, _exemptions, _isComment, main, _rules, sources, startsWith (+1 more)

### Community 116 - "tokens.g.dart"
Cohesion: 0.22
Nodes (8): enteredUrgent, fire, Haptics, enteredUrgent, fire, Haptics, package:flutter/services.dart, tokens.g.dart

### Community 117 - "ImportState"
Cohesion: 0.20
Nodes (10): ImportController, ImportDone, ImportExtracting, ImportFailed, ImportIdle, ImportParsing, ImportReview, ImportSaving (+2 more)

### Community 118 - "strike_through_test.dart"
Cohesion: 0.20
Nodes (9): package:catedra/theme/motion.dart, package:catedra/theme/strike_through.dart, _host, main, _plain, _struck, style, text (+1 more)

### Community 119 - "Contrato de tokens"
Cohesion: 0.22
Nodes (8): Los .g.dart quedan fuera del analizador, Reglas de lint del proyecto, Regla de cero literales en UI, Contrato de tokens, Escala tipografica de 11 pasos, Los archivos generados no se versionan, setup.sh script, main

### Community 120 - "map_style_test.dart"
Cohesion: 0.22
Nodes (8): dart:ui, package:catedra/theme/map_style.dart, package:flutter/painting.dart, _apply, m, main, _rgb, v

### Community 121 - "build"
Cohesion: 0.25
Nodes (9): shellTabProvider, AppShell, _AppShellState, build, nextAfterTodayProvider, todayStateProvider, build, _DoneCard (+1 more)

### Community 122 - "update_manifest.dart"
Cohesion: 0.22
Nodes (8): apk, fromJson, isNewerThan, notes, UpdateManifest, versionCode, versionName, Uri

### Community 123 - "session_fields.dart"
Cohesion: 0.22
Nodes (8): build, DayChip, label, onTap, selected, TimeField, value, MinutesOfDay

### Community 124 - "subjectsDaoProvider"
Cohesion: 0.25
Nodes (8): subjectsDaoProvider, _remove, _save, toggleSubjectCancelled, _confirmDelete, _persist, _remove, _save

### Community 125 - "ambient.dart"
Cohesion: 0.29
Nodes (6): Temperatura ambiental solo en tema oscuro, Ambient, base, card, enabledFor, warmthAt

### Community 126 - "GeneratedDatabase"
Cohesion: 0.33
Nodes (6): GeneratedDatabase, DatabaseAtV1, DatabaseAtV2, DatabaseAtV3, DatabaseAtV4, DatabaseAtV5

### Community 127 - "ambient.dart"
Cohesion: 0.33
Nodes (5): Ambient, base, card, enabledFor, warmthAt

### Community 128 - "MascotView"
Cohesion: 0.40
Nodes (5): Compuerta de host de la mascota, Mascota de esquina urgente a 62 px, MascotView, _MascotViewState, TickerProviderStateMixin

### Community 129 - "ConsumerState"
Cohesion: 0.40
Nodes (5): ConsumerState, mascotAnticProvider, mascotTipsProvider, build, _MascotCompanionState

### Community 130 - "i0.VersionedSchema"
Cohesion: 0.40
Nodes (5): i0.VersionedSchema, Schema2, Schema3, Schema4, Schema5

### Community 131 - "Cátedra"
Cohesion: 0.40
Nodes (4): Arrancar, Claves de API, Cátedra, Dónde está qué

### Community 132 - "StateNotifier"
Cohesion: 0.50
Nodes (4): LocationController, LocationState, UpdateDownloader, StateNotifier

### Community 133 - "update_manifest_test.dart"
Cohesion: 0.50
Nodes (3): package:catedra/domain/updates/update_manifest.dart, main, ok

### Community 134 - "Swatch de 34 px del selector de color"
Cohesion: 0.67
Nodes (3): Swatch de 34 px del selector de color, Cinco medidas dibujadas sin token, minTouchTarget 44 manda sobre el tema

## Knowledge Gaps
- **2055 isolated node(s):** `SMALL`, `MEDIUM`, `WIDE`, `controller`, `subscriptions` (+2050 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **11 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `_List` connect `Timeline del dia` to `Context`, `.schedule`, `subject_detail_providers.dart`, `MainActivity de Android`, `Pantalla de calculadora`, `DAO de materias (CRUD)`, `Lista de materias`, `WidgetData`, `Vista de horario semanal`?**
  _High betweenness centrality (0.096) - this node is a cross-community bridge._
- **Why does `WidgetData` connect `WidgetData` to `.build`?**
  _High betweenness centrality (0.054) - this node is a cross-community bridge._
- **Why does `dart` connect `Generador de tokens` to `import_controller_test.dart`, `subject_detail_providers.dart`, `Color`, `dart:io`, `import_save_test.dart`, `Contrato de tokens`, `Hoja de detalle de materia`?**
  _High betweenness centrality (0.046) - this node is a cross-community bridge._
- **What connects `SMALL`, `MEDIUM`, `WIDE` to the rest of the system?**
  _2055 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Generador de tokens` be split into smaller, more focused modules?**
  _Cohesion score 0.024691358024691357 - nodes in this community are weakly interconnected._
- **Should `Columnas del esquema Drift` be split into smaller, more focused modules?**
  _Cohesion score 0.028985507246376812 - nodes in this community are weakly interconnected._
- **Should `Tiempo y plan de salida` be split into smaller, more focused modules?**
  _Cohesion score 0.06896551724137931 - nodes in this community are weakly interconnected._