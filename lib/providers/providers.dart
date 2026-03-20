// providers/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/familia_service.dart';
import '../services/movimiento_service.dart';
import '../services/meta_service.dart';
import '../services/sueldo_service.dart';
import '../services/deuda_service.dart';
import '../services/finance_bot_service.dart';
import '../services/suscripcion_service.dart';
import '../models/movimiento.dart';
import '../core/utils/currency_formatter.dart';

// â”€â”€ SERVICIOS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final familiaServiceProvider = Provider<FamiliaService>((ref) => FamiliaService());
final movimientoServiceProvider = Provider<MovimientoService>((ref) => MovimientoService());
final metaServiceProvider = Provider<MetaService>((ref) => MetaService());
final sueldoServiceProvider = Provider<SueldoService>((ref) => SueldoService());
final deudaServiceProvider = Provider<DeudaService>((ref) => DeudaService());
final suscripcionServiceProvider = Provider<SuscripcionService>((ref) => SuscripcionService());

final suscripcionesStreamProvider = StreamProvider.family((ref, String fid) =>
    ref.watch(suscripcionServiceProvider).getSuscripcionesStream(fid));

final financeBotServiceProvider = Provider<FinanceBotService>((ref) {
  final bot = FinanceBotService();
  bot.init();
  return bot;
});

// â”€â”€ AUTH â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
final authStateProvider = StreamProvider<User?>((ref) =>
    ref.watch(authServiceProvider).authStateChanges);

// â”€â”€ FAMILIA ID â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
final familiaIdProvider = StateProvider<String?>((ref) => null);

// â”€â”€ FAMILIA + MIEMBROS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
final familiaStreamProvider = StreamProvider.family((ref, String fid) =>
    ref.watch(familiaServiceProvider).getFamiliaStream(fid));

final miembrosStreamProvider = StreamProvider.family((ref, String fid) =>
    ref.watch(familiaServiceProvider).getMiembrosStream(fid));

final miembroActualProvider = Provider((ref) {
  final user = ref.watch(authStateProvider).value;
  final fid = ref.watch(familiaIdProvider);
  if (user == null || fid == null) return null;
  final ms = ref.watch(miembrosStreamProvider(fid)).value ?? [];
  try {
    return ms.firstWhere((m) => m.id == user.uid);
  } catch (_) {
    return null;
  }
});

// â”€â”€ MOVIMIENTOS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
final movimientosStreamProvider = StreamProvider.family((ref, String fid) =>
    ref.watch(movimientoServiceProvider).getMovimientosStream(fid));

// â”€â”€ SALDO TOTAL HISTORICO â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
final saldoTotalProvider = Provider.family<double, String>((ref, fid) {
  final movs = ref.watch(movimientosStreamProvider(fid)).value ?? [];
  return movs.fold(0.0, (sum, m) => m.esIngreso ? sum + m.monto : sum - m.monto);
});

// â”€â”€ RESUMEN MES ACTUAL â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
final resumenMesProvider = Provider.family<ResumenMes, String>((ref, fid) {
  final now = DateTime.now();
  final inicio = DateTime(now.year, now.month, 1);
  final movs = ref.watch(movimientosStreamProvider(fid)).value ?? [];
  final mes = movs.where((m) => !m.fecha.isBefore(inicio)).toList();
  final ing = mes.where((m) => m.esIngreso).fold(0.0, (s, m) => s + m.monto);
  final gas = mes.where((m) => m.esGasto).fold(0.0, (s, m) => s + m.monto);
  return ResumenMes(ingresos: ing, gastos: gas, movimientos: mes);
});

// â”€â”€ SUELDOS MES ACTUAL â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
final sueldoMesActualProvider = StreamProvider.family((ref, String fid) {
  final mes = DateFormatter.mesAnioKey(DateTime.now());
  return ref.watch(sueldoServiceProvider).getSueldoMesStream(fid, mes);
});

// â”€â”€ TERMOMETRO â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

// -- RESUMEN MES ANTERIOR --
final resumenMesAnteriorProvider = Provider.family<ResumenMesAnterior, String>((ref, fid) {
  final now = DateTime.now();
  final firstDayThisMonth = DateTime(now.year, now.month, 1);
  final firstDayLastMonth = DateTime(now.year, now.month - 1, 1);
  final movs = ref.watch(movimientosStreamProvider(fid)).value ?? [];
  final mes = movs.where((m) => !m.fecha.isBefore(firstDayLastMonth) && m.fecha.isBefore(firstDayThisMonth)).toList();
  final Map<String, double> gastosCat = {};
  for (final m in mes) {
    if (m.esGasto) gastosCat[m.categoria] = (gastosCat[m.categoria] ?? 0) + m.monto;
  }
  final gas = mes.where((m) => m.esGasto).fold(0.0, (s, m) => s + m.monto);
  return ResumenMesAnterior(gastos: gas, gastosPorCat: gastosCat);
});

enum EstadoTermometro { verde, amarillo, rojo, sinDatos }

final termometroProvider = Provider.family<EstadoTermometro, String>((ref, fid) {
  final resumen = ref.watch(resumenMesProvider(fid));
  final presupuestoTotal = resumen.ingresos;
  if (presupuestoTotal <= 0) return EstadoTermometro.sinDatos;
  final now = DateTime.now();
  final diasEnMes = DateTime(now.year, now.month + 1, 0).day;
  final proyeccion = (resumen.gastos / now.day.clamp(1, 31)) * diasEnMes;
  final pct = proyeccion / presupuestoTotal;
  if (pct < 0.70) return EstadoTermometro.verde;
  if (pct < 0.95) return EstadoTermometro.amarillo;
  return EstadoTermometro.rojo;
});

// â”€â”€ METAS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
final metasStreamProvider = StreamProvider.family((ref, String fid) =>
    ref.watch(metaServiceProvider).getMetasStream(fid));

// â”€â”€ DEUDAS DEL MES â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
final deudasProvider = Provider.family((ref, String fid) {
  final now = DateTime.now();
  final inicio = DateTime(now.year, now.month, 1);
  final movs = (ref.watch(movimientosStreamProvider(fid)).value ?? [])
      .where((m) => !m.fecha.isBefore(inicio)).toList();
  final miembros = ref.watch(miembrosStreamProvider(fid)).value ?? [];
  return ref.watch(deudaServiceProvider).calcularDeudas(movimientos: movs, miembros: miembros);
});

// â”€â”€ TEMA â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
final isDarkModeProvider = StateProvider<bool>((ref) => true);

// â”€â”€ HELPER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class ResumenMes {
  final double ingresos;
  final double gastos;
  final List<Movimiento> movimientos;
  const ResumenMes({required this.ingresos, required this.gastos, required this.movimientos});
  double get saldo => ingresos - gastos;
}

class ResumenMesAnterior {
  final double gastos;
  final Map<String, double> gastosPorCat;
  const ResumenMesAnterior({required this.gastos, required this.gastosPorCat});
}

final deudasManualesStreamProvider = StreamProvider.family((ref, String fid) =>
    ref.watch(deudaServiceProvider).getDeudasManualesStream(fid));

