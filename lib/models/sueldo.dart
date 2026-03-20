import 'package:cloud_firestore/cloud_firestore.dart';

class Sueldo {
  final Map<String, double> aportes;
  final double totalFamiliar;

  Sueldo({required this.aportes})
      : totalFamiliar = aportes.values.fold(0.0, (s, a) => s + a);

  factory Sueldo.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) return Sueldo(aportes: {});
    final data = doc.data() as Map<String, dynamic>;
    final map = <String, double>{};
    data.forEach((k, v) {
      if (v is num) map[k] = v.toDouble();
    });
    return Sueldo(aportes: map);
  }
}
