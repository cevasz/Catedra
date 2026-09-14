import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

// SessionStatus y TransportMode los necesita database.g.dart, que es un `part`
// de este archivo y por tanto ve estos imports, no los de tables.dart.
import '../../domain/attendance/attendance.dart';
import '../../domain/departure/departure.dart';
import 'daos/schedule_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/subjects_dao.dart';
import 'schema_versions.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Semesters,
    Subjects,
    Campuses,
    Rooms,
    ClassSessions,
    SessionInstances,
    Evaluations,
    UserSettings,
  ],
  daos: [ScheduleDao, SubjectsDao, SettingsDao],
)
class CatedraDatabase extends _$CatedraDatabase {
  CatedraDatabase() : super(_open());

  /// Para tests: base en memoria, sin tocar disco ni plugins.
  CatedraDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // La fila única de ajustes tiene que existir desde el arranque; si no,
          // toda lectura de ajustes necesitaría un caso nulo.
          await into(userSettings).insert(
            const UserSettingsCompanion(id: Value(1)),
            mode: InsertMode.insertOrIgnore,
          );
        },
        // Todavía no hay ningún paso: v1 es la primera versión publicada. El
        // `stepByStep` vacío está aquí a propósito y no como olvido — el día
        // que suba `schemaVersion`, drift obliga a declarar el salto aquí en
        // vez de dejar a los usuarios con datos frente a un esquema viejo.
        //
        // El esquema de cada versión se exporta a `drift_schemas/` con
        // `dart run drift_dev schema dump`, y `test/core/migration_test.dart`
        // verifica los saltos contra esos volcados.
        onUpgrade: stepByStep(),
        beforeOpen: (details) async {
          // Las claves foráneas están apagadas por defecto en SQLite.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

LazyDatabase _open() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'catedra.sqlite'));
    await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    return NativeDatabase.createInBackground(file);
  });
}
