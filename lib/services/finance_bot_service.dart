import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/movimiento.dart';
import '../models/meta.dart';
import '../core/utils/currency_formatter.dart';

class FinanceBotService {
  late GenerativeModel _model;
  bool _isInit = false;

  void init() {
    if (_isInit) return;
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      debugPrint('FinanceBot: API Key de Gemini no configurada.');
      return;
    }
    
    _model = GenerativeModel(
      model: 'gemini-flash-latest',
      apiKey: apiKey,
      systemInstruction: Content.system('Eres FinanceBot, un asistente financiero amigable para una aplicacion llamada FamilyWallet. '
          'Responde de forma concisa, empatica y util basandote en los datos proveidos.'),
    );
    _isInit = true;
  }

  Future<String> sendMessage({
    required String pregunta,
    required double saldoTotal,
    required double ingresosMes,
    required double gastosMes,
    required double sueldoFamiliar,
    required List<Movimiento> movimientosMes,
    required List<Meta> metas,
    required String nombreFamilia,
  }) async {
    init();
    if (!_isInit) {
      return "Para usar FinanceBot, necesitas agregar tu GEMINI_API_KEY en el archivo .env del proyecto. Avisame cuando lo hagas! ";
    }

    try {
      final prompt = '''
El usuario de la familia "$nombreFamilia" pregunta: "$pregunta"

Datos financieros actuales:
- Saldo Total Historico: ${CurrencyFormatter.format(saldoTotal)}
- Ingresos este mes: ${CurrencyFormatter.format(ingresosMes)}
- Gastos este mes: ${CurrencyFormatter.format(gastosMes)}
- Sueldo/Presupuesto configurado para el mes: ${CurrencyFormatter.format(sueldoFamiliar)}

Metas activas (${metas.length}):
${metas.map((m) => "- ${m.nombre}: ${CurrencyFormatter.format(m.acumulado)} de ${CurrencyFormatter.format(m.objetivo)}").join('\n')}

Ultimos gastos (max 10):
${movimientosMes.take(10).map((m) => "- ${m.categoria} por ${CurrencyFormatter.format(m.monto)} el ${m.fecha.day}/${m.fecha.month} (${m.autorNombre})").join('\n')}

Da un consejo corto o responde la pregunta basandote en estos datos.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? "No pude generar una respuesta. Intenta de nuevo.";
    } catch (e) {
      return "Error detallado: $e";
    }
  }
}


