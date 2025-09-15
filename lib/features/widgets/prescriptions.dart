import 'package:flutter/material.dart';

class PrescriptionsCard extends StatelessWidget {
  const PrescriptionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    final items = const [
      ('Milo · Amoxicilina', '5 días · 250mg'),
      ('Nina · Antiinflamatorio', '3 días · 50mg'),
      ('Simba · Antiparasitario', 'Única dosis'),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text('Recetas emitidas', style: t.titleLarge),
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
                  leading: const Icon(Icons.medication),
                  title: Text(e.$1),
                  subtitle: Text(e.$2),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {}, // TODO: abrir receta
                )),
          ],
        ),
      ),
    );
  }
}
