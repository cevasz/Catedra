// ─────────────────────────────────────────────────────────────────────────────
// ERIZÓGENES · erizo de mar cínico, con la lámpara de Diógenes
//
// Se consume SOLO vía `MascotView(pose:, size:, host:)`. Ningún otro feature
// importa la geometría ni los colores de este módulo directamente.
//
// EL DIBUJO (rediseño 2026-09-23, §37 y §39)
//   Erizo de mar griego: cúpula terracota con tubérculos, agujas oscuras con
//   la punta clara (más claras en tema oscuro, para no perder la silueta),
//   pies tubulares y sombra. Lleva la lucerna con la que Diógenes buscaba «un
//   hombre»: la llama dice cómo está (viva, alta al examinar, humo al dormir,
//   casi apagada si algo no cuadra). La cara es el personaje: un párpado
//   escéptico, cejas, media sonrisa y barba de tres púas. Cada pose es una
//   combinación de cara, púas y lámpara; no hay un dibujo distinto por pose.
//   `MascotVase` lo pinta además en un ánfora de figuras negras, de fondo.
//   Lienzo de referencia: «Erizógenes rediseño», lámina «Elegida».
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
// salvo la fase de la carrera, que es lineal)
//   reposo / satisfecho    respira 1 → 1,02 desde las patas
//   rodando                corre: bob, zancada alterna, agujas barridas que
//                          aletean y sombra que respira. Con `weary` (carga
//                          larga) se cansa y cada tanto mira hacia atrás
//   dormido                respiración de sueño 1 → 0,985 y tres «z» que suben
//   examinando             la mirada barre ±1,2 px, con la lámpara en alto
//   confundido             la lámpara, caída, se mece ±4° en el suelo
//   la llama               se mece con la respiración
//   entrada (todas)        una vez: escala 0,6 → 1 con easeOutBackBounce
//
// TACTO (solo si `interactive`, que es el default)
//   toque                  salta, abre los ojos, eriza las púas; la sombra se
//                          encoge y la lámpara sube con él
//   N toques seguidos      se marea: pose confundido (mascot.dizzyTaps en
//                          mascot.pokeWindowMs, durante mascotDizzy)
//   mantener pulsado       entrecierra los ojos y se sonroja; no lo admitirá
//   arrastrar el dedo      la mirada sigue al dedo
//   Quien lo usa recibe `onTap` / `onLongPress` para decir algo útil.
//
// CAMBIOS Y GESTOS (§40)
//   cambio de pose         cuerpo, cara, púas y lámpara se interpolan
//                          (mascotMorph); lo discreto cambia a mitad
//   `beat` + `beatKey`     un gesto de una vez: notice, celebrate, hop, sigh,
//                          stumble. Quien lo pone dice qué pasó; el erizo
//                          decide cómo se mueve
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
  vase('jarrón de fondo'),
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

/// Gestos de una sola vez con los que reacciona a lo que pasa. Son pocos y
/// secos: la personalidad está en cuánto se contiene.
enum MascotBeat {
  /// Salta una vez, como al tocarlo.
  hop,

  /// Se da cuenta: abre los ojos, sube las cejas, se eriza un poco.
  notice,

  /// Se da cuenta y da un saltito. Para lo que de verdad merece algo.
  celebrate,

  /// Suspira: párpados abajo, púas caídas, se hunde un poco.
  sigh,

  /// Tropieza de lado y se le desordenan las púas. Para los errores.
  stumble;

  Duration get duration => switch (this) {
        hop => MotionDurations.mascotHop,
        notice => MotionDurations.mascotNotice,
        celebrate => MotionDurations.mascotCelebrate,
        sigh => MotionDurations.mascotSigh,
        stumble => MotionDurations.mascotStumble,
      };
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
    this.weary = false,
    this.beat,
    this.beatKey,
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

  /// Solo cuenta rodando: una carga larga lo cansa. La mueve `MascotLoader`
  /// pasado `mascotLoaderLong`, no la pantalla.
  final bool weary;

  /// Un gesto de una sola vez. Suena al montarse si viene puesto y cada vez
  /// que cambia [beatKey]: quien lo pone solo dice qué pasó, no anima nada.
  final MascotBeat? beat;

  /// Cambiarla vuelve a reproducir [beat], aunque sea el mismo gesto.
  final Object? beatKey;

  @override
  State<MascotView> createState() => _MascotViewState();
}

class _MascotViewState extends State<MascotView> with TickerProviderStateMixin {
  late final AnimationController _idle; // respiración, sueño o rodada
  late final AnimationController _aux; // squash, z, mirada o bamboleo
  late final AnimationController _enter; // una vez, al aparecer
  late final AnimationController _blink;
  late final AnimationController _poke; // salto al tocarlo
  late final AnimationController _morph; // de una pose a la siguiente
  late final AnimationController _beat; // un gesto de una sola vez
  bool _entered = false;

