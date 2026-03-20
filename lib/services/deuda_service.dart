import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/movimiento.dart';
import '../models/miembro.dart';
import '../models/deuda_manual.dart';

class DeudaService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference _deudasRef(String fid) =>
      _db.collection('familias').doc(fid).collection('deudas_manuales');

  Stream<List<DeudaManual>> getDeudasManualesStream(String fid) {
    return _deudasRef(fid).orderBy('fechaCreacion', descending: true).snapshots().map((s) {
      return s.docs.map((d) => DeudaManual.fromFirestore(d)).toList();
    });
  }

  Future<void> agregarDeudaManual(String fid, DeudaManual deuda) async {
    await _deudasRef(fid).doc(deuda.id).set(deuda.toMap());
  }

  Future<void> abonarDeudaManual(String fid, String id, double monto) async {
    await _deudasRef(fid).doc(id).update({'pagado': FieldValue.increment(monto)});
  }

  Future<void> eliminarDeudaManual(String fid, String id) async {
    await _deudasRef(fid).doc(id).delete();
  }

  List<Map<String, dynamic>> calcularDeudas({
    required List<Movimiento> movimientos,
    required List<Miembro> miembros,
  }) {
    if (miembros.isEmpty) return [];
    
    final gastosCompartidos = movimientos.where((m) => m.tipoPago == 'compartido' && m.esGasto).toList();
    if (gastosCompartidos.isEmpty) return [];
    
    final totalCompartido = gastosCompartidos.fold(0.0, (s, m) => s + m.monto);
    final cuotaPorPersona = totalCompartido / miembros.length;

    // Calcular balances
    Map<String, double> balances = {};
    for (var m in miembros) {
      balances[m.id] = -cuotaPorPersona; // Todos empiezan debiendo la cuota
    }
    
    for (var m in gastosCompartidos) {
      balances[m.autorId] = (balances[m.autorId] ?? -cuotaPorPersona) + m.monto;
    }

    // Calcular transferencias requeridas (greedy)
    List<Map<String, dynamic>> transferencias = [];
    
    var deudores = balances.entries.where((e) => e.value < -0.01).toList()..sort((a,b) => a.value.compareTo(b.value));
    var acreedores = balances.entries.where((e) => e.value > 0.01).toList()..sort((a,b) => b.value.compareTo(a.value));

    int i = 0, j = 0;
    while (i < deudores.length && j < acreedores.length) {
      final deudor = deudores[i];
      final acreedor = acreedores[j];
      
      final deuda = -deudor.value;
      final credito = acreedor.value;
      
      final montoTransferir = deuda < credito ? deuda : credito;
      
      transferencias.add({
        'deudorId': deudor.key,
        'deudorNombre': miembros.firstWhere((m) => m.id == deudor.key).nombre,
        'acreedorId': acreedor.key,
        'acreedorNombre': miembros.firstWhere((m) => m.id == acreedor.key).nombre,
        'monto': montoTransferir,
      });

      deudores[i] = MapEntry(deudor.key, deudor.value + montoTransferir);
      acreedores[j] = MapEntry(acreedor.key, acreedor.value - montoTransferir);

      if (deudores[i].value > -0.01) i++;
      if (acreedores[j].value < 0.01) j++;
    }

    return transferencias;
  }
}

