import 'package:catedra/features/mascot/mascot_view.dart';
import 'package:catedra/theme/app_theme.dart';
import 'package:catedra/theme/tokens.g.dart';
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

  testWidgets('bajo reduced-motion aparece con fade y se queda quieta', (tester) async {
    await tester.pumpWidget(host(MascotPose.dormido, reduced: true));
    await tester.pump(ReducedMotion.duration);
    await tester.pump(MotionDurations.mascotSleep);
    expect(tester.takeException(), isNull);
    // Sin loops corriendo no hay fotogramas pendientes: el árbol está quieto.
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
