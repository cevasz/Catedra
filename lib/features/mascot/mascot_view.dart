// ─────────────────────────────────────────────────────────────────────────────
// ERIZÓGENES · erizo de mar cínico, de monóculo
//
// Se consume SOLO vía `MascotView(pose:, size:, host:)`. Ningún otro feature
// importa la geometría ni los colores de este módulo directamente.
//
// EL DIBUJO (rediseño 2026-09-23, §37)
//   Cúpula de erizo de mar violeta con tubérculos, agujas con punta clara en
//   dos capas, pies tubulares y sombra en el suelo. La cara es el personaje:
//   un párpado escéptico, el ojo del monóculo agrandado por el cristal, cejas,
//   media sonrisa y una barba de tres púas. Cada pose es una combinación de
//   párpados, cejas, boca y púas; no hay un dibujo distinto por pose.
//   El lienzo de referencia es «Erizógenes rediseño» (dirección B).
//
// PANTALLAS DONDE PUEDE APARECER
//   A1  splash / bienvenida
//   A3  procesando el PDF          (pose: examinando)
//   A5  error de lectura del PDF   (pose: confundido)
//   B1  compañero en la cabecera de Hoy, con consejos (pose según el consejo)
//   B2  «sal ya», pequeño en la esquina de la card (pose: rodando)
//   B4  sin clases hoy             (pose: dormido)
//   D3  materia sin notas          (pose: reposo)
//   Widget 4×4, a 44 px en la esquina inferior
//   Hitos: fin de semestre, primera materia creada, materia salvada del riesgo
//
// PANTALLAS DONDE NO APARECE NUNCA
//   Materia perdida y calculadora imposible: ahí una cara burlona se lee como
//   burla. Solo tipografía.
//
// El parpadeo aleatorio (cada 4–7 s) lo maneja este módulo con su propio Timer.
// El feature que lo consume no sabe nada de eso.
//
// MICRO-MOVIMIENTOS (todos en loop, todos del contrato, con easeInOutSine
// salvo la rodada, que es lineal)
//   reposo / satisfecho    respira 1 → 1,02 desde las patas
//   rodando                gira 360° y se aplasta/estira al ritmo
//   dormido                respiración de sueño 1 → 0,985 y tres «z» que suben
//   examinando             la mirada barre ±1,2 px y el monóculo destella
//   confundido             el monóculo, caído, se bambolea ±4° de su cadena
//   entrada (todas)        una vez: escala 0,6 → 1 con easeOutBackBounce
//
// TACTO (solo si `interactive`, que es el default)
//   toque                  salta, abre los ojos, eriza las púas; la sombra se
//                          encoge y el monóculo brinca
//   N toques seguidos      se marea: pose confundido (mascot.dizzyTaps en
//                          mascot.pokeWindowMs, durante mascotDizzy)
//   mantener pulsado       entrecierra los ojos y se sonroja; no lo admitirá
//   arrastrar el dedo      la mirada sigue al dedo
//   Quien lo usa recibe `onTap` / `onLongPress` para decir algo útil.
//
// Bajo reduced-motion las poses se congelan en su primer fotograma. No se
// ocultan: la mascota sigue ahí, quieta.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/strings.g.dart';
import '../../theme/haptics.dart';
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
  companion('B1 compañero'),
  widget4x4('widget 4x4'),
  loader('carga'),
  corner('esquina global'),
  homeWidget('widgets');

  const MascotHost(this.contractName);

  /// Nombre tal como aparece en `mascot.allowedScreens` de tokens.json.
  final String contractName;
}

class MascotView extends StatefulWidget {
  const MascotView({
    required this.pose,
    required this.size,
    required this.host,
    this.interactive = true,
    this.onTap,
    this.onLongPress,
    this.semanticHint,
    super.key,
  });

  final MascotPose pose;
  final double size;

  /// Obliga a declarar desde dónde se llama. No hay valor por defecto a
  /// propósito: si no sabes en qué pantalla estás, no deberías poner la mascota.
  final MascotHost host;

  /// Reacciona al tacto. Apagado solo donde un toque se confundiría con otro
  /// control, como la esquina del «sal ya».
  final bool interactive;

  /// Se llama después de la reacción. El erizo reacciona siempre; qué dice es
  /// cosa de quien lo pone.
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Qué hace tocarlo, para el lector de pantalla. Por defecto, el consejo
  /// siguiente de Hoy; la esquina dice que suelta una sentencia.
  final String? semanticHint;

  @override
  State<MascotView> createState() => _MascotViewState();
}

class _MascotViewState extends State<MascotView> with TickerProviderStateMixin {
  late final AnimationController _idle; // respiración, sueño o rodada
  late final AnimationController _aux; // squash, z, mirada o bamboleo
  late final AnimationController _enter; // una vez, al aparecer
  late final AnimationController _blink;
  late final AnimationController _poke; // salto al tocarlo
  bool _entered = false;

  /// Hacia dónde mira mientras lo arrastras, en -1..1 por eje.
  Offset _look = Offset.zero;

  /// Mantenido pulsado: ojos entrecerrados y rubor.
  bool _petted = false;

