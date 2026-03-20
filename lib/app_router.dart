import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/providers.dart';

import 'screens/onboarding/welcome_screen.dart';
import 'screens/onboarding/auth_screen.dart';
import 'screens/onboarding/familia_screen.dart';
import 'screens/home/main_scaffold.dart';
import 'screens/home/home_screen.dart';
import 'screens/movimiento/add_movimiento_screen.dart';
import 'screens/historial/historial_screen.dart';
import 'screens/estadisticas/estadisticas_screen.dart';
import 'screens/metas/metas_screen.dart';
import 'screens/sueldos/sueldos_screen.dart';
import 'screens/deudas/deudas_screen.dart';
import 'screens/mas/mas_screen.dart';
import 'screens/suscripciones/suscripciones_screen.dart';
import 'screens/configuracion/configuracion_screen.dart';


final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final familiaId = ref.watch(familiaIdProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      if (authState.isLoading) return null;
      final user = authState.value;
      final loc = state.matchedLocation;
      final goingToAuth = loc == '/' || loc == '/auth';

      if (user == null && !goingToAuth) return '/';
      if (user != null && familiaId == null && loc != '/familia_setup') return '/familia_setup';
      if (user != null && familiaId != null && (goingToAuth || loc == '/familia_setup')) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (c, s) => const WelcomeScreen()),
      GoRoute(path: '/auth', builder: (c, s) => const AuthScreen()),
      GoRoute(path: '/familia_setup', builder: (c, s) => const FamiliaScreen()),
      GoRoute(path: '/movimiento/add', builder: (c, s) => const AddMovimientoScreen()),

      ShellRoute(
        builder: (c, s, child) => MainScaffold(child: child),
        routes: [
          GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
          GoRoute(path: '/historial', builder: (c, s) => const HistorialScreen()),
          GoRoute(path: '/estadisticas', builder: (c, s) => const EstadisticasScreen()),
          GoRoute(path: '/metas', builder: (c, s) => const MetasScreen()),
          GoRoute(path: '/sueldos', builder: (c, s) => const SueldosScreen()),
          GoRoute(path: '/suscripciones', builder: (c, s) => const SuscripcionesScreen()),
          GoRoute(path: '/deudas', builder: (c, s) => const DeudasScreen()),
          GoRoute(path: '/mas', builder: (c, s) => const MasScreen()),
          GoRoute(path: '/configuracion', builder: (c, s) => const ConfiguracionScreen()),
        ],
      ),
    ],
  );
});
