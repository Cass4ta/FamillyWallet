import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/providers.dart';
import '../../core/constants/categorias.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/theme/app_theme.dart';

class EstadisticasScreen extends ConsumerStatefulWidget {
  const EstadisticasScreen({super.key});
  @override
  ConsumerState<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends ConsumerState<EstadisticasScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fid = ref.watch(familiaIdProvider);
    if (fid == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final resumenActual = ref.watch(resumenMesProvider(fid));
    final resumenAnterior = ref.watch(resumenMesAnteriorProvider(fid));
    final deudasManuales = ref.watch(deudasManualesStreamProvider(fid)).value ?? [];
    final gastos = resumenActual.movimientos.where((m) => m.esGasto).toList();

    // Gastos por categoria (mes actual)
    Map<String, double> gastosPorCat = {};
    for (var m in gastos) {
      gastosPorCat[m.categoria] = (gastosPorCat[m.categoria] ?? 0) + m.monto;
    }

    // Mayor categoria de gasto
    String? mayorCatId;
    double mayorMonto = 0;
    gastosPorCat.forEach((id, monto) {
      if (monto > mayorMonto) { mayorMonto = monto; mayorCatId = id; }
    });
    final mayorCat = mayorCatId != null ? getCategoriaById(mayorCatId!) : null;

    // Pie chart sections
    List<PieChartSectionData> sections = [];
    gastosPorCat.forEach((catId, monto) {
      final cat = getCategoriaById(catId);
      sections.add(PieChartSectionData(
        color: cat.color,
        value: monto,
        title: resumenActual.gastos > 0 ? '${(monto / resumenActual.gastos * 100).toStringAsFixed(1)}%' : '',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
      ));
    });

    // Bar chart: use actual categories that have data
    final allCatIds = {...gastosPorCat.keys, ...resumenAnterior.gastosPorCat.keys}.toList();
    // Limit to known categories + keep at least the main ones
    final knownCatIds = categorias.map((c) => c.id).toSet();
    final barCatIds = allCatIds.where((id) => knownCatIds.contains(id)).toList();
    
    // If no categories have data, show a default set of 4
    final displayCats = barCatIds.isNotEmpty ? barCatIds : ['comida', 'transporte', 'hogar', 'salud'];

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < displayCats.length; i++) {
      final cat = displayCats[i];
      final actual = gastosPorCat[cat] ?? 0;
      final anterior = resumenAnterior.gastosPorCat[cat] ?? 0;
      barGroups.add(BarChartGroupData(x: i, barRods: [
        BarChartRodData(toY: actual, color: AppTheme.accent, width: 10, borderRadius: BorderRadius.circular(4)),
        BarChartRodData(toY: anterior, color: Colors.grey.shade600, width: 10, borderRadius: BorderRadius.circular(4)),
      ]));
    }

    final catLabels = displayCats.map((id) {
      final c = getCategoriaById(id);
      final name = c.nombre;
      return name.length > 5 ? name.substring(0, 5) : name;
    }).toList();

    final maxBar = [...barGroups.expand((g) => g.barRods.map((r) => r.toY))].fold(0.0, (a, b) => a > b ? a : b);

