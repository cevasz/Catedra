import 'dart:math' as math;

import 'package:catedra/domain/attendance/attendance.dart';
import 'package:catedra/features/mascot/application/mascot_voice.dart';
import 'package:catedra/features/mascot/mascot_view.dart';
import 'package:catedra/l10n/strings.g.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VariantPicker', () {
    test('nunca repite la misma frase dos veces seguidas', () {
      final picker = VariantPicker(math.Random(7));
      final lines = SMascotVoice.aphorisms;
      var previous = picker.pick(lines);
      for (var i = 0; i < 200; i++) {
        final next = picker.pick(lines);
        expect(next, isNot(previous));
        previous = next;
      }
    });

    test('con una sola variante la devuelve siempre, y con ninguna, vacío', () {
      final picker = VariantPicker();
      expect(picker.pick(['una']), 'una');
      expect(picker.pick(['una']), 'una');
      expect(picker.pick(const []), isEmpty);
    });
  });

  test('las variantes con huecos salen llenas, sin llaves sueltas', () {
    final lines = SMascotVoice.nextClassVariants(clase: 'Física', hora: '8:00', salon: '302E', salida: '7:35');
    expect(lines, hasLength(greaterThan(1)));
    for (final l in lines) {
      expect(l, contains('Física'));
      expect(l, isNot(contains('{')));
    }
  });

  test('marcar una clase se comenta; justificada y posible falta, no', () {
    expect(reactionForStatus(SessionStatus.asistio), MascotReaction.attended);
    expect(reactionForStatus(SessionStatus.falto), MascotReaction.absence);
    expect(reactionForStatus(SessionStatus.canceladaProfe), MascotReaction.cancelled);
    expect(reactionForStatus(SessionStatus.justificada), isNull);
    expect(reactionForStatus(SessionStatus.posibleFalta), isNull);
  });

  test('la esquina dice la frase y se calla sola', () {
    fakeAsync((async) {
      final c = MascotCornerController(VariantPicker(math.Random(1)));
      c.react(MascotReaction.taskDone);
      expect(SMascotVoice.reactTaskDone, contains(c.state!.text));
      expect(c.state!.pose, MascotPose.satisfecho);

      async.elapse(kMascotLineDuration - const Duration(milliseconds: 1));
      expect(c.state, isNotNull);
      async.elapse(const Duration(milliseconds: 2));
      expect(c.state, isNull);
      c.dispose();
    });
  });

  test('una frase nueva reinicia el tiempo y sube el número de serie', () {
    fakeAsync((async) {
      final c = MascotCornerController();
      c.react(MascotReaction.grade);
      final first = c.state!.serial;
      async.elapse(kMascotLineDuration ~/ 2);
      c.muse();
      expect(c.state!.serial, first + 1);
      async.elapse(kMascotLineDuration ~/ 2 + const Duration(milliseconds: 10));
      expect(c.state, isNotNull, reason: 'la segunda frase tiene su propio tiempo');
      c.dispose();
    });
  });
}
