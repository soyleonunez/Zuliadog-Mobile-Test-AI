import 'package:flutter/material.dart';

/// =====================
///  HOME (pantalla completa)
/// =====================
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zuliadog Dashboard')),
      body: const HomeBody(), // usamos el cuerpo reutilizable
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
    );
  }
}

/// =====================
///  HOME BODY (para incrustar en shells)
/// =====================
class HomeBody extends StatelessWidget {
  const HomeBody({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _Header(),
        SizedBox(height: 16),
        _KpiGrid(),
        SizedBox(height: 16),
        _RevenueCard(),
        SizedBox(height: 16),
        _PieAndPerf(),
        SizedBox(height: 16),
        _TransactionsCard(),
        SizedBox(height: 24),
      ],
    );
  }
}

/// ===================== Secciones =====================

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, c) {
            final isWide = c.maxWidth > 720;
            final left = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bienvenido 👋', style: t.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  'Resumen de actividad y métricas clave',
                  style: t.bodyMedium?.copyWith(color: Colors.grey[700]),
                ),
              ],
            );

            final right = Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Exportar'),
                ),
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.trending_up),
                  label: const Text('Crear reporte'),
                ),
              ],
            );

            return isWide
                ? Row(children: [left, const Spacer(), right])
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [left, const SizedBox(height: 12), right],
                  );
          },
        ),
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid();

  @override
  Widget build(BuildContext context) {
    const data = [
      ('Pacientes', '128', Icons.pets),
      ('Citas hoy', '14', Icons.event_available),
      ('Docs subidos', '56', Icons.folder_shared),
      ('Tickets abiertos', '7', Icons.receipt_long),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final cross = c.maxWidth >= 1100 ? 4 : (c.maxWidth >= 720 ? 2 : 1);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: data.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cross,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.6,
          ),
          itemBuilder: (_, i) => _KpiCard(
            title: data[i].$1,
            value: data[i].$2,
            icon: data[i].$3,
          ),
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _KpiCard(
      {required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: t.labelLarge?.copyWith(color: Colors.grey[700])),
                  const SizedBox(height: 4),
                  Text(value,
                      style: t.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Icon(Icons.arrow_outward, color: Colors.grey[500]),
          ],
        ),
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  const _RevenueCard();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    // Placeholder de gráfico sin libs
    Widget miniChart() => Container(
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                scheme.primaryContainer,
                scheme.secondaryContainer,
              ],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
            ),
          ),
          child: const Center(child: Icon(Icons.show_chart)),
        );

    Widget leftContent() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ingresos del mes', style: t.titleLarge),
            const SizedBox(height: 8),
            Text('Comparativa vs. mes anterior',
                style: t.bodyMedium?.copyWith(color: Colors.grey[700])),
            const SizedBox(height: 16),
            Text('\$ 12,430',
                style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.arrow_upward, size: 18, color: scheme.primary),
                const SizedBox(width: 4),
                Text('+8.2%',
                    style: t.bodyMedium?.copyWith(color: scheme.primary)),
                const SizedBox(width: 10),
                Text('vs. \$11,480',
                    style: t.bodySmall?.copyWith(color: Colors.grey[600])),
              ],
            ),
          ],
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, c) {
            final isWide = c.maxWidth > 900;

            if (isWide) {
              return Row(
                children: [
                  Expanded(flex: 2, child: leftContent()),
                  const SizedBox(width: 16),
                  Expanded(flex: 3, child: miniChart()),
                ],
              );
            } else {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  leftContent(),
                  const SizedBox(height: 16),
                  miniChart(),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}

class _PieAndPerf extends StatelessWidget {
  const _PieAndPerf();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final isWide = c.maxWidth > 1100;

      if (isWide) {
        return Row(
          children: const [
            Expanded(child: _PieCard(title: 'Servicios')),
            SizedBox(width: 12),
            Expanded(child: _PerfCard(title: 'Rendimiento semanal')),
          ],
        );
      } else {
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PieCard(title: 'Servicios'),
            SizedBox(height: 12),
            _PerfCard(title: 'Rendimiento semanal'),
          ],
        );
      }
    });
  }
}

class _PieCard extends StatelessWidget {
  final String title;
  const _PieCard({required this.title});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    Widget fakePie() => Container(
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(colors: [
              scheme.primaryContainer,
              scheme.secondaryContainer,
              scheme.tertiaryContainer,
              scheme.primaryContainer,
            ]),
          ),
          child: const Center(child: Icon(Icons.pie_chart_outline_rounded)),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: t.titleLarge),
          const SizedBox(height: 12),
          fakePie(),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _LegendDot(label: 'Consulta'),
              _LegendDot(label: 'Vacuna'),
              _LegendDot(label: 'Cirugía'),
              _LegendDot(label: 'Otros'),
            ],
          ),
        ]),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final String label;
  const _LegendDot({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
            color: scheme.primary, borderRadius: BorderRadius.circular(4)),
      ),
      const SizedBox(width: 6),
      Text(label),
    ]);
  }
}

class _PerfCard extends StatelessWidget {
  final String title;
  const _PerfCard({required this.title});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    // Gradient usando withValues (no deprecado)
    Widget trend() => Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                scheme.primary.withValues(alpha: .15),
                scheme.primary.withValues(alpha: .35),
              ],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
            ),
          ),
          child: const Center(child: Icon(Icons.multiline_chart)),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: t.titleLarge),
          const SizedBox(height: 12),
          trend(),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.arrow_upward, size: 18, color: scheme.primary),
              const SizedBox(width: 6),
              Text('Mejora +4.1% esta semana',
                  style: t.bodyMedium?.copyWith(color: scheme.primary)),
            ],
          ),
        ]),
      ),
    );
  }
}

class _TransactionsCard extends StatelessWidget {
  const _TransactionsCard();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final items = List.generate(
      8,
      (i) => (
        'Transacción #${1000 + i}',
        i.isEven ? 'Completada' : 'Pendiente',
        i.isEven
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text('Transacciones recientes', style: t.titleLarge),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) => ListTile(
              leading: CircleAvatar(child: Text('${i + 1}')),
              title: Text(items[i].$1),
              subtitle: Text(items[i].$2),
              trailing: Icon(
                items[i].$3 ? Icons.check_circle : Icons.timelapse,
                color: items[i].$3 ? Colors.green : Colors.orange,
              ),
              onTap: () {},
            ),
          ),
        ]),
      ),
    );
  }
}