    // Deudas summary
    final totalDeuda = deudasManuales.fold(0.0, (s, d) => s + d.monto);
    final totalPagado = deudasManuales.fold(0.0, (s, d) => s + d.pagado);
    final pendiente = totalDeuda - totalPagado;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadisticas'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Distribucion'),
            Tab(text: 'Mes vs Anterior'),
            Tab(text: 'Deudas'),
          ],
          indicatorColor: AppTheme.accent,
        ),
      ),
      body: Column(
        children: [
          if (mayorCat != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: mayorCat.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: mayorCat.color, width: 1),
              ),
              child: Row(
                children: [
                  Icon(mayorCat.icono, color: mayorCat.color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Mayor gasto del mes', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        Text('${mayorCat.nombre}: ${CurrencyFormatter.format(mayorMonto)}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: mayorCat.color, fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [

                // ── TAB 1: Distribucion (pie chart) ──
                gastos.isEmpty
                    ? const Center(child: Text('No hay gastos este mes.', style: TextStyle(color: AppTheme.textSecondary)))
                    : Column(
                        children: [
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 200,
                            child: PieChart(PieChartData(sections: sections, centerSpaceRadius: 35, sectionsSpace: 2)),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView.builder(
                              itemCount: gastosPorCat.length,
                              itemBuilder: (ctx, index) {
                                final catId = gastosPorCat.keys.elementAt(index);
                                final monto = gastosPorCat[catId]!;
                                final cat = getCategoriaById(catId);
                                final pct = resumenActual.gastos > 0 ? (monto / resumenActual.gastos * 100) : 0.0;
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: cat.color.withValues(alpha: 0.2),
                                    child: Icon(cat.icono, color: cat.color, size: 18),
                                  ),
                                  title: Text(cat.nombre),
                                  subtitle: LinearProgressIndicator(
                                    value: pct / 100,
                                    color: cat.color,
                                    backgroundColor: AppTheme.surfaceDark,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(CurrencyFormatter.format(monto), style: TextStyle(fontWeight: FontWeight.bold, color: cat.color, fontSize: 13)),
                                      Text('${pct.toStringAsFixed(1)}%', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                // ── TAB 2: Mes vs Anterior (bar chart) ──
                barGroups.isEmpty
                    ? const Center(child: Text('No hay datos para comparar.', style: TextStyle(color: AppTheme.textSecondary)))
                    : Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const _Legend(color: AppTheme.accent, label: 'Este mes'),
                                const SizedBox(width: 24),
                                const _Legend(color: Colors.grey, label: 'Mes anterior'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: BarChart(BarChartData(
                                maxY: maxBar > 0 ? maxBar * 1.2 : 100,
                                barGroups: barGroups,
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  getDrawingHorizontalLine: (v) => const FlLine(color: Colors.white10, strokeWidth: 1),
                                ),
                                borderData: FlBorderData(show: false),
                                titlesData: FlTitlesData(leftTitles: AxisTitles(sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 48,
                                    getTitlesWidget: (v, _) {
                                      if (v == 0) return const Text('0', style: TextStyle(fontSize: 9));
                                      if (v >= 1000000) return Text('${(v / 1000000).toStringAsFixed(1)}M', style: const TextStyle(fontSize: 9));
                                      if (v >= 1000) return Text('${(v / 1000).toStringAsFixed(0)}k', style: const TextStyle(fontSize: 9));
                                      return Text(v.toInt().toString(), style: const TextStyle(fontSize: 9));
                                    },
                                  )),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  bottomTitles: AxisTitles(sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (v, _) {
                                      final idx = v.toInt();
                                      if (idx < 0 || idx >= catLabels.length) return const SizedBox();
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(catLabels[idx], style: const TextStyle(fontSize: 9)),
                                      );
                                    },
                                  )),
                                ),
                                groupsSpace: 12,
                              )),
                            ),
                          ],
                        ),
                      ),

                // ── TAB 3: Deudas ──
                deudasManuales.isEmpty
                    ? const Center(child: Text('No hay deudas manuales registradas.', style: TextStyle(color: AppTheme.textSecondary)))
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Resumen general
                          Card(
                            color: AppTheme.cardDark,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  const Text('Resumen de Deudas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _StatChip(label: 'Total', value: CurrencyFormatter.format(totalDeuda), color: AppTheme.error),
                                      _StatChip(label: 'Pagado', value: CurrencyFormatter.format(totalPagado), color: Colors.green),
                                      _StatChip(label: 'Pendiente', value: CurrencyFormatter.format(pendiente), color: Colors.orange),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  LinearProgressIndicator(
                                    value: totalDeuda > 0 ? (totalPagado / totalDeuda).clamp(0.0, 1.0) : 0,
                                    color: Colors.green,
                                    backgroundColor: AppTheme.surfaceDark,
                                    minHeight: 10,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    totalDeuda > 0 ? 'Progreso total: ${(totalPagado / totalDeuda * 100).toStringAsFixed(1)}%' : 'Sin deudas registradas',
                                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Cada deuda
                          ...deudasManuales.map((d) {
                            final pct = d.monto > 0 ? (d.pagado / d.monto).clamp(0.0, 1.0) : 0.0;
                            return Card(
                              color: AppTheme.cardDark,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(d.titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        Text(CurrencyFormatter.format(d.monto), style: const TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text('${d.deudor} -> ${d.acreedor}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: pct,
                                      color: pct >= 1.0 ? Colors.green : AppTheme.accent,
                                      backgroundColor: AppTheme.surfaceDark,
                                      minHeight: 8,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('${(pct * 100).toStringAsFixed(1)}% pagado', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                        Text(CurrencyFormatter.format(d.pagado), style: const TextStyle(fontSize: 11, color: Colors.green)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 13)),
    ]);
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      ],
    );
  }
}