import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/movimiento.dart';

class MovimientoService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference _col(String familiaId) =>
      _db.collection('familias').doc(familiaId).collection('movimientos');

  Stream<List<Movimiento>> getMovimientosStream(String familiaId) {
    return _col(familiaId)
        .where('esError', isEqualTo: false)
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Movimiento.fromFirestore).toList());
  }

  Future<void> agregarMovimiento(String familiaId, Movimiento movimiento) async {
    await _col(familiaId).add(movimiento.toMap());
  }

  Future<void> editarMovimiento(String familiaId, String movId, Movimiento movimiento) async {
    await _col(familiaId).doc(movId).update(movimiento.toMap());
  }

  Future<void> marcarComoError(String familiaId, String movId) async {
    await _col(familiaId).doc(movId).update({'esError': true});
  }
}
