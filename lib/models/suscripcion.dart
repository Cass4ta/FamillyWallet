import 'package:cloud_firestore/cloud_firestore.dart';

class Suscripcion {
  final String id;
  final String nombre;
  final double montoPredeterminado;
  final String categoria;
  final bool esFijo;
  final int diaCobro;
  final bool activa;
  final String icono;

  Suscripcion({
    required this.id,
    required this.nombre,
    required this.montoPredeterminado,
    required this.categoria,
    required this.esFijo,
    required this.diaCobro,
    required this.activa,
    this.icono = 'attach_money',
  });

  factory Suscripcion.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Suscripcion(
      id: doc.id,
      nombre: d['nombre'] ?? '',
      montoPredeterminado: (d['montoPredeterminado'] ?? 0).toDouble(),
      categoria: d['categoria'] ?? 'servicios',
      esFijo: d['esFijo'] ?? true,
      diaCobro: (d['diaCobro'] ?? 1) as int,
      activa: d['activa'] ?? true,
      icono: d['icono'] ?? 'attach_money',
    );
  }

  Map<String, dynamic> toMap() => {
    'nombre': nombre,
    'montoPredeterminado': montoPredeterminado,
    'categoria': categoria,
    'esFijo': esFijo,
    'diaCobro': diaCobro,
    'activa': activa,
    'icono': icono,
  };
}
