import 'package:cloud_firestore/cloud_firestore.dart';

class Movimiento {
  final String id;
  final String tipo;
  final double monto;
  final String categoria;
  final String descripcion;
  final DateTime fecha;
  final String autorId;
  final String autorNombre;
  final bool esSueldo;
  final String tipoPago;
  final bool esError;
  final int? diaCobro;

  Movimiento({
    required this.id,
    required this.tipo,
    required this.monto,
    required this.categoria,
    required this.descripcion,
    required this.fecha,
    required this.autorId,
    required this.autorNombre,
    this.esSueldo = false,
    required this.tipoPago,
    this.esError = false,
    this.diaCobro,
  });

  bool get esIngreso => tipo == 'ingreso';
  bool get esGasto => tipo == 'gasto';

  factory Movimiento.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Movimiento(
      id: doc.id,
      tipo: data['tipo'] ?? 'gasto',
      monto: (data['monto'] ?? 0).toDouble(),
      categoria: data['categoria'] ?? 'otros',
      descripcion: data['descripcion'] ?? '',
      fecha: (data['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
      autorId: data['autorId'] ?? '',
      autorNombre: data['autorNombre'] ?? '',
      esSueldo: data['esSueldo'] ?? false,
      tipoPago: data['tipoPago'] ?? 'personal',
      esError: data['esError'] ?? false,
      diaCobro: data['diaCobro'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tipo': tipo,
      'monto': monto,
      'categoria': categoria,
      'descripcion': descripcion,
      'fecha': Timestamp.fromDate(fecha),
      'autorId': autorId,
      'autorNombre': autorNombre,
      'esSueldo': esSueldo,
      'tipoPago': tipoPago,
      'esError': esError,
      if (diaCobro != null) 'diaCobro': diaCobro,
    };
  }
}
