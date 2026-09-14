import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../domain/attendance/attendance.dart';
import '../../../domain/import/schedule_parser.dart';
import '../../../theme/tokens.g.dart';
import '../data/claude_schedule_parser.dart';
import '../data/pdf_text.dart';

/// Por qué falló la importación. Cada motivo tiene su texto en A5.
enum ImportFailure {
  /// Hay páginas pero ninguna trae texto: está escaneado como imagen.
  noText,

  /// No se pudo abrir: dañado, cifrado o no es un PDF.
  unreadable,

  /// Sí hay texto, pero ninguna línea parece una clase.
  nothingFound,
}

/// La máquina de estados del importador: A2 → A3 → A4 (o A5).
sealed class ImportState {
  const ImportState();
}

/// A2: esperando un archivo.
class ImportIdle extends ImportState {
  const ImportIdle();
}

/// A3, primera mitad: sacando el texto del PDF, página a página.
class ImportExtracting extends ImportState {
  const ImportExtracting({required this.fileName});
  final String fileName;
}

/// A3, segunda mitad: las filas van apareciendo. `refining` es la pasada con
/// Claude, que corre sobre lo que la heurística ya enseñó.
class ImportParsing extends ImportState {
  const ImportParsing({
    required this.fileName,
    required this.found,
    required this.done,
    required this.total,
    this.refining = false,
  });

  final String fileName;
  final List<ParsedClass> found;
  final int done;
  final int total;
  final bool refining;
}

/// A4: la persona revisa y corrige antes de guardar.
class ImportReview extends ImportState {
  ImportReview({required this.classes, required this.usedClaude, List<int>? ids})
      : ids = ids ?? List<int>.generate(classes.length, (i) => i);

  final List<ParsedClass> classes;

  /// Identidad estable de cada fila mientras se edita. Los índices cambian al
  /// quitar una materia; los campos de texto necesitan una clave que no.
  final List<int> ids;

  /// Para decirlo en la pantalla si hace falta; hoy solo se registra.
  final bool usedClaude;

  int get sessionCount => classes.fold(0, (n, c) => n + c.sessions.length);
  int get doubtCount => classes.where((c) => c.isLowConfidence).length;

  /// Se puede confirmar cuando toda materia tiene nombre y todo horario tiene
  /// día. Lo demás (profesor, salón) puede faltar.
  bool get canConfirm =>
      classes.isNotEmpty &&
      classes.every((c) => c.nombre.trim().isNotEmpty) &&
      classes.every((c) => c.sessions.every((s) => s.diaSemana >= 1 && s.diaSemana <= 7)) &&
      sessionCount > 0;

  ImportReview copyWith({List<ParsedClass>? classes, List<int>? ids}) =>
      ImportReview(classes: classes ?? this.classes, usedClaude: usedClaude, ids: ids ?? this.ids);
}

class ImportSaving extends ImportState {
  const ImportSaving();
}

class ImportDone extends ImportState {
  const ImportDone({required this.subjects, required this.sessions});
  final int subjects;
  final int sessions;
}

/// A5.
class ImportFailed extends ImportState {
  const ImportFailed(this.reason);
  final ImportFailure reason;
}

/// Cuántas filas se revelan por paso en A3. El revelado es una cascada de
/// `MotionStagger.pdfRows` por fila; con esto un PDF de cien líneas tarda lo
/// mismo en aparecer que uno de veinte.
const int _revealSteps = 20;

class ImportController extends StateNotifier<ImportState> {
  ImportController(this._ref) : super(const ImportIdle());

  final Ref _ref;

  /// Sube con cada importación o cancelación. Un resultado que llega con una
  /// generación vieja se descarta sin tocar el estado.
  int _generation = 0;

  /// Abre el selector del sistema. Si la persona lo cierra sin escoger, no
  /// pasa nada: A2 sigue ahí.
  Future<void> pick() async {
    final PlatformFile? file;
    final Uint8List bytes;
    try {
      file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      if (file == null) return;
      bytes = await file.readAsBytes();
    } on Exception {
      // El selector del sistema falló o el archivo no se pudo leer: es el
      // mismo caso que un PDF ilegible, y A5 ya sabe decirlo.
      if (mounted) state = const ImportFailed(ImportFailure.unreadable);
      return;
    }
    await importBytes(bytes, fileName: file.name);
  }

  /// Un resultado es viejo si la persona canceló, empezó otra importación o
  /// cerró la pantalla mientras llegaba.
  bool _stale(int generation) => !mounted || generation != _generation;

  Future<void> importBytes(Uint8List bytes, {required String fileName}) async {
    final generation = ++_generation;
    state = ImportExtracting(fileName: fileName);

    final PdfTextResult text;
    try {
      text = await PdfText.extract(bytes);
    } on Exception {
      // PdfUnreadableException o cualquier tropiezo interno del extractor con
      // un archivo raro: para la persona es lo mismo, no se pudo abrir.
      if (_stale(generation)) return;
      state = const ImportFailed(ImportFailure.unreadable);
      return;
    }
    if (_stale(generation)) return;

    if (!text.hasText) {
      state = const ImportFailed(ImportFailure.noText);
      return;
    }

    // Revelado en cascada: la heurística es instantánea, pero las filas
    // entran de a pocas para que la persona vea qué se va encontrando.
    final lines = text.lines;
    final step = (lines.length / _revealSteps).ceil().clamp(1, lines.length);
    var found = <ParsedClass>[];
    for (var done = step; done <= lines.length + step - 1; done += step) {
      final upTo = done.clamp(0, lines.length);
      found = ScheduleParser.parse(lines.sublist(0, upTo));
      state = ImportParsing(fileName: fileName, found: found, done: upTo, total: lines.length);
      if (upTo == lines.length) break;
      await Future<void>.delayed(MotionStagger.pdfRows);
      if (_stale(generation)) return;
    }

    var classes = found;
    var usedClaude = false;
    if (ClaudeScheduleParser.isConfigured) {
      state = ImportParsing(
        fileName: fileName,
        found: found,
        done: lines.length,
        total: lines.length,
        refining: true,
      );
      try {
        final refined = await ClaudeScheduleParser().parse(lines.join('\n'));
        if (_stale(generation)) return;
        if (refined.isNotEmpty) {
          classes = refined;
          usedClaude = true;
        }
      } on ClaudeParseException {
        // Sin red o sin respuesta útil: se sigue con lo heurístico. El
        // importador nunca depende de la API para funcionar.
      }
    }
    if (_stale(generation)) return;

    if (classes.isEmpty) {
      state = const ImportFailed(ImportFailure.nothingFound);
      return;
    }
    state = ImportReview(classes: classes, usedClaude: usedClaude);
  }

