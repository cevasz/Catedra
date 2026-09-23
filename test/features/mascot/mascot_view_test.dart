import 'package:catedra/features/mascot/mascot_view.dart';
import 'package:catedra/theme/app_theme.dart';
import 'package:catedra/theme/tokens.g.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cada pose tiene su propio micro-movimiento y su propio camino en el
/// painter. Se pintan todas, en varios fotogramas, para que un fallo de
/// geometría no espere a que alguien abra justo esa pantalla.
void main() {
  Widget host(MascotPose pose, {bool reduced = false, double size = 118}) => MaterialApp(
        theme: AppTheme.dark(),
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: Center(
            child: MascotView(pose: pose, size: size, host: MascotHost.milestone),
          ),
        ),
      );

  for (final pose in MascotPose.values) {
    testWidgets('$pose se pinta y anima sin excepciones', (tester) async {
      await tester.pumpWidget(host(pose));
      // Entrada, un ciclo largo del idle y un parpadeo posible.
      await tester.pump(MotionDurations.mascotEnter);
      await tester.pump(MotionDurations.mascotSleep);
      await tester.pump(MascotTokens.blinkMax);
      expect(tester.takeException(), isNull);
      expect(find.byType(MascotView), findsOneWidget);
    });
  }

  testWidgets('a tamaño pequeño usa la variante de púas gordas sin fallar', (tester) async {
    await tester.pumpWidget(host(MascotPose.rodando, size: MascotTokens.sizeWidget4x4));
    await tester.pump(MotionDurations.mascotRoll);
    expect(tester.takeException(), isNull);
  });

  MascotPose drawn(WidgetTester tester) =>
      (tester.state(find.byType(MascotView)) as dynamic).debugDrawnPose as MascotPose;

  testWidgets('los toques seguidos del contrato lo marean y se le pasa', (tester) async {
    await tester.pumpWidget(host(MascotPose.reposo));
    await tester.pump(MotionDurations.mascotEnter);

    for (var i = 0; i < MascotTokens.dizzyTaps - 1; i++) {
      await tester.tap(find.byType(MascotView));
      await tester.pump(MotionDurations.mascotHop);
    }
    expect(drawn(tester), MascotPose.reposo, reason: 'uno menos del umbral no marea');

    await tester.tap(find.byType(MascotView));
    await tester.pump();
    expect(drawn(tester), MascotPose.confundido);

    await tester.pump(MotionDurations.mascotDizzy);
    expect(drawn(tester), MascotPose.reposo);
  });

  testWidgets('bajo reduced-motion el toque no salta: no quedan fotogramas', (tester) async {
    await tester.pumpWidget(host(MascotPose.reposo, reduced: true));
    await tester.pump(ReducedMotion.duration);
    await tester.tap(find.byType(MascotView));
    // El toque en sí puede pedir un fotograma; a mitad de lo que duraría el
    // salto ya no debería quedar nada animándose.
    await tester.pump();
    await tester.pump(MotionDurations.mascotHop ~/ 2);
    expect(tester.takeException(), isNull);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('mantener pulsado y arrastrar se pintan sin fallar', (tester) async {
    await tester.pumpWidget(host(MascotPose.examinando));
    await tester.pump(MotionDurations.mascotEnter);
    final center = tester.getCenter(find.byType(MascotView));
    final gesture = await tester.startGesture(center);
    await tester.pump(kLongPressTimeout + MotionDurations.fast);
    await gesture.up();
    final drag = await tester.startGesture(center);
    await drag.moveBy(const Offset(40, -30));
    await tester.pump();
    await drag.up();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('bajo reduced-motion aparece con fade y se queda quieta', (tester) async {
    await tester.pumpWidget(host(MascotPose.dormido, reduced: true));
    await tester.pump(ReducedMotion.duration);
    await tester.pump(MotionDurations.mascotSleep);
    expect(tester.takeException(), isNull);
    // Sin loops corriendo no hay fotogramas pendientes: el árbol está quieto.
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
