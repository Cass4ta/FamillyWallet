import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../core/widgets/termometro_widget.dart';
import '../../core/widgets/movimiento_tile.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/theme/app_theme.dart';
import '../finance_bot/finance_bot_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familiaId = ref.watch(familiaIdProvider);
    if (familiaId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final familiaInfo = ref.watch(familiaStreamProvider(familiaId));
    final termEstado = ref.watch(termometroProvider(familiaId));
    final resumenMes = ref.watch(resumenMesProvider(familiaId));
    final saldoTotal = ref.watch(saldoTotalProvider(familiaId));
    final allMovs = ref.watch(movimientosStreamProvider(familiaId)).value ?? [];
    final ultimos = allMovs.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 120,
        leading: const Center(
          child: Padding(
            padding: EdgeInsets.only(left: 16),
            child: Text(
              'FamilyWallet',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
        title: Text(familiaInfo.value?.nombre ?? 'FamilyWallet'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.group),
            tooltip: 'Código de familia',
            onPressed: () {
              final code = familiaInfo.value?.codigoInvitacion ?? '';
              showDialog(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Código Familia'),
                  content: Text(
                    code,
                    style: const TextStyle(fontSize: 32, letterSpacing: 8),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.smart_toy, color: AppTheme.accent),
            tooltip: 'FinanceBot',
            onPressed: () => FinanceBotSheet.show(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: ListView(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
          children: [
            // Total balance
            Center(
              child: Column(
                children: [
                  const Text(
                    'Saldo Total Familiar',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(saldoTotal),
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 40),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Budget thermometer
            TermometroWidget(
              estado: termEstado,
              gastosMes: resumenMes.gastos,
              sueldoFamiliar: resumenMes.ingresos,
            ),
            const SizedBox(height: 16),

            // Quick-access shortcuts
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.cardDark,
                      foregroundColor: AppTheme.textPrimary,
                    ),
                    icon: const Icon(Icons.attach_money),
                    label: const Text('Sueldos'),
                    onPressed: () => context.push('/sueldos'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.cardDark,
                      foregroundColor: AppTheme.textPrimary,
                    ),
                    icon: const Icon(Icons.handshake),
                    label: const Text('Deudas'),
                    onPressed: () => context.push('/deudas'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent movements
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Últimos Movimientos',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                TextButton(
                  onPressed: () => context.go('/historial'),
                  child: const Text('Ver todos'),
                ),
              ],
            ),

            if (ultimos.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No hay movimientos registrados.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              )
            else
              ...ultimos.map((m) {
                final colorIndex = m.autorNombre.isNotEmpty
                    ? m.autorNombre.codeUnitAt(0) % 5
                    : 0;
                return MovimientoTile(movimiento: m, autorColorIndex: colorIndex);
              }),
          ],
        ),
      ),
    );
  }
}
