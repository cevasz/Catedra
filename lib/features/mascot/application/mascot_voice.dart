import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/attendance/attendance.dart';
import '../../../l10n/strings.g.dart';
import '../../../theme/tokens.g.dart';
import '../mascot_view.dart';

/// Qué acaba de pasar en la app, para que Erizógenes lo comente.
enum MascotReaction {
  attended,
  absence,
  cancelled,
  grade,
  taskAdded,
  taskDone,
  saved,
  alarms;

  List<String> get lines => switch (this) {
        attended => SMascotVoice.reactAttended,
        absence => SMascotVoice.reactAbsence,
        cancelled => SMascotVoice.reactCancelled,
        grade => SMascotVoice.reactGrade,
        taskAdded => SMascotVoice.reactTaskAdded,
        taskDone => SMascotVoice.reactTaskDone,
        saved => SMascotVoice.reactSaved,
        alarms => SMascotVoice.reactAlarms,
      };

  MascotPose get pose => switch (this) {
        absence => MascotPose.examinando,
        cancelled => MascotPose.dormido,
        _ => MascotPose.satisfecho,
      };
}

/// Qué comenta el erizo cuando marcas una clase. Justificada y «posible
/// falta» no merecen comentario: la primera es burocracia, la segunda aún no
/// es un hecho.
MascotReaction? reactionForStatus(SessionStatus status) => switch (status) {
      SessionStatus.asistio => MascotReaction.attended,
      SessionStatus.falto => MascotReaction.absence,
      SessionStatus.canceladaProfe => MascotReaction.cancelled,
      _ => null,
    };

/// Una frase que Erizógenes está diciendo ahora mismo en la esquina.
class MascotLine {
  const MascotLine(this.text, this.pose, this.serial);

  final String text;
  final MascotPose pose;

  /// Sube con cada frase: dos frases iguales seguidas también se animan.
  final int serial;
}

/// Escoge variantes sin repetir la última que salió de la misma lista.
///
/// Diógenes no se repetía; su erizo tampoco. Con una sola variante devuelve
/// esa, y con una lista vacía, cadena vacía.
class VariantPicker {
  VariantPicker([math.Random? random]) : _random = random ?? math.Random();

  final math.Random _random;
  final Map<int, int> _last = {};

  String pick(List<String> options) {
    if (options.isEmpty) return '';
    if (options.length == 1) return options.single;
    final key = Object.hashAll(options);
    var i = _random.nextInt(options.length);
    if (i == _last[key]) i = (i + 1) % options.length;
    _last[key] = i;
    return options[i];
  }
}

/// Cuánto se queda una frase en la esquina antes de que el erizo se esconda.
const Duration kMascotLineDuration = MotionDurations.mascotLine;

/// La esquina de Erizógenes: lo que dice ahora, o nada.
///
/// Cualquier pantalla puede pedirle que reaccione con [MascotCornerController.react];
/// la frase se va sola a los pocos segundos.
final mascotCornerProvider = StateNotifierProvider<MascotCornerController, MascotLine?>(
  (ref) => MascotCornerController(),
);

class MascotCornerController extends StateNotifier<MascotLine?> {
  MascotCornerController([VariantPicker? picker])
      : _picker = picker ?? VariantPicker(),
        super(null);

  final VariantPicker _picker;
  Timer? _hide;
  int _serial = 0;

  void react(MascotReaction? reaction) {
    if (reaction != null) say(_picker.pick(reaction.lines), reaction.pose);
  }

  /// Una frase suelta, sin dato detrás: una sentencia o una queja por el toque.
  void muse() => say(
        _picker.pick([...SMascotVoice.aphorisms, ...SMascotVoice.petLines]),
        MascotPose.reposo,
      );

  void say(String text, MascotPose pose) {
    if (text.isEmpty) return;
    _hide?.cancel();
    state = MascotLine(text, pose, ++_serial);
    _hide = Timer(kMascotLineDuration, dismiss);
  }

  void dismiss() {
    _hide?.cancel();
    state = null;
  }

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }
}
