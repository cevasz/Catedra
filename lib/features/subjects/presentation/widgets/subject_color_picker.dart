import 'package:flutter/material.dart';

import '../../../../theme/motion.dart';
import '../../../../theme/tokens.g.dart';

/// Los ocho colores de materia del contrato, en fila y seleccionables.
///
/// Se elige un índice, no un color: lo que se guarda en la BD es `color_index`
/// para que la materia se vea igual en cualquier dispositivo y sobreviva a un
/// cambio de paleta. Por eso el widget devuelve `int` y no `Color`.
class SubjectColorPicker extends StatelessWidget {
  const SubjectColorPicker({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final guard = MotionGuard.of(context);

    return Wrap(
      spacing: SpaceTokens.m,
      runSpacing: SpaceTokens.m,
      children: [
        for (var i = 0; i < SubjectPalette.length; i++)
          Semantics(
            label: SubjectPalette.names[i],
            selected: i == selected,
            button: true,
            child: InkWell(
              onTap: () => onChanged(i),
              borderRadius: BorderRadius.circular(RadiusTokens.full),
              child: AnimatedContainer(
                duration: guard.duration(MotionDurations.fast),
                curve: guard.curve(MotionCurves.easeOutCubic),
                width: ComponentTokens.colorPickerSwatch,
                height: ComponentTokens.colorPickerSwatch,
                decoration: BoxDecoration(
                  color: SubjectPalette.at(i),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: i == selected
                        ? ColorTokens.textPrimary.of(b)
                        : ColorTokens.surfaceBorder.of(b),
                    // El seleccionado se marca con el mismo grosor que el borde
                    // de acento de una materia: es el mismo lenguaje.
                    width: i == selected
                        ? BorderTokens.subjectAccent
                        : BorderTokens.hairline,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
