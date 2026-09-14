import 'package:flutter/material.dart';

import 'motion.dart';

/// Entrada en cascada: opacidad más una subida corta, escalonada por índice.
///
/// Es la misma animación que el contrato describe para la timeline de Hoy
/// (40 ms de escalonado, 12 px de subida, easeOutExpo). Vive aquí y no dentro
/// de una feature porque tres listas distintas la usan y tres copias serían
/// tres oportunidades de que una se desincronice del contrato.
///
/// El escalonado se topa a las primeras filas: más allá el retraso acumulado
/// deja de leerse como cascada y empieza a leerse como lentitud.
class CascadeIn extends StatelessWidget {
  const CascadeIn({
    required this.index,
    required this.guard,
    required this.child,
    this.step = MotionStagger.timeline,
    this.rise = MotionOffsets.timelineRise,
    super.key,
  });

  final int index;
  final MotionGuard guard;
  final Widget child;

  /// Escalonado entre filas. `MotionStagger.pdfRows` para el revelado del PDF.
  final Duration step;

  /// Subida en píxeles. Bajo reduced-motion la resuelve el guard a cero.
  final double rise;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration:
          guard.duration(MotionDurations.base) + guard.stagger(staggerDelay(step, index)),
      curve: guard.curve(MotionCurves.easeOutExpo),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, guard.offset(rise) * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
