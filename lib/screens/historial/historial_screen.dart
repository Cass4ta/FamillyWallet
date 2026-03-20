import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../core/widgets/movimiento_tile.dart';
import '../../core/theme/app_theme.dart';

class HistorialScreen extends ConsumerWidget {
  const HistorialScreen({super.key});

  void _confirmarEliminar(BuildContext context, WidgetRef ref, String fid, String movId, String desc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 40),
        title: const Text('Eliminar movimiento'),
        content: Text('Se eliminara "$desc". Esta accion no se puede deshacer pero el registro queda marcado como error internamente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(movimientoServiceProvider).marcarComoError(fid, movId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Movimiento eliminado'), backgroundColor: AppTheme.error),
                );
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fid = ref.watch(familiaIdProvider);
    if (fid == null) return const Center(child: CircularProgressIndicator());

    final asyncMovs = ref.watch(movimientosStreamProvider(fid));

    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: asyncMovs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (movs) {
          if (movs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: AppTheme.textSecondary),
                  SizedBox(height: 16),
                  Text('No hay movimientos registrados.', style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: movs.length,
            itemBuilder: (ctx, i) {
              final m = movs[i];
              final cid = m.autorNombre.isNotEmpty ? m.autorNombre.codeUnitAt(0) % 5 : 0;
              return Dismissible(
                key: Key(m.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) async {
                  bool confirmed = false;
                  await showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      icon: const Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 40),
                      title: const Text('Eliminar movimiento?'),
                      content: Text('Se eliminara "${m.descripcion.isNotEmpty ? m.descripcion : m.categoria}".'),
                      actions: [
                        TextButton(onPressed: () { Navigator.pop(ctx); confirmed = false; }, child: const Text('Cancelar')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                          onPressed: () { Navigator.pop(ctx); confirmed = true; },
                          child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  return confirmed;
                },
                onDismissed: (_) async {
                  await ref.read(movimientoServiceProvider).marcarComoError(fid, m.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Movimiento eliminado'),
                        backgroundColor: AppTheme.error,
                        action: SnackBarAction(
                          label: 'OK',
                          textColor: Colors.white,
                          onPressed: () {},
                        ),
                      ),
                    );
                  }
                },
                background: Container(
                  color: AppTheme.error.withValues(alpha: 0.2),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_outline, color: AppTheme.error, size: 28),
                      SizedBox(height: 4),
                      Text('Eliminar', style: TextStyle(color: AppTheme.error, fontSize: 11)),
                    ],
                  ),
                ),
                child: MovimientoTile(
                  movimiento: m,
                  autorColorIndex: cid,
                  onLongPress: () => _confirmarEliminar(context, ref, fid, m.id, m.descripcion.isNotEmpty ? m.descripcion : m.categoria),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
