import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';

class MainScaffold extends ConsumerWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  int _calculateIndex(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/historial')) return 1;
    if (location.startsWith('/estadisticas')) return 2;
    if (location.startsWith('/metas')) return 3;
    if (location.startsWith('/sueldos') || location.startsWith('/deudas') || location.startsWith('/suscripciones')) return 4;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0: context.go('/home'); break;
      case 1: context.go('/historial'); break;
      case 2: context.go('/estadisticas'); break;
      case 3: context.go('/metas'); break;
      case 4: context.go('/mas'); break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _calculateIndex(location);

    return Scaffold(
      body: child,
      floatingActionButton: currentIndex == 0 || currentIndex == 1
          ? FloatingActionButton(
              heroTag: 'fab_add',
              onPressed: () => context.push('/movimiento/add'),
              backgroundColor: AppTheme.accent,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => _onItemTapped(context, i),
        backgroundColor: AppTheme.surfaceDark,
        indicatorColor: AppTheme.accent.withValues(alpha: 0.2),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Historial'),
          NavigationDestination(icon: Icon(Icons.pie_chart_outline), selectedIcon: Icon(Icons.pie_chart), label: 'Stats'),
          NavigationDestination(icon: Icon(Icons.savings_outlined), selectedIcon: Icon(Icons.savings), label: 'Metas'),
          NavigationDestination(icon: Icon(Icons.more_horiz), selectedIcon: Icon(Icons.more_horiz), label: 'Mas'),
        ],
      ),
    );
  }
}
