import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../core/utils/snackbar_utils.dart';

class FamiliaScreen extends ConsumerStatefulWidget {
  const FamiliaScreen({super.key});

  @override
  ConsumerState<FamiliaScreen> createState() => _FamiliaScreenState();
}

class _FamiliaScreenState extends ConsumerState<FamiliaScreen> {
  final _nombreFamCtrl = TextEditingController();
  final _codigoCtrl = TextEditingController();
  final _userNombreCtrl = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkExistingFamily();
  }

  @override
  void dispose() {
    _nombreFamCtrl.dispose();
    _codigoCtrl.dispose();
    _userNombreCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkExistingFamily() async {
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      final familiaId = await ref.read(authServiceProvider).getFamiliaIdForUser(user.uid);
      if (familiaId != null) {
        ref.read(familiaIdProvider.notifier).state = familiaId;
        if (mounted) context.go('/home');
        return;
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _crear() async {
    final nombreFam = _nombreFamCtrl.text.trim();
    final userNombre = _userNombreCtrl.text.trim();

    if (nombreFam.isEmpty || userNombre.isEmpty) {
      showErrorSnackBar(context, 'Por favor completá tu nombre y el de la familia.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = ref.read(authStateProvider).value!;
      final familiaId = await ref.read(familiaServiceProvider).crearFamilia(
        nombre: nombreFam,
        userId: user.uid,
        userEmail: user.email ?? '',
        userName: userNombre,
      );
      ref.read(familiaIdProvider.notifier).state = familiaId;
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) showErrorSnackBar(context, getFirestoreErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _unir() async {
    final codigo = _codigoCtrl.text.trim();
    final userNombre = _userNombreCtrl.text.trim();

    if (codigo.isEmpty || userNombre.isEmpty) {
      showErrorSnackBar(context, 'Por favor completá tu nombre y el código de familia.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = ref.read(authStateProvider).value!;
      final familiaId = await ref.read(familiaServiceProvider).unirseConCodigo(
        codigo: codigo,
        userId: user.uid,
        userEmail: user.email ?? '',
        userName: userNombre,
      );
      if (familiaId != null) {
        ref.read(familiaIdProvider.notifier).state = familiaId;
        if (mounted) context.go('/home');
      } else {
        if (mounted) showErrorSnackBar(context, 'El código de familia es inválido o expiró. Verificalo.');
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, getFirestoreErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    ref.read(familiaIdProvider.notifier).state = null;
    await ref.read(authServiceProvider).signOut();
    if (mounted) context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Familia'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _signOut,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                TextField(
                  controller: _userNombreCtrl,
                  decoration: const InputDecoration(labelText: 'Tu nombre (ej. Papá)'),
                ),
                const SizedBox(height: 32),
                const Text('Crear nueva familia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: _nombreFamCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre familia (ej. Los Pérez)'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: _crear, child: const Text('Crear Familia')),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('-- O --', style: TextStyle(color: Colors.grey))),
                ),
                const Text('Unirme a familia existente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: _codigoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Código de 6 letras',
                    prefixIcon: Icon(Icons.key),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: _unir, child: const Text('Unirme con Código')),
                const SizedBox(height: 32),
                TextButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  label: const Text('Cerrar sesión', style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ),
    );
  }
}
