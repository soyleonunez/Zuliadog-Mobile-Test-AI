import 'package:flutter/material.dart';

class MedRecordsCard extends StatelessWidget {
  const MedRecordsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    final items = const [
      ('Luna', 'Consulta general · 12/09'),
      ('Milo', 'Vacunación · 12/09'),
      ('Rocky', 'Control post-op · 11/09'),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text('Historias médicas', style: t.titleLarge),
                const Spacer(),
                TextButton(
                  onPressed: () {}, // TODO: ver todas
                  child: const Text('Ver todas'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...items.map((e) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.folder_shared),
                  title: Text(e.$1),
                  subtitle: Text(e.$2),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {}, // TODO: abrir historia
                )),
          ],
        ),
      ),
    );
  }
}
