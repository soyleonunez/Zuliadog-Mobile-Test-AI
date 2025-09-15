import 'package:flutter/material.dart';

class AppointmentsCard extends StatelessWidget {
  const AppointmentsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    final items = const [
      ('08:30', 'Consulta general', 'Luna · Canina'),
      ('09:15', 'Vacunación', 'Milo · Felina'),
      ('10:00', 'Control post-op', 'Rocky · Canina'),
      ('11:30', 'Rayos X', 'Nina · Felina'),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text('Citas de hoy', style: t.titleLarge),
                const Spacer(),
                FilledButton.tonal(
                  onPressed: () {}, // TODO: ir a calendario
                  child: const Text('Ver calendario'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final (time, title, who) = items[i];
                return ListTile(
                  leading: CircleAvatar(child: Text(time)),
                  title: Text(title),
                  subtitle: Text(who),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {}, // TODO: abrir detalle cita
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
