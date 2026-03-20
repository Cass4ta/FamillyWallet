import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../core/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ConfiguracionScreen extends ConsumerWidget {
  const ConfiguracionScreen({super.key});

  String _avatarInitial(User? user) {
    if (user == null) return 'U';
    final name = user.displayName;
    if (name != null && name.isNotEmpty) return name[0].toUpperCase();
    final email = user.email;
    if (email != null && email.isNotEmpty) return email[0].toUpperCase();
    return 'U';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fid = ref.watch(familiaIdProvider);
    final familiaInfo = fid != null
        ? ref.watch(familiaStreamProvider(fid)).value
        : null;
    final isDark = ref.watch(isDarkModeProvider);
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        children: [
          // ── Profile Header ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppTheme.accent.withValues(alpha: 0.2),
                  child: Text(
                    _avatarInitial(user),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accent,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? user?.email ?? 'Usuario',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                    if (familiaInfo != null)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Familia: ${familiaInfo.nombre}',
                          style: const TextStyle(color: AppTheme.accent, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Invitation Code ─────────────────────────────────────────────
          if (familiaInfo != null)
            ListTile(
              leading: const Icon(Icons.group_add, color: AppTheme.accent),
              title: const Text('Código de Invitación'),
              subtitle: Text(
                familiaInfo.codigoInvitacion,
                style: const TextStyle(letterSpacing: 4, fontWeight: FontWeight.bold),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Código copiado')),
                ),
              ),
            ),

          // ── Dark Mode Toggle ────────────────────────────────────────────
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: const Text('Modo oscuro'),
            value: isDark,
            onChanged: (v) => ref.read(isDarkModeProvider.notifier).state = v,
            activeThumbColor: AppTheme.accent,
          ),

          const Divider(height: 1),

          // ── Danger Zone ─────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'CUENTA',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, letterSpacing: 1),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.sensor_door_outlined, color: Colors.orange),
            title: const Text('Salir de la familia', style: TextStyle(color: Colors.orange)),
            onTap: () async {
              final confirm = await _showConfirmDialog(
                context,
                title: 'Salir de la familia',
                content: 'Saldrás de este grupo familiar y perderás acceso a los movimientos compartidos hasta que te vuelvas a unir con un código.',
                actionLabel: 'Salir',
                actionColor: Colors.orange,
              );
              if (confirm == true && user != null && fid != null) {
                await ref.read(familiaServiceProvider).expulsarMiembro(fid, user.uid);
                ref.read(familiaIdProvider.notifier).state = null;
              }
            },
          ),

          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.error),
            title: const Text('Cerrar sesión', style: TextStyle(color: AppTheme.error)),
            onTap: () async {
              final confirm = await _showConfirmDialog(
                context,
                title: 'Cerrar sesión',
                content: 'La sesión se cerrará en este dispositivo. Tus datos quedan guardados en la nube.',
                actionLabel: 'Cerrar sesión',
                actionColor: AppTheme.error,
              );
              if (confirm == true) {
                ref.read(familiaIdProvider.notifier).state = null;
                await ref.read(authServiceProvider).signOut();
              }
            },
          ),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    required String actionLabel,
    required Color actionColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: actionColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(actionLabel, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
