import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../providers/providers.dart';
import '../../models/suscripcion.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/currency_input_formatter.dart';
import '../../core/theme/app_theme.dart';
import '../../models/movimiento.dart';

class SuscripcionesScreen extends ConsumerWidget {
  const SuscripcionesScreen({super.key});

  void _mostrarAgregar(BuildContext context, WidgetRef ref) {
    final fid = ref.read(familiaIdProvider);
    if (fid == null) return;
    final nombreCtrl = TextEditingController();
    final montoCtrl = TextEditingController();
    bool esFijo = true;
    int diaCobro = 1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setDlgState) => AlertDialog(
          title: const Text('Nueva Suscripción / Gasto Fijo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre (ej: Netflix, Luz)')),
                const SizedBox(height: 12),
                TextField(
                  controller: montoCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                  decoration: const InputDecoration(labelText: 'Monto predeterminado', prefixText: r'$'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Tipo: '),
                    const SizedBox(width: 12),
                    ChoiceChip(label: const Text('Fijo'), selected: esFijo, onSelected: (_) => setDlgState(() => esFijo = true)),
                    const SizedBox(width: 8),
                    ChoiceChip(label: const Text('Variable'), selected: !esFijo, onSelected: (_) => setDlgState(() => esFijo = false)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.event_repeat, size: 18),
                    const SizedBox(width: 8),
                    const Text('Día de cobro:'),
                    const SizedBox(width: 12),
                    DropdownButton<int>(
                      value: diaCobro,
                      items: List.generate(28, (i) => i + 1)
                          .map((d) => DropdownMenuItem(value: d, child: Text('Día $d')))
                          .toList(),
                      onChanged: (v) => setDlgState(() => diaCobro = v!),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (nombreCtrl.text.isEmpty) return;
                final valStr = montoCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
                final monto = valStr.isEmpty ? 0.0 : double.parse(valStr);
                final s = Suscripcion(
                  id: const Uuid().v4(),
                  nombre: nombreCtrl.text.trim(),
                  montoPredeterminado: monto,
                  categoria: 'servicios',
                  esFijo: esFijo,
                  diaCobro: diaCobro,
                  activa: true,
                );
                await ref.read(suscripcionServiceProvider).agregarSuscripcion(fid, s);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fid = ref.watch(familiaIdProvider);
    if (fid == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final suscs = ref.watch(suscripcionesStreamProvider(fid));

    return Scaffold(
      appBar: AppBar(title: const Text('Suscripciones y Gastos Fijos')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarAgregar(context, ref),
        child: const Icon(Icons.add),
      ),
      body: suscs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) return const Center(child: Text('No hay suscripciones registradas.', style: TextStyle(color: AppTheme.textSecondary)));
          final fijo = list.where((s) => s.esFijo).toList();
          final variable = list.where((s) => !s.esFijo).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (fijo.isNotEmpty) ...[
                _SectionHeader(label: 'Gastos Fijos Mensuales', total: fijo.fold(0.0, (s, x) => s + x.montoPredeterminado)),
                ...fijo.map((s) => _SuscripcionTile(susc: s, fid: fid, ref: ref)),
              ],
              if (variable.isNotEmpty) ...[
                const SizedBox(height: 12),
                _SectionHeader(label: 'Gastos Variables', total: variable.fold(0.0, (s, x) => s + x.montoPredeterminado)),
                ...variable.map((s) => _SuscripcionTile(susc: s, fid: fid, ref: ref)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final double total;
  const _SectionHeader({required this.label, required this.total});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(CurrencyFormatter.format(total), style: const TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _SuscripcionTile extends StatelessWidget {
  final Suscripcion susc;
  final String fid;
  final WidgetRef ref;
  const _SuscripcionTile({required this.susc, required this.fid, required this.ref});

  Future<void> _descontarEsteMes(BuildContext context) async {
    final user = ref.read(miembroActualProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo identificar tu usuario.'), backgroundColor: Colors.red),
      );
      return;
    }

    // Verificar si ya fue descontado este mes
    final now = DateTime.now();
    final inicioMes = DateTime(now.year, now.month, 1);
    final movs = ref.read(movimientosStreamProvider(fid)).value ?? [];
    final yaDescontado = movs.any((m) =>
      m.descripcion == susc.nombre &&
      m.esGasto &&
      !m.fecha.isBefore(inicioMes)
    );

    if (yaDescontado) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${susc.nombre} ya fue descontado este mes.'),
          backgroundColor: Colors.orange.shade700,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Descontar ${susc.nombre}'),
        content: Text(
          'Se registrará un gasto de ${CurrencyFormatter.format(susc.montoPredeterminado)} para este mes.\n\n¿Confirmás?'
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Descontar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final mov = Movimiento(
      id: const Uuid().v4(),
      tipo: 'gasto',
      monto: susc.montoPredeterminado,
      categoria: susc.categoria,
      descripcion: susc.nombre,
      fecha: DateTime.now(),
      autorId: user.id,
      autorNombre: user.nombre,
      esSueldo: false,
      tipoPago: 'compartido',
    );

    await ref.read(movimientoServiceProvider).agregarMovimiento(fid, mov);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('${susc.nombre} descontado del mes ✓'),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Verificar si ya fue descontado este mes para mostrar indicador
    final now = DateTime.now();
    final inicioMes = DateTime(now.year, now.month, 1);
    final movs = ref.watch(movimientosStreamProvider(fid)).value ?? [];
    final yaDescontado = movs.any((m) =>
      m.descripcion == susc.nombre &&
      m.esGasto &&
      !m.fecha.isBefore(inicioMes)
    );

    return Card(
      color: AppTheme.cardDark,
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: yaDescontado
                  ? Colors.green.withValues(alpha: 0.15)
                  : AppTheme.accent.withValues(alpha: 0.15),
              child: Icon(
                yaDescontado ? Icons.check_circle : Icons.subscriptions,
                color: yaDescontado ? Colors.green : AppTheme.accent,
              ),
            ),
            title: Text(susc.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Día ${susc.diaCobro} de cada mes · ${susc.esFijo ? "Fijo" : "Variable"}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(CurrencyFormatter.format(susc.montoPredeterminado), style: const TextStyle(fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Eliminar suscripción'),
                        content: Text('Se eliminará "${susc.nombre}" de la lista.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('No')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                            onPressed: () => Navigator.pop(c, true),
                            child: const Text('Sí', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await ref.read(suscripcionServiceProvider).eliminarSuscripcion(fid, susc.id);
                    }
                  },
                  child: const Icon(Icons.delete_outline, color: AppTheme.error, size: 18),
                ),
              ],
            ),
          ),
          // Botón "Descontar este mes"
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: SizedBox(
              width: double.infinity,
              child: yaDescontado
                ? OutlinedButton.icon(
                    icon: const Icon(Icons.check, color: Colors.green, size: 16),
                    label: const Text('Ya descontado este mes', style: TextStyle(color: Colors.green)),
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.green),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  )
                : ElevatedButton.icon(
                    icon: const Icon(Icons.remove_circle_outline, size: 16),
                    label: const Text('Descontar este mes'),
                    onPressed: () => _descontarEsteMes(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error.withValues(alpha: 0.15),
                      foregroundColor: AppTheme.error,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 0,
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
