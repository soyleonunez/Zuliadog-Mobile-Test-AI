import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:zuliadog/core/theme.dart';

class ClinicalKpiCard extends StatelessWidget {
  const ClinicalKpiCard({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Ejemplo: tiempo promedio de consulta (minutos) últimos 7 días
    final points = const [24.0, 22.0, 25.0, 21.0, 20.0, 23.0, 19.0];

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
                      'Indicadores clínicos',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.neutral900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tiempo promedio por consulta (7 días)',
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
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) =>
                      FlLine(color: Colors.black12, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      getTitlesWidget: (v, meta) => Text('${v.toInt()}m',
                          style: const TextStyle(fontSize: 11)),
                      interval: 5,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, meta) {
                        const labels = [
                          'Lu',
                          'Ma',
                          'Mi',
                          'Ju',
                          'Vi',
                          'Sa',
                          'Do'
                        ];
                        final i = v.toInt();
                        if (i < 0 || i >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(labels[i],
                            style: const TextStyle(fontSize: 11));
                      },
                      interval: 1,
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) => touchedSpots
                        .map(
                          (s) => LineTooltipItem(
                            '${s.y.toStringAsFixed(0)} min',
                            TextStyle(
                              color: scheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                        .toList(),
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (int i = 0; i < points.length; i++)
                        FlSpot(i.toDouble(), points[i]),
                    ],
                    isCurved: true,
                    barWidth: 3,
                    color: scheme.primary,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          scheme.primary.withOpacity(0.25),
                          scheme.primary.withOpacity(0.02),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.trending_down, color: scheme.primary, size: 18),
              const SizedBox(width: 6),
              Text(
                'Mejoró 3 min frente a la semana anterior',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
