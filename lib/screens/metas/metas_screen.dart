import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../providers/providers.dart';
import '../../models/meta.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/currency_input_formatter.dart';
import '../../core/theme/app_theme.dart';
import '../../models/movimiento.dart';

class MetasScreen extends ConsumerWidget {
  const MetasScreen({super.key});

  void _mostrarAddMeta(BuildContext context, WidgetRef ref) {
    final fid = ref.read(familiaIdProvider);
    if (fid == null) return;
    final nombreCtrl = TextEditingController();
    final montoCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva Meta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre de la meta')),
            const SizedBox(height: 16),
            TextField(
              controller: montoCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              decoration: const InputDecoration(labelText: 'Objetivo Total', prefixText: r'$'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final val = montoCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
              if (nombreCtrl.text.isEmpty || val.isEmpty) return;
              final meta = Meta(
                id: const Uuid().v4(),
                nombre: nombreCtrl.text,
                objetivo: double.parse(val),
                acumulado: 0,
                fechaLimite: DateTime.now().add(const Duration(days: 90)),
              );
              await ref.read(metaServiceProvider).agregarMeta(fid, meta);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Crear'),
          )
        ],
      ),
    );
  }

  void _mostrarAbonarMeta(BuildContext context, WidgetRef ref, Meta meta) {
    final fid = ref.read(familiaIdProvider);
    if (fid == null) return;
    final montoCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Aportar a ${meta.nombre}'),
        content: TextField(
          controller: montoCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [CurrencyInputFormatter()],
          decoration: const InputDecoration(labelText: 'Cantidad a aportar', prefixText: r'$'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final val = montoCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
              if (val.isEmpty) return;
              final monto = double.parse(val);

              // Abonar a la meta
              await ref.read(metaServiceProvider).abonarMeta(fid, meta.id, monto);
              if (ctx.mounted) Navigator.pop(ctx);

              // Preguntar si descontar del saldo
              if (ctx.mounted) {
                final descontar = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Descontar del saldo?'),
                    content: Text('El aporte de ${CurrencyFormatter.format(monto)} a "${meta.nombre}", desea registrarlo tambien como gasto y descontarlo del saldo total?'),
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
                    categoria: 'ahorro',
                    descripcion: 'Aporte a meta: ${meta.nombre}',
                    fecha: DateTime.now(),
                    autorId: authState?.uid ?? '',
                    autorNombre: authState?.displayName ?? 'Usuario',
                    tipoPago: 'personal',
                  );
                  await ref.read(movimientoServiceProvider).agregarMovimiento(fid, mov);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gasto registrado y descontado del saldo')));
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fid = ref.watch(familiaIdProvider);
    if (fid == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final metasAsync = ref.watch(metasStreamProvider(fid));

    return Scaffold(
      appBar: AppBar(title: const Text('Metas Familiares')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarAddMeta(context, ref),
        child: const Icon(Icons.add),
      ),
      body: metasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (metas) {
          if (metas.isEmpty) return const Center(child: Text('No hay metas activas.', style: TextStyle(color: AppTheme.textSecondary)));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: metas.length,
            itemBuilder: (ctx, i) {
              final m = metas[i];
              final pct = (m.acumulado / m.objetivo).clamp(0.0, 1.0);
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
                          Text(m.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.add_circle, color: AppTheme.accent),
                                onPressed: () => _mostrarAbonarMeta(context, ref, m),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (c) => AlertDialog(
                                      title: const Text('Eliminar meta'),
                                      content: const Text('Esta accion es permanente. Continuar?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                                          onPressed: () => Navigator.pop(c, true),
                                          child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await ref.read(metaServiceProvider).eliminarMeta(fid, m.id);
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: pct,
                        color: pct >= 1.0 ? Colors.green : AppTheme.accent,
                        backgroundColor: AppTheme.surfaceDark,
                        minHeight: 12,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Progreso: ${(pct * 100).toStringAsFixed(1)}%', style: const TextStyle(color: AppTheme.textSecondary)),
                          Text('${CurrencyFormatter.format(m.acumulado)} / ${CurrencyFormatter.format(m.objetivo)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}