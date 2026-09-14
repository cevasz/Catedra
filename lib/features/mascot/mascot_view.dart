// ─────────────────────────────────────────────────────────────────────────────
// ERIZÓGENES · erizo peludo de monóculo
//
// Se consume SOLO vía `MascotView(pose:, size:)`. Ningún otro feature importa
// la geometría ni los colores de este módulo directamente.
//
// PANTALLAS DONDE PUEDE APARECER
//   A1  splash / bienvenida
//   A3  procesando el PDF          (pose: examinando)
//   A5  error de lectura del PDF   (pose: confundido)
//   B2  «sal ya», pequeño en la esquina de la card (pose: rodando)
//   B4  sin clases hoy             (pose: dormido)
//   D3  materia sin notas          (pose: reposo)
//   Widget 4×4, a 44 px en la esquina inferior
//   Hitos: fin de semestre, primera materia creada, materia salvada del riesgo
//
// PANTALLAS DONDE NO APARECE NUNCA
//   Detalle de materia, calculadora de notas, horario semanal, mapa, ajustes.
//   Son pantallas de trabajo.
//   Tampoco cuando el usuario pierde una materia ni cuando la calculadora dice
//   que ya no da: ahí una mascota tierna se siente burlona. Solo tipografía.
//   Widgets 2×2 y 4×2.
//
// El parpadeo aleatorio (cada 4–7 s) lo maneja este módulo con su propio Timer.
// El feature que lo consume no sabe nada de eso.
//
// MICRO-MOVIMIENTOS (todos en loop, todos del contrato)
//   reposo / satisfecho    respira 1 → 1,02 desde las patas
//   rodando                gira 360° y se aplasta/estira al ritmo
//   dormido                respiración de sueño 1 → 0,985 y tres «z» que suben
//   examinando             la mirada barre ±1,2 px y el monóculo destella
//   confundido             el monóculo se bambolea ±4°; la cabeza no
//   entrada (todas)        una vez: escala 0,6 → 1 con easeOutBackBounce
//
// Bajo reduced-motion las poses se congelan en su primer fotograma. No se
// ocultan: la mascota sigue ahí, quieta.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/motion.dart';
import '../../theme/tokens.g.dart';

export '../../theme/tokens.g.dart' show MascotPose;

/// Pantallas con permiso. En debug, instanciar `MascotView` desde otro sitio
/// revienta con un mensaje claro: la regla de diseño es también de código.
enum MascotHost {
  splash('A1 splash'),
  pdfParsing('A3 procesando PDF'),
  pdfError('A5 error de PDF'),
  urgentCorner('B2 sal ya (esquina)'),
  emptyDay('B4 sin clases hoy'),
  emptyGrades('D3 materia sin notas'),
  milestone('hitos'),
  widget4x4('widget 4x4');

  const MascotHost(this.contractName);

  /// Nombre tal como aparece en `mascot.allowedScreens` de tokens.json.
  final String contractName;
}

class MascotView extends StatefulWidget {
  const MascotView({
    required this.pose,
    required this.size,
    required this.host,
    super.key,
  });

  final MascotPose pose;
  final double size;

  /// Obliga a declarar desde dónde se llama. No hay valor por defecto a
  /// propósito: si no sabes en qué pantalla estás, no deberías poner la mascota.
  final MascotHost host;

  @override
  State<MascotView> createState() => _MascotViewState();
}

class _MascotViewState extends State<MascotView> with TickerProviderStateMixin {
  late final AnimationController _idle; // respiración, sueño o rodada
  late final AnimationController _aux; // squash, z, mirada o bamboleo
  late final AnimationController _enter; // una vez, al aparecer
  late final AnimationController _blink;
  bool _entered = false;
  Timer? _blinkTimer;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    assert(
      MascotTokens.allowedScreens.contains(widget.host.contractName),
      'MascotView en una pantalla no permitida: ${widget.host.contractName}. '
      'Ver la lista en el encabezado de lib/features/mascot/mascot_view.dart.',
    );