  /// Cancelar durante A3 vuelve a A2. Lo que estaba en vuelo se descarta al
  /// llegar porque la generación ya no coincide.
  void cancel() {
    _generation++;
    state = const ImportIdle();
  }

  void reset() {
    _generation++;
    state = const ImportIdle();
  }

  // ------------------------------------------------------------- revisión

  void updateClass(int index, ParsedClass updated) {
    final s = state;
    if (s is! ImportReview) return;
    final list = [...s.classes];
    list[index] = updated;
    state = s.copyWith(classes: list);
  }

  void removeClass(int index) {
    final s = state;
    if (s is! ImportReview) return;
    final list = [...s.classes]..removeAt(index);
    final ids = [...s.ids]..removeAt(index);
    state = s.copyWith(classes: list, ids: ids);
  }

  /// Corregir un campo quita la duda que lo señalaba: si la persona ya lo
  /// miró, la insignia sobra.
  void setName(int index, String value) {
    final s = state;
    if (s is! ImportReview) return;
    final c = s.classes[index];
    updateClass(
      index,
      c.copyWith(
        nombre: value,
        doubts: {...c.doubts}..removeAll([ParseDoubt.missingName, ParseDoubt.nameFromPreviousLine]),
      ),
    );
  }

  void setProfesor(int index, String value) {
    final s = state;
    if (s is! ImportReview) return;
    final c = s.classes[index];
    final v = value.trim();
    updateClass(index, v.isEmpty ? c.copyWith(clearProfesor: true) : c.copyWith(profesor: v));
  }

  void setSalon(int index, String value) {
    final s = state;
    if (s is! ImportReview) return;
    final c = s.classes[index];
    final v = value.trim();
    updateClass(index, v.isEmpty ? c.copyWith(clearSalon: true) : c.copyWith(salon: v));
  }

  void setSession(int classIndex, int sessionIndex, ParsedSession session) {
    final s = state;
    if (s is! ImportReview) return;
    final c = s.classes[classIndex];
    final sessions = [...c.sessions];
    if (sessionIndex < sessions.length) {
      sessions[sessionIndex] = session;
    } else {
      sessions.add(session);
    }
    updateClass(
      classIndex,
      c.copyWith(sessions: sessions, doubts: _sessionDoubts(c.doubts, sessions)),
    );
  }

  void removeSession(int classIndex, int sessionIndex) {
    final s = state;
    if (s is! ImportReview) return;
    final c = s.classes[classIndex];
    final sessions = [...c.sessions]..removeAt(sessionIndex);
    updateClass(
      classIndex,
      c.copyWith(sessions: sessions, doubts: _sessionDoubts(c.doubts, sessions)),
    );
  }

  static Set<ParseDoubt> _sessionDoubts(Set<ParseDoubt> current, List<ParsedSession> sessions) {
    final d = {...current}..removeAll([ParseDoubt.missingDays, ParseDoubt.badRange]);
    if (sessions.any((s) => s.diaSemana < 1 || s.diaSemana > 7)) d.add(ParseDoubt.missingDays);
    if (sessions.any((s) => s.fin <= s.inicio)) d.add(ParseDoubt.badRange);
    return d;
  }

  // ------------------------------------------------------------- guardar

  /// Crea materias, salones y clases. El color se asigna por orden de
  /// aparición, no al azar, para que dos importaciones del mismo PDF den el
  /// mismo resultado.
  Future<void> confirm() async {
    final s = state;
    if (s is! ImportReview || !s.canConfirm) return;
    state = const ImportSaving();

    final dao = _ref.read(subjectsDaoProvider);
    final defaultLimit = _ref.read(settingsProvider).valueOrNull?.limiteFaltasPorDefecto ??
        AttendanceCounter.defaultLimit;

    // Los colores siguen tras las materias que ya existen, para no repetir
    // el primero de la paleta en cada importación.
    final existing = await dao.watchOverview().first;
    var colorCursor = existing.length;

    var sessions = 0;
    for (final c in s.classes) {
      final subjectId = await dao.createSubject(
        nombre: c.nombre.trim(),
        colorIndex: colorCursor++ % SubjectPalette.length,
        limiteFaltas: defaultLimit,
        profesor: c.profesor,
      );
      final roomId = c.salon == null ? null : await dao.ensureRoom(codigo: c.salon);
      for (final ses in c.sessions) {
        await dao.saveSession(
          subjectId: subjectId,
          diaSemana: ses.diaSemana,
          horaInicio: ses.inicio.raw,
          horaFin: ses.fin.raw,
          roomId: roomId,
        );
        sessions++;
      }
    }
    state = ImportDone(subjects: s.classes.length, sessions: sessions);
  }
}

final importControllerProvider =
    StateNotifierProvider.autoDispose<ImportController, ImportState>(
  (ref) => ImportController(ref),
);
