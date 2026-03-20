import 'package:flutter/material.dart';

/// Shows a floating error SnackBar with red background and an error icon.
void showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 4),
    ),
  );
}

/// Shows a floating success SnackBar with green background and a check icon.
void showSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
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

/// Maps a Firestore/Firebase error string to a user-friendly Spanish message.
String getFirestoreErrorMessage(dynamic error) {
  final msg = error.toString().toLowerCase();
  if (msg.contains('permission-denied')) {
    return 'No tenés permisos para realizar esta acción.';
  } else if (msg.contains('not-found')) {
    return 'No se encontró la información solicitada.';
  } else if (msg.contains('network-request-failed') || msg.contains('unavailable')) {
    return 'Verificá tu conexión a internet e intentá de nuevo.';
  }
  return 'Ocurrió un error inesperado. Por favor intentá de nuevo.';
}
