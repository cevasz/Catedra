import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/numbers.dart';
import '../../../l10n/strings.g.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/cascade.dart';
import '../../../theme/layout.dart';
import '../../../theme/motion.dart';
import '../../../theme/tokens.g.dart';
import '../../../theme/transitions.dart';
import '../../import/presentation/import_pdf_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../subject_detail/presentation/subject_detail_screen.dart';
import '../application/subjects_providers.dart';
import 'subject_form_screen.dart';

/// La pestaña Materias: todo el semestre en una lista.
///
/// Cada tarjeta contesta de un vistazo las dos preguntas que importan: cuántas
/// faltas te quedan y cómo vas de nota. Sin mascota: la lista de pantallas
/// permitidas del contrato no la incluye.
class SubjectsScreen extends ConsumerWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = ref.watch(subjectsOverviewProvider);

    // En tablet la lista es el panel maestro y la materia se abre al lado,
    // sin salir de la pantalla. Tocar una fila cambia el panel derecho.
    if (context.sizeClass.isExpanded) {
      final list = subjects.valueOrNull ?? const <SubjectCard>[];
      final selected = ref.watch(selectedSubjectProvider);
      final open = list.any((c) => c.subject.id == selected)
          ? selected
          : list.firstOrNull?.subject.id;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: LayoutTokens.masterPaneWidth,
            child: _ListScaffold(subjects: subjects, selectedId: open),
          ),
          const VerticalDivider(),
          Expanded(
            child: StateSwitcher(
              rise: MotionOffsets.pdfRowRise,
              child: open == null
                  ? const SizedBox.shrink(key: ValueKey('none'))
                  : SubjectDetailScreen(
                      key: ValueKey(open),
                      subjectId: open,
                      embedded: true,
                    ),
            ),
          ),
        ],
      );
    }

    return _ListScaffold(subjects: subjects, selectedId: null);
  }
}

/// La lista con su app bar y su FAB. Es la pantalla entera en teléfono y el
/// panel izquierdo en tablet.
class _ListScaffold extends StatelessWidget {
  const _ListScaffold({required this.subjects, required this.selectedId});

  final AsyncValue<List<SubjectCard>> subjects;

  /// Fila resaltada en tablet. Null en teléfono: ahí no hay selección.
  final int? selectedId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(SSubjects.title),
        actions: [
          IconButton(
            onPressed: () => openImportPdf(context),
            tooltip: SPdfPicker.title,
            icon: const Icon(Icons.upload_file_outlined),
          ),
          IconButton(
            onPressed: () => openSettings(context),
            tooltip: SSettings.title,
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      floatingActionButton: subjects.valueOrNull?.isEmpty ?? true
          ? null
          : FloatingActionButton.extended(
              onPressed: () => openSubjectForm(context),
              icon: const Icon(Icons.add),
              label: const Text(SSubjects.addSubject),
            ),
      body: subjects.when(
        loading: () => const SizedBox.shrink(),
        error: (e, _) => _Failure(error: e),
        data: (list) => list.isEmpty
            ? const _Empty()
            : _List(subjects: list, selectedId: selectedId),
      ),
    );
  }
}

/// Abre el formulario de materia. Se expone como función para que la tarjeta,
/// el FAB y el estado vacío usen exactamente la misma ruta.
Future<void> openSubjectForm(BuildContext context, {int? subjectId}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => SubjectFormScreen(subjectId: subjectId)),
  );
}

class _List extends StatelessWidget {
  const _List({required this.subjects, required this.selectedId});

  final List<SubjectCard> subjects;
  final int? selectedId;

  @override
  Widget build(BuildContext context) {
    final guard = MotionGuard.of(context);
    final b = Theme.of(context).brightness;

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        SpaceTokens.screenMargin,
        SpaceTokens.m,
        SpaceTokens.screenMargin,
        // Espacio para que el FAB no tape la última tarjeta.
        SpaceTokens.xxxl * 2,
      ),
      itemCount: subjects.length + 1,
      separatorBuilder: (_, __) => SizedBox(height: SpaceTokens.cardGap),
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: EdgeInsets.only(bottom: SpaceTokens.xs),
            child: Text(
              subjects.length == 1
                  ? SSubjects.countOne
                  : SSubjects.count(n: subjects.length),
              style: context.type(
                TypeTokens.bodyM,
                color: ColorTokens.textTertiary.of(b),
              ),
            ),
          );
        }
        final card = subjects[i - 1];
        return CascadeIn(
          index: i - 1,
          guard: guard,
          child: _SubjectTile(card: card, selected: card.subject.id == selectedId),
        );
      },
    );
  }
}

