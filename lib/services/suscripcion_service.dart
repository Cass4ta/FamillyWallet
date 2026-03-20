import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/suscripcion.dart';

class SuscripcionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference _col(String fid) =>
      _db.collection('familias').doc(fid).collection('suscripciones');

  Stream<List<Suscripcion>> getSuscripcionesStream(String fid) {
    return _col(fid).where('activa', isEqualTo: true).snapshots()
        .map((s) => s.docs.map(Suscripcion.fromFirestore).toList());
  }

  Future<void> agregarSuscripcion(String fid, Suscripcion s) async {
    await _col(fid).doc(s.id).set(s.toMap());
  }

  Future<void> eliminarSuscripcion(String fid, String id) async {
    await _col(fid).doc(id).update({'activa': false});
  }

  Future<void> editarSuscripcion(String fid, Suscripcion s) async {
    await _col(fid).doc(s.id).update(s.toMap());
  }
}
