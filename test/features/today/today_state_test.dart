import 'package:catedra/core/db/daos/schedule_dao.dart';
import 'package:catedra/core/db/database.dart';
import 'package:catedra/core/providers.dart';
import 'package:catedra/domain/attendance/attendance.dart';
import 'package:catedra/domain/departure/departure.dart';
import 'package:catedra/features/today/application/today_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _day = DateTime(2026, 9, 8); // martes

DayClass _clase({
  required int id,
  required int inicio,
  required int fin,
  SessionStatus estado = SessionStatus.pendiente,
  DateTime? marcadaEn,
}) =>
    DayClass(
      instance: SessionInstance(
        id: id,
        sessionId: id,
        fecha: _day,
        estado: estado,
        marcadaEn: marcadaEn,
      ),
      session: ClassSession(
        id: id,
        subjectId: 1,
        diaSemana: 2,
        horaInicio: inicio,
        horaFin: fin,
      ),
      subject: const Subject(
        id: 1,
        semesterId: 1,
        nombre: 'Bases de datos',
        colorIndex: 0,
        limiteFaltas: 6,
        archivada: false,
      ),
    );

const _settings = UserSetting(
  id: 1,
  bufferMinutos: 4,
  modoTransporte: TransportMode.bus,
  tema: 0,
  limiteFaltasPorDefecto: 6,
);

/// Monta el provider de Hoy con clases, hora y ajustes fijos. Nada toca la BD.
Future<TodayState> _state(List<DayClass> classes, {required int hour, required int minute}) async {
  final now = DateTime(_day.year, _day.month, _day.day, hour, minute);
  final container = ProviderContainer(overrides: [
    todayProvider.overrideWith((ref) => _day),
    todayClassesProvider.overrideWith((ref) => Stream.value(classes)),
    clockProvider.overrideWith((ref) => Stream.value(now)),
    settingsProvider.overrideWith((ref) => Stream.value(_settings)),
  ]);
  addTearDown(container.dispose);

  // Se espera el primer valor de los tres streams para que el provider
  // derivado no vea el loading.
  await container.read(todayClassesProvider.future);
  await container.read(clockProvider.future);
  await container.read(settingsProvider.future);
  return container.read(todayStateProvider).requireValue;
}

void main() {
  group('todayStateProvider', () {
    test('la próxima es la primera que no ha terminado', () async {
      final s = await _state(
        [_clase(id: 1, inicio: 480, fin: 600), _clase(id: 2, inicio: 840, fin: 960)],
        hour: 10,
        minute: 30,
      );
      expect(s.next?.instance.id, 2);
      expect(s.isDone, isFalse);
    });

    test('una cancelada se salta y queda como noticia hasta su hora de fin', () async {
      final s = await _state(
        [
          _clase(
            id: 1,
            inicio: 600,
            fin: 720,
            estado: SessionStatus.canceladaProfe,
            marcadaEn: DateTime(2026, 9, 8, 9, 40),
          ),
          _clase(id: 2, inicio: 840, fin: 960),
        ],
        hour: 9,
        minute: 43,
      );
      expect(s.next?.instance.id, 2);
      expect(s.cancelled?.instance.id, 1);
      expect(s.minutesSinceCancelled, 3, reason: 'es el «Marcada hace 3 min» de B3');
    });

    test('pasada su hora, la cancelada deja de ser noticia', () async {
      final s = await _state(
        [_clase(id: 1, inicio: 600, fin: 720, estado: SessionStatus.canceladaProfe)],
        hour: 12,
        minute: 1,
      );
      expect(s.cancelled, isNull);
      expect(s.isDone, isTrue);
    });

    test('«ya voy» avanza la card a la clase de después', () async {
      final s = await _state(
        [
          _clase(id: 1, inicio: 600, fin: 720, estado: SessionStatus.asistio),
          _clase(id: 2, inicio: 840, fin: 960),
        ],
        hour: 9,
        minute: 50,
      );
      expect(s.next?.instance.id, 2);
      expect(s.isUrgent, isFalse);
    });

    test('sin nada por delante el día está hecho, no vacío', () async {
      final s = await _state([_clase(id: 1, inicio: 480, fin: 600)], hour: 18, minute: 0);
      expect(s.isEmpty, isFalse);
      expect(s.isDone, isTrue);
      expect(s.plan, isNull);
    });

    test('el plan usa el buffer y el transporte de Ajustes', () async {
      final s = await _state([_clase(id: 1, inicio: 600, fin: 720)], hour: 8, minute: 0);
      final plan = s.plan!;
      expect(plan.mode, TransportMode.bus);
      expect(plan.bufferMinutes, 4);
      expect(plan.travelMinutes, DeparturePlanner.fallbackTravelMinutes[TransportMode.bus]);
      // 10:00 − 35 de bus − 4 de buffer = 9:21.
      expect(plan.leaveAt.hhmm, '9:21');
    });

    test('los huecos se miden entre clases vivas y saltan la cancelada', () async {
      final s = await _state(
        [
          _clase(id: 1, inicio: 480, fin: 600),
          _clase(id: 2, inicio: 600, fin: 720, estado: SessionStatus.canceladaProfe),
          _clase(id: 3, inicio: 840, fin: 960),
        ],
        hour: 7,
        minute: 0,
      );
      // Tras la clase 1 quedan libres 10:00–14:00: cuatro horas, no dos.
      expect(s.gapsAfter.keys, [1]);
      expect(s.gapsAfter[1]!.minutes, 240);
    });

    test('un cambio de salón no aparece como hueco', () async {
      final s = await _state(
        [_clase(id: 1, inicio: 480, fin: 600), _clase(id: 2, inicio: 615, fin: 720)],
        hour: 7,
        minute: 0,
      );
      expect(s.gapsAfter, isEmpty);
    });
  });
}
