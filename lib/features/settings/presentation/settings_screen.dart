import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../../../core/providers.dart';
import '../../../domain/alarms/alarm_planner.dart';
import '../../../domain/attendance/attendance.dart';
import '../../../domain/departure/departure.dart';
import '../../../l10n/strings.g.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/haptics.dart';
import '../../../theme/layout.dart';
import '../../../theme/tokens.g.dart';
import '../../alarms/application/alarms_controller.dart';
import '../../mascot/application/mascot_voice.dart';
import '../../mascot/mascot_loader.dart';

/// Ajustes. Se guarda al tocar: no hay botón de guardar porque ningún ajuste
/// es destructivo y todos se ven en vivo en Hoy.
///
/// Sin mascota: «ajustes» está en la lista de pantallas prohibidas.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(SSettings.title)),
      body: ContentWidth(
        child: settings.when(
          loading: () => const MascotLoader(),
          error: (e, _) => Center(child: Text('$e')),
          data: (s) => _Loaded(settings: s),
        ),
      ),
    );
  }
}

Future<void> openSettings(BuildContext context) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => const SettingsScreen()),
  );
}

class _Loaded extends ConsumerWidget {
  const _Loaded({required this.settings});

  final UserSetting settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.read(settingsDaoProvider);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        SpaceTokens.screenMargin,
        SpaceTokens.m,
        SpaceTokens.screenMargin,
        SpaceTokens.xxxl,
      ),
      children: [
        const _SectionLabel(SSettings.sectionDepartures),
        _Card(
          children: [
            _Row(
              title: SSettings.buffer,
              subtitle: SSettings.bufferHint,
              trailing: Text(
                SSettings.bufferUnit(n: settings.bufferMinutos),
                style: context.type(TypeTokens.titleS),
              ),
            ),
            Slider(
              value: settings.bufferMinutos.toDouble(),
              min: DeparturePlanner.minBufferMinutes.toDouble(),
              max: DeparturePlanner.maxBufferMinutes.toDouble(),
              divisions: DeparturePlanner.maxBufferMinutes -
                  DeparturePlanner.minBufferMinutes,
              onChanged: (v) => dao.setBuffer(v.round()),
            ),
            SizedBox(height: SpaceTokens.s),
            _Row(title: SSettings.transportDefault),
            SizedBox(height: SpaceTokens.s),
            SegmentedButton<TransportMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: TransportMode.walk,
                  label: Text(STransport.walk),
                  icon: Icon(Icons.directions_walk),
                ),
                ButtonSegment(
                  value: TransportMode.bus,
                  label: Text(STransport.bus),
                  icon: Icon(Icons.directions_bus_outlined),
                ),
                ButtonSegment(
                  value: TransportMode.car,
                  label: Text(STransport.car),
                  icon: Icon(Icons.directions_car_outlined),
                ),
              ],
              selected: {settings.modoTransporte},
              onSelectionChanged: (set) {
                Haptics.fire('cambioTransporte');
                dao.setTransport(set.single);
              },
            ),
          ],
        ),
        SizedBox(height: SpaceTokens.xl),
        const _SectionLabel(SSettings.sectionSubjects),
        _Card(
          children: [
            _Row(
              title: SSettings.absenceLimitDefault,
              subtitle: SSettings.absenceLimitHint,
              trailing: _Stepper(
                value: settings.limiteFaltasPorDefecto,
                min: AttendanceCounter.minLimit,
                max: AttendanceCounter.maxLimit,
                onChanged: dao.setDefaultAbsenceLimit,
              ),
            ),
          ],
        ),
        SizedBox(height: SpaceTokens.xl),
        const _SectionLabel(SAlarms.section),
        _AlarmsCard(settings: settings),
        SizedBox(height: SpaceTokens.xl),
        const _SectionLabel(SSettings.sectionAppearance),
        _Card(
          children: [
            SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                    value: ThemeMode.system, label: Text(SSettings.themeAuto)),
                ButtonSegment(
                    value: ThemeMode.light, label: Text(SSettings.themeLight)),
                ButtonSegment(
                    value: ThemeMode.dark, label: Text(SSettings.themeDark)),
              ],
              selected: {
                ThemeMode
                    .values[settings.tema.clamp(0, ThemeMode.values.length - 1)]
              },
              onSelectionChanged: (set) => dao.setThemeIndex(set.single.index),
            ),
            SizedBox(height: SpaceTokens.l),
            _Row(
              title: SSettings.mascotCorner,
              subtitle: SSettings.mascotCornerHint,
              trailing: Switch(value: settings.mascotaEsquina, onChanged: dao.setMascotCorner),
            ),
          ],
        ),
      ],
    );
  }
}

/// Alarmas en el Reloj del teléfono y avisos de evaluación.
///
/// Las del Reloj se crean al tocar el botón, no solas: el Reloj no deja que
/// otra app borre alarmas, así que crearlas a espaldas de la persona cada vez
/// que cambia el horario llenaría el Reloj de copias.
class _AlarmsCard extends ConsumerStatefulWidget {
  const _AlarmsCard({required this.settings});

  final UserSetting settings;

  @override
  ConsumerState<_AlarmsCard> createState() => _AlarmsCardState();
}

