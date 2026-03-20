import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/snackbar_utils.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  String _mapFirebaseError(dynamic error) {
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'email-already-in-use'                  => 'Este correo ya está registrado. Intentá iniciar sesión.',
        'user-not-found'                        => 'No existe una cuenta con ese correo. Verificá o registrate.',
        'wrong-password'                        => 'La contraseña es incorrecta. Intentá de nuevo.',
        'invalid-credential'                    => 'Correo o contraseña incorrectos. Verificá tus datos.',
        'invalid-email'                         => 'El formato del correo electrónico no es válido.',
        'weak-password'                         => 'La contraseña es muy débil. Debe tener al menos 6 caracteres.',
        'too-many-requests'                     => 'Demasiados intentos fallidos. Esperá unos minutos e intentá de nuevo.',
        'user-disabled'                         => 'Esta cuenta fue deshabilitada. Contactá al soporte.',
        'network-request-failed'                => 'Sin conexión a internet. Verificá tu red e intentá de nuevo.',
        'operation-not-allowed'                 => 'Este método de inicio de sesión no está habilitado.',
        'account-exists-with-different-credential' => 'Este correo ya se registró con contraseña. Por favor iniciá sesión con tus credenciales.',
        'credential-already-in-use'             => 'Esta cuenta de Google ya está vinculada a otro usuario.',
        _ => 'Ocurrió un error inesperado (${error.code}).',
      };
    }

    final errStr = error.toString();
    if (errStr.contains('sign_in_canceled') || errStr.contains('CANCELED')) {
      return 'Cancelaste el inicio de sesión con Google.';
    }
    return 'Ocurrió un error inesperado. Por favor intentá de nuevo.';
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showErrorSnackBar(context, 'Por favor completá el correo y la contraseña.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await ref.read(authServiceProvider).signInWithEmail(email, password);
      } else {
        await ref.read(authServiceProvider).registerWithEmail(email, password);
      }
      if (mounted) context.go('/familia_setup');
    } catch (e) {
      if (mounted) showErrorSnackBar(context, _mapFirebaseError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleAuth() async {
    setState(() => _isLoading = true);
    try {
      final user = await ref.read(authServiceProvider).signInWithGoogle();
      if (user != null && mounted) context.go('/familia_setup');
    } catch (e) {
      if (mounted) showErrorSnackBar(context, _mapFirebaseError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Iniciar Sesión' : 'Registro')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passCtrl,
              decoration: const InputDecoration(labelText: 'Contraseña', prefixIcon: Icon(Icons.lock)),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: _submit,
                child: Text(_isLogin ? 'Entrar' : 'Registrarse'),
              ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.g_mobiledata, size: 28),
              label: const Text('Continuar con Google'),
              onPressed: _isLoading ? null : _googleAuth,
            ),
            const Spacer(),
            TextButton(
              onPressed: () => setState(() => _isLogin = !_isLogin),
              child: Text(
                _isLogin ? '¿No tienes cuenta? Regístrate' : '¿Ya tienes cuenta? Inicia sesión',
                style: const TextStyle(color: AppTheme.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