class _SubjectTile extends ConsumerWidget {
  const _SubjectTile({required this.card, required this.selected});

  final SubjectCard card;

  /// Solo en tablet: la fila abierta en el panel derecho.
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = Theme.of(context).brightness;
    final accent = SubjectPalette.at(card.subject.colorIndex);
    final semaphore = SemaphoreTokens.color[card.tally.state]!.of(b);

    return Material(
      color: selected ? ColorTokens.surfaceRaised.of(b) : ColorTokens.surfaceCard.of(b),
      borderRadius: BorderRadius.circular(RadiusTokens.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(RadiusTokens.card),
        onTap: () {
          if (context.sizeClass.isExpanded) {
            ref.read(selectedSubjectProvider.notifier).state = card.subject.id;
            return;
          }
          Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => SubjectDetailScreen(subjectId: card.subject.id),
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.all(SpaceTokens.cardPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(RadiusTokens.card),
            border: Border(
              left: BorderSide(
                color: accent,
                width: ComponentTokens.subjectCardAccentBorderLeft,
              ),
              top: BorderSide(
                color: ColorTokens.surfaceBorder.of(b),
                width: BorderTokens.hairline,
              ),
              right: BorderSide(
                color: ColorTokens.surfaceBorder.of(b),
                width: BorderTokens.hairline,
              ),
              bottom: BorderSide(
                color: ColorTokens.surfaceBorder.of(b),
                width: BorderTokens.hairline,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(card.subject.nombre, style: context.type(TypeTokens.titleS)),
              SizedBox(height: SpaceTokens.xs),
              Text(
                [
                  card.subject.profesor,
                  card.weeklyClasses == 0
                      ? SSubjects.noSchedule
                      : card.weeklyClasses == 1
                          ? SSubjects.classesPerWeekOne
                          : SSubjects.classesPerWeek(n: card.weeklyClasses),
                ].whereType<String>().join(' · '),
                style: context.type(
                  TypeTokens.captionS,
                  color: ColorTokens.textTertiary.of(b),
                ),
              ),
              SizedBox(height: SpaceTokens.m),
              Row(
                children: [
                  _Dot(color: semaphore),
                  SizedBox(width: SpaceTokens.xs + SpaceTokens.xs / 2),
                  Text(
                    SSubjects.absencesShort(
                      used: card.tally.used,
                      limit: card.tally.limit,
                    ),
                    style: context.type(TypeTokens.captionS, color: semaphore),
                  ),
                  const Spacer(),
                  Text(
                    card.hasGrades
                        ? SSubjects.gradeShort(n: Numbers.grade(card.grades.accumulated))
                        : SSubjects.gradeNone,
                    style: context.type(
                      TypeTokens.captionS,
                      color: card.hasGrades
                          ? ColorTokens.textSecondary.of(b)
                          : ColorTokens.textTertiary.of(b),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// El punto del semáforo. Es el mismo lenguaje que el anillo segmentado de la
/// pantalla de materia, reducido a lo que cabe en una fila.
class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: LayoutTokens.timelineRowDotSize,
        height: LayoutTokens.timelineRowDotSize,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(LayoutTokens.screenPaddingHHero),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              SSubjects.emptyHeadline,
              textAlign: TextAlign.center,
              style: context.type(TypeTokens.titleM),
            ),
            SizedBox(height: SpaceTokens.s),
            Text(
              SSubjects.emptyBody,
              textAlign: TextAlign.center,
              style: context.type(
                TypeTokens.bodyM,
                color: ColorTokens.textSecondary.of(b),
              ),
            ),
            SizedBox(height: SpaceTokens.xl),
            FilledButton(
              onPressed: () => openSubjectForm(context),
              child: const Text(SSubjects.emptyCta),
            ),
            SizedBox(height: SpaceTokens.s),
            OutlinedButton(
              onPressed: () => openImportPdf(context),
              child: const Text(SOnboarding.ctaImport),
            ),
          ],
        ),
      ),
    );
  }
}

/// Un fallo de base de datos se enseña, no se traga. Sin texto inventado: el
/// mensaje del error es el mensaje.
class _Failure extends StatelessWidget {
  const _Failure({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(SpaceTokens.screenMargin),
        child: Text(
          '$error',
          textAlign: TextAlign.center,
          style: context.type(
            TypeTokens.bodyM,
            color: ColorTokens.accentUrgent.of(b),
          ),
        ),
      ),
    );
  }
}
