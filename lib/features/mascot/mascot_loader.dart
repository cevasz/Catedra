import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/strings.g.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import '../../theme/transitions.dart';
import 'application/mascot_voice.dart';
import 'mascot_view.dart';

/// Erizógenes rodando mientras algo carga, en lugar de un spinner.
///
/// Con «reducir movimiento» el erizo se queda quieto y la frase cambia igual,
/// sin animarse.
class MascotLoader extends StatelessWidget {
  const MascotLoader({this.lines, this.inline = false, super.key});

  /// Frases propias de esta espera; por defecto, las de carga genéricas.
  final List<String>? lines;

  /// En línea: erizo pequeño y frase al lado, para una fila o una cabecera.
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final mascot = MascotView(
      pose: MascotPose.rodando,
      size: inline ? MascotTokens.sizeLoaderInline : MascotTokens.sizeLoader,
      host: MascotHost.loader,
      interactive: false,
    );
    final text = RotatingLine(
      lines: lines ?? SMascotVoice.loadingLines,
      textAlign: inline ? TextAlign.start : TextAlign.center,
      style: context.type(TypeTokens.bodyM, color: context.themed(ColorTokens.textSecondary)),
    );

    if (inline) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [mascot, SizedBox(width: SpaceTokens.m), Flexible(child: text)],
      );
    }
    return Center(
      child: Padding(
        padding: EdgeInsets.all(SpaceTokens.screenMargin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [mascot, SizedBox(height: SpaceTokens.l), text],
        ),
      ),
    );
  }
}

/// Una frase de Erizógenes que cambia sola cada
/// [MotionDurations.mascotLoaderLine]: una espera larga con la misma frase se
/// lee como una app colgada.
class RotatingLine extends StatefulWidget {
  const RotatingLine({required this.lines, this.style, this.textAlign, super.key});

  final List<String> lines;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  State<RotatingLine> createState() => _RotatingLineState();
}

class _RotatingLineState extends State<RotatingLine> {
  final _picker = VariantPicker();
  late String _line = _picker.pick(widget.lines);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(MotionDurations.mascotLoaderLine, (_) {
      if (mounted) setState(() => _line = _picker.pick(widget.lines));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StateSwitcher(
        child: Text(_line, key: ValueKey(_line), textAlign: widget.textAlign, style: widget.style),
      );
}
