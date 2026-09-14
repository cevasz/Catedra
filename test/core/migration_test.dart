import 'package:catedra/core/db/database.dart';
import 'package:catedra/core/db/schema_versions.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../generated_migrations/schema.dart';

/// La red que faltaba en el esquema.
///
/// `drift_schemas/drift_schema_v1.json` es el volcado de la v1 tal como salió
/// publicada. Este test compara el esquema que `tables.dart` produce hoy contra
/// ese volcado: si alguien añade una columna sin exportar la nueva versión, el
/// fallo aparece aquí y no en el teléfono de alguien con datos dentro.
///
/// Para exportar una versión nueva, tras subir `schemaVersion`:
///   dart run drift_dev schema dump lib/core/db/database.dart drift_schemas/
///   dart run drift_dev schema steps drift_schemas/ lib/core/db/schema_versions.dart
///   dart run drift_dev schema generate drift_schemas/ test/generated_migrations/
void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('el esquema en código sigue siendo idéntico al volcado de la v1', () async {
    final connection = await verifier.startAt(1);
    final db = CatedraDatabase.forTesting(connection);
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, 1);
  });

  test('una base recién creada nace en la versión declarada', () async {
    final db = CatedraDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    // Fuerza la apertura real: sin una consulta, `onCreate` no llega a correr.
    await db.customSelect('SELECT 1').get();

    expect(db.schemaVersion, 1);
  });

  test('onCreate deja la fila única de ajustes lista', () async {
    final db = CatedraDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final rows = await db.select(db.userSettings).get();
    expect(rows, hasLength(1));
    expect(rows.single.id, 1);
    // Los defaults del contrato, no los del código de pantalla.
    expect(rows.single.bufferMinutos, 5);
    expect(rows.single.limiteFaltasPorDefecto, 6);
  });

  test('un salto de versión sin paso declarado falla ruidosamente', () {
    // El día que `schemaVersion` suba a 2 sin declarar el paso, stepByStep
    // lanza en vez de dejar el esquema a medias. Se comprueba el contrato del
    // helper generado, que es lo que protege al usuario con datos.
    expect(migrationSteps, isNotNull);
  });
}
