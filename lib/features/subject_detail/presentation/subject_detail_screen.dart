import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/time/minutes_of_day.dart';
import '../../../l10n/strings.g.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/layout.dart';
import '../../../theme/tokens.g.dart';
import '../../subjects/application/subjects_providers.dart';
import '../../subjects/presentation/subjects_screen.dart';
import '../application/subject_detail_providers.dart';
import 'widgets/attendance_tab.dart';
import 'widgets/grades_tab.dart';

/// La pantalla de una materia: Notas y Asistencia.
///
/// Sin mascota. «detalle de materia» está en la lista de pantallas prohibidas
/// del contrato: aquí se viene a trabajar, y a veces a recibir malas noticias.
///
/// En teléfono son dos pestañas. En tablet, las dos columnas a la vez: la
/// pregunta «¿cómo voy?» tiene dos mitades y caben juntas.
class SubjectDetailScreen extends ConsumerWidget {
  const SubjectDetailScreen({
    required this.subjectId,
    this.embedded = false,
    super.key,
  });

  final int subjectId;

  /// `true` cuando vive en el panel derecho de Materias en tablet: sin flecha
  /// de volver, y si la materia se borra se limpia la selección en vez de
  /// cerrar una ruta que no existe.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(subjectDetailProvider(subjectId));

    return async.when(
      loading: () => const Scaffold(body: SizedBox.shrink()),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (state) {
        // La materia se borró mientras la pantalla estaba abierta. Se cierra
        // sola en vez de quedarse enseñando datos que ya no existen.
        if (state == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            if (embedded) {
              ref.read(selectedSubjectProvider.notifier).state = null;
            } else {
              Navigator.of(context).maybePop();
            }
          });
          return const Scaffold(body: SizedBox.shrink());
        }
        return _Loaded(state: state, embedded: embedded);
      },
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.state, required this.embedded});

  final SubjectDetailState state;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final subject = state.detail.subject;
    final accent = SubjectPalette.at(subject.colorIndex);
    final wide = context.sizeClass.isExpanded;

    final actions = [
      TextButton(
        onPressed: () => openSubjectForm(context, subjectId: subject.id),
        child: const Text(SSubjectDetail.edit),
      ),
    ];

    if (wide) {
      return Scaffold(
        appBar: AppBar(
          title: Text(subject.nombre),
          automaticallyImplyLeading: !embedded,
          actions: actions,
        ),
        body: Column(
          children: [
            _Header(state: state, accent: accent),
            // Cada pestaña trae su propio margen de pantalla; sumados en el
            // centro hacen el hueco entre columnas, así que no se añade otro.
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _Pane(label: SGrades.tab, child: GradesTab(state: state))),
                  Expanded(child: _Pane(label: SAttendance.tab, child: AttendanceTab(state: state))),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(subject.nombre),
          automaticallyImplyLeading: !embedded,
          actions: actions,
          bottom: TabBar(
            indicatorColor: accent,
            indicatorWeight: BorderTokens.tabIndicator,
            dividerColor: ColorTokens.surfaceBorder.of(b),
            labelColor: ColorTokens.textPrimary.of(b),
            unselectedLabelColor: ColorTokens.textTertiary.of(b),
            labelStyle: context.type(TypeTokens.bodyS),
            tabs: const [
              Tab(text: SGrades.tab),
              Tab(text: SAttendance.tab),
            ],
          ),
        ),
        body: Column(
          children: [
            _Header(state: state, accent: accent),
            Expanded(
              child: TabBarView(
                children: [
                  GradesTab(state: state),
                  AttendanceTab(state: state),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Una de las dos columnas de tablet, con la etiqueta que en teléfono era la
/// pestaña.
class _Pane extends StatelessWidget {
  const _Pane({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: SpaceTokens.l, left: SpaceTokens.screenMargin),
            child: Text(
              label,
              style: context.type(TypeTokens.label, color: context.themed(ColorTokens.textTertiary)),
            ),
          ),
          Expanded(child: child),
        ],
      );
}

/// Profesor y horario. Es lo que se consulta sin pensar: dónde y con quién.
class _Header extends StatelessWidget {
  const _Header({required this.state, required this.accent});

  final SubjectDetailState state;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final subject = state.detail.subject;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(
        SpaceTokens.screenMargin,
        SpaceTokens.m,
        SpaceTokens.screenMargin,
        0,
      ),
      padding: EdgeInsets.all(SpaceTokens.cardPadding),
      decoration: BoxDecoration(
        color: ColorTokens.surfaceCard.of(b),
        borderRadius: BorderRadius.circular(RadiusTokens.card),
        border: Border(
          left: BorderSide(
            color: accent,
            width: ComponentTokens.subjectCardAccentBorderLeft,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subject.profesor ?? SSubjectDetail.noProfessor,
            style: context.type(TypeTokens.bodyS),
          ),
          if (state.detail.sessions.isNotEmpty) ...[
            SizedBox(height: SpaceTokens.xs),
            Text(
              state.detail.sessions
                  .map((s) => SSessionForm.summary(
                        dia: SWeek.days[s.session.diaSemana - 1],
                        inicio: MinutesOfDay(s.session.horaInicio).hhmm,
                        fin: MinutesOfDay(s.session.horaFin).hhmm,
                      ))
                  .join('  ·  '),
              style: context.type(
                TypeTokens.captionS,
                color: ColorTokens.textTertiary.of(b),
              ),
            ),
          ],
          // La fecha límite para cancelar la materia es un dato que se
          // necesita antes de llegar a la calculadora, no solo dentro de ella.
          if (subject.fechaLimiteCancelacion != null) ...[
            SizedBox(height: SpaceTokens.s),
            Text(
              SCalculator.withdrawDeadline(
                fecha: DateFormat("d 'de' MMMM", 'es_CO')
                    .format(subject.fechaLimiteCancelacion!),
              ),
              style: context.type(
                TypeTokens.captionS,
                color: ColorTokens.accentAttention.of(b),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
