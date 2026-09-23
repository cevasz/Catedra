import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../l10n/strings.g.dart';
import '../../../theme/layout.dart';
import '../../../theme/motion.dart';
import '../../../theme/tokens.g.dart';
import '../../map/presentation/map_screen.dart';
import '../../schedule/presentation/week_screen.dart';
import '../../subjects/presentation/subjects_screen.dart';
import '../../today/presentation/today_screen.dart';
import '../../updates/application/update_providers.dart';
import '../../updates/presentation/update_sheet.dart';

/// Posición de cada pestaña. Quien quiera saltar a una desde otra pantalla
/// escribe uno de estos en `shellTabProvider`, no un número suelto.
abstract final class ShellTab {
  static const int today = 0;
  static const int week = 1;
  static const int subjects = 2;
  static const int map = 3;
}

/// Las cuatro pestañas del prototipo. La navegación entre ellas NUNCA vibra:
/// está en la lista `never` del contrato háptico.
///
/// En teléfono es la barra inferior del prototipo. Desde `medium` pasa a un
/// riel lateral: en una pantalla ancha una barra abajo queda lejos del pulgar
/// y roba una franja entera de alto que el contenido sí aprovecha.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const _screens = <Widget>[
    TodayScreen(),
    WeekScreen(),
    SubjectsScreen(),
    MapScreen(),
  ];

  static const _icons = <IconData>[
    Icons.schedule_outlined,
    Icons.calendar_today_outlined,
    Icons.menu_book_outlined,
    Icons.place_outlined,
  ];

  /// Relleno cuando la pestaña está activa: la forma dice dónde estás aunque
  /// el color no se distinga.
  static const _selectedIcons = <IconData>[
    Icons.schedule,
    Icons.calendar_today,
    Icons.menu_book,
    Icons.place,
  ];

  static const _labels = <String>[STabs.today, STabs.week, STabs.subjects, STabs.map];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Al abrir, mira si hay una versión nueva publicada. Sin red no pasa nada.
    ref.listen<AsyncValue<UpdateCheck>>(updateCheckProvider, (_, next) {
      final update = next.valueOrNull?.available;
      if (update != null) showUpdateBanner(context, ref, update);
    });
    final index = ref.watch(shellTabProvider);
    final size = context.sizeClass;
    void select(int i) => ref.read(shellTabProvider.notifier).state = i;

    final body = IndexedStack(index: index, children: _screens);

    if (size.hasRail) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: index,
              onDestinationSelected: select,
              groupAlignment: -1,
              destinations: [
                for (var i = 0; i < _screens.length; i++)
                  NavigationRailDestination(
                    icon: Icon(_icons[i]),
                    selectedIcon: Icon(_selectedIcons[i]),
                    label: Text(_labels[i]),
                    padding: EdgeInsets.symmetric(vertical: SpaceTokens.xs),
                  ),
              ],
            ),
            const VerticalDivider(),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: select,
        destinations: [
          for (var i = 0; i < _screens.length; i++)
            NavigationDestination(
              icon: _NavBounceIcon(
                icon: i == index ? _selectedIcons[i] : _icons[i],
                isSelected: i == index,
              ),
              label: _labels[i],
            ),
        ],
      ),
    );
  }
}

/// Ícono de navegación con micro-rebote elástico al ser seleccionado.
class _NavBounceIcon extends StatelessWidget {
  const _NavBounceIcon({required this.icon, required this.isSelected});

  final IconData icon;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isSelected ? 1.08 : 1.0,
      duration: MotionDurations.fast,
      curve: MotionCurves.easeOutBackBounce,
      child: Icon(icon),
    );
  }
}
