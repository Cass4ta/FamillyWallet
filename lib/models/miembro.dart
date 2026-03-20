import 'package:cloud_firestore/cloud_firestore.dart';

class Miembro {
  final String id;
  final String nombre;
  final String email;
  final String rol;
  final double sueldo;
  final int colorIndex;

  Miembro({required this.id, required this.nombre, required this.email, required this.rol, required this.sueldo, required this.colorIndex});

  factory Miembro.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Miembro(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      email: data['email'] ?? '',
      rol: data['rol'] ?? '',
      sueldo: (data['sueldo'] ?? 0).toDouble(),
      colorIndex: data['colorIndex'] ?? 0,
    );
  }
}
