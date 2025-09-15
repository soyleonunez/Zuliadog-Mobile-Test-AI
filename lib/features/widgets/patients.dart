import 'package:flutter/material.dart';

class PatientsCard extends StatefulWidget {
  const PatientsCard({super.key});

  @override
  State<PatientsCard> createState() => _PatientsCardState();
}

class _PatientsCardState extends State<PatientsCard> {
  final _controller = TextEditingController();
  final _results = <Map<String, String>>[
    {'name': 'Luna', 'species': 'Canina', 'owner': 'María P.'},
    {'name': 'Milo', 'species': 'Felina', 'owner': 'José R.'},
  ];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text('Pacientes', style: t.titleLarge),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () {}, // TODO: crear historia
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva historia'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Nombre de la mascota o del dueño…',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final r = _results[i];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.pets)),
                  title: Text('${r['name']} · ${r['species']}'),
                  subtitle: Text('Dueño: ${r['owner']}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {}, // TODO: abrir ficha
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