class _AlarmsCardState extends ConsumerState<_AlarmsCard> {
  bool _busy = false;

  Future<void> _create() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    final created = await ref.read(createClockAlarmsProvider)();
    if (!mounted) return;
    setState(() => _busy = false);
    final text = switch (created) {
      null => SAlarms.failed,
      0 => SAlarms.none,
      final n => SAlarms.created(n: n),
    };
    messenger.showSnackBar(SnackBar(content: Text(text)));
    if (created != null && created > 0) {
      ref.read(mascotCornerProvider.notifier).react(MascotReaction.alarms);
    }
  }

  Future<void> _toggleEvals(bool on) async {
    await ref.read(settingsDaoProvider).setEvalAlarm(on);
    if (on) await ref.read(alarmChannelProvider).requestNotifications();
  }

  Future<void> _pickReminderTime() async {
    final m = widget.settings.avisoEvaluacionMin;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60),
    );
    if (picked != null) {
      await ref.read(settingsDaoProvider).setEvalReminderMinute(picked.hour * 60 + picked.minute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    final dao = ref.read(settingsDaoProvider);
    final b = Theme.of(context).brightness;

    return _Card(
      children: [
        Text(SAlarms.intro, style: context.type(TypeTokens.captionS, color: ColorTokens.textSecondary.of(b))),
        SizedBox(height: SpaceTokens.m),
        _Row(
          title: SAlarms.wake,
          subtitle: SAlarms.wakeDesc(n: s.alarmaDespertarMin),
          trailing: Switch(value: s.alarmaDespertar, onChanged: dao.setWakeAlarm),
        ),
        if (s.alarmaDespertar)
          Slider(
            value: s.alarmaDespertarMin.toDouble(),
            min: AlarmPlanner.minWakeMinutes.toDouble(),
            max: AlarmPlanner.maxWakeMinutes.toDouble(),
            divisions: (AlarmPlanner.maxWakeMinutes - AlarmPlanner.minWakeMinutes) ~/ AlarmPlanner.wakeStep,
            label: SAlarms.minutes(n: s.alarmaDespertarMin),
            onChanged: (v) => dao.setWakeMinutes(v.round()),
          ),
        SizedBox(height: SpaceTokens.s),
        _Row(
          title: SAlarms.leave,
          subtitle: SAlarms.leaveDesc,
          trailing: Switch(value: s.alarmaSalir, onChanged: dao.setLeaveAlarm),
        ),
        SizedBox(height: SpaceTokens.m),
        _Row(
          title: SAlarms.evals,
          subtitle: SAlarms.evalsDesc(hora: reminderLabel(s.avisoEvaluacionMin)),
          trailing: Switch(value: s.alarmaEvaluaciones, onChanged: _toggleEvals),
        ),
        if (s.alarmaEvaluaciones)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _pickReminderTime,
              icon: const Icon(Icons.schedule),
              label: Text('${SAlarms.evalHourLabel}: ${reminderLabel(s.avisoEvaluacionMin)}'),
            ),
          ),
        SizedBox(height: SpaceTokens.l),
        FilledButton.icon(
          onPressed: _busy || !(s.alarmaDespertar || s.alarmaSalir) ? null : _create,
          icon: const Icon(Icons.alarm_add),
          label: const Text(SAlarms.create),
        ),
        SizedBox(height: SpaceTokens.s),
        OutlinedButton.icon(
          onPressed: ref.read(alarmChannelProvider).showAlarms,
          icon: const Icon(Icons.alarm),
          label: const Text(SAlarms.openClock),
        ),
        SizedBox(height: SpaceTokens.s),
        Text(SAlarms.cantDelete, style: context.type(TypeTokens.captionS, color: ColorTokens.textTertiary.of(b))),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(left: SpaceTokens.xs, bottom: SpaceTokens.s),
        child: Text(
          text.toUpperCase(),
          style: context.type(TypeTokens.label,
              color: context.themed(ColorTokens.textTertiary)),
        ),
      );
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(SpaceTokens.cardPadding),
      decoration: BoxDecoration(
        color: ColorTokens.surfaceCard.of(b),
        borderRadius: BorderRadius.circular(RadiusTokens.card),
        border: Border.all(
            color: ColorTokens.surfaceBorder.of(b),
            width: BorderTokens.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.type(TypeTokens.bodyM)),
              if (subtitle != null) ...[
                SizedBox(height: SpaceTokens.xs / 2),
                Text(
                  subtitle!,
                  style: context.type(
                    TypeTokens.captionS,
                    color: ColorTokens.textTertiary.of(b),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          SizedBox(width: SpaceTokens.m),
          trailing!,
        ],
      ],
    );
  }
}

/// Menos / número / más. Para un entero pequeño es más directo que un campo
/// de texto con teclado: se ve el valor y se toca una vez por paso.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove),
          iconSize: IconTokens.sizeL,
        ),
        SizedBox(
          width: IconTokens.minTouchTarget,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: context.type(TypeTokens.titleS,
                color: ColorTokens.textPrimary.of(b)),
          ),
        ),
        IconButton(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add),
          iconSize: IconTokens.sizeL,
        ),
      ],
    );
  }
}
