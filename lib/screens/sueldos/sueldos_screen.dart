import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../providers/providers.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/currency_input_formatter.dart';
import '../../core/theme/app_theme.dart';
import '../../models/movimiento.dart';

class SueldosScreen extends ConsumerWidget {
  const SueldosScreen({super.key});

  void _mostrarEditAporte(BuildContext context, WidgetRef ref, String miembroId, String nombreBase, double aporteActual) {
    final fid = ref.read(familiaIdProvider);
    if (fid == null) return;

    final montoCtrl = TextEditingController(text: aporteActual > 0 ? aporteActual.toInt().toString() : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sueldo de $nombreBase'),
        content: TextField(
          controller: montoCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [CurrencyInputFormatter()],
          decoration: const InputDecoration(labelText: 'Ingreso aportado este mes', prefixText: r'$'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final valStr = montoCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
              final val = valStr.isEmpty ? 0.0 : double.parse(valStr);
              final mes = DateFormatter.mesAnioKey(DateTime.now());

              // 1. Guardar en la coleccion de sueldos (para el resumen de presupuesto)
              await ref.read(sueldoServiceProvider).actualizarAporte(fid, mes, miembroId, val);

              // 2. Eliminar el movimiento de sueldo anterior de este miembro en este mes si existe
              final movService = ref.read(movimientoServiceProvider);
              final movs = ref.read(movimientosStreamProvider(fid)).value ?? [];
              final now = DateTime.now();
              final inicioMes = DateTime(now.year, now.month, 1);
              final anterior = movs.where((m) =>
                m.esSueldo &&
                m.autorId == miembroId &&
                !m.fecha.isBefore(inicioMes)
              ).toList();
              for (final a in anterior) {
                await movService.marcarComoError(fid, a.id);
              }

              // 3. Crear nuevo movimiento de ingreso tipo sueldo
              if (val > 0) {
                final mov = Movimiento(
                  id: const Uuid().v4(),
                  tipo: 'ingreso',
                  monto: val,
                  categoria: 'sueldo',
                  descripcion: 'Sueldo de $nombreBase',
                  fecha: DateTime.now(),
                  autorId: miembroId,
                  autorNombre: nombreBase,
                  esSueldo: true,
                  tipoPago: 'personal',
                );
                await movService.agregarMovimiento(fid, mov);
              }

              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fid = ref.watch(familiaIdProvider);
    if (fid == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final miembrosAsync = ref.watch(miembrosStreamProvider(fid));
    final sueldoMesAsync = ref.watch(sueldoMesActualProvider(fid));

    return Scaffold(
      appBar: AppBar(title: const Text('Sueldos del Mes')),
      body: miembrosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (miembros) {
          final sueldoData = sueldoMesAsync.value;
          final aportes = sueldoData?.aportes ?? {};
          final total = sueldoData?.totalFamiliar ?? 0.0;

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                color: AppTheme.cardDark,
                child: Column(
                  children: [
                    const Text('Total Presupuestado Familiar', style: TextStyle(color: AppTheme.textSecondary)),
                    const SizedBox(height: 8),
                    Text(CurrencyFormatter.format(total), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.accent)),
                    const SizedBox(height: 4),
                    const Text('(Se suma al saldo total automaticamente)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: miembros.length,
                  itemBuilder: (ctx, i) {
                    final m = miembros[i];
                    final aporte = aportes[m.id] ?? 0.0;
                    return Card(
                      color: AppTheme.cardDark,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(child: Text(m.nombre.isNotEmpty ? m.nombre[0].toUpperCase() : '?')),
                        title: Text(m.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Sueldo aportado: ${CurrencyFormatter.format(aporte)}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, color: AppTheme.accent),
                          onPressed: () => _mostrarEditAporte(context, ref, m.id, m.nombre, aporte),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}