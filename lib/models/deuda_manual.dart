import 'package:cloud_firestore/cloud_firestore.dart';

class DeudaManual {
  final String id;
  final String titulo;
  final double monto;
  final String deudor; // Quien debe el dinero
  final String acreedor;
  final double pagado; // A quien se le debe
  final DateTime fechaCreacion;

  DeudaManual({
    required this.id,
    required this.titulo,
    required this.monto,
    required this.deudor,
    required this.acreedor,
    required this.pagado,
    required this.fechaCreacion,
  });

  factory DeudaManual.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return DeudaManual(
      id: doc.id,
      titulo: d['titulo'] ?? '',
      monto: (d['monto'] ?? 0).toDouble(),
      deudor: d['deudor'] ?? '',
      acreedor: d['acreedor'] ?? '',
      pagado: (d['pagado'] ?? 0).toDouble(),
      fechaCreacion: (d['fechaCreacion'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'titulo': titulo,
    'monto': monto,
    'deudor': deudor,
    'acreedor': acreedor,
    'pagado': pagado,
    'fechaCreacion': Timestamp.fromDate(fechaCreacion),
  };
}

