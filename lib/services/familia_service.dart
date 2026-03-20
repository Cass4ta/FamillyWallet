import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/familia.dart';
import '../models/miembro.dart';

class FamiliaService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  String _generarCodigo() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    var result = '';
    var r = random;
    for (int i = 0; i < 6; i++) {
      result += chars[r % chars.length];
      r ~/= chars.length;
    }
    return result;
  }

  Future<String> crearFamilia({
    required String nombre,
    required String userId,
    required String userEmail,
    required String userName,
  }) async {
    final familiaId = _uuid.v4();
    final codigo = _generarCodigo();
    final expira = DateTime.now().add(const Duration(hours: 48));

    await _db.collection('familias').doc(familiaId).set({
      'nombre': nombre,
      'codigoInvitacion': codigo,
      'creadoEn': FieldValue.serverTimestamp(),
      'codigoExpira': Timestamp.fromDate(expira),
    });

    await _db
        .collection('familias')
        .doc(familiaId)
        .collection('miembros')
        .doc(userId)
        .set({
      'nombre': userName,
      'email': userEmail,
      'rol': 'admin',
      'sueldo': 0,
      'colorIndex': 0,
    });

    await _db.collection('users').doc(userId).set({
      'familiaId': familiaId,
    }, SetOptions(merge: true));

    return familiaId;
  }

  Future<String?> unirseConCodigo({
    required String codigo,
    required String userId,
    required String userEmail,
    required String userName,
  }) async {
    final query = await _db
        .collection('familias')
        .where('codigoInvitacion', isEqualTo: codigo.toUpperCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final familiaDoc = query.docs.first;
    final data = familiaDoc.data();
    final expira = (data['codigoExpira'] as Timestamp?)?.toDate();
    if (expira != null && DateTime.now().isAfter(expira)) return null;

    final miembrosRef = familiaDoc.reference.collection('miembros');
    final miembros = await miembrosRef.get();
    if (miembros.docs.length >= 5) return null;

    final colorIndex = miembros.docs.length % 5;
    await miembrosRef.doc(userId).set({
      'nombre': userName,
      'email': userEmail,
      'rol': 'miembro',
      'sueldo': 0,
      'colorIndex': colorIndex,
    });

    await _db.collection('users').doc(userId).set({
      'familiaId': familiaDoc.id,
    }, SetOptions(merge: true));

    return familiaDoc.id;
  }

  Stream<Familia?> getFamiliaStream(String familiaId) {
    return _db.collection('familias').doc(familiaId).snapshots().map(
      (doc) => doc.exists ? Familia.fromFirestore(doc) : null,
    );
  }

  Stream<List<Miembro>> getMiembrosStream(String familiaId) {
    return _db
        .collection('familias')
        .doc(familiaId)
        .collection('miembros')
        .snapshots()
        .map((snap) => snap.docs.map(Miembro.fromFirestore).toList());
  }

  Future<void> actualizarNombreFamilia(String familiaId, String nombre) async {
    await _db.collection('familias').doc(familiaId).update({'nombre': nombre});
  }

  Future<void> expulsarMiembro(String familiaId, String userId) async {
    await _db
        .collection('familias')
        .doc(familiaId)
        .collection('miembros')
        .doc(userId)
        .delete();
        
    try {
      await _db.collection('users').doc(userId).update({
        'familiaId': FieldValue.delete(),
      });
    } catch (_) {}
  }

  Future<void> regenerarCodigo(String familiaId) async {
    final codigo = _generarCodigo();
    final expira = DateTime.now().add(const Duration(hours: 48));
    await _db.collection('familias').doc(familiaId).update({
      'codigoInvitacion': codigo,
      'codigoExpira': Timestamp.fromDate(expira),
    });
  }
}