  /// La pose que ya se ve y de la que parte la interpolación.
  MascotPose? _shownPose;
  MascotPose? _morphFrom;
  MascotBeat? _activeBeat;

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
    _morph = AnimationController(vsync: this, duration: MotionDurations.mascotMorph, value: 1);
    _beat = AnimationController(vsync: this, duration: MotionDurations.mascotHop);
  }

  /// La pose que se dibuja: la pedida, salvo que esté mareado.
  MascotPose get _pose => _dizzy ? MascotPose.confundido : widget.pose;

  @visibleForTesting
  MascotPose get debugDrawnPose => _pose;

  @visibleForTesting
  MascotBeat? get debugBeat => _beat.isAnimating ? _activeBeat : null;

  @visibleForTesting
  bool get debugMorphing => _morph.isAnimating;

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
        MascotPose.rodando => MotionDurations.mascotRun,
        MascotPose.dormido => MotionDurations.mascotSleep,
        _ => MotionDurations.mascotBreathe,
      };

  /// Null cuando la pose no tiene segundo movimiento.
  Duration? get _auxDuration => switch (_pose) {
        // Corriendo, el segundo reloj es el de mirar atrás cuando se cansa.
        MascotPose.rodando => MotionDurations.mascotLookBack,
        MascotPose.dormido => MotionDurations.mascotSleep,
        MascotPose.examinando => MotionDurations.mascotGlance,
        MascotPose.confundido => MotionDurations.mascotBreathe,
        _ => null,
      };

  @override
  void didUpdateWidget(MascotView old) {
    super.didUpdateWidget(old);
    if (old.pose != widget.pose) _syncMotion();
    if (widget.beat != null && widget.beatKey != old.beatKey) _playBeat(widget.beat!);
  }

  /// Bajo reduced-motion no hay gesto: la pose y la frase ya lo dicen.
  void _playBeat(MascotBeat beat) {
    if (MotionGuard.of(context).reduced) return;
    _activeBeat = beat;
    _beat
      ..duration = beat.duration
      ..forward(from: 0);
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
      if (widget.beat != null) _playBeat(widget.beat!);
    }
  }

  void _syncMotion() {
    final guard = MotionGuard.of(context);

    // Cambio de pose: se interpola desde la que se veía. Bajo reduced-motion
    // cambia de golpe.
    final target = _pose;
    if (_shownPose != null && _shownPose != target && !guard.reduced) {
      _morphFrom = _shownPose;
      _morph.forward(from: 0);
    } else if (guard.reduced) {
      _morph.value = 1;
    }
    _shownPose = target;

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
        // La fase de la carrera y la de mirar atrás avanzan sin volver.
        _idle.repeat();
        _aux.repeat();
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
    _morph.dispose();
    _beat.dispose();
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
          animation: Listenable.merge([_idle, _aux, _blink, _enter, _poke, _morph, _beat]),
          builder: (context, _) {
            // Entrada: sobrepasa un poco y asienta. El origen es la base de la
            // silueta para que parezca que llega al suelo, no que se infla.
            final t = enterCurve.value;
            final scale = guard.reduced ? 1.0 : MascotTokens.enterScale + (1 - MascotTokens.enterScale) * t;
            final pose = _pose;
            // El contrato pide easeInOutSine para los vaivenes. Sin curva, un
            // `repeat(reverse: true)` es una onda triangular: el cuerpo frena
            // en seco arriba y abajo y la respiración se ve mecánica. La fase
            // de la carrera es lineal (los senos van dentro del pintor) y las
            // z y la mirada atrás avanzan sin volver.
            final linear = pose == MascotPose.rodando || pose == MascotPose.dormido;
            final idle = pose == MascotPose.rodando ? _idle.value : _sine.transform(_idle.value);
            final aux = linear ? _aux.value : _sine.transform(_aux.value);
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
                    weary: widget.weary,
                    from: _morph.isAnimating ? _morphFrom : null,
                    morph: MotionCurves.easeOutCubic.transform(_morph.value),
                    beat: _beat.isAnimating ? _activeBeat : null,
                    beatT: _beat.value,
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

/// Erizógenes pintado en un ánfora de figuras negras, como las musas de
/// Hércules: una pintura de vasija que respira y cuya lámpara se mece.
///
/// Es fondo, no protagonista: va tenue (`vaseOpacity*`), no se toca y el
/// lector de pantalla la ignora. Aparece solo donde el contrato lo deja
/// (`jarrón de fondo`), detrás de un estado vacío o de la bienvenida.
class MascotVase extends StatefulWidget {
  const MascotVase({this.pose = MascotPose.reposo, this.width = MascotTokens.sizeVase, super.key});

  final MascotPose pose;

  /// El alto sale de la proporción del ánfora (3:4).
  final double width;

  @override
  State<MascotVase> createState() => _MascotVaseState();
}

class _MascotVaseState extends State<MascotVase> with SingleTickerProviderStateMixin {
  late final AnimationController _breathe =
      AnimationController(vsync: this, duration: MotionDurations.mascotBreathe);

  @override
  void initState() {
    super.initState();
    assert(MascotTokens.allowedScreens.contains(MascotHost.vase.contractName));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Un loop de fondo: bajo reduced-motion no existe.
    if (MotionGuard.of(context).allowsLoops) {
      _breathe.repeat(reverse: true);
    } else {
      _breathe
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ExcludeSemantics(
      child: IgnorePointer(
        child: Opacity(
          opacity: dark ? MascotTokens.vaseOpacityDark : MascotTokens.vaseOpacityLight,
          child: RepaintBoundary(
            child: SizedBox(
              width: widget.width,
              height: widget.width * _VasePainter.height / _VasePainter.width,
              child: AnimatedBuilder(
                animation: _breathe,
                builder: (context, _) => CustomPaint(
                  painter: _VasePainter(
                    pose: widget.pose,
                    idle: MotionCurves.easeInOutSine.transform(_breathe.value),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// El dibujo
//
// Todas las coordenadas están en un lienzo de 100×100. La geometría es la
// ilustración (exenta del guardia de literales); lo que se mueve en una
// reacción sale de MascotTokens.
// ─────────────────────────────────────────────────────────────────────────────

enum _Mouth { smirk, flat, sleep, purse, grin, wavy }

/// Dónde lleva la lucerna y cómo está la llama.
class _Lamp {
  const _Lamp(this.at, {this.rotation = 0, this.flame = 1, this.lean = 0, this.held = true});

  /// Centro de la lámpara, relativo a (0, cy) del cuerpo.
  final Offset at;
  final double rotation;

  /// 0 apagada (sale humo), 1 normal, más de 1 alta.
  final double flame;

  /// Hacia dónde se tuerce la punta de la llama.
  final double lean;

  /// Dormido o confundido la lámpara está en el suelo: nadie la sostiene.
  final bool held;

  static _Lamp lerp(_Lamp a, _Lamp b, double t) => _Lamp(
        Offset.lerp(a.at, b.at, t)!,
        rotation: a.rotation + (b.rotation - a.rotation) * t,
        flame: a.flame + (b.flame - a.flame) * t,
        lean: a.lean + (b.lean - a.lean) * t,
        held: t >= 0.5 ? b.held : a.held,
      );
}

/// Una pose es una cara, una actitud de las púas y una lámpara sobre el mismo
/// cuerpo.
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
    required this.lamp,
    this.sweep = 0,
    this.droop = 0,
    this.bristle = 0,
    this.irregular = 0,
    this.breathes = false,
    this.runs = false,
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
  final _Lamp lamp;

  /// Grados que las agujas se barren hacia atrás (carrera).
  final double sweep;

  /// Grados que las agujas se tumban hacia los lados (sueño).
  final double droop;

  /// Cuánto más largas: 0 relajadas, positivo erizadas.
  final double bristle;

  /// 0 ordenadas, 1 cada una por su lado (desconcierto).
  final double irregular;
  final bool breathes, runs, paw, smallPupils;

  /// De una pose a otra. Lo continuo se interpola; lo discreto (boca, si
  /// corre, si respira) cambia a mitad de camino.
  static _PoseSpec lerp(_PoseSpec a, _PoseSpec b, double t) {
    double l(double x, double y) => x + (y - x) * t;
    final late = t >= 0.5;
    return _PoseSpec(
      cy: l(a.cy, b.cy),
      ryTop: l(a.ryTop, b.ryTop),
      ryBottom: l(a.ryBottom, b.ryBottom),
      tilt: l(a.tilt, b.tilt),
      lidLeft: l(a.lidLeft, b.lidLeft),
      lidRight: l(a.lidRight, b.lidRight),
      browLeft: Offset.lerp(a.browLeft, b.browLeft, t)!,
      browRight: Offset.lerp(a.browRight, b.browRight, t)!,
      gaze: Offset.lerp(a.gaze, b.gaze, t)!,
      mouth: late ? b.mouth : a.mouth,
      lamp: _Lamp.lerp(a.lamp, b.lamp, t),
      sweep: l(a.sweep, b.sweep),
      droop: l(a.droop, b.droop),
      bristle: l(a.bristle, b.bristle),
      irregular: l(a.irregular, b.irregular),
      breathes: late ? b.breathes : a.breathes,
      runs: late ? b.runs : a.runs,
      paw: late ? b.paw : a.paw,
      smallPupils: late ? b.smallPupils : a.smallPupils,
    );
  }

  /// La misma pose con un gesto encima: cada mando se suma a lo que ya hay.
  _PoseSpec adjusted({
    required double Function(double) lids,
    double browLift = 0,
    double bristle = 0,
    double droop = 0,
    double irregular = 0,
    double tilt = 0,
    Offset gaze = Offset.zero,
  }) =>
      _PoseSpec(
        cy: cy,
        ryTop: ryTop,
        ryBottom: ryBottom,
        tilt: this.tilt + tilt,
        lidLeft: lids(lidLeft),
        lidRight: lids(lidRight),
        browLeft: browLeft.translate(-browLift, 0),
        browRight: browRight.translate(-browLift, 0),
        gaze: this.gaze + gaze,
        mouth: mouth,
        lamp: lamp,
        sweep: sweep,
        droop: this.droop + droop,
        bristle: this.bristle + bristle,
        irregular: math.min(1, this.irregular + irregular),
        breathes: breathes,
        runs: runs,
        paw: paw,
        smallPupils: smallPupils,
      );
}

const Map<MascotPose, _PoseSpec> _poses = {
  // Escéptico: un ojo a media asta, la lámpara abajo, por si acaso.
  MascotPose.reposo: _PoseSpec(
    cy: 60,
    ryTop: 26,
    ryBottom: 20,
    tilt: 0,
    lidLeft: 0.42,
    lidRight: 0.22,
    browLeft: Offset(0, 6),
    browRight: Offset(-3, -4),
    gaze: Offset(0.4, 0.3),
    mouth: _Mouth.smirk,
    lamp: _Lamp(Offset(70, 13)),
    breathes: true,
  ),
  MascotPose.rodando: _PoseSpec(
    cy: 60,
    ryTop: 26,
    ryBottom: 20,
    tilt: 9,
    lidLeft: 0.34,
    lidRight: 0.3,
    browLeft: Offset(1, 10),
    browRight: Offset(0, -8),
    gaze: Offset(1.6, 0),
    mouth: _Mouth.flat,
    lamp: _Lamp(Offset(74, 3), rotation: -8, lean: -5),
    sweep: -32,
    runs: true,
  ),
  MascotPose.dormido: _PoseSpec(
    cy: 65,
    ryTop: 21,
    ryBottom: 18,
    tilt: 0,
    lidLeft: 1,
    lidRight: 1,
    browLeft: Offset(2, 2),
    browRight: Offset(2, -2),
    gaze: Offset.zero,
    mouth: _Mouth.sleep,
    lamp: _Lamp(Offset(76, 18), flame: 0, held: false),
    droop: 38,
    bristle: -0.2,
  ),
  // Busca con la lámpara en alto, como quien busca a un hombre honesto.
  MascotPose.examinando: _PoseSpec(
    cy: 61,
    ryTop: 26,
    ryBottom: 20,
    tilt: -7,
    lidLeft: 0.62,
    lidRight: 0.05,
    browLeft: Offset(2, 14),
    browRight: Offset(-6, -10),
    gaze: Offset(1.2, 1.8),
    mouth: _Mouth.purse,
    lamp: _Lamp(Offset(84, -16), rotation: -6),
    bristle: 0.08,
    paw: true,
  ),
  // Satisfecho a lo cínico: párpados pesados y media sonrisa, no un «¡yay!».
  MascotPose.satisfecho: _PoseSpec(
    cy: 59,
    ryTop: 26,
    ryBottom: 20,
    tilt: -4,
    lidLeft: 0.5,
    lidRight: 0.44,
    browLeft: Offset(-3, -4),
    browRight: Offset(-4, -2),
    gaze: Offset(0, 2.4),
    mouth: _Mouth.grin,
    lamp: _Lamp(Offset(70, 13), rotation: 4, flame: 0.9, lean: 1),
    bristle: 0.14,
    breathes: true,
  ),
  // Se le cae la lámpara y la llama tiembla, casi apagada.
  MascotPose.confundido: _PoseSpec(
    cy: 60,
    ryTop: 26,
    ryBottom: 20,
    tilt: -11,
    lidLeft: 0,
    lidRight: 0.05,
    browLeft: Offset(-6, -12),
    browRight: Offset(0, 14),
    gaze: Offset(-1.2, 0.8),
    mouth: _Mouth.wavy,
    lamp: _Lamp(Offset(74, 19), rotation: 34, flame: 0.45, lean: 3, held: false),
    bristle: 0.12,
    irregular: 1,
    smallPupils: true,
  ),
};

/// Cuánto se tumban las púas al dormir: la referencia para acortarlas.
const double _sleepDroop = 38;

/// Semieje horizontal del cuerpo: igual en todas las poses.
const double _bodyRx = 28;

/// Centros de los ojos en x.
const double _eyeLeftX = 38.5;
const double _eyeRightX = 61.5;

double _rad(double deg) => deg * math.pi / 180;

Paint _fill(Color c) => Paint()..color = c;

/// Los colores con que se pinta, como pinturas ya hechas: una vez por tema, no
/// en cada fotograma. `figure` es la figura negra del ánfora: todo silueta y
/// las líneas «incisas» dejan ver el barro.
class _Palette {
  _Palette({
    required Color body,
    required Color spikes,
    required Color tip,
    required Color paw,
    required Color eye,
    required Color pupil,
    required this.line,
    required this.accent,
    required Color lampClay,
    required this.lampDark,
    required Color flame,
    required Color flameCore,
    required this.glow,
    this.tubercle,
    this.rim,
    this.smoke,
    this.shadowAlpha = 0,
  })  : body = _fill(body),
        spikes = _fill(spikes),
        tip = _fill(tip),
        paw = _fill(paw),
        eye = _fill(eye),
        pupil = _fill(pupil),
        lampClay = _fill(lampClay),
        flame = _fill(flame),
        flameCore = _fill(flameCore);

  final Paint body, spikes, tip, paw, eye, pupil, lampClay, flame, flameCore;

  /// Cejas, párpados y boca.
  final Color line;

  /// z del sueño, líneas de velocidad y rubor.
  final Color accent;
  final Color lampDark, glow;
  final Color? tubercle, rim, smoke;

  /// 0 = sin sombra (en la vasija el suelo es una línea).
  final double shadowAlpha;

  static final light = _Palette(
    body: ColorTokens.mascotBody,
    spikes: ColorTokens.mascotSpikes,
    tip: ColorTokens.mascotSpikeTip,
    paw: ColorTokens.mascotPaw,
    eye: ColorTokens.mascotEye,
    pupil: ColorTokens.mascotPupil,
    line: ColorTokens.mascotBrow,
    accent: ColorTokens.mascotAccent,
    lampClay: ColorTokens.mascotLampClay,
    lampDark: ColorTokens.mascotLampDark,
    flame: ColorTokens.mascotFlame,
    flameCore: ColorTokens.mascotFlameCore,
    glow: ColorTokens.mascotFlameGlow,
    tubercle: ColorTokens.mascotTubercle,
    rim: MascotTokens.rimLightOnLightTheme ? ColorTokens.mascotRimLight : null,
    smoke: ColorTokens.mascotEye,
    shadowAlpha: MascotTokens.shadowAlphaLight,
  );

  static final dark = _Palette(
    body: ColorTokens.mascotBody,
    spikes: ColorTokens.mascotSpikesOnDark,
    tip: ColorTokens.mascotSpikeTipOnDark,
    paw: ColorTokens.mascotPawOnDark,
    eye: ColorTokens.mascotEye,
    pupil: ColorTokens.mascotPupil,
    line: ColorTokens.mascotBrow,
    accent: ColorTokens.mascotAccent,
    lampClay: ColorTokens.mascotLampClay,
    lampDark: ColorTokens.mascotLampDark,
    flame: ColorTokens.mascotFlame,
    flameCore: ColorTokens.mascotFlameCore,
    glow: ColorTokens.mascotFlameGlow,
    tubercle: ColorTokens.mascotTubercle,
    rim: ColorTokens.mascotRimLight,
    smoke: ColorTokens.mascotEye,
    shadowAlpha: MascotTokens.shadowAlphaDark,
  );

  static final figure = _Palette(
    body: ColorTokens.mascotVaseBlack,
    spikes: ColorTokens.mascotVaseBlack,
    tip: ColorTokens.mascotVaseBlack,
    paw: ColorTokens.mascotVaseBlack,
    eye: ColorTokens.mascotVaseClay,
    pupil: ColorTokens.mascotVaseBlack,
    line: ColorTokens.mascotVaseClay,
    accent: ColorTokens.mascotVaseBlack,
    lampClay: ColorTokens.mascotVaseBlack,
    lampDark: ColorTokens.mascotVaseClay,
    flame: ColorTokens.mascotVaseClay,
    flameCore: ColorTokens.mascotVaseHighlight,
    glow: ColorTokens.mascotVaseClay,
  );
}

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
    this.weary = false,
    this.figure = false,
    this.from,
    this.morph = 1,
    this.beat,
    this.beatT = 0,
  });

  final MascotPose pose;

  /// Tema oscuro: agujas y pies más claros, y otra opacidad de sombra.
  final bool dark;
  final bool rim;

  /// 0..1, ya con su curva. Respiración, sueño o fase de la carrera.
  final double idle;

  /// 0..1, ya con su curva. z, mirada, bamboleo o mirar atrás.
  final double aux;

  /// 0..1. 1 = ojos cerrados.
  final double blink;

  /// 0..1 durante el salto de un toque; 0 en reposo.
  final double poke;

  /// Hacia dónde mira mientras lo arrastras, -1..1 por eje.
  final Offset look;

  /// Mantenido pulsado: ojos entrecerrados y rubor.
  final bool petted;

  /// Carga larga: corre cansado y mira atrás.
  final bool weary;

  /// Pintado en el ánfora: figura negra, sin sombra ni luz de borde.
  final bool figure;

  /// Pose de la que viene y cuánto lleva (0..1, ya con curva). Null: quieta.
  final MascotPose? from;
  final double morph;

  /// Gesto en curso y su progreso 0..1.
  final MascotBeat? beat;
  final double beatT;

  static final Paint _line = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  _Palette get _c => figure ? _Palette.figure : (dark ? _Palette.dark : _Palette.light);

  @override
  void paint(Canvas canvas, Size size) {
    final c = _c;
    final base = from != null && morph < 1 ? _PoseSpec.lerp(_poses[from]!, _poses[pose]!, morph) : _poses[pose]!;

    // El gesto se reparte en unos pocos mandos: n (se da cuenta), s (suspira),
    // e (tropieza) y un salto con su propia fase.
    final t = beat == null ? 0.0 : beatT;
    double bump(double x) => x <= 0 || x >= 1 ? 0 : math.sin(math.pi * x);
    final n = switch (beat) {
      MascotBeat.notice => bump(t),
      MascotBeat.celebrate => bump(t / 0.4),
      _ => 0.0,
    };
    final sigh = beat == MascotBeat.sigh ? bump(t) : 0.0;
    final trip = beat == MascotBeat.stumble ? (1 - t) : 0.0;
    final (double hopPhase, double hopAmp) = poke > 0
        ? (poke, 1.0)
        : switch (beat) {
            MascotBeat.hop => (t, 1.0),
            MascotBeat.celebrate when t > 0.4 => ((t - 0.4) / 0.6, MascotTokens.celebrateHop),
            _ => (0.0, 0.0),
          };
    final hop = hopAmp * bump(hopPhase);
    final p = beat == null
        ? base
        : base.adjusted(
            lids: (l) => (l * (1 - n) + MascotTokens.sighLid * sigh).clamp(0.0, l >= 0.99 && n == 0 ? 1.0 : 0.9),
            browLift: MascotTokens.noticeBrow * n,
            bristle: MascotTokens.noticeBristle * n + 0.3 * bump(t) * (trip > 0 ? 1 : 0),
            droop: MascotTokens.sighDroop * sigh,
            irregular: trip,
            tilt: MascotTokens.stumbleTilt * math.sin(2 * math.pi * t) * trip,
            gaze: Offset(0, 1.5 * sigh),
          );
    // A tamaño pequeño la silueta necesita agujas más gordas y trazos más
    // gruesos, y pierde los tubérculos y el asa: es la única variante.
    final small = size.width <= MascotTokens.smallThreshold;

    // La carrera: la fase va lineal y los senos salen de ella. Cansado, la
    // zancada se acorta y cada tanto mira hacia atrás.
    final phase = p.runs ? 2 * math.pi * idle : 0.0;
    final step = math.sin(phase);
    final effort = weary ? MascotTokens.wearyBob : 1.0;
    final bob = p.runs ? -MascotTokens.runBob * step.abs() * effort : 0.0;
    final stride = p.runs ? step * effort : 0.0;
    final lookBack = p.runs && weary ? ((math.sin(2 * math.pi * aux) - 0.6) / 0.4).clamp(0.0, 1.0) : 0.0;

    canvas.save();
    canvas.scale(size.width / 100.0);

    if (c.shadowAlpha > 0) _paintShadow(canvas, p, c, hop, step.abs() * (p.runs ? 1 : 0));

    // Tropiezo: un vaivén de lado que se apaga. Se da cuenta: se estira un
    // poco hacia arriba. Suspiro: se hunde desde los pies.
    if (trip > 0) canvas.translate(MascotTokens.stumbleShift * math.sin(3 * math.pi * t) * trip, 0);
    if (n > 0) canvas.translate(0, -MascotTokens.noticeLift * n);
    if (sigh > 0) _scaleFromFeet(canvas, p, 1, 1 - MascotTokens.sighSink * sigh);

    // Salto (toque o gesto): sube y, al despegar y al caer, se aplasta.
    if (hop > 0) {
      canvas.translate(0, -MascotTokens.hopHeight * hop);
      const edge = MascotTokens.hopSquashPhase;
      final squash = hopPhase < edge
          ? (edge - hopPhase) / edge
          : hopPhase > 1 - edge
              ? (hopPhase - (1 - edge)) / edge
              : 0.0;
      _scaleFromFeet(canvas, p, 1 + MascotTokens.hopSquashX * squash, 1 - MascotTokens.hopSquashY * squash);
    }

    if (p.runs) {
      _paintSpeedLines(canvas, p, c);
      canvas.translate(0, bob);
      // Al tocar el suelo se aplasta un poco: dos contactos por ciclo.
      final contact = MascotTokens.squashScale * (1 - step.abs());
      _scaleFromFeet(canvas, p, 1 + contact, 1 - contact);
    } else if (pose == MascotPose.dormido) {
      // Respiración de sueño: más lenta y hacia abajo. Un cuerpo dormido no se
      // hincha, se hunde un poco.
      _scaleFromFeet(canvas, p, 1, 1 - (1 - MascotTokens.sleepScale) * idle);
    } else if (p.breathes) {
      _scaleFromFeet(canvas, p, 1, 1 + (MascotTokens.breatheScaleMax - 1) * idle);
    }

    canvas.translate(50, p.cy);
    canvas.rotate(_rad(p.tilt - MascotTokens.lookBackTilt * lookBack));
    canvas.translate(-50, -p.cy);

    // Un toque lo eriza y le abre los ojos de golpe.
    final bristle = p.bristle + MascotTokens.hopBristle * hop;
    final flutter = p.runs ? MascotTokens.runSpineFlutter * math.sin(2 * phase) : 0.0;
    _paintSpikes(canvas, p, c, small, bristle, p.sweep + flutter);
    _paintFeet(canvas, p, c, small, stride);
    _paintBody(canvas, p, c, small);
    _paintFace(canvas, p, c, small, hop, lookBack);
    if (p.paw) _paintPaw(canvas, p, c);
    _paintLamp(canvas, p, c, small, hop, phase);
    if (pose == MascotPose.dormido) _paintZs(canvas, c);

    canvas.restore();
  }

  void _scaleFromFeet(Canvas canvas, _PoseSpec p, double sx, double sy) {
    final originY = p.cy + p.ryBottom;
    canvas.translate(50, originY);
    canvas.scale(sx, sy);
    canvas.translate(-50, -originY);
  }

  /// La sombra se queda en el suelo: al saltar o en lo alto de cada zancada se
  /// encoge y se aclara.
  void _paintShadow(Canvas canvas, _PoseSpec p, _Palette c, double hop, double runUp) {
    final k = 1 - MascotTokens.shadowHopShrink * hop - 0.12 * runUp;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(50, p.cy + p.ryBottom + 7), width: 48 * k, height: 6.4 * k),
      Paint()..color = ColorTokens.mascotShadow.withValues(alpha: c.shadowAlpha * k),
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
  void _paintSpikes(Canvas canvas, _PoseSpec p, _Palette c, bool small, double bristle, double sweep) {
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
        // Tumbadas se ven más cortas; proporcional para que se interpole.
        final length = reach * share * variation * (1 - 0.18 * math.min(1, p.droop / _sleepDroop));
        final cos = math.cos(a);
        var turn = sweep;
        if (p.droop > 0) turn += p.droop * cos.sign * math.min(1, cos.abs() * 3);
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
    canvas.drawPath(shafts, c.spikes);
    canvas.drawPath(tips, c.tip);
  }

  /// Pies tubulares. Corriendo se alternan: el que va adelante, levantado.
  void _paintFeet(Canvas canvas, _PoseSpec p, _Palette c, bool small, double stride) {
    final y = p.cy + p.ryBottom + 1.5;
    final w = small ? 14.0 : 12.0;
    final h = small ? 9.2 : 7.6;
    final reach = MascotTokens.runStride * stride;
    final lift = MascotTokens.runLift;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(41 - reach, y - math.max(0, stride) * lift), width: w, height: h),
      c.paw,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(59 + reach, y - math.max(0, -stride) * lift), width: w, height: h),
      c.paw,
    );
  }

  /// La cúpula: media elipse alta arriba y otra más baja abajo. Encima, las
  /// hileras de tubérculos de un erizo de mar y la luz de borde en oscuro.
  void _paintBody(Canvas canvas, _PoseSpec p, _Palette c, bool small) {
    final top = Rect.fromCenter(center: Offset(50, p.cy), width: _bodyRx * 2, height: p.ryTop * 2);
    final bottom = Rect.fromCenter(center: Offset(50, p.cy), width: _bodyRx * 2, height: p.ryBottom * 2);
    canvas.drawPath(
      Path()
        ..addArc(top, math.pi, math.pi)
        ..arcTo(bottom, 0, math.pi, false)
        ..close(),
      c.body,
    );

    final tubercle = c.tubercle;
    if (!small && tubercle != null) {
      final paint = Paint()..color = tubercle.withValues(alpha: 0.55);
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
            paint,
          );
        }
      }
    }

    final rimColor = c.rim;
    if (rim && rimColor != null) {
      canvas.drawArc(
        top,
        _rad(-160),
        _rad(50),
        false,
        _line
          ..color = rimColor
          ..strokeWidth = 2.4,
      );
    }
  }

  void _paintFace(Canvas canvas, _PoseSpec p, _Palette c, bool small, double hop, double lookBack) {
    final ey = p.cy - 2;
    final er = small ? 8.2 : 7.4;
    final pupilR = (small ? 3.4 : 2.8) * (p.smallPupils ? 0.72 : 1);

    // Examinando: la mirada barre de lado a lado, como quien lee una fila.
    final glance = pose == MascotPose.examinando ? MascotTokens.glanceOffset * (2 * aux - 1) : 0.0;
    var gaze = p.gaze + Offset(glance, 0) + look * MascotTokens.lookPupil;
    gaze = Offset.lerp(gaze, const Offset(-MascotTokens.lookBackGaze, 0), lookBack)!;

    double lid(double base) {
      var l = petted ? math.max(base, MascotTokens.pettedLid) : base;
      if (weary && p.runs) l = math.min(0.9, l + MascotTokens.wearyLid);
      l *= 1 - hop; // el salto le abre los ojos
      return l + (1 - l) * blink;
    }

    _paintEye(canvas, c, Offset(_eyeLeftX, ey), er * 0.95, er * 1.02, lid(p.lidLeft), gaze, pupilR, small);
    _paintEye(canvas, c, Offset(_eyeRightX, ey - 0.5), er, er * 1.05, lid(p.lidRight), gaze, pupilR, small);

    final browWidth = small ? 3.6 : 3.0;
    _paintBrow(canvas, c, Offset(_eyeLeftX, ey - er - 2.2), p.browLeft, browWidth);
    _paintBrow(canvas, c, Offset(_eyeRightX, ey - er - 3.6), p.browRight, browWidth);

    if (petted) {
      final blush = Paint()..color = c.accent.withValues(alpha: MascotTokens.blushAlpha);
      for (final cx in const [31.0, 69.0]) {
        canvas.drawOval(Rect.fromCenter(center: Offset(cx, p.cy + 8), width: 9, height: 4.5), blush);
      }
    }

    _paintMouth(canvas, p, c, small);
    _paintBeard(canvas, p, c, small);
  }

  /// Un ojo con su párpado: el blanco, la pupila con su brillo, y encima un
  /// párpado del color del cuerpo recortado a la forma del ojo. Cerrado del
  /// todo es una curva cansada hacia abajo.
  void _paintEye(
    Canvas canvas,
    _Palette c,
    Offset o,
    double rx,
    double ry,
    double lid,
    Offset gaze,
    double pupilR,
    bool small,
  ) {
    if (lid >= 0.99) {
      canvas.drawPath(
        Path()
          ..moveTo(o.dx - rx, o.dy)
          ..quadraticBezierTo(o.dx, o.dy + ry * 0.7, o.dx + rx, o.dy),
        _line
          ..color = c.line
          ..strokeWidth = small ? 2.6 : 2.0,
      );
      return;
    }
    final oval = Rect.fromCenter(center: o, width: rx * 2, height: ry * 2);
    canvas.drawOval(oval, c.eye);
    canvas.save();
    canvas.clipPath(Path()..addOval(oval));
    final pupil = o + gaze;
    canvas.drawCircle(pupil, pupilR, c.pupil);
    canvas.drawCircle(pupil.translate(-pupilR * 0.35, -pupilR * 0.4), pupilR * 0.28, c.eye);
    final top = o.dy - ry;
    final ly = top + lid * 2 * ry;
    if (lid > 0) {
      canvas.drawPath(
        Path()
          ..moveTo(o.dx - rx - 1, top - 1)
          ..lineTo(o.dx + rx + 1, top - 1)
          ..lineTo(o.dx + rx + 1, ly)
          ..quadraticBezierTo(o.dx, ly + ry * 0.18, o.dx - rx - 1, ly)
          ..close(),
        c.body,
      );
    }
    canvas.restore();
    if (lid > 0) {
      canvas.drawPath(
        Path()
          ..moveTo(o.dx - rx * 0.98, ly)
          ..quadraticBezierTo(o.dx, ly + ry * 0.18, o.dx + rx * 0.98, ly),
        _line
          ..color = c.line
          ..strokeWidth = 1.5,
      );
    }
  }

  /// [shape]: dx cuánto baja la ceja, dy su inclinación en grados.
  void _paintBrow(Canvas canvas, _Palette c, Offset o, Offset shape, double width) {
    const half = 6.2;
    final a = _rad(shape.dy);
    final y = o.dy + shape.dx;
    canvas.drawPath(
      Path()
        ..moveTo(o.dx - half * math.cos(a), y - half * math.sin(a))
        ..quadraticBezierTo(o.dx, y - 1.4, o.dx + half * math.cos(a), y + half * math.sin(a)),
      _line
        ..color = c.line
        ..strokeWidth = width,
    );
  }

  void _paintMouth(Canvas canvas, _PoseSpec p, _Palette c, bool small) {
    final y = p.cy + 11;
    final mouth = weary && p.runs ? _Mouth.wavy : p.mouth;
    final path = switch (mouth) {
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
        ..color = c.line
        ..strokeWidth = small ? 2.4 : 2.0,
    );
  }

  /// La barba del filósofo: tres púas que cuelgan de la barbilla. Dormido se
  /// le tuercen hacia los lados.
  void _paintBeard(Canvas canvas, _PoseSpec p, _Palette c, bool small) {
    final y = p.cy + 15 - 1.5;
    final droop = 0.5 * math.min(1, p.droop / _sleepDroop);
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
    canvas.drawPath(shafts, c.spikes);
    canvas.drawPath(tips, c.tip);
  }

  void _paintPaw(Canvas canvas, _PoseSpec p, _Palette c) {
    canvas.save();
    canvas.translate(72, p.cy + 6);
    canvas.rotate(_rad(-24));
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 13, height: 10), c.paw);
    canvas.restore();
  }

  /// La lucerna griega de barro: cuerpo, pico, asa y llama. Se dibuja en su
  /// sitio sin escalar y luego se escala desde su centro, así que la
  /// geometría de abajo es la de una lámpara de 20 unidades de largo.
  void _paintLamp(Canvas canvas, _PoseSpec p, _Palette c, bool small, double hop, double phase) {
    final lamp = p.lamp;
    final k = small ? 1.6 : 1.35;
    final o = Offset(lamp.at.dx, p.cy + lamp.at.dy - MascotTokens.hopLampLift * hop * (lamp.held ? 1 : 0));
    var rotation = lamp.rotation;
    // Caída en el suelo, se mece con el bamboleo del desconcierto.
    if (pose == MascotPose.confundido) rotation += MascotTokens.wobbleDegrees * (2 * aux - 1);
    // La llama se mece con la respiración; corriendo, aletea hacia atrás.
    final sway =
        p.runs ? MascotTokens.flameSway * math.sin(2 * phase) : MascotTokens.flameSway * (2 * idle - 1);
    final lean = lamp.lean + sway;

    canvas.save();
    canvas.translate(o.dx, o.dy);
    canvas.rotate(_rad(rotation));
    canvas.scale(k);

    const f = Offset(11.2, -1.8); // boca del pico, donde nace la llama
    if (lamp.flame > 0) {
      final r = 12 * lamp.flame;
      canvas.drawCircle(f.translate(0, -3), r, Paint()..color = c.glow.withValues(alpha: 0.18));
      canvas.drawCircle(f.translate(0, -3), r * 0.55, Paint()..color = c.glow.withValues(alpha: 0.14));
    }
    if (!small) {
      canvas.drawCircle(
        const Offset(-8.2, -0.6),
        2.5,
        _line
          ..color = c.lampDark
          ..strokeWidth = 1.4,
      );
    }
    canvas.drawPath(
      Path()
        ..moveTo(4, -2.6)
        ..quadraticBezierTo(9, -2.8, 11.6, -1.9)
        ..quadraticBezierTo(12.8, -0.4, 11.2, 0.9)
        ..quadraticBezierTo(8, 2.2, 4, 2.6)
        ..close(),
      c.lampClay,
    );
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 15.2, height: 7.8), c.lampClay);
    canvas.drawPath(
      Path()
        ..moveTo(-7, 1.2)
        ..quadraticBezierTo(0, 3.6, 7, 1.2),
      _line
        ..color = c.lampDark
        ..strokeWidth = 1.1,
    );
    canvas.drawOval(Rect.fromCenter(center: const Offset(-0.8, -2.6), width: 5.6, height: 2.4),
        Paint()..color = c.lampDark);

    if (lamp.flame > 0) {
      final h = 8 * lamp.flame;
      canvas.drawPath(
        Path()
          ..moveTo(f.dx - 2, f.dy)
          ..quadraticBezierTo(f.dx - 2.6, f.dy - h / 2, f.dx + lean, f.dy - h)
          ..quadraticBezierTo(f.dx + 2.6, f.dy - h / 2, f.dx + 2, f.dy)
          ..quadraticBezierTo(f.dx, f.dy + 1.6, f.dx - 2, f.dy)
          ..close(),
        c.flame,
      );
      canvas.drawPath(
        Path()
          ..moveTo(f.dx - 0.9, f.dy)
          ..quadraticBezierTo(f.dx - 1.1, f.dy - h * 0.3, f.dx + lean / 2, f.dy - h * 0.58)
          ..quadraticBezierTo(f.dx + 1.1, f.dy - h * 0.3, f.dx + 0.9, f.dy)
          ..close(),
        c.flameCore,
      );
    } else if (c.smoke != null) {
      // Apagada: un hilo de humo que sube.
      canvas.drawPath(
        Path()
          ..moveTo(f.dx, f.dy - 1)
          ..relativeQuadraticBezierTo(-2.5, -3, 0, -6)
          ..relativeQuadraticBezierTo(2.5, -3, 0, -6),
        _line
          ..color = c.smoke!.withValues(alpha: 0.35)
          ..strokeWidth = 1.2,
      );
    }
    canvas.restore();

    // El pie tubular que la sostiene, por debajo.
    if (lamp.held) {
      canvas.drawOval(
        Rect.fromCenter(center: o.translate(-1.5 * k, 4.3 * k), width: 6.4 * k, height: 4.6 * k),
        c.paw,
      );
    }
  }

  /// Tres «z» que suben y se apagan, desfasadas un tercio de ciclo. Se dibujan
  /// como trazo, no como texto: son parte de la ilustración.
  void _paintZs(Canvas canvas, _Palette c) {
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
          ..color = c.accent.withValues(alpha: alpha.clamp(0.0, 1.0))
          ..strokeWidth = 1.8,
      );
    }
  }

  void _paintSpeedLines(Canvas canvas, _PoseSpec p, _Palette c) {
    for (final (x1, dy, x2, alpha) in const [
      (3.0, -16.0, 16.0, 0.42),
      (0.0, -3.0, 11.0, 0.26),
      (4.0, 10.0, 13.0, 0.13)
    ]) {
      canvas.drawLine(
        Offset(x1, p.cy + dy),
        Offset(x2, p.cy + dy),
        _line
          ..color = c.accent.withValues(alpha: alpha)
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
      old.petted != petted ||
      old.weary != weary ||
      old.figure != figure ||
      old.from != from ||
      old.morph != morph ||
      old.beat != beat ||
      old.beatT != beatT;
}

/// El ánfora de figuras negras, en un lienzo de 120×160: cuello negro con
/// hojas, meandro en el hombro, el panel de barro donde va Erizógenes y los
/// rayos sobre el pie.
class _VasePainter extends CustomPainter {
  _VasePainter({required this.pose, required this.idle});

  static const double width = 120;
  static const double height = 160;

  final MascotPose pose;
  final double idle;

  static final Path _shape = Path()
    ..moveTo(40, 6)
    ..lineTo(80, 6)
    ..lineTo(78, 12)
    ..lineTo(70, 16)
    ..lineTo(68, 34)
    ..quadraticBezierTo(96, 44, 98, 72)
    ..cubicTo(100, 104, 78, 132, 66, 142)
    ..lineTo(64, 148)
    ..lineTo(74, 156)
    ..lineTo(46, 156)
    ..lineTo(56, 148)
    ..lineTo(54, 142)
    ..cubicTo(42, 132, 20, 104, 22, 72)
    ..quadraticBezierTo(24, 44, 52, 34)
    ..lineTo(50, 16)
    ..lineTo(42, 12)
    ..close();

  static final Paint _clay = Paint()..color = ColorTokens.mascotVaseClay;
  static final Paint _black = Paint()..color = ColorTokens.mascotVaseBlack;
  static final Paint _stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..color = ColorTokens.mascotVaseBlack;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / width);

    // Asas, detrás del cuerpo.
    for (final handle in [
      Path()
        ..moveTo(51, 20)
        ..cubicTo(30, 16, 20, 34, 30, 52),
      Path()
        ..moveTo(69, 20)
        ..cubicTo(90, 16, 100, 34, 90, 52),
    ]) {
      canvas.drawPath(handle, _stroke..strokeWidth = 4.2);
    }
    canvas.drawPath(_shape, _clay);

    canvas.save();
    canvas.clipPath(_shape);
    canvas.drawRect(const Rect.fromLTWH(0, 0, width, 33), _black);
    final leaf = Paint()..color = ColorTokens.mascotVaseClay.withValues(alpha: 0.8);
    for (var i = 0; i < 5; i++) {
      final x = 50.0 + i * 5;
      canvas.drawPath(
        Path()
          ..moveTo(x, 30)
          ..quadraticBezierTo(x + 2.5, 20, x + 5, 30)
          ..close(),
        leaf,
      );
    }
    // Meandro en el hombro, entre dos filetes.
    const y = 47.0;
    canvas.drawRect(const Rect.fromLTWH(0, y - 5.2, width, 1.2), _black);
    canvas.drawRect(const Rect.fromLTWH(0, y + 2.2, width, 1.2), _black);
    final key = Path();
    for (var i = 0; i < 22; i++) {
      final x = 4 + i * 5.2;
      key
        ..moveTo(x, y + 2)
        ..lineTo(x, y - 3)
        ..lineTo(x + 3.4, y - 3)
        ..lineTo(x + 3.4, y)
        ..lineTo(x + 1.7, y);
    }
    canvas.drawPath(key, _stroke..strokeWidth = 0.9);
    // Franja negra con rayos sobre el pie.
    canvas.drawRect(const Rect.fromLTWH(0, 122, width, 40), _black);
    canvas.drawRect(const Rect.fromLTWH(0, 118, width, 1.2), _black);
    final ray = Paint()..color = ColorTokens.mascotVaseClay.withValues(alpha: 0.85);
    for (var i = 0; i < 9; i++) {
      final x = 38 + i * 5.4;
      canvas.drawPath(
        Path()
          ..moveTo(x, 146)
          ..lineTo(x + 2.7, 126)
          ..lineTo(x + 5.4, 146)
          ..close(),
        ray,
      );
    }
    canvas.restore();

    // La figura, pintada en el panel, sobre una línea de suelo.
    canvas.save();
    canvas.translate(33, 58);
    canvas.scale(0.54);
    _ErizogenesPainter(
      pose: pose,
      dark: false,
      rim: false,
      idle: idle,
      aux: 0,
      blink: 0,
      figure: true,
    ).paint(canvas, const Size(100, 100));
    canvas.restore();
    canvas.drawLine(const Offset(30, 114), const Offset(90, 114), _stroke..strokeWidth = 1.2);

    // El brillo del barro cocido.
    canvas.drawPath(
      Path()
        ..moveTo(30, 70)
        ..quadraticBezierTo(30, 96, 42, 116),
      _stroke
        ..color = ColorTokens.mascotVaseHighlight.withValues(alpha: 0.35)
        ..strokeWidth = 2,
    );
    _stroke.color = ColorTokens.mascotVaseBlack;

    canvas.restore();
  }

  @override
  bool shouldRepaint(_VasePainter old) => old.pose != pose || old.idle != idle;
}
