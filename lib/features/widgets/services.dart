import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:zuliadog/core/theme.dart';

class ServicesCard extends StatelessWidget {
  const ServicesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final data = [
      _Slice('Consulta', 38, Colors.blue),
      _Slice('Vacunación', 24, Colors.teal),
      _Slice('Cirugía', 12, Colors.purple),
      _Slice('Grooming', 16, Colors.orange),
      _Slice('Emergencia', 10, Colors.red),
    ];

    final int total = data.fold<int>(0, (a, b) => a + b.value);

    return SectionCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Distribución de servicios',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.neutral900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Últimos 30 días',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.neutral500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Row(
              children: [
                Expanded(
                  flex: 6,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 48,
                      startDegreeOffset: -90,
                      sections: [
                        for (final s in data)
                          PieChartSectionData(
                            value: s.value.toDouble(),
                            color: s.color.withOpacity(0.85),
                            title:
                                '${((s.value / total) * 100).toStringAsFixed(0)}%',
                            titleStyle: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                            radius: 90,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 5,
                  child: _Legend(data: data, total: total),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Slice {
  final String label;
  final int value;
  final Color color;
  _Slice(this.label, this.value, this.color);
}

class _Legend extends StatelessWidget {
  final List<_Slice> data;
  final int total;
  const _Legend({required this.data, required this.total});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in data) ...[
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: s.color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(s.label, style: t.bodyMedium)),
              Text(
                '${s.value}',
                style: t.bodyMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        const Divider(),
        Row(
          children: [
            Text('Total',
                style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('$total',
                style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }
}
