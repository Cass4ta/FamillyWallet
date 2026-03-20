import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class MasScreen extends StatelessWidget {
  const MasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mas opciones')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MasCard(
            icon: Icons.attach_money,
            title: 'Sueldos del Mes',
            subtitle: 'Gestiona el aporte de cada miembro',
            color: Colors.green,
            onTap: () => context.push('/sueldos'),
          ),
          _MasCard(
            icon: Icons.handshake,
            title: 'Deudas y Balance',
            subtitle: 'Registra deudas o saldos pendientes',
            color: Colors.orange,
            onTap: () => context.push('/deudas'),
          ),
          _MasCard(
            icon: Icons.subscriptions,
            title: 'Suscripciones y Gastos Fijos',
            subtitle: 'Netflix, Luz, Agua, Gas, etc.',
            color: AppTheme.accent,
            onTap: () => context.push('/suscripciones'),
          ),
          _MasCard(
            icon: Icons.settings,
            title: 'Configuracion',
            subtitle: 'Perfil, Modo Oscuro, Cerrar Sesion',
            color: Colors.blueGrey,
            onTap: () => context.push('/configuracion'),
          ),
        ],
      ),
    );
  }
}

class _MasCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _MasCard({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.cardDark,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                radius: 24,
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
