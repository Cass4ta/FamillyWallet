import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';

class TermometroWidget extends StatelessWidget {
  final EstadoTermometro estado;
  final double gastosMes;
  final double sueldoFamiliar;

  const TermometroWidget({
    super.key,
    required this.estado,
    required this.gastosMes,
    required this.sueldoFamiliar,
  });

  Color get color {
    switch (estado) {
      case EstadoTermometro.verde: return AppTheme.accent;
      case EstadoTermometro.amarillo: return AppTheme.warning;
      case EstadoTermometro.rojo: return AppTheme.error;
      case EstadoTermometro.sinDatos: return Colors.grey;
    }
  }

  String get emoji {
    switch (estado) {
      case EstadoTermometro.verde: return '🟢';
      case EstadoTermometro.amarillo: return '🟡';
      case EstadoTermometro.rojo: return '🔴';
      case EstadoTermometro.sinDatos: return '⚫';
    }
  }

  String get label {
    switch (estado) {
      case EstadoTermometro.verde: return 'Van muy bien';
      case EstadoTermometro.amarillo: return 'Con cuidado';
      case EstadoTermometro.rojo: return 'Ajustados';
      case EstadoTermometro.sinDatos: return 'Registra tus sueldos del mes';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pct = sueldoFamiliar > 0
        ? (gastosMes / sueldoFamiliar).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          if (estado != EstadoTermometro.sinDatos) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ).animate().slideX(begin: -1, end: 0, duration: 600.ms, curve: Curves.easeOut),
            ),
            const SizedBox(height: 8),
            Text(
              'Gastado: ${CurrencyFormatter.format(gastosMes)} de ${CurrencyFormatter.format(sueldoFamiliar)} (${(pct * 100).toStringAsFixed(0)}%)',
              style: TextStyle(color: color.withValues(alpha: 0.9), fontSize: 12),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}
