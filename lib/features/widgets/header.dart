import 'package:flutter/material.dart';

class HeaderWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  const HeaderWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
  });

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
                Text(title, style: t.headlineSmall),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: t.bodyMedium?.copyWith(color: Colors.grey[700]),
                  ),
                ],
              ],
            );

            final right = Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () {}, // TODO: abrir calendario
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Calendario'),
                ),
                FilledButton.icon(
                  onPressed: () {}, // TODO: crear cita
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva cita'),
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
