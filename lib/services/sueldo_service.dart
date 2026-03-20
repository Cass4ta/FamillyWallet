import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sueldo.dart';

class SueldoService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  Stream<Sueldo?> getSueldoMesStream(String fid, String mes) {
    return _db.collection('familias').doc(fid).collection('sueldos').doc(mes)
        .snapshots().map((doc) => Sueldo.fromFirestore(doc));
  }

  Future<void> actualizarAporte(String fid, String mes, String miembroId, double monto) async {
    final doc = _db.collection('familias').doc(fid).collection('sueldos').doc(mes);
    await doc.set({
      miembroId: monto
    }, SetOptions(merge: true));
  }
}
