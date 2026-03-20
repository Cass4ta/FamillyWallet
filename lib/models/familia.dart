import 'package:cloud_firestore/cloud_firestore.dart';

class Familia {
  final String id;
  final String nombre;
  final String codigoInvitacion;
  final DateTime creadoEn;

  Familia({required this.id, required this.nombre, required this.codigoInvitacion, required this.creadoEn});

  factory Familia.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Familia(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      codigoInvitacion: data['codigoInvitacion'] ?? '',
      creadoEn: (data['creadoEn'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
