import 'package:flutter/material.dart';

class ResourcesCard extends StatelessWidget {
  const ResourcesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    final resources = const [
      ('Planes de vacunación', Icons.vaccines),
      ('Desparasitación', Icons.health_and_safety),
      ('Dietas y guías', Icons.restaurant_menu),
      ('Libros digitales', Icons.menu_book),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text('Recursos', style: t.titleLarge),
                const Spacer(),
                TextButton(
                  onPressed: () {}, // TODO: ver todos
                  child: const Text('Ver todos'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: resources.map((e) {
                final (title, icon) = e;
                return ActionChip(
                  avatar: Icon(icon),
                  label: Text(title),
                  onPressed: () {}, // TODO: abrir recurso
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
