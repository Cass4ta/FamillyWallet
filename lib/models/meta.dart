import 'package:cloud_firestore/cloud_firestore.dart';

class Meta {
  final String id;
  final String nombre;
  final double objetivo;
  final double acumulado;
  final DateTime fechaLimite;

  Meta({required this.id, required this.nombre, required this.objetivo, required this.acumulado, required this.fechaLimite});

  factory Meta.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Meta(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      objetivo: (data['objetivo'] ?? 0).toDouble(),
      acumulado: (data['acumulado'] ?? 0).toDouble(),
      fechaLimite: (data['fechaLimite'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