    _idle = AnimationController(vsync: this, duration: _idleDuration);
    _aux = AnimationController(vsync: this, duration: _auxDuration ?? MotionDurations.base);
    _enter = AnimationController(vsync: this, duration: MotionDurations.mascotEnter);
    _blink = AnimationController(vsync: this, duration: MotionDurations.mascotBlink);
  }

  Duration get _idleDuration => switch (widget.pose) {
        MascotPose.rodando => MotionDurations.mascotRoll,
        MascotPose.dormido => MotionDurations.mascotSleep,
        _ => MotionDurations.mascotBreathe,
      };

  /// Null cuando la pose no tiene segundo movimiento.
  Duration? get _auxDuration => switch (widget.pose) {
        // El squash va al doble de frecuencia que la rodada: dos contactos
        // con el suelo por vuelta.
        MascotPose.rodando => MotionDurations.mascotRoll ~/ 2,
        MascotPose.dormido => MotionDurations.mascotSleep,
        MascotPose.examinando => MotionDurations.mascotGlance,
        MascotPose.confundido => MotionDurations.mascotBreathe,
        _ => null,
      };

  @override
  void didUpdateWidget(MascotView old) {
    super.didUpdateWidget(old);
    if (old.pose != widget.pose) {
      _idle.duration = _idleDuration;
      _aux.duration = _auxDuration ?? MotionDurations.base;
      _syncMotion();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
    if (!_entered) {
      _entered = true;
      // Bajo reduced-motion la entrada se queda en el fade del contrato: la
      // escala no se toca y solo aparece.
      _enter.duration = MotionGuard.of(context).duration(MotionDurations.mascotEnter);
      _enter.forward();
    }
  }

  void _syncMotion() {
    final guard = MotionGuard.of(context);
    _blinkTimer?.cancel();

    if (!guard.allowsLoops) {
      // Congelado en el primer fotograma, no oculto.
      for (final c in [_idle, _aux, _blink]) {
        c.stop();
        c.value = 0;
      }
      return;
    }

    switch (widget.pose) {
      case MascotPose.rodando:
        _idle.repeat();
        _aux.repeat(reverse: true);
      case MascotPose.dormido:
        _idle.repeat(reverse: true);
        // Las z suben siempre en el mismo sentido: no vuelven.
        _aux.repeat();
      case MascotPose.examinando || MascotPose.confundido:
        _idle.repeat(reverse: true);
        _aux.repeat(reverse: true);
      case MascotPose.reposo || MascotPose.satisfecho:
        _idle.repeat(reverse: true);
        _aux.stop();
        _aux.value = 0;
    }

    if (_eyesCanBlink) _scheduleBlink();
  }

  bool get _eyesCanBlink =>
      widget.pose != MascotPose.dormido && widget.pose != MascotPose.satisfecho;

  /// Cada 4–7 s. El intervalo se sortea de nuevo tras cada parpadeo para que no
  /// caiga en un ritmo perceptible.
  void _scheduleBlink() {
    final min = MascotTokens.blinkMin.inMilliseconds;
    final max = MascotTokens.blinkMax.inMilliseconds;
    final wait = Duration(milliseconds: min + _random.nextInt(max - min));
    _blinkTimer = Timer(wait, () async {
      if (!mounted) return;
      await _blink.forward();
      await _blink.reverse();
      if (mounted) _scheduleBlink();
    });
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _idle.dispose();
    _aux.dispose();
    _enter.dispose();
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    // La luz de borde solo existe en oscuro: sobre hueso el cuerpo se queda
    // igual y solo desaparece el rim.
    final rim = brightness == Brightness.dark || MascotTokens.rimLightOnLightTheme;

    final guard = MotionGuard.of(context);
    final enterCurve = CurvedAnimation(
      parent: _enter,
      curve: guard.curve(MotionCurves.easeOutBackBounce),
    );

    return RepaintBoundary(
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: Listenable.merge([_idle, _aux, _blink, _enter]),
          builder: (context, _) {
            // Entrada: sobrepasa un poco y asienta. El origen es la base de la
            // silueta para que parezca que llega al suelo, no que se infla.
            final t = enterCurve.value;
            final scale = guard.reduced ? 1.0 : MascotTokens.enterScale + (1 - MascotTokens.enterScale) * t;
            return Opacity(
              opacity: _enter.value.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.bottomCenter,
                child: CustomPaint(
                  painter: _ErizogenesPainter(
                    pose: widget.pose,
                    rim: rim,
                    idle: _idle.value,
                    aux: _aux.value,
                    blink: _blink.value,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Parámetros de una pose. Portados uno a uno del prototipo Erizogenes.dc.html
/// para que la silueta sea idéntica; cambiarlos aquí es desviarse del diseño.
class _PoseSpec {
  const _PoseSpec({
    required this.rx,
    required this.ry,
    required this.cy,
    required this.spikeLength,
    required this.tilt,
    required this.spikeTilt,
    required this.eye,
    required this.gaze,
    required this.monocle,
    this.breathes = false,
    this.rolls = false,
    this.speedLines = false,
    this.paw = false,
  });

  final double rx, ry, cy, spikeLength, tilt, spikeTilt;
  final _Eye eye;
  final Offset gaze;

  /// x, y, radio, rotación del monóculo.
  final List<double> monocle;
  final bool breathes, rolls, speedLines, paw;
}

enum _Eye { open, arc, squint }

const Map<MascotPose, _PoseSpec> _poses = {
  MascotPose.reposo: _PoseSpec(
    rx: 30, ry: 30, cy: 54, spikeLength: 15, tilt: 0, spikeTilt: 0,
    eye: _Eye.open, gaze: Offset.zero, monocle: [62, 50, 12, 0], breathes: true,
  ),
  MascotPose.rodando: _PoseSpec(
    rx: 29, ry: 29, cy: 54, spikeLength: 14, tilt: 0, spikeTilt: 0,
    eye: _Eye.open, gaze: Offset(1.6, 0), monocle: [62, 50, 12, -8],
    rolls: true, speedLines: true,
  ),
  MascotPose.dormido: _PoseSpec(
    rx: 35, ry: 23, cy: 64, spikeLength: 10, tilt: 0, spikeTilt: 24,
    eye: _Eye.arc, gaze: Offset.zero, monocle: [63, 60, 11, 7],
  ),
  MascotPose.examinando: _PoseSpec(
    rx: 30, ry: 29, cy: 56, spikeLength: 16, tilt: 10, spikeTilt: 0,
    eye: _Eye.open, gaze: Offset(1, 1.6), monocle: [63, 52, 13, 4], paw: true,
  ),
  MascotPose.satisfecho: _PoseSpec(
    rx: 31, ry: 29, cy: 55, spikeLength: 14, tilt: 4, spikeTilt: -6,
    eye: _Eye.squint, gaze: Offset.zero, monocle: [62, 50, 12, 2],
  ),
  MascotPose.confundido: _PoseSpec(
    rx: 30, ry: 29, cy: 54, spikeLength: 15, tilt: -12, spikeTilt: 8,
    eye: _Eye.open, gaze: Offset(-1.6, 1), monocle: [66, 62, 11, 26],
  ),
};

class _ErizogenesPainter extends CustomPainter {
  _ErizogenesPainter({
    required this.pose,
    required this.rim,
    required this.idle,
    required this.aux,
    required this.blink,
  });

  final MascotPose pose;
  final bool rim;

  /// 0..1. Respiración, sueño o ángulo de rodada según la pose.
  final double idle;

  /// 0..1. El segundo movimiento de la pose: squash, z, mirada o bamboleo.
  final double aux;

  /// 0..1. 1 = ojos cerrados.
  final double blink;

  @override
  void paint(Canvas canvas, Size size) {
    final p = _poses[pose]!;
    final scale = size.width / 100.0;
    // A tamaño pequeño la silueta necesita púas más gordas y monóculo más grueso:
    // es la única variante permitida.
    final small = size.width <= MascotTokens.smallThreshold;

    canvas.save();
    canvas.scale(scale);

    // Rodada: gira el conjunto alrededor del centro del cuerpo y, encima, se
    // aplasta y estira al ritmo: dos contactos con el suelo por vuelta.
    if (p.rolls) {
      if (p.speedLines) _paintSpeedLines(canvas);
      canvas.translate(50, p.cy);
      canvas.rotate(idle * 2 * math.pi);
      final squash = MascotTokens.squashScale * (1 - 2 * aux);
      canvas.scale(1 + squash, 1 - squash);
      canvas.translate(-50, -p.cy);
    } else if (pose == MascotPose.dormido) {
      // Respiración de sueño: más lenta y hacia abajo. Un cuerpo dormido no se
      // hincha, se hunde un poco.
      final s = 1 - (1 - MascotTokens.sleepScale) * idle;
      final originY = p.cy + p.ry;
      canvas.translate(50, originY);
      canvas.scale(1, s);
      canvas.translate(-50, -originY);
    } else if (p.breathes) {
      // Respiración: 1,0 → 1,02 con origen en las patas.
      final s = 1 + (MascotTokens.breatheScaleMax - 1) * idle;
      final originY = p.cy + p.ry;
      canvas.translate(50, originY);
      canvas.scale(1, s);
      canvas.translate(-50, -originY);
    }

    // Inclinación de la pose.
    canvas.translate(50, p.cy);
    canvas.rotate(p.tilt * math.pi / 180);
    canvas.translate(-50, -p.cy);

    _paintSpikes(canvas, p, small);
    _paintFeet(canvas, p, small);
    _paintBody(canvas, p);
    if (rim) _paintRim(canvas, p);
    _paintEyes(canvas, p, small);
    _paintMonocle(canvas, p, small);
    if (p.paw) _paintPaw(canvas, p);
    if (pose == MascotPose.dormido) _paintZs(canvas);

    canvas.restore();
  }

  /// Tres «z» que suben y se apagan, desfasadas un tercio de ciclo. Se dibujan
  /// como trazo, no como texto: son parte de la ilustración.
  void _paintZs(Canvas canvas) {
    const anchors = [Offset(78, 40), Offset(86, 28), Offset(92, 18)];
    const sizes = [6.0, 5.0, 4.0];
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (var i = 0; i < anchors.length; i++) {
      final t = (aux + i / 3) % 1.0;
      final alpha = t < 0.3 ? (t / 0.3) * 0.9 : 0.9 * (1 - (t - 0.3) / 0.7);
      final dy = 6 - 16 * t;
      final o = anchors[i].translate(0, dy);
      final w = sizes[i];
      canvas.drawPath(
        Path()
          ..moveTo(o.dx, o.dy)
          ..lineTo(o.dx + w, o.dy)
          ..lineTo(o.dx, o.dy + w)
          ..lineTo(o.dx + w, o.dy + w),
        paint..color = ColorTokens.mascotMonocle.withValues(alpha: alpha.clamp(0.0, 1.0)),
      );
    }
  }

  void _paintSpeedLines(Canvas canvas) {
    final paint = Paint()
      ..color = ColorTokens.mascotMonocle
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const lines = [
      [4.0, 40.0, 18.0, 40.0, 0.42],
      [0.0, 55.0, 12.0, 55.0, 0.26],
      [5.0, 70.0, 15.0, 70.0, 0.13],
    ];
    for (final l in lines) {
      canvas.drawLine(
        Offset(l[0], l[1]),
        Offset(l[2], l[3]),
        paint..color = ColorTokens.mascotMonocle.withValues(alpha: l[4]),
      );
    }
  }

  void _paintSpikes(Canvas canvas, _PoseSpec p, bool small) {
    final n = small ? MascotTokens.spikesSmall : MascotTokens.spikesNormal;
    final length = p.spikeLength * (small ? 1.5 : 1.15);
    final spikeRy = small ? 5.4 : 3.5;
    final paint = Paint()..color = ColorTokens.mascotSpikes;

    for (var i = 0; i < n; i++) {
      final a = (i * 360 / n) - 90;
      final r = a * math.pi / 180;
      final cx = 50 + (p.rx + length * 0.3) * math.cos(r);
      final cy = p.cy + (p.ry + length * 0.3) * math.sin(r);

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate((a + p.spikeTilt) * math.pi / 180);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: length, height: spikeRy * 2),
        paint,
      );
      canvas.restore();
    }
  }

  void _paintFeet(Canvas canvas, _PoseSpec p, bool small) {
    final paint = Paint()..color = ColorTokens.mascotPaw;
    final y = p.cy + p.ry + 2;
    final w = (small ? 8.0 : 7.0) * 2;
    final h = (small ? 6.0 : 5.0) * 2;
    canvas.drawOval(Rect.fromCenter(center: Offset(38, y), width: w, height: h), paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(62, y), width: w, height: h), paint);
  }

  void _paintBody(Canvas canvas, _PoseSpec p) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(50, p.cy), width: p.rx * 2, height: p.ry * 2),
      Paint()..color = ColorTokens.mascotBody,
    );
  }

  /// Luz de borde: un arco corto arriba a la izquierda, no un contorno completo.
  void _paintRim(Canvas canvas, _PoseSpec p) {
    final rect = Rect.fromCenter(
      center: Offset(50, p.cy),
      width: p.rx * 2,
      height: p.ry * 2,
    );
    // 24 % del perímetro, empezando en -158°, igual que el dasharray del SVG.
    const start = -158 * math.pi / 180;
    const sweep = 0.24 * 2 * math.pi;
    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..color = ColorTokens.mascotRimLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintEyes(Canvas canvas, _PoseSpec p, bool small) {
    final eyeY = p.cy - 4;
    final eyeR = small ? 8.0 : 7.0;
    final eyeRy = p.eye == _Eye.squint ? (small ? 3.2 : 2.6) : (small ? 8.6 : 7.8);

    if (p.eye == _Eye.arc) {
      final paint = Paint()
        ..color = ColorTokens.mascotEye
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      for (final x in [34.0, 53.0]) {
        canvas.drawPath(
          Path()
            ..moveTo(x, eyeY)
            ..quadraticBezierTo(x + 6, eyeY + 5.5, x + 12, eyeY),
          paint,
        );
      }
      return;
    }

    // El parpadeo aplasta los ojos en el eje Y, con origen en su propia línea.
    canvas.save();
    canvas.translate(0, eyeY);
    canvas.scale(1, (1 - blink * 0.92).clamp(0.08, 1.0));
    canvas.translate(0, -eyeY);

    final white = Paint()..color = ColorTokens.mascotEye;
    final pupil = Paint()..color = ColorTokens.mascotPupil;
    final pupilR = p.eye == _Eye.squint ? (small ? 2.6 : 2.2) : (small ? 3.6 : 3.1);

    // Examinando: la mirada barre de lado a lado, como quien lee una fila.
    final glance = pose == MascotPose.examinando
        ? MascotTokens.glanceOffset * (2 * aux - 1)
        : 0.0;

    for (final cx in [40.0, 59.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, eyeY), width: eyeR * 2, height: eyeRy * 2),
        white,
      );
      canvas.drawCircle(Offset(cx + p.gaze.dx + glance, eyeY + p.gaze.dy), pupilR, pupil);
    }
    canvas.restore();
  }

  void _paintMonocle(Canvas canvas, _PoseSpec p, bool small) {
    final mx = p.monocle[0];
    final my = p.monocle[1];
    final mr = p.monocle[2];
    final paint = Paint()
      ..color = ColorTokens.mascotMonocle
      ..style = PaintingStyle.stroke
      ..strokeWidth = small ? 4.0 : 2.6
      ..strokeCap = StrokeCap.round;

    canvas.save();
    // Confundido: el monóculo se bambolea sobre su propio centro. La cabeza
    // no se mueve: el desconcierto está en el objeto, no en el erizo.
    if (pose == MascotPose.confundido) {
      final deg = MascotTokens.wobbleDegrees * (2 * aux - 1);
      canvas.translate(mx, my);
      canvas.rotate(deg * math.pi / 180);
      canvas.translate(-mx, -my);
    }

    canvas.drawCircle(Offset(mx, my), mr, paint);

    // Examinando: un destello corto en el cristal, una vez por barrido.
    if (pose == MascotPose.examinando) {
      final glint = (1 - (aux - 0.85).abs() / 0.15).clamp(0.0, 1.0) * 0.7;
      if (glint > 0) {
        canvas.drawArc(
          Rect.fromCircle(center: Offset(mx, my), radius: mr * 0.72),
          -140 * math.pi / 180,
          50 * math.pi / 180,
          false,
          Paint()
            ..color = ColorTokens.mascotEye.withValues(alpha: glint)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // La cadena cuelga hacia atrás cuando rueda.
    final chain = Path();
    if (p.rolls) {
      chain.moveTo(mx - mr * 0.7, my + mr * 0.55);
      chain.relativeQuadraticBezierTo(-13, 6, -23, 0);
    } else {
      chain.moveTo(mx + mr * 0.62, my + mr * 0.72);
      chain.relativeQuadraticBezierTo(5.5, 9, -1.5, 16);
    }
    canvas.drawPath(chain, paint..strokeWidth = small ? 2.6 : 1.8);
    canvas.restore();
  }

  void _paintPaw(Canvas canvas, _PoseSpec p) {
    canvas.save();
    canvas.translate(70, p.cy - 1);
    canvas.rotate(-18 * math.pi / 180);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 13, height: 10),
      Paint()..color = ColorTokens.mascotPaw,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ErizogenesPainter old) =>
      old.pose != pose ||
      old.rim != rim ||
      old.idle != idle ||
      old.aux != aux ||
      old.blink != blink;
}
