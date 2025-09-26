// lib/features/data/buscador.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Modelo de fila devuelta por la vista `v_app`
/// Mapea los campos de v_app a una estructura consistente
class PatientSearchRow {
  final String patientId;
  final String clinicId;
  final String patientName;
  final String? historyNumber; // MRN (ej. 001000)
  final int? mrnInt;
  final String? ownerName;
  final String? ownerPhone;
  final String? ownerEmail;
  final String? species;
  final String? breed;
  final String? breedId; // ID de la raza para obtener imagen
  final String? sex;

  PatientSearchRow({
    required this.patientId,
    required this.clinicId,
    required this.patientName,
    required this.historyNumber,
    required this.mrnInt,
    required this.ownerName,
    required this.ownerPhone,
    required this.ownerEmail,
    required this.species,
    required this.breed,
    required this.breedId,
    required this.sex,
  });

  factory PatientSearchRow.fromJson(Map<String, dynamic> j) {
    return PatientSearchRow(
      patientId:
          j['patient_id']?.toString() ?? j['patient_uuid']?.toString() ?? '',
      clinicId: j['clinic_id']?.toString() ?? '',
      patientName: j['patient_name']?.toString() ??
          j['paciente_name_snapshot']?.toString() ??
          '',
      historyNumber: j['history_number']?.toString() ??
          j['patient_mrn']?.toString() ??
          j['mrn']?.toString() ??
          j['history_number_snapshot']?.toString(),
      mrnInt: j['mrn_int'] is num ? (j['mrn_int'] as num).toInt() : null,
      ownerName:
          j['owner_name']?.toString() ?? j['owner_name_snapshot']?.toString(),
      ownerPhone: j['owner_phone']?.toString(),
      ownerEmail: j['owner_email']?.toString(),
      species: _getSpeciesLabel(j['patient_species_code']),
      breed: j['breed_label']?.toString() ?? j['breed']?.toString(),
      breedId: j['breed_id']?.toString(),
      sex: j['sex']?.toString(),
    );
  }

  static String _getSpeciesLabel(String? speciesCode) {
    switch (speciesCode?.toUpperCase()) {
      case 'CAN':
        return 'Canino';
      case 'FEL':
        return 'Felino';
      case 'AVE':
        return 'Ave';
      case 'EQU':
        return 'Equino';
      case 'BOV':
        return 'Bovino';
      case 'POR':
        return 'Porcino';
      case 'CAP':
        return 'Caprino';
      case 'OVI':
        return 'Ovino';
      default:
        return speciesCode ?? 'Sin especificar';
    }
  }
}

class SearchRepository {
  final SupabaseClient _db = Supabase.instance.client;

  /// Busca en v_app por MRN exacto, MRN numérico, nombre de paciente o nombre de dueño.
  Future<List<PatientSearchRow>> search(String query, {int limit = 30}) async {
    final q = query.trim();
    final isNumeric = int.tryParse(q.replaceAll(RegExp(r'\D'), '')) != null;

    final baseSel = _db.from('v_app').select('*');

    if (q.isEmpty) {
      // Lista inicial (suave): algunos pacientes ordenados por nombre
      final rows =
          await baseSel.order('patient_name', ascending: true).limit(limit);
      return rows.map((e) => PatientSearchRow.fromJson(e)).toList();
    }

    // OR compuesto para v_app:
    final ors = <String>[
      "patient_name.ilike.%$q%",
      "history_number.ilike.%$q%",
      "patient_mrn.ilike.%$q%",
      "mrn.ilike.%$q%",
      "owner_name.ilike.%$q%",
      "record_title.ilike.%$q%",
      if (isNumeric) ...[
        "history_number.eq.$q",
        "patient_mrn.eq.$q",
        "mrn.eq.$q",
      ],
    ];

    final rows = await baseSel
        .or(ors.join(','))
        .order('history_number', ascending: true, nullsFirst: true)
        .limit(limit);

    // Agrupar por patient_id para evitar duplicados
    final Map<String, Map<String, dynamic>> uniquePatients = {};
    for (final record in rows) {
      final patientId = record['patient_id'] ?? record['patient_uuid'];
      if (patientId != null && !uniquePatients.containsKey(patientId)) {
        uniquePatients[patientId] = record;
      }
    }

    return uniquePatients.values
        .map((e) => PatientSearchRow.fromJson(e))
        .toList();
  }
}

class BuscadorPage extends StatefulWidget {
  const BuscadorPage({super.key});

  @override
  State<BuscadorPage> createState() => _BuscadorPageState();
}

class _BuscadorPageState extends State<BuscadorPage> {
  final _controller = TextEditingController();
  final _repo = SearchRepository();
  Timer? _debounce;
  bool _loading = false;
  List<PatientSearchRow> _items = [];
  Object? _lastError;

  @override
  void initState() {
    super.initState();
    _runSearch(''); // carga inicial
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _runSearch(text);
    });
  }

  Future<void> _runSearch(String text) async {
    setState(() {
      _loading = true;
      _lastError = null;
    });
    try {
      final data = await _repo.search(text);
      setState(() => _items = data);
    } on PostgrestException catch (e) {
      setState(() => _lastError = '${e.message} (code: ${e.code})');
    } catch (e) {
      setState(() => _lastError = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openPatient(PatientSearchRow row) {
    // TODO: Navegar a tu visor de paciente (ej. visor.dart)
    // Navigator.push(context, MaterialPageRoute(
    //   builder: (_) => VisorPacientePage(patientId: row.patientId),
    // ));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Abrir paciente: ${row.patientName}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscador Zuliadog'),
        actions: [
          IconButton(
            tooltip: 'Limpiar',
            onPressed: () {
              _controller.clear();
              _runSearch('');
            },
            icon: const Icon(Icons.clear_all),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _controller,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: 'Buscar por MRN (#001000), paciente o dueño',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
            ),
          ),
          if (_lastError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Error: $_lastError',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: _items.isEmpty && !_loading
                ? const Center(child: Text('Sin resultados'))
                : ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final it = _items[i];
                      final subtitleParts = <String>[
                        if (it.historyNumber != null &&
                            it.historyNumber!.isNotEmpty)
                          'MRN: ${it.historyNumber}',
                        if (it.ownerName?.isNotEmpty == true)
                          'Dueño: ${it.ownerName}',
                        if ((it.species?.isNotEmpty ?? false) ||
                            (it.breed?.isNotEmpty ?? false))
                          [it.species, it.breed]
                              .where((e) => (e ?? '').isNotEmpty)
                              .join(' • '),
                        if (it.sex?.isNotEmpty == true) it.sex!,
                      ];
                      final subtitle = subtitleParts.join(' • ');

                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.pets)),
                        title: Text(it.patientName),
                        subtitle: Text(subtitle),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _openPatient(it),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: abrir formulario "nuevo paciente"
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
    );
  }
}
