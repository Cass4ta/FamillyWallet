import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../providers/providers.dart';
import '../../models/movimiento.dart';
import '../../core/constants/categorias.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/currency_input_formatter.dart';
import '../../core/utils/snackbar_utils.dart';

class AddMovimientoScreen extends ConsumerStatefulWidget {
  const AddMovimientoScreen({super.key});

  @override
  ConsumerState<AddMovimientoScreen> createState() => _AddMovimientoScreenState();
}

class _AddMovimientoScreenState extends ConsumerState<AddMovimientoScreen> {
  bool _isGasto = true;
  bool _isSueldo = false;
  bool _isCompartido = true;
  bool _isLoading = false;
  int _diaCobro = 1;
  String _selectedCategoria = 'otros';
  DateTime _selectedDate = DateTime.now();

  final _montoCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void dispose() {
    _montoCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final montoText = _montoCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (montoText.isEmpty) {
      showErrorSnackBar(context, 'Debes ingresar un monto.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final familiaId = ref.read(familiaIdProvider);
      final fbUser = ref.read(authStateProvider).value;
      if (familiaId == null || fbUser == null) throw Exception('Sesión inválida o expirada.');

      // Wait for the member stream if it is not yet available.
      var miembro = ref.read(miembroActualProvider);
      if (miembro == null) {
        final miembros = await ref.read(miembrosStreamProvider(familiaId).future);
        miembro = miembros.firstWhere(
          (m) => m.id == fbUser.uid,
          orElse: () => throw Exception('No se encontró tu usuario en la base de datos.'),
        );
      }

      final movimiento = Movimiento(
        id: const Uuid().v4(),
        tipo: _isGasto ? 'gasto' : 'ingreso',
        monto: double.parse(montoText),
        categoria: _isSueldo ? 'ingresos' : _selectedCategoria,
        descripcion: _descCtrl.text.trim(),
        fecha: _selectedDate,
        autorId: miembro.id,
        autorNombre: miembro.nombre,
        esSueldo: _isSueldo,
        tipoPago: _isCompartido ? 'compartido' : 'personal',
        diaCobro: _isSueldo ? _diaCobro : null,
      );

      await ref.read(movimientoServiceProvider).agregarMovimiento(familiaId, movimiento);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableCats = categorias
        .where((c) => _isGasto ? c.id != 'ingresos' : true)
        .toList();

    if (!availableCats.any((c) => c.id == _selectedCategoria)) {
      _selectedCategoria = availableCats.first.id;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Movimiento')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Type selector
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _TypeTab(
                          title: 'Gasto',
                          isSelected: _isGasto,
                          color: AppTheme.error,
                          onTap: () => setState(() {
                            _isGasto = true;
                            _isSueldo = false;
                          }),
                        ),
                      ),
                      Expanded(
                        child: _TypeTab(
                          title: 'Ingreso',
                          isSelected: !_isGasto,
                          color: AppTheme.accent,
                          onTap: () => setState(() => _isGasto = false),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Amount field
                TextField(
                  controller: _montoCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: _isGasto ? AppTheme.error : AppTheme.accent,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 20, top: 14),
                      child: Text(
                        r'$',
                        style: TextStyle(
                          fontSize: 28,
                          color: _isGasto ? AppTheme.error : AppTheme.accent,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Income-specific options
                if (!_isGasto) ...[
                  SwitchListTile(
                    title: const Text('¿Es tu sueldo del mes?'),
                    value: _isSueldo,
                    activeThumbColor: AppTheme.accent,
                    onChanged: (v) => setState(() => _isSueldo = v),
                  ),
                  if (_isSueldo) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.event_repeat, color: AppTheme.accent),
                        const SizedBox(width: 12),
                        const Text('Día de cobro:'),
                        const SizedBox(width: 16),
                        DropdownButton<int>(
                          value: _diaCobro,
                          items: List.generate(28, (i) => i + 1)
                              .map((d) => DropdownMenuItem(value: d, child: Text('Día $d')))
                              .toList(),
                          onChanged: (v) => setState(() => _diaCobro = v!),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                ],

                // Category selector
                if (!_isSueldo) ...[
                  const Text('Categoría', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: availableCats.length,
                      itemBuilder: (_, i) {
                        final cat = availableCats[i];
                        final isSelected = cat.id == _selectedCategoria;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategoria = cat.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 80,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? cat.color.withValues(alpha: 0.2)
                                  : AppTheme.cardDark,
                              border: Border.all(
                                color: isSelected ? cat.color : Colors.transparent,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(cat.icono, color: isSelected ? cat.color : AppTheme.textSecondary),
                                const SizedBox(height: 4),
                                Text(
                                  cat.nombre,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isSelected ? cat.color : AppTheme.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Description
                TextField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    prefixIcon: Icon(Icons.notes),
                  ),
                ),
                const SizedBox(height: 16),

                // Expense type (shared vs personal)
                if (_isGasto) ...[
                  const Text('Tipo de Gasto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<bool>(
                          // ignore: deprecated_member_use
                          title: const Text('Común'),
                          value: true,
                          groupValue: _isCompartido,
                          onChanged: (v) => setState(() => _isCompartido = v!),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<bool>(
                          // ignore: deprecated_member_use
                          title: const Text('Personal'),
                          value: false,
                          groupValue: _isCompartido,
                          onChanged: (v) => setState(() => _isCompartido = v!),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Date picker
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(DateFormatter.formatDate(_selectedDate)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                ),
                const SizedBox(height: 32),

                // Save button
                ElevatedButton(
                  onPressed: _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isGasto ? AppTheme.error : AppTheme.accent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Guardar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
    );
  }
}

class _TypeTab extends StatelessWidget {
  final String title;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TypeTab({
    required this.title,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? color : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
