import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../providers/providers.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/currency_input_formatter.dart';
import '../../core/theme/app_theme.dart';
import '../../models/deuda_manual.dart';
import '../../models/movimiento.dart';

class DeudasScreen extends ConsumerStatefulWidget {
  const DeudasScreen({super.key});

  @override
  ConsumerState<DeudasScreen> createState() => _DeudasScreenState();
}

class _DeudasScreenState extends ConsumerState<DeudasScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  void _mostrarAbonarDeuda(BuildContext context, WidgetRef ref, DeudaManual m) {
    final fid = ref.read(familiaIdProvider);
    if (fid == null) return;
    final montoCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Abonar a ${m.titulo}'),
        content: TextField(
          controller: montoCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [CurrencyInputFormatter()],
          decoration: const InputDecoration(labelText: 'Cantidad a abonar', prefixText: r'$'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final valStr = montoCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
              if (valStr.isEmpty) return;
              final monto = double.parse(valStr);

              // Registrar el abono
              await ref.read(deudaServiceProvider).abonarDeudaManual(fid, m.id, monto);
              if (ctx.mounted) Navigator.pop(ctx);

              // Preguntar si descontar del saldo
              if (ctx.mounted) {
                final descontar = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Descontar del saldo?'),
                    content: Text('El pago de ${CurrencyFormatter.format(monto)} a "${m.titulo}", desea registrarlo tambien como gasto y descontarlo del saldo total?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('No')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
                        onPressed: () => Navigator.pop(c, true),
                        child: const Text('Si, descontar', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                if (descontar == true) {
                  final authState = ref.read(authStateProvider).value;
                  final mov = Movimiento(
                    id: const Uuid().v4(),
                    tipo: 'gasto',
                    monto: monto,
                    categoria: 'deudas',
                    descripcion: 'Pago deuda: ${m.titulo}',
                    fecha: DateTime.now(),
                    autorId: authState?.uid ?? '',
                    autorNombre: authState?.displayName ?? 'Usuario',
                    tipoPago: 'personal',
                  );
                  await ref.read(movimientoServiceProvider).agregarMovimiento(fid, mov);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pago descontado del saldo')));
                  }
                }
              }
            },
            child: const Text('Abonar'),
          )
        ],
      ),
    );
  }

  void _mostrarAgregar(BuildContext context, WidgetRef ref) {
    final fid = ref.read(familiaIdProvider);
    if (fid == null) return;

    final tituloCtrl = TextEditingController();
    final montoCtrl = TextEditingController();
    final deudorCtrl = TextEditingController();
    final acreedorCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar Deuda Manual'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: tituloCtrl, decoration: const InputDecoration(labelText: 'Concepto (ej: Prestamo, Tarjeta)')),
              const SizedBox(height: 12),
              TextField(
                controller: montoCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                decoration: const InputDecoration(labelText: 'Monto total', prefixText: r'$'),
              ),
              const SizedBox(height: 12),
              TextField(controller: deudorCtrl, decoration: const InputDecoration(labelText: 'Quien debe? (Ej: Nosotros, Banco)')),
              const SizedBox(height: 12),
              TextField(controller: acreedorCtrl, decoration: const InputDecoration(labelText: 'A quien? (Ej: Banco, Juan)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (tituloCtrl.text.isEmpty || deudorCtrl.text.isEmpty || acreedorCtrl.text.isEmpty) return;
              final valStr = montoCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
              final monto = valStr.isEmpty ? 0.0 : double.parse(valStr);
              if (monto <= 0) return;
              final deuda = DeudaManual(
                id: const Uuid().v4(),
                titulo: tituloCtrl.text,
                monto: monto,
                deudor: deudorCtrl.text,
                acreedor: acreedorCtrl.text,
                pagado: 0.0,
                fechaCreacion: DateTime.now(),
              );
              await ref.read(deudaServiceProvider).agregarDeudaManual(fid, deuda);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fid = ref.watch(familiaIdProvider);
    if (fid == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final balancesCalculados = ref.watch(deudasProvider(fid));
    final manualesStream = ref.watch(deudasManualesStreamProvider(fid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deudas y Balance'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppTheme.accent,
          tabs: const [Tab(text: 'Balance Grupal'), Tab(text: 'Deudas Manuales')],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarAgregar(context, ref),
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          balancesCalculados.isEmpty
              ? const Center(child: Text('Las cuentas estan claras entre miembros.', style: TextStyle(color: AppTheme.textSecondary)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: balancesCalculados.length,
                  itemBuilder: (ctx, i) {
                    final d = balancesCalculados[i];
                    return Card(
                      color: AppTheme.cardDark,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${d['deudorNombre']} le debe a', style: const TextStyle(color: AppTheme.textSecondary)),
                                  Text(d['acreedorNombre'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.accent)),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textSecondary),
                            const SizedBox(width: 8),
                            Text(CurrencyFormatter.format(d['monto']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.error)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          manualesStream.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (manuales) {
              if (manuales.isEmpty) return const Center(child: Text('No hay deudas manuales registradas', style: TextStyle(color: AppTheme.textSecondary)));
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: manuales.length,
                itemBuilder: (ctx, i) {
                  final m = manuales[i];
                  final pct = m.monto > 0 ? (m.pagado / m.monto).clamp(0.0, 1.0) : 0.0;
                  final pagada = pct >= 1.0;
                  return Card(
                    color: AppTheme.cardDark,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(m.titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 2),
                                    Text('${m.deudor} le debe a ${m.acreedor}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: AppTheme.accent),
                                    tooltip: 'Abonar',
                                    onPressed: () => _mostrarAbonarDeuda(context, ref, m),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                                    tooltip: 'Eliminar',
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (c) => AlertDialog(
                                          title: const Text('Eliminar deuda'),
                                          content: const Text('Se borrara esta deuda de la lista. Continuar?'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('No')),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                                              onPressed: () => Navigator.pop(c, true),
                                              child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) await ref.read(deudaServiceProvider).eliminarDeudaManual(fid, m.id);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: pct,
                            color: pagada ? Colors.green : AppTheme.accent,
                            backgroundColor: AppTheme.surfaceDark,
                            minHeight: 10,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                pagada ? 'Deuda pagada!' : 'Pagado: ${(pct * 100).toStringAsFixed(1)}%',
                                style: TextStyle(color: pagada ? Colors.green : AppTheme.textSecondary, fontSize: 12, fontWeight: pagada ? FontWeight.bold : FontWeight.normal),
                              ),
                              Text('${CurrencyFormatter.format(m.pagado)} / ${CurrencyFormatter.format(m.monto)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}