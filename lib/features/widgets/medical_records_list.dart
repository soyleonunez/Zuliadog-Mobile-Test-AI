import 'package:flutter/material.dart';
import '../services/history_service.dart';
import 'history_text_editor.dart';

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
            return HistoryTextEditor(
              record: r,
              historyService: widget.historyService,
              onSaved: () {
                // Recargar la lista cuando se guarde un cambio
                setState(() {
                  _future = widget.historyService.fetchRecords(
                    clinicId: widget.clinicId,
                    mrn: widget.mrn,
                  );
                });
              },
            );
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