  /// Toques recientes. A partir de [MascotTokens.dizzyTaps] se marea.
  final List<DateTime> _pokes = [];
  bool _dizzy = false;
  Timer? _dizzyTimer;
  Timer? _blinkTimer;

  /// Sube cada vez que cambia el movimiento. Un parpadeo en vuelo de una
  /// generación anterior no programa el siguiente: sin esto, cambiar de pose
  /// a mitad de un parpadeo dejaba dos cadenas de parpadeo sueltas y el erizo
  /// parpadeaba el doble.
  int _blinkGeneration = 0;
  final _random = math.Random();

  static const Curve _sine = MotionCurves.easeInOutSine;

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
    _poke = AnimationController(vsync: this, duration: MotionDurations.mascotHop);
  }

  /// La pose que se dibuja: la pedida, salvo que esté mareado.
  MascotPose get _pose => _dizzy ? MascotPose.confundido : widget.pose;

  @visibleForTesting
  MascotPose get debugDrawnPose => _pose;

  void _handleTap() {
    unawaited(Haptics.fire('tocarMascota'));
    final now = DateTime.now();
    _pokes
      ..add(now)
      ..removeWhere((t) => now.difference(t) > MascotTokens.pokeWindow);
    if (_pokes.length >= MascotTokens.dizzyTaps && !_dizzy) {
      _pokes.clear();
      setState(() => _dizzy = true);
      _syncMotion();
      _dizzyTimer?.cancel();
      _dizzyTimer = Timer(MotionDurations.mascotDizzy, () {
        if (!mounted) return;
        setState(() => _dizzy = false);
        _syncMotion();
      });
    }
    if (!MotionGuard.of(context).reduced) _poke.forward(from: 0);
    widget.onTap?.call();
  }

  void _handleLongPress() {
    unawaited(Haptics.fire('tocarMascota'));
    setState(() => _petted = true);
    widget.onLongPress?.call();
  }

  void _lookAt(Offset local) {
    final half = widget.size / 2;
    final dx = ((local.dx - half) / half).clamp(-1.0, 1.0);
    final dy = ((local.dy - half) / half).clamp(-1.0, 1.0);
    setState(() => _look = Offset(dx, dy));
  }

  void _release() => setState(() {
        _look = Offset.zero;
        _petted = false;
      });

  Duration get _idleDuration => switch (_pose) {
        MascotPose.rodando => MotionDurations.mascotRoll,
        MascotPose.dormido => MotionDurations.mascotSleep,
        _ => MotionDurations.mascotBreathe,
      };

  /// Null cuando la pose no tiene segundo movimiento.
  Duration? get _auxDuration => switch (_pose) {
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
    if (old.pose != widget.pose) _syncMotion();
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
    _blinkGeneration++;
    _blinkTimer?.cancel();

    if (!guard.allowsLoops) {
      // Congelado en el primer fotograma, no oculto.
      for (final c in [_idle, _aux, _blink]) {
        c.stop();
        c.value = 0;
      }
      return;
    }

    _idle.duration = _idleDuration;
    _aux.duration = _auxDuration ?? MotionDurations.base;
    switch (_pose) {
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

  bool get _eyesCanBlink => _pose != MascotPose.dormido;

  /// Cada 4–7 s. El intervalo se sortea de nuevo tras cada parpadeo para que no
  /// caiga en un ritmo perceptible.
  void _scheduleBlink() {
    final generation = _blinkGeneration;
    final min = MascotTokens.blinkMin.inMilliseconds;
    final max = MascotTokens.blinkMax.inMilliseconds;
    final wait = Duration(milliseconds: min + _random.nextInt(max - min));
    _blinkTimer = Timer(wait, () async {
      if (!mounted || generation != _blinkGeneration) return;
      await _blink.forward();
      await _blink.reverse();
      if (mounted && generation == _blinkGeneration) _scheduleBlink();
    });
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _dizzyTimer?.cancel();
    _poke.dispose();
    _idle.dispose();
    _aux.dispose();
    _enter.dispose();
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final dark = brightness == Brightness.dark;
    // La luz de borde solo existe en oscuro: sobre hueso el cuerpo se queda
    // igual y solo desaparece el rim.
    final rim = dark || MascotTokens.rimLightOnLightTheme;

    final guard = MotionGuard.of(context);
    final enterCurve = CurvedAnimation(
      parent: _enter,
      curve: guard.curve(MotionCurves.easeOutBackBounce),
    );

    final art = RepaintBoundary(
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: Listenable.merge([_idle, _aux, _blink, _enter, _poke]),
          builder: (context, _) {
            // Entrada: sobrepasa un poco y asienta. El origen es la base de la
            // silueta para que parezca que llega al suelo, no que se infla.
            final t = enterCurve.value;
            final scale = guard.reduced ? 1.0 : MascotTokens.enterScale + (1 - MascotTokens.enterScale) * t;
            final pose = _pose;
            // El contrato pide easeInOutSine para los vaivenes. Sin curva, un
            // `repeat(reverse: true)` es una onda triangular: el cuerpo frena
            // en seco arriba y abajo y la respiración se ve mecánica. La
            // rodada es lineal (gira a velocidad constante) y las z suben sin
            // volver.
            final idle = pose == MascotPose.rodando ? _idle.value : _sine.transform(_idle.value);
            final aux = pose == MascotPose.dormido ? _aux.value : _sine.transform(_aux.value);
            return Opacity(
              opacity: _enter.value.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.bottomCenter,
                child: CustomPaint(
                  painter: _ErizogenesPainter(
                    pose: pose,
                    dark: dark,
                    rim: rim,
                    idle: idle,
                    aux: aux,
                    blink: _petted ? 0 : _blink.value,
                    poke: _poke.isAnimating ? _poke.value : 0,
                    look: _look,
                    petted: _petted,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    if (!widget.interactive) return art;
    return Semantics(
      button: true,
      label: widget.semanticHint ?? SMascotVoice.hint,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        onLongPress: _handleLongPress,
        onLongPressEnd: (_) => _release(),
        onPanStart: (d) => _lookAt(d.localPosition),
        onPanUpdate: (d) => _lookAt(d.localPosition),
        onPanEnd: (_) => _release(),
        onPanCancel: _release,
        child: art,
      ),
    );
  }
}

/// Erizógenes quieto, en el fotograma de reposo de la pose: sin entrada,
/// sin parpadeo, sin temporizadores.
///
/// Existe para los widgets de la pantalla de inicio, que son vistas nativas:
/// ahí se captura una sola imagen y un `MascotView` capturado en su primer
/// fotograma saldría a mitad de la entrada, encogido y medio transparente.
/// No lleva `host` porque no se monta en ninguna pantalla: se rasteriza.
class MascotStill extends StatelessWidget {
  const MascotStill({required this.pose, required this.size, required this.brightness, super.key});

  final MascotPose pose;
  final double size;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _ErizogenesPainter(
            pose: pose,
            dark: brightness == Brightness.dark,
            rim: brightness == Brightness.dark || MascotTokens.rimLightOnLightTheme,
            idle: 0,
            aux: 0,
            blink: 0,
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// El dibujo
//
// Todas las coordenadas están en un lienzo de 100×100. La geometría es la
// ilustración (exenta del guardia de literales); lo que se mueve en una
// reacción sale de MascotTokens.
// ─────────────────────────────────────────────────────────────────────────────

enum _Mouth { smirk, flat, sleep, purse, grin, wavy }

/// Dónde está el monóculo: puesto, resbalado al dormir o caído colgando de
/// la cadena cuando algo no cuadra.
enum _Monocle { on, slid, fallen }

/// Una pose es una cara y una actitud de las púas sobre el mismo cuerpo.
class _PoseSpec {
  const _PoseSpec({
    required this.cy,
    required this.ryTop,
    required this.ryBottom,
    required this.tilt,
    required this.lidLeft,
    required this.lidRight,
    required this.browLeft,
    required this.browRight,
    required this.gaze,
    required this.mouth,
    this.sweep = 0,
    this.droop = 0,
    this.bristle = 0,
    this.irregular = 0,
    this.monocle = _Monocle.on,
    this.monocleRadius = 10.5,
    this.magnify = 1,
    this.breathes = false,
    this.rolls = false,
    this.stride = false,
    this.paw = false,
    this.smallPupils = false,
  });

  /// Centro vertical del cuerpo y sus dos semiejes: la cúpula es más alta que
  /// honda, como la testa de un erizo de mar.
  final double cy, ryTop, ryBottom;

  /// Inclinación del cuerpo, en grados.
  final double tilt;

  /// Párpado superior: 0 abierto, 1 cerrado.
  final double lidLeft, lidRight;

  /// Cejas: dx es cuánto baja (negativo, sube) y dy la inclinación en grados.
  final Offset browLeft, browRight;
  final Offset gaze;
  final _Mouth mouth;

  /// Grados que las agujas se barren hacia atrás (carrera).
  final double sweep;

  /// Grados que las agujas se tumban hacia los lados (sueño).
  final double droop;

  /// Cuánto más largas: 0 relajadas, positivo erizadas.
  final double bristle;

  /// 0 ordenadas, 1 cada una por su lado (desconcierto).
  final double irregular;

  final _Monocle monocle;
  final double monocleRadius;

  /// Cuánto agranda el cristal el ojo derecho.
  final double magnify;
  final bool breathes, rolls, stride, paw, smallPupils;
}

const Map<MascotPose, _PoseSpec> _poses = {
  // Escéptico: un ojo a media asta, el otro agrandado por el monóculo.
  MascotPose.reposo: _PoseSpec(
    cy: 60, ryTop: 26, ryBottom: 20, tilt: 0, lidLeft: 0.42, lidRight: 0.22,
    browLeft: Offset(0, 6), browRight: Offset(-3, -4), gaze: Offset(0.4, 0.3),
    mouth: _Mouth.smirk, breathes: true,
  ),
  MascotPose.rodando: _PoseSpec(
    cy: 60, ryTop: 26, ryBottom: 20, tilt: 9, lidLeft: 0.34, lidRight: 0.3,
    browLeft: Offset(1, 10), browRight: Offset(0, -8), gaze: Offset(1.6, 0),
    mouth: _Mouth.flat, sweep: -32, rolls: true, stride: true,
  ),
  MascotPose.dormido: _PoseSpec(
    cy: 65, ryTop: 21, ryBottom: 18, tilt: 0, lidLeft: 1, lidRight: 1,
    browLeft: Offset(2, 2), browRight: Offset(2, -2), gaze: Offset.zero,
    mouth: _Mouth.sleep, droop: 38, bristle: -0.2, monocle: _Monocle.slid,
    monocleRadius: 9.5, magnify: 0.9,
  ),
  MascotPose.examinando: _PoseSpec(
    cy: 61, ryTop: 26, ryBottom: 20, tilt: -7, lidLeft: 0.62, lidRight: 0.05,
    browLeft: Offset(2, 14), browRight: Offset(-6, -10), gaze: Offset(1.2, 1.8),
    mouth: _Mouth.purse, bristle: 0.08, monocleRadius: 12, magnify: 1.18, paw: true,
  ),
  // Satisfecho a lo cínico: párpados pesados y media sonrisa, no un «¡yay!».
  MascotPose.satisfecho: _PoseSpec(
    cy: 59, ryTop: 26, ryBottom: 20, tilt: -4, lidLeft: 0.5, lidRight: 0.44,
    browLeft: Offset(-3, -4), browRight: Offset(-4, -2), gaze: Offset(0, 2.4),
    mouth: _Mouth.grin, bristle: 0.14, breathes: true,
  ),
  MascotPose.confundido: _PoseSpec(
    cy: 60, ryTop: 26, ryBottom: 20, tilt: -11, lidLeft: 0, lidRight: 0.05,
    browLeft: Offset(-6, -12), browRight: Offset(0, 14), gaze: Offset(-1.2, 0.8),
    mouth: _Mouth.wavy, bristle: 0.12, irregular: 1, monocle: _Monocle.fallen,
    monocleRadius: 9.5, magnify: 0.88, smallPupils: true,
  ),
};

/// Semieje horizontal del cuerpo: igual en todas las poses.
const double _bodyRx = 28;

/// Ojos: centros en x. El derecho es el del monóculo.
const double _eyeLeftX = 38.5;
const double _eyeRightX = 61.5;

double _rad(double deg) => deg * math.pi / 180;

class _ErizogenesPainter extends CustomPainter {
  _ErizogenesPainter({
    required this.pose,
    required this.dark,
    required this.rim,
    required this.idle,
    required this.aux,
    required this.blink,
    this.poke = 0,
    this.look = Offset.zero,
    this.petted = false,
  });

  final MascotPose pose;

  /// Tema oscuro: la sombra se nota más sobre hueso que sobre casi negro, así
  /// que cada tema tiene su opacidad.
  final bool dark;
  final bool rim;

  /// 0..1, ya con su curva. Respiración, sueño o ángulo de rodada.
  final double idle;

  /// 0..1, ya con su curva. Squash, z, mirada o bamboleo.
  final double aux;

  /// 0..1. 1 = ojos cerrados.
  final double blink;

  /// 0..1 durante el salto de un toque; 0 en reposo.
  final double poke;

  /// Hacia dónde mira mientras lo arrastras, -1..1 por eje.
  final Offset look;

  /// Mantenido pulsado: ojos entrecerrados y rubor.
  final bool petted;

  /// Curva del salto: sube y baja una vez, 0 en los extremos.
  double get _hop => math.sin(poke * math.pi);

  // Pinturas de color fijo: se crean una vez, no en cada fotograma.
  static final Paint _body = Paint()..color = ColorTokens.mascotBody;
  static final Paint _spikes = Paint()..color = ColorTokens.mascotSpikes;
  static final Paint _tip = Paint()..color = ColorTokens.mascotSpikeTip;
  static final Paint _tubercle = Paint()..color = ColorTokens.mascotTubercle.withValues(alpha: 0.55);
  static final Paint _paw = Paint()..color = ColorTokens.mascotPaw;
  static final Paint _eyeWhite = Paint()..color = ColorTokens.mascotEye;
  static final Paint _pupil = Paint()..color = ColorTokens.mascotPupil;
  static final Paint _glass = Paint()..color = ColorTokens.mascotEye.withValues(alpha: 0.10);
  static final Paint _chainDot = Paint()..color = ColorTokens.mascotMonocle;
  static final Paint _blush = Paint()
    ..color = ColorTokens.mascotMonocle.withValues(alpha: MascotTokens.blushAlpha);
  static final Paint _line = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    final p = _poses[pose]!;
    final hop = poke > 0 ? _hop : 0.0;
    // A tamaño pequeño la silueta necesita agujas más gordas y trazos más
    // gruesos, y pierde los tubérculos: es la única variante permitida.
    final small = size.width <= MascotTokens.smallThreshold;

    canvas.save();
    canvas.scale(size.width / 100.0);

    _paintShadow(canvas, p, hop);

    // Toque: salta y, al despegar y al caer, se aplasta contra el suelo.
    if (hop > 0) {
      canvas.translate(0, -MascotTokens.hopHeight * hop);
      const phase = MascotTokens.hopSquashPhase;
      final squash = poke < phase
          ? (phase - poke) / phase
          : poke > 1 - phase
              ? (poke - (1 - phase)) / phase
              : 0.0;
      final originY = p.cy + p.ryBottom;
      canvas.translate(50, originY);
      canvas.scale(1 + MascotTokens.hopSquashX * squash, 1 - MascotTokens.hopSquashY * squash);
      canvas.translate(-50, -originY);
    }

    if (p.rolls) _paintSpeedLines(canvas, p);

    // Rodada: gira el conjunto alrededor del centro del cuerpo y, encima, se
    // aplasta y estira al ritmo: dos contactos con el suelo por vuelta.
    if (p.rolls) {
      canvas.translate(50, p.cy);
      canvas.rotate(idle * 2 * math.pi);
      final squash = MascotTokens.squashScale * (1 - 2 * aux);
      canvas.scale(1 + squash, 1 - squash);
      canvas.translate(-50, -p.cy);
    } else if (pose == MascotPose.dormido) {
      // Respiración de sueño: más lenta y hacia abajo. Un cuerpo dormido no se
      // hincha, se hunde un poco.
      _scaleFromFeet(canvas, p, 1 - (1 - MascotTokens.sleepScale) * idle);
    } else if (p.breathes) {
      _scaleFromFeet(canvas, p, 1 + (MascotTokens.breatheScaleMax - 1) * idle);
    }

    canvas.translate(50, p.cy);
    canvas.rotate(_rad(p.tilt));
    canvas.translate(-50, -p.cy);

    // Un toque lo eriza y le abre los ojos de golpe.
    final bristle = p.bristle + MascotTokens.hopBristle * hop;
    _paintSpikes(canvas, p, small, bristle);
    _paintFeet(canvas, p, small);
    _paintBody(canvas, p, small);
    _paintFace(canvas, p, small, hop);
    if (p.paw) _paintPaw(canvas, p);
    _paintMonocle(canvas, p, small, hop);
    if (pose == MascotPose.dormido) _paintZs(canvas);

    canvas.restore();
  }

  void _scaleFromFeet(Canvas canvas, _PoseSpec p, double s) {
    final originY = p.cy + p.ryBottom;
    canvas.translate(50, originY);
    canvas.scale(1, s);
    canvas.translate(-50, -originY);
  }

  /// La sombra se queda en el suelo: al saltar se encoge y se aclara.
  void _paintShadow(Canvas canvas, _PoseSpec p, double hop) {
    final k = 1 - MascotTokens.shadowHopShrink * hop;
    final alpha = (dark ? MascotTokens.shadowAlphaDark : MascotTokens.shadowAlphaLight) * k;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(50, p.cy + p.ryBottom + 7), width: 48 * k, height: 6.4 * k),
      Paint()..color = ColorTokens.mascotShadow.withValues(alpha: alpha),
    );
  }

  /// Punto de la superficie de la cúpula en el ángulo [a], escalado por [k].
  Offset _surface(_PoseSpec p, double a, double k) {
    final s = math.sin(a);
    return Offset(50 + _bodyRx * k * math.cos(a), p.cy + (s < 0 ? p.ryTop : p.ryBottom) * k * s);
  }

  static void _needle(Path path, Offset base, double angle, double length, double halfWidth) {
    final dx = math.cos(angle), dy = math.sin(angle);
    path
      ..moveTo(base.dx - dy * halfWidth, base.dy + dx * halfWidth)
      ..lineTo(base.dx + dx * length, base.dy + dy * length)
      ..lineTo(base.dx + dy * halfWidth, base.dy - dx * halfWidth)
      ..close();
  }

  /// Agujas de erizo de mar en dos capas, con la punta clara. Nacen dentro
  /// del cuerpo (que las tapa) y cubren todo menos el vientre. El largo varía
  /// con una suma de senos fija: irregular a la vista, idéntico en cada
  /// fotograma.
  void _paintSpikes(Canvas canvas, _PoseSpec p, bool small, double bristle) {
    final shafts = Path();
    final tips = Path();
    final reach = 17 * (1 + bristle * 1.6);
    final layers = small
        ? [(MascotTokens.spikesSmall, 1.0, 3.1, 0.0)]
        : [
            (MascotTokens.spikesNormal, 1.0, 2.3, 0.0),
            (MascotTokens.spikesFront, 0.62, 2.0, 0.5),
          ];
    for (final (n, share, width, offset) in layers) {
      for (var i = 0; i < n; i++) {
        final a = _rad(158 + (i + offset) / (n - 1) * 224);
        final variation = 1 + 0.17 * math.sin(i * 2.39 + offset * 7) + 0.09 * math.sin(i * 5.1 + 1.3);
        final length = reach * share * variation * (p.droop > 0 ? 0.82 : 1);
        final c = math.cos(a);
        var turn = p.sweep;
        if (p.droop > 0) turn += p.droop * c.sign * math.min(1, c.abs() * 3);
        if (p.irregular > 0) turn += 16 * math.sin(i * 3.7) * p.irregular;
        final angle = a + _rad(turn);
        final base = _surface(p, a, 0.86);
        const root = _bodyRx * 0.14;
        _needle(shafts, base, angle, length + root, width);
        final tipStart = length * 0.62 + root;
        _needle(
          tips,
          base.translate(math.cos(angle) * tipStart, math.sin(angle) * tipStart),
          angle,
          length * 0.38,
          width * 0.38,
        );
      }
    }
    canvas.drawPath(shafts, _spikes);
    canvas.drawPath(tips, _tip);
  }

  /// Pies tubulares. Rodando, uno adelante y levantado.
  void _paintFeet(Canvas canvas, _PoseSpec p, bool small) {
    final y = p.cy + p.ryBottom + 1.5;
    final w = small ? 14.0 : 12.0;
    final h = small ? 9.2 : 7.6;
    final stride = p.stride ? 0.8 : 0.0;
    canvas.drawOval(Rect.fromCenter(center: Offset(41 - 3 * stride, y - stride * 2.5), width: w, height: h), _paw);
    canvas.drawOval(Rect.fromCenter(center: Offset(59 + 3 * stride, y), width: w, height: h), _paw);
  }

  /// La cúpula: media elipse alta arriba y otra más baja abajo. Encima, las
  /// hileras de tubérculos de un erizo de mar y la luz de borde en oscuro.
  void _paintBody(Canvas canvas, _PoseSpec p, bool small) {
    final top = Rect.fromCenter(center: Offset(50, p.cy), width: _bodyRx * 2, height: p.ryTop * 2);
    final bottom = Rect.fromCenter(center: Offset(50, p.cy), width: _bodyRx * 2, height: p.ryBottom * 2);
    canvas.drawPath(
      Path()
        ..addArc(top, math.pi, math.pi)
        ..arcTo(bottom, 0, math.pi, false)
        ..close(),
      _body,
    );

    if (!small) {
      for (final phi in const [-0.95, -0.42, 0.1, 0.62]) {
        for (final th in const [0.3, 0.52, 0.74, 0.96]) {
          final y = p.cy - p.ryTop * math.cos(th);
          // Solo en lo alto: la cara no lleva tubérculos.
          if (y > p.cy - 11) continue;
          final r = 0.75 + 0.35 * math.sin(th);
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(50 + _bodyRx * math.sin(th) * math.sin(phi), y),
              width: 2 * r * (0.6 + 0.4 * math.cos(phi)),
              height: 2 * r,
            ),
            _tubercle,
          );
        }
      }
    }

    if (rim) {
      canvas.drawArc(
        top,
        _rad(-160),
        _rad(50),
        false,
        _line
          ..color = ColorTokens.mascotRimLight
          ..strokeWidth = 2.4,
      );
    }
  }

  void _paintFace(Canvas canvas, _PoseSpec p, bool small, double hop) {
    final ey = p.cy - 2;
    final er = small ? 8.2 : 7.4;
    final pupilR = (small ? 3.4 : 2.8) * (p.smallPupils ? 0.72 : 1);
    final monocleOn = p.monocle == _Monocle.on;
    final mag = monocleOn ? p.magnify : 1.0;
    final glass = monocleOn ? 1.08 : 1.0;

    // Examinando: la mirada barre de lado a lado, como quien lee una fila.
    final glance = pose == MascotPose.examinando ? MascotTokens.glanceOffset * (2 * aux - 1) : 0.0;
    final gaze = p.gaze + Offset(glance, 0) + look * MascotTokens.lookPupil;

    double lid(double base) {
      var l = petted ? math.max(base, MascotTokens.pettedLid) : base;
      l *= 1 - hop; // el salto le abre los ojos
      return l + (1 - l) * blink;
    }

    _paintEye(canvas, Offset(_eyeLeftX, ey), er * 0.95, er * 1.02, lid(p.lidLeft), gaze, pupilR, small);
    _paintEye(
      canvas,
      Offset(_eyeRightX, ey - 0.5),
      er * mag * glass,
      er * 1.05 * mag * glass,
      lid(p.lidRight),
      gaze * mag,
      pupilR * mag * (monocleOn ? 1.15 : 1),
      small,
    );

    final browWidth = small ? 3.6 : 3.0;
    _paintBrow(canvas, Offset(_eyeLeftX, ey - er - 2.2), p.browLeft, browWidth);
    _paintBrow(canvas, Offset(_eyeRightX, ey - er * mag - 3.6), p.browRight, browWidth);

    if (petted) {
      for (final cx in const [31.0, 69.0]) {
        canvas.drawOval(Rect.fromCenter(center: Offset(cx, p.cy + 8), width: 9, height: 4.5), _blush);
      }
    }

    _paintMouth(canvas, p, small);
    _paintBeard(canvas, p, small);
  }

  /// Un ojo con su párpado: el blanco, la pupila con su brillo, y encima un
  /// párpado del color del cuerpo recortado a la forma del ojo. Cerrado del
  /// todo es una curva cansada hacia abajo.
  void _paintEye(Canvas canvas, Offset c, double rx, double ry, double lid, Offset gaze, double pupilR, bool small) {
    if (lid >= 0.99) {
      canvas.drawPath(
        Path()
          ..moveTo(c.dx - rx, c.dy)
          ..quadraticBezierTo(c.dx, c.dy + ry * 0.7, c.dx + rx, c.dy),
        _line
          ..color = ColorTokens.mascotBrow
          ..strokeWidth = small ? 2.6 : 2.0,
      );
      return;
    }
    final oval = Rect.fromCenter(center: c, width: rx * 2, height: ry * 2);
    canvas.drawOval(oval, _eyeWhite);
    canvas.save();
    canvas.clipPath(Path()..addOval(oval));
    final pupil = c + gaze;
    canvas.drawCircle(pupil, pupilR, _pupil);
    canvas.drawCircle(pupil.translate(-pupilR * 0.35, -pupilR * 0.4), pupilR * 0.28, _eyeWhite);
    final top = c.dy - ry;
    final ly = top + lid * 2 * ry;
    if (lid > 0) {
      canvas.drawPath(
        Path()
          ..moveTo(c.dx - rx - 1, top - 1)
          ..lineTo(c.dx + rx + 1, top - 1)
          ..lineTo(c.dx + rx + 1, ly)
          ..quadraticBezierTo(c.dx, ly + ry * 0.18, c.dx - rx - 1, ly)
          ..close(),
        _body,
      );
    }
    canvas.restore();
    if (lid > 0) {
      canvas.drawPath(
        Path()
          ..moveTo(c.dx - rx * 0.98, ly)
          ..quadraticBezierTo(c.dx, ly + ry * 0.18, c.dx + rx * 0.98, ly),
        _line
          ..color = ColorTokens.mascotBrow
          ..strokeWidth = 1.5,
      );
    }
  }

  /// [shape]: dx cuánto baja la ceja, dy su inclinación en grados.
  void _paintBrow(Canvas canvas, Offset c, Offset shape, double width) {
    const half = 6.2;
    final a = _rad(shape.dy);
    final y = c.dy + shape.dx;
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - half * math.cos(a), y - half * math.sin(a))
        ..quadraticBezierTo(c.dx, y - 1.4, c.dx + half * math.cos(a), y + half * math.sin(a)),
      _line
        ..color = ColorTokens.mascotBrow
        ..strokeWidth = width,
    );
  }

  void _paintMouth(Canvas canvas, _PoseSpec p, bool small) {
    final y = p.cy + 11;
    final path = switch (p.mouth) {
      _Mouth.smirk => Path()
        ..moveTo(44, y)
        ..quadraticBezierTo(49, y + 2, 56, y - 2.2),
      _Mouth.flat => Path()
        ..moveTo(45, y)
        ..lineTo(55, y + 0.6),
      _Mouth.sleep => Path()
        ..moveTo(48, y)
        ..quadraticBezierTo(50, y + 1.2, 52, y),
      _Mouth.purse => Path()
        ..moveTo(48.5, y)
        ..quadraticBezierTo(50, y - 1, 51.5, y),
      _Mouth.grin => Path()
        ..moveTo(44, y - 1)
        ..quadraticBezierTo(50, y + 3.2, 56, y - 2.4),
      _Mouth.wavy => Path()
        ..moveTo(44.5, y)
        ..quadraticBezierTo(46.8, y - 1.8, 49, y)
        ..quadraticBezierTo(51.2, y + 1.8, 53.5, y),
    };
    canvas.drawPath(
      path,
      _line
        ..color = ColorTokens.mascotBrow
        ..strokeWidth = small ? 2.4 : 2.0,
    );
  }

  /// La barba del filósofo: tres púas que cuelgan de la barbilla. Dormido se
  /// le tuercen hacia los lados.
  void _paintBeard(Canvas canvas, _PoseSpec p, bool small) {
    final y = p.cy + 15 - 1.5;
    final droop = p.droop > 0 ? 0.5 : 0.0;
    final shafts = Path();
    final tips = Path();
    for (final (x, length, deg) in const [(46.6, 8.0, 20.0), (50.0, 11.0, 0.0), (53.4, 8.0, -20.0)]) {
      final angle = _rad(90 + deg * (1 - droop));
      final l = length * (1 - droop * 0.25);
      _needle(shafts, Offset(x, y), angle, l, small ? 2.4 : 1.6);
      _needle(
        tips,
        Offset(x + math.cos(angle) * l * 0.6, y + math.sin(angle) * l * 0.6),
        angle,
        l * 0.4,
        small ? 0.9 : 0.8,
      );
    }
    canvas.drawPath(shafts, _spikes);
    canvas.drawPath(tips, _tip);
  }

  void _paintPaw(Canvas canvas, _PoseSpec p) {
    canvas.save();
    canvas.translate(72, p.cy + 6);
    canvas.rotate(_rad(-24));
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 13, height: 10), _paw);
    canvas.restore();
  }

  void _paintMonocle(Canvas canvas, _PoseSpec p, bool small, double hop) {
    final eye = Offset(_eyeRightX, p.cy - 2.5);
    var r = p.monocleRadius;
    final (Offset center, double rotation) = switch (p.monocle) {
      _Monocle.on => (eye.translate(0, -MascotTokens.hopMonocleLift * hop), 0.0),
      _Monocle.slid => (eye.translate(0, 5), 12.0),
      // Caído: cuelga de la cadena y, bajo el bamboleo, se mece.
      _Monocle.fallen => (const Offset(70, 83), 28 + MascotTokens.wobbleDegrees * (2 * aux - 1)),
    };
    if (p.monocle == _Monocle.fallen) r = 7.5;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_rad(rotation));
    canvas.drawCircle(Offset.zero, r, _glass);
    canvas.drawCircle(
      Offset.zero,
      r,
      _line
        ..color = ColorTokens.mascotMonocle
        ..strokeWidth = small ? MascotTokens.monocleStrokeSmall : MascotTokens.monocleStrokeNormal,
    );
    final glint = Rect.fromCircle(center: Offset.zero, radius: r * 0.7);
    canvas.drawArc(
      glint,
      _rad(-150),
      _rad(45),
      false,
      _line
        ..color = ColorTokens.mascotEye.withValues(alpha: 0.55)
        ..strokeWidth = small ? 1.6 : 1.2,
    );
    // Examinando: un destello más fuerte, una vez por barrido.
    if (pose == MascotPose.examinando) {
      final flash = (1 - (aux - 0.85).abs() / 0.15).clamp(0.0, 1.0) * 0.7;
      if (flash > 0) {
        canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: r * 0.72),
          _rad(-140),
          _rad(50),
          false,
          _line
            ..color = ColorTokens.mascotEye.withValues(alpha: flash)
            ..strokeWidth = 1.6,
        );
      }
    }
    canvas.restore();

    // La cadena: una fila de eslabones. Rodando cuelga hacia atrás; caído,
    // sube hasta donde estaba el ojo.
    final (Offset from, Offset control, Offset to) = switch (p.monocle) {
      _Monocle.fallen => (center.translate(-4, -6), const Offset(66, 62), const Offset(72, 56)),
      _ when p.rolls => (
          center.translate(-r * 0.7, r * 0.6),
          center.translate(-r * 0.7 - 12, r * 0.6 + 7),
          center.translate(-r * 0.7 - 24, r * 0.6 + 1),
        ),
      _ => (
          center.translate(r * 0.64, r * 0.72),
          center.translate(r * 0.64 + 5, r * 0.72 + 9),
          center.translate(r * 0.64 - 1.5, r * 0.72 + 17),
        ),
    };
    if (small) {
      canvas.drawPath(
        Path()
          ..moveTo(from.dx, from.dy)
          ..quadraticBezierTo(control.dx, control.dy, to.dx, to.dy),
        _line
          ..color = ColorTokens.mascotMonocle
          ..strokeWidth = 2.2,
      );
      return;
    }
    const links = 9;
    for (var i = 0; i <= links; i++) {
      final t = i / links;
      final u = 1 - t;
      canvas.drawCircle(from * (u * u) + control * (2 * u * t) + to * (t * t), 0.75, _chainDot);
    }
  }

  /// Tres «z» que suben y se apagan, desfasadas un tercio de ciclo. Se dibujan
  /// como trazo, no como texto: son parte de la ilustración.
  void _paintZs(Canvas canvas) {
    const anchors = [Offset(80, 40), Offset(88, 29), Offset(93, 20)];
    const sizes = [6.0, 5.0, 4.0];
    for (var i = 0; i < anchors.length; i++) {
      final t = (aux + i / 3) % 1.0;
      final alpha = t < 0.3 ? (t / 0.3) * 0.9 : 0.9 * (1 - (t - 0.3) / 0.7);
      final o = anchors[i].translate(0, 6 - 16 * t);
      final w = sizes[i];
      canvas.drawPath(
        Path()
          ..moveTo(o.dx, o.dy)
          ..lineTo(o.dx + w, o.dy)
          ..lineTo(o.dx, o.dy + w)
          ..lineTo(o.dx + w, o.dy + w),
        _line
          ..color = ColorTokens.mascotMonocle.withValues(alpha: alpha.clamp(0.0, 1.0))
          ..strokeWidth = 1.8,
      );
    }
  }

  void _paintSpeedLines(Canvas canvas, _PoseSpec p) {
    for (final (x1, dy, x2, alpha) in const [(3.0, -16.0, 16.0, 0.42), (0.0, -3.0, 11.0, 0.26), (4.0, 10.0, 13.0, 0.13)]) {
      canvas.drawLine(
        Offset(x1, p.cy + dy),
        Offset(x2, p.cy + dy),
        _line
          ..color = ColorTokens.mascotMonocle.withValues(alpha: alpha)
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(_ErizogenesPainter old) =>
      old.pose != pose ||
      old.dark != dark ||
      old.rim != rim ||
      old.idle != idle ||
      old.aux != aux ||
      old.blink != blink ||
      old.poke != poke ||
      old.look != look ||
      old.petted != petted;
}
