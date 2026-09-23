import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/alarm_channel.dart';
import '../../../core/providers.dart';
import '../../../core/time/minutes_of_day.dart';
import '../../../domain/alarms/alarm_planner.dart';
import '../../../domain/departure/departure.dart';
import '../../../l10n/strings.g.dart';
import '../../tasks/application/tasks_providers.dart';

final alarmChannelProvider = Provider<AlarmChannel>((ref) => const AlarmChannel());

/// Minutos entre inicio de clase y hora de salir: trayecto + buffer, igual
/// que Hoy y los widgets.
int leaveOffsetOf(({TransportMode mode, int? travel, int buffer}) s) =>
    DeparturePlanner.travelMinutesFor(s.mode, s.travel) + s.buffer;

/// Qué alarmas saldrían hoy con el horario y los ajustes actuales.
Future<List<(PlannedAlarm, String)>> plannedClockAlarms(Ref ref) async {
  final settings = await ref.read(settingsDaoProvider).get();
  final sessions = await ref.read(scheduleDaoProvider).watchLiveSessions().first;
  final alarms = AlarmPlanner.weekly(
    classes: [
      for (final (session, subject, _) in sessions)
        WeeklyClass(
          subject: subject.nombre,
          weekday: session.diaSemana,
          start: session.horaInicio,
          end: session.horaFin,
        ),
    ],
    leaveOffset: leaveOffsetOf((
      mode: settings.modoTransporte,
      travel: settings.trayectoMinutos,
      buffer: settings.bufferMinutos,
    )),
    wake: settings.alarmaDespertar,
    wakeMinutes: settings.alarmaDespertarMin,
    leave: settings.alarmaSalir,
    travelMinutes: DeparturePlanner.travelMinutesFor(settings.modoTransporte, settings.trayectoMinutos),
  );
  return [
    for (final a in alarms)
      (a, a.kind == AlarmKind.wake ? SAlarms.wakeLabel : SAlarms.leaveLabel(clase: a.subject!)),
  ];
}

/// Crea las alarmas en el Reloj. Devuelve cuántas creó, o null si el teléfono
/// no tiene una app de reloj que las acepte.
final createClockAlarmsProvider = Provider<Future<int?> Function()>((ref) {
  return () async {
    final channel = ref.read(alarmChannelProvider);
    if (!await channel.canSetAlarms()) return null;
    return channel.setAlarms(await plannedClockAlarms(ref));
  };
});

/// Mantiene programados los avisos de la víspera de cada evaluación. Se
/// activa con un `ref.watch` en la raíz de la app, igual que los widgets.
final evalRemindersSyncProvider = Provider<void>((ref) {
  if (kIsWeb || !Platform.isAndroid) return;
  final settings = ref.watch(settingsProvider).valueOrNull;
  final pending = ref.watch(pendingProvider).valueOrNull;
  if (settings == null || pending == null) return;

  final evaluations = settings.alarmaEvaluaciones
      ? [
          for (final p in pending)
            if (p.evaluation != null && p.evaluation!.fecha != null)
              DatedEvaluation(
                id: p.evaluation!.id,
                name: p.evaluation!.nombre,
                subject: p.subject.nombre,
                date: p.evaluation!.fecha!,
              ),
        ]
      : const <DatedEvaluation>[];

  final reminders = AlarmPlanner.evaluationReminders(
    evaluations: evaluations,
    reminderMinute: settings.avisoEvaluacionMin,
    now: DateTime.now(),
  );
  unawaited(ref.read(alarmChannelProvider).scheduleReminders(
        channelName: SAlarms.evals,
        items: [
          for (final r in reminders)
            (
              id: r.evaluation.id,
              at: r.at,
              title: SAlarms.evalTitle(eval: r.evaluation.name),
              body: SAlarms.evalBodyNoTime(clase: r.evaluation.subject),
            ),
        ],
      ));
});

/// «20:00», para el ajuste de la hora del aviso.
String reminderLabel(int minute) => MinutesOfDay(minute).hhmm;
