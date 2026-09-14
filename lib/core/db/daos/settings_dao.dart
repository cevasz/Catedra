import 'package:drift/drift.dart';

import '../../../domain/departure/departure.dart';
import '../database.dart';
import '../tables.dart';

part 'settings_dao.g.dart';

/// La fila única de ajustes. Se lee como stream para que cambiar el buffer en
/// Ajustes mueva la hora de salida de Hoy sin recargar nada.
@DriftAccessor(tables: [UserSettings])
class SettingsDao extends DatabaseAccessor<CatedraDatabase> with _$SettingsDaoMixin {
  SettingsDao(super.db);

  /// `onCreate` inserta la fila 1, así que `watchSingle` no debería fallar
  /// nunca. Si alguien la borra a mano, mejor que reviente aquí que pintar
  /// ajustes inventados.
  Stream<UserSetting> watch() =>
      (select(userSettings)..where((t) => t.id.equals(1))).watchSingle();

  Future<UserSetting> get() =>
      (select(userSettings)..where((t) => t.id.equals(1))).getSingle();

  /// Cada campo se escribe por separado: una pantalla de ajustes guarda al
  /// tocar, no con un botón de «Guardar», y no debe pisar lo que no tocó.
  Future<void> setBuffer(int minutos) => _write(
        UserSettingsCompanion(bufferMinutos: Value(minutos)),
      );

  Future<void> setTransport(TransportMode mode) => _write(
        UserSettingsCompanion(modoTransporte: Value(mode)),
      );

  Future<void> setDefaultAbsenceLimit(int limite) => _write(
        UserSettingsCompanion(limiteFaltasPorDefecto: Value(limite)),
      );

  /// `tema` guarda el índice de `ThemeMode` (0 auto, 1 claro, 2 oscuro). Se
  /// recibe el entero y no el enum porque este archivo no importa Flutter.
  Future<void> setThemeIndex(int index) => _write(
        UserSettingsCompanion(tema: Value(index)),
      );

  Future<void> _write(UserSettingsCompanion data) =>
      (update(userSettings)..where((t) => t.id.equals(1))).write(data);
}
