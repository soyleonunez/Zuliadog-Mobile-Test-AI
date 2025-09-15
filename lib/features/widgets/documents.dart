import 'package:flutter/material.dart';

class DocumentsCard extends StatelessWidget {
  const DocumentsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    final items = const [
      ('Hemograma — Nina.pdf', 'Pendiente de revisión'),
      ('Radiografía — Rocky.pdf', 'Aprobado'),
      ('Consentimiento — Simba.pdf', 'Pendiente de firma'),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text('Bandeja de documentos', style: t.titleLarge),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {}, // TODO: subir
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Subir'),
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
                final (title, status) = items[i];
                return ListTile(
                  leading:
                      const CircleAvatar(child: Icon(Icons.picture_as_pdf)),
                  title: Text(title),
                  subtitle: Text(status),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {}, // TODO: abrir visor
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
