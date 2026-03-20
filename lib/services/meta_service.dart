import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meta.dart';

class MetaService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference _col(String fid) => _db.collection('familias').doc(fid).collection('metas');

  Stream<List<Meta>> getMetasStream(String fid) {
    return _col(fid).snapshots().map((s) => s.docs.map(Meta.fromFirestore).toList());
  }

  Future<void> agregarMeta(String fid, Meta meta) async {
    await _col(fid).doc(meta.id).set({
      'nombre': meta.nombre,
      'objetivo': meta.objetivo,
      'acumulado': meta.acumulado,
      'fechaLimite': meta.fechaLimite,
    });
  }

  Future<void> abonarMeta(String fid, String metaId, double monto) async {
    await _col(fid).doc(metaId).update({
      'acumulado': FieldValue.increment(monto)
    });
  }
  Future<void> eliminarMeta(String fid, String metaId) async {
    await _col(fid).doc(metaId).delete();
  }
}
