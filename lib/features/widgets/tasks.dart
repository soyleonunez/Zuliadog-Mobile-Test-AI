import 'package:flutter/material.dart';

class TasksCard extends StatelessWidget {
  const TasksCard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    final tasks = [
      ('Revisar resultados de laboratorio de Nina', false),
      ('Imprimir receta de Luna', true),
      ('Confirmar cita de vacunación de Milo', false),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text('Tareas del día', style: t.titleLarge),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {}, // TODO: ver todas
                  icon: const Icon(Icons.list_alt),
                  label: const Text('Ver todas'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...tasks.map((tup) {
              final (text, done) = tup;
              return CheckboxListTile(
                value: done,
                onChanged: (_) {}, // TODO: toggle
                title: Text(text),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              );
            }),
          ],
        ),
      ),
    );
  }
}
