import 'package:flutter/material.dart';
import '../services/history_service.dart';

/// Widget para mostrar la lista de historias médicas de un paciente
class MedicalRecordsList extends StatefulWidget {
  final String clinicId;
  final String mrn;
  final HistoryService historyService;

  const MedicalRecordsList({
    super.key,
    required this.clinicId,
    required this.mrn,
    required this.historyService,
  });

  @override
  State<MedicalRecordsList> createState() => _MedicalRecordsListState();
}

class _MedicalRecordsListState extends State<MedicalRecordsList> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.historyService.fetchRecords(
      clinicId: widget.clinicId,
      mrn: widget.mrn,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return _ErrorView(
            error: snap.error.toString(),
            onRetry: () {
              setState(() {
                _future = widget.historyService.fetchRecords(
                  clinicId: widget.clinicId,
                  mrn: widget.mrn,
                );
              });
            },
          );
        }
        final items = snap.data ?? [];
        if (items.isEmpty) {
          return const _EmptyView(
            title: 'Sin historias',
            subtitle: 'Registra la primera historia clínica para este MRN.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final r = items[i];
            return _RecordCard(record: r);
          },
        );
      },
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String title, subtitle;
  const _EmptyView({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.note_alt_outlined, size: 48),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(subtitle, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 8),
            Text('No se pudo cargar',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final Map<String, dynamic> record;
  const _RecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final date = (record['date'] ?? '').toString();
    final title = (record['title'] ?? 'Historia clínica');
    final diagnosis = (record['diagnosis'] ?? '—');
    final summary = (record['summary'] ?? 'Sin resumen');
    final attachments = (record['attachments'] ?? []) as List;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera
            Row(
              children: [
                const Icon(Icons.calendar_month, size: 18),
                const SizedBox(width: 6),
                Text(date, style: Theme.of(context).textTheme.labelMedium),
                const Spacer(),
                Chip(label: Text(record['department_code'] ?? 'MED')),
              ],
            ),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(summary),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.fact_check_outlined, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text('Dx: $diagnosis')),
              ],
            ),
            const SizedBox(height: 10),
            // Adjuntos
            if (attachments.isNotEmpty) ...[
              const Divider(),
              Text('Adjuntos', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: attachments
                    .map((a) =>
                        _AttachmentChip(att: Map<String, dynamic>.from(a)))
                    .toList(),
              )
            ],
          ],
        ),
      ),
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  final Map<String, dynamic> att;
  const _AttachmentChip({required this.att});

  @override
  Widget build(BuildContext context) {
    final label = (att['label'] ?? 'Documento').toString();
    final docType = (att['doc_type'] ?? 'other').toString();

    return ActionChip(
      avatar: Icon(_iconFor(docType)),
      label: Text(label),
      onPressed: () async {
        // TODO: Implementar apertura de archivo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Abrir: $label')),
        );
      },
    );
  }

  IconData _iconFor(String t) {
    switch (t) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'image':
        return Icons.image_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }
}
