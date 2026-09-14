import 'package:drift/drift.dart';

import '../../domain/attendance/attendance.dart';
import '../../domain/departure/departure.dart';

/// Un semestre académico. Sin esta tabla «cambio de semestre» no tiene dónde
/// vivir y el horario viejo contamina la vista Hoy.
class Semesters extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nombre => text().withLength(min: 1, max: 60)();

  /// Fechas absolutas, nunca offsets.
  DateTimeColumn get fechaInicio => dateTime()();
  DateTimeColumn get fechaFin => dateTime()();
  BoolColumn get activo => boolean().withDefault(const Constant(false))();
}

class Subjects extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get semesterId => integer().references(Semesters, #id)();
  TextColumn get nombre => text().withLength(min: 1, max: 80)();
  TextColumn get profesor => text().withLength(max: 80).nullable()();

  /// Índice en SubjectPalette, 0-7. Se guarda el índice y no el color para que
  /// la materia se vea igual en cualquier dispositivo y sobreviva a un cambio
  /// de paleta. Nunca se asigna al azar.
  IntColumn get colorIndex => integer()();

  IntColumn get limiteFaltas => integer().withDefault(const Constant(6))();
  IntColumn get creditos => integer().nullable()();

  /// «Última fecha para cancelar la materia: 12 de septiembre» (E2). Es por
  /// materia, no global: cada una tiene la suya.
  DateTimeColumn get fechaLimiteCancelacion => dateTime().nullable()();

  BoolColumn get archivada => boolean().withDefault(const Constant(false))();
}

class Campuses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nombre => text()();

  /// Polígono del geofence como JSON de puntos. SQLite no tiene tipo geo y la
  /// evaluación punto-en-polígono se hace en Dart puro, que sí es testeable.
  TextColumn get poligonoJson => text()();
}

class Rooms extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get codigo => text().withLength(min: 1, max: 20)();
  TextColumn get edificio => text().nullable()();

  /// «Bloque 4, piso 2» (F1). El piso es su propia columna porque se usa para
  /// ordenar y para el tiempo de caminata dentro del edificio.
  IntColumn get piso => integer().nullable()();

  /// «Entra por el patio.» Texto libre del usuario, no del parser.
  TextColumn get indicaciones => text().nullable()();

  /// Nullable a propósito: un salón puede existir sin geocodificar y la Fase 1
  /// no debe exigir ubicación para nada.
  RealColumn get lat => real().nullable()();
  RealColumn get lng => real().nullable()();
  IntColumn get campusId => integer().references(Campuses, #id).nullable()();
}

class ClassSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get subjectId => integer().references(Subjects, #id)();

  /// ISO 8601: 1 = lunes … 7 = domingo, igual que DateTime.weekday. Cualquier
  /// otra convención genera off-by-one el día que alguien mezcle las dos.
  IntColumn get diaSemana => integer()();

  /// Minutos desde medianoche. Ver MinutesOfDay.
  IntColumn get horaInicio => integer()();
  IntColumn get horaFin => integer()();

  IntColumn get roomId => integer().references(Rooms, #id).nullable()();

  /// Ventana de vigencia. Una clase puede empezar tarde en el semestre o
  /// terminar antes; sin esto el calendario genera sesiones que no existen.
  DateTimeColumn get fechaDesde => dateTime().nullable()();
  DateTimeColumn get fechaHasta => dateTime().nullable()();
}

class SessionInstances extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer().references(ClassSessions, #id)();

  /// Fecha absoluta del día de clase, normalizada a medianoche local.
  DateTimeColumn get fecha => dateTime()();

  IntColumn get estado => intEnum<SessionStatus>()
      .withDefault(Constant(SessionStatus.pendiente.index))();

  /// «Marcada hace 3 min» + Deshacer (B3) necesita el instante del marcado,
  /// no solo el estado final.
  DateTimeColumn get marcadaEn => dateTime().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {sessionId, fecha},
      ];
}

class Evaluations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get subjectId => integer().references(Subjects, #id)();
  TextColumn get nombre => text().withLength(min: 1, max: 80)();

  /// Fracción del total: 0.30 para un 30 %. Se guarda como real y no como
  /// entero de porcentaje para no perder un 12,5 %.
  RealColumn get porcentaje => real()();

  /// Nullable: una evaluación sin calificar es el caso normal y es justo lo
  /// que alimenta la calculadora inversa.
  RealColumn get nota => real().nullable()();

  DateTimeColumn get fecha => dateTime().nullable()();
  IntColumn get orden => integer().withDefault(const Constant(0))();
}

/// Fila única. `id` fijo en 1 para que un UPSERT no pueda duplicarla.
class UserSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  IntColumn get bufferMinutos => integer().withDefault(const Constant(5))();
  IntColumn get modoTransporte =>
      intEnum<TransportMode>().withDefault(Constant(TransportMode.walk.index))();
  TextColumn get direccionCasa => text().nullable()();
  RealColumn get homeLat => real().nullable()();
  RealColumn get homeLng => real().nullable()();

  /// 0 auto, 1 claro, 2 oscuro. Coincide con ThemeMode.
  IntColumn get tema => integer().withDefault(const Constant(0))();
  IntColumn get limiteFaltasPorDefecto => integer().withDefault(const Constant(6))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
