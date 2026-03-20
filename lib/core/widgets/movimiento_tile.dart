import 'package:flutter/material.dart';
import '../../models/movimiento.dart';
import '../../core/constants/categorias.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/constants/avatar_colors.dart';
import '../../core/theme/app_theme.dart';

class MovimientoTile extends StatelessWidget {
  final Movimiento movimiento;
  final int autorColorIndex;
  final VoidCallback? onLongPress;

  const MovimientoTile({
    super.key,
    required this.movimiento,
    this.autorColorIndex = 0,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final cat = getCategoriaById(movimiento.categoria);
    final isIngreso = movimiento.esIngreso;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: cat.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(cat.icono, color: cat.color, size: 22),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              movimiento.descripcion.isNotEmpty ? movimiento.descripcion : cat.nombre,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isIngreso ? "+" : "-"}${CurrencyFormatter.format(movimiento.monto)}',
            style: TextStyle(
              color: isIngreso ? AppTheme.accent : AppTheme.error,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          CircleAvatar(
            radius: 8,
            backgroundColor: getAvatarColor(autorColorIndex),
          ),
          const SizedBox(width: 6),
          Text(
            movimiento.autorNombre,
            style: const TextStyle(fontSize: 11),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: cat.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(cat.nombre, style: TextStyle(color: cat.color, fontSize: 10)),
          ),
          const Spacer(),
          Text(
            DateFormatter.formatDate(movimiento.fecha),
            style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
          ),
        ],
      ),
      onLongPress: onLongPress,
    );
  }
}
