import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../menu.dart';
import '../../core/navigation.dart';

/// =========================
/// CONFIGURACIÓN (ajustable)
/// =========================
const kTableRecords = 'medical_records'; // tabla de bloques
const kTableAttachments = 'record_attachments'; // tabla de adjuntos
const kTablePatients = 'patients'; // ficha del paciente
const kBucketRecords = 'medical_records'; // bucket binarios (PDF/IMG)

final _supa = Supabase.instance.client;

/// =========================
/// MODELOS SIMPLES
/// =========================
class HistoryBlock {
  final String id;
  final String patientId;
  final DateTime createdAt;
  final String author;
  final bool locked;
  final String deltaJson;
  final List<Attachment> attachments;

  HistoryBlock({
    required this.id,
    required this.patientId,
    required this.createdAt,
    required this.author,
    required this.locked,
    required this.deltaJson,
    required this.attachments,
  });

  HistoryBlock copyWith({
    bool? locked,
    String? deltaJson,
    List<Attachment>? attachments,
  }) {
    return HistoryBlock(
      id: id,
      patientId: patientId,
      createdAt: createdAt,
      author: author,
      locked: locked ?? this.locked,
      deltaJson: deltaJson ?? this.deltaJson,
      attachments: attachments ?? this.attachments,
    );
  }
}

class Attachment {
  final String id;
  final String name;
  final int size;
  final String mime;
  final String path;
  Attachment({
    required this.id,
    required this.name,
    required this.size,
    required this.mime,
    required this.path,
  });
}

class PatientSummary {
  final String id; // MRN o id
  final String name;
  final String species;
  final String breed;
  final String sex;
  final String ownerLastname;
  final String ageLabel;
  final double? temperature;
  final int? respiration;
  final int? pulse;
  final String? hydration;

  PatientSummary({
    required this.id,
    required this.name,
    required this.species,
    required this.breed,
    required this.sex,
    required this.ownerLastname,
    required this.ageLabel,
    this.temperature,
    this.respiration,
    this.pulse,
    this.hydration,
  });
}

/// =========================
/// REPO "INLINE" (en este mismo archivo)
/// =========================
class RecordsRepo {
  Future<List<HistoryBlock>> listBlocks(String patientId) async {
    final rows = await _supa
        .from(kTableRecords)
        .select(
            'id, patient_id, author, created_at, locked, content_delta, $kTableAttachments(id, name, mime, size, path)')
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((r) => HistoryBlock(
              id: r['id'] as String,
              patientId: r['patient_id'].toString(),
              author: (r['author'] ?? '—') as String,
              createdAt: DateTime.parse(r['created_at'] as String),
              locked: (r['locked'] ?? false) as bool,
              deltaJson: (r['content_delta'] ?? '[]').toString(),
              attachments: ((r[kTableAttachments] as List?) ?? [])
                  .map((a) => Attachment(
                        id: a['id'] as String,
                        name: a['name'] as String,
                        mime: a['mime'] as String,
                        size: (a['size'] ?? 0) as int,
                        path: a['path'] as String,
                      ))
                  .toList(),
            ))
        .toList();
  }

  Future<String> createBlock({
    required String patientId,
    required String author,
  }) async {
    final inserted = await _supa
        .from(kTableRecords)
        .insert({
          'patient_id': patientId,
          'author': author,
          'locked': false,
          'content_delta': '[]',
        })
        .select('id')
        .single();

    return inserted['id'] as String;
  }

  Future<void> setLocked(String recordId, bool locked) async {
    await _supa
        .from(kTableRecords)
        .update({'locked': locked}).eq('id', recordId);
  }

  Future<void> updateDelta(String recordId, String deltaJson) async {
    await _supa
        .from(kTableRecords)
        .update({'content_delta': deltaJson}).eq('id', recordId);
  }

  Future<Attachment> uploadAttachment({
    required String recordId,
    required String patientId,
    required PlatformFile file,
  }) async {
    // Path: records/<patient>/<record>/<filename>
    final path = 'records/$patientId/$recordId/${file.name}';
    final bytes = file.bytes ?? Uint8List(0);

    await _supa.storage.from(kBucketRecords).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(upsert: true, contentType: _guessMime(file)),
        );

    final row = await _supa
        .from(kTableAttachments)
        .insert({
          'record_id': recordId,
          'name': file.name,
          'mime': _guessMime(file),
          'size': file.size,
          'path': path,
        })
        .select()
        .single();

    return Attachment(
      id: row['id'] as String,
      name: row['name'] as String,
      mime: row['mime'] as String,
      size: (row['size'] ?? 0) as int,
      path: row['path'] as String,
    );
  }

  String getPublicUrl(String path) =>
      _supa.storage.from(kBucketRecords).getPublicUrl(path);
}

String _guessMime(PlatformFile f) {
  final ext = (f.extension ?? '').toLowerCase();
  if (ext == 'pdf') return 'application/pdf';
  if (['jpg', 'jpeg'].contains(ext)) return 'image/jpeg';
  if (ext == 'png') return 'image/png';
  return 'application/octet-stream';
}

class PatientsRepo {
  Future<PatientSummary?> getSummary(String patientIdOrMrn) async {
    final row = await _supa
        .from(kTablePatients)
        .select()
        .eq('id', patientIdOrMrn)
        .maybeSingle();
    if (row == null) return null;

    String _age(DateTime? birth) {
      if (birth == null) return '—';
      final now = DateTime.now();
      int y = now.year - birth.year;
      if (now.month < birth.month ||
          (now.month == birth.month && now.day < birth.day)) y--;
      return y <= 0 ? 'Menos de 1 año' : '$y años';
    }

    final birth =
        row['birth_date'] != null ? DateTime.parse(row['birth_date']) : null;

    return PatientSummary(
      id: row['id'].toString(), // o MRN si tu id es el MRN
      name: (row['name'] ?? '—').toString(),
      species: (row['species'] ?? '—').toString(),
      breed: (row['breed'] ?? '—').toString(),
      sex: (row['sex'] ?? '—').toString(),
      ownerLastname: (row['owner_lastname'] ?? '').toString(),
      ageLabel: _age(birth),
      temperature: (row['temperature'] as num?)?.toDouble(),
      respiration: (row['respiration'] as num?)?.toInt(),
      pulse: (row['pulse'] as num?)?.toInt(),
      hydration: row['hydration']?.toString(),
    );
  }
}

class HistoriasPage extends StatefulWidget {
  final String? patientId; // usa MRN o id
  final String authorName; // muestra en bloques nuevos

  const HistoriasPage({
    super.key,
    this.patientId,
    this.authorName = 'Doctor/a',
  });

  static const route = '/historias';

  @override
  State<HistoriasPage> createState() => _HistoriasPageState();
}

class _HistoriasPageState extends State<HistoriasPage> {
  final repo = RecordsRepo();
  final patients = PatientsRepo();

  PatientSummary? _patient;
  List<HistoryBlock> _blocks = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _initializeDateFormatting();
    // Para desarrollo, usar un patientId de prueba si no se proporciona uno
    final patientId = widget.patientId ?? 'test-patient-1';
    if (patientId != null) {
      _loadAll();
    }
  }

  Future<void> _initializeDateFormatting() async {
    await initializeDateFormatting('es_VE', null);
  }

  Future<void> _loadAll() async {
    final patientId = widget.patientId ?? 'test-patient-1';
    if (patientId == null) return;

    setState(() => _loading = true);
    final p = await patients.getSummary(patientId);
    final list = await repo.listBlocks(patientId);
    setState(() {
      _patient = p;
      _blocks = list;
      _loading = false;
    });
  }

  Future<void> _createBlock() async {
    final patientId = widget.patientId ?? 'test-patient-1';
    if (patientId == null) return;

    await repo.createBlock(
      patientId: patientId,
      author: widget.authorName,
    );
    final list = await repo.listBlocks(patientId);
    setState(() => _blocks = list);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        focusColor: AppColors.primary500.withOpacity(.12),
        hoverColor: AppColors.neutral50,
        splashColor: AppColors.primary500.withOpacity(.08),
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary500,
              secondary: AppColors.primary600,
              surface: Colors.white,
              onSurface: AppColors.neutral900,
            ),
      ),
      child: Scaffold(
        backgroundColor: AppColors.neutral50,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSidebar(
              activeRoute: 'frame_historias',
              onTap: (route) => _handleNavigation(context, route),
              userRole: UserRole.doctor,
            ),
            Expanded(
              child: Column(
                children: [
                  _TopBar(
                    title: 'Historias Médicas',
                    onExport: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Exportar (pendiente)')),
                      );
                    },
                  ),
                  const Divider(height: 1, color: AppColors.neutral200),
                  Expanded(
                    child: _loading
                        ? _LoadingState()
                        : _HistoriesContent(
                            patient: _patient,
                            blocks: _blocks,
                            loading: _loading,
                            query: _query,
                            onQueryChanged: (q) => setState(() => _query = q),
                            onCreateBlock: _createBlock,
                            onToggleLock: (block, locked) async {
                              await repo.setLocked(block.id, locked);
                              setState(() {
                                final index =
                                    _blocks.indexWhere((b) => b.id == block.id);
                                if (index != -1) {
                                  _blocks[index] =
                                      _blocks[index].copyWith(locked: locked);
                                }
                              });
                            },
                            onSaveDelta: (block, deltaJson) async {
                              await repo.updateDelta(block.id, deltaJson);
                            },
                            onAddFiles: (block, files) async {
                              final list = [...block.attachments];
                              for (final f in files) {
                                final att = await repo.uploadAttachment(
                                  recordId: block.id,
                                  patientId: block.patientId,
                                  file: f,
                                );
                                list.add(att);
                              }
                              setState(() {
                                final index =
                                    _blocks.indexWhere((b) => b.id == block.id);
                                if (index != -1) {
                                  _blocks[index] = _blocks[index]
                                      .copyWith(attachments: list);
                                }
                              });
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNavigation(BuildContext context, String route) {
    if (route == 'frame_home') {
      NavigationHelper.navigateToRoute(context, '/home');
    } else if (route == 'frame_historias') {
      // Ya estamos en historias
    } else {
      // Navegar a la página correspondiente
      String routePath = '/home'; // fallback
      switch (route) {
        case 'frame_pacientes':
          routePath = '/pacientes';
          break;
        case 'frame_recetas':
          routePath = '/recetas';
          break;
        case 'frame_laboratorio':
          routePath = '/laboratorio';
          break;
        case 'frame_agenda':
          routePath = '/agenda';
          break;
        case 'frame_visor_medico':
          routePath = '/visor-medico';
          break;
        case 'frame_recursos':
          routePath = '/recursos';
          break;
        case 'frame_tickets':
          routePath = '/tickets';
          break;
        case 'frame_reportes':
          routePath = '/reportes';
          break;
      }
      NavigationHelper.navigateToRoute(context, routePath);
    }
  }
}

/// =========================
/// WIDGETS AUXILIARES
/// =========================

class _PatientSelectionView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medical_services,
            size: 64,
            color: AppColors.neutral400,
          ),
          const SizedBox(height: 16),
          Text(
            'Historias Médicas',
            style: AppText.titleL.copyWith(
              color: AppColors.neutral700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selecciona un paciente para ver sus historias clínicas',
            style: AppText.bodyM.copyWith(
              color: AppColors.neutral500,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoriesContent extends StatelessWidget {
  final PatientSummary? patient;
  final List<HistoryBlock> blocks;
  final bool loading;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onCreateBlock;
  final Future<void> Function(HistoryBlock block, bool locked) onToggleLock;
  final Future<void> Function(HistoryBlock block, String deltaJson) onSaveDelta;
  final Future<void> Function(HistoryBlock block, List<PlatformFile> files)
      onAddFiles;

  const _HistoriesContent({
    required this.patient,
    required this.blocks,
    required this.loading,
    required this.query,
    required this.onQueryChanged,
    required this.onCreateBlock,
    required this.onToggleLock,
    required this.onSaveDelta,
    required this.onAddFiles,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Contenido principal
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.search),
                                hintText:
                                    'Buscar por texto dentro de los bloques…',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: onQueryChanged,
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: onCreateBlock,
                            icon: const Icon(Icons.add),
                            label: const Text('Nuevo bloque de historia'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: blocks.isEmpty
                            ? const _EmptyState()
                            : ListView.separated(
                                itemCount: blocks.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, i) {
                                  final b = blocks[i];
                                  if (query.trim().isNotEmpty &&
                                      !b.deltaJson
                                          .toLowerCase()
                                          .contains(query.toLowerCase())) {
                                    return const SizedBox.shrink();
                                  }
                                  return HistoryBlockCard(
                                    block: b,
                                    dateFmt: DateFormat(
                                        'd MMMM y, hh:mm a', 'es_VE'),
                                    onToggleLock: (locked) =>
                                        onToggleLock(b, locked),
                                    onSaveDelta: (deltaJson) =>
                                        onSaveDelta(b, deltaJson),
                                    onAddFiles: (files) => onAddFiles(b, files),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
          ),
        ),
        // Sidebar derecha (Ficha del paciente)
        if (patient != null)
          SizedBox(
            width: 320,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                      color: Theme.of(context).dividerColor, width: 1),
                ),
              ),
              child: _PatientSidebar(summary: patient!),
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_add_outlined,
              size: 64, color: Theme.of(context).hintColor),
          const SizedBox(height: 12),
          const Text('Aún no hay bloques. Crea el primero.'),
        ],
      ),
    );
  }
}

class HistoryBlockCard extends StatefulWidget {
  final HistoryBlock block;
  final DateFormat dateFmt;
  final Future<void> Function(bool locked) onToggleLock;
  final Future<void> Function(String deltaJson) onSaveDelta;
  final Future<void> Function(List<PlatformFile> files) onAddFiles;

  const HistoryBlockCard({
    super.key,
    required this.block,
    required this.dateFmt,
    required this.onToggleLock,
    required this.onSaveDelta,
    required this.onAddFiles,
  });

  @override
  State<HistoryBlockCard> createState() => _HistoryBlockCardState();
}

class _HistoryBlockCardState extends State<HistoryBlockCard> {
  late TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.block.deltaJson);
    _controller.addListener(() {
      if (widget.block.locked) return;
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 700), () async {
        await widget.onSaveDelta(_controller.text);
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.block;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.dateFmt.format(b.createdAt),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    Text('Autor: ${b.author}',
                        style: TextStyle(color: Theme.of(context).hintColor)),
                  ],
                ),
                Row(
                  children: [
                    _StatusChip(locked: b.locked),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'toggle',
                          child: Text(b.locked ? 'Desbloquear' : 'Bloquear'),
                        ),
                        const PopupMenuItem(
                          value: 'duplicate',
                          child: Text('Duplicar'),
                        ),
                        const PopupMenuItem(
                          value: 'history',
                          child: Text('Ver historial'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Eliminar'),
                        ),
                      ],
                      onSelected: (v) async {
                        if (v == 'toggle') {
                          await widget.onToggleLock(!b.locked);
                          setState(() {});
                        } else if (v == 'duplicate') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Duplicar (pendiente)')),
                          );
                        } else if (v == 'delete') {
                          // TODO: borrar bloque (si lo habilitas)
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // EDITOR
            AbsorbPointer(
              absorbing: b.locked,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: TextField(
                  controller: _controller,
                  readOnly: b.locked,
                  maxLines: 10,
                  decoration: const InputDecoration(
                    hintText: 'Escribe la historia médica aquí...',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // DROP + LISTA ADJUNTOS
            _DropAttach(
              onPicked: (files) => widget.onAddFiles(files),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  b.attachments.map((a) => _AttachmentPill(att: a)).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool locked;
  const _StatusChip({required this.locked});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: locked
            ? Colors.red.withOpacity(0.1)
            : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: locked ? Colors.red : Colors.green,
          width: 1,
        ),
      ),
      child: Text(
        locked ? 'Bloqueado' : 'Editable',
        style: TextStyle(
          color: locked ? Colors.red : Colors.green,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DropAttach extends StatelessWidget {
  final Function(List<PlatformFile>) onPicked;

  const _DropAttach({required this.onPicked});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await FilePicker.platform.pickFiles(allowMultiple: true);
        if (result != null) {
          onPicked(result.files);
        }
      },
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).dividerColor,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            'Haz clic para seleccionar archivos',
            style: TextStyle(
              color: Theme.of(context).hintColor,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _AttachmentPill extends StatelessWidget {
  final Attachment att;

  const _AttachmentPill({required this.att});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor,
          width: 1,
        ),
      ),
      child: Text(
        att.name,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PatientSidebar extends StatelessWidget {
  final PatientSummary summary;

  const _PatientSidebar({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ficha del Paciente',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _InfoRow(label: 'Nombre', value: summary.name),
          _InfoRow(label: 'Especie', value: summary.species),
          _InfoRow(label: 'Raza', value: summary.breed),
          _InfoRow(label: 'Sexo', value: summary.sex),
          _InfoRow(label: 'Dueño', value: summary.ownerLastname),
          _InfoRow(label: 'Edad', value: summary.ageLabel),
          if (summary.temperature != null)
            _InfoRow(label: 'Temperatura', value: '${summary.temperature}°C'),
          if (summary.respiration != null)
            _InfoRow(label: 'Respiración', value: '${summary.respiration} rpm'),
          if (summary.pulse != null)
            _InfoRow(label: 'Pulso', value: '${summary.pulse} bpm'),
          if (summary.hydration != null)
            _InfoRow(label: 'Hidratación', value: summary.hydration!),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).hintColor,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary500.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.medical_services,
              size: 40,
              color: AppColors.primary500,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Cargando historias médicas...',
            style: AppText.titleM.copyWith(
              color: AppColors.neutral700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Por favor espera mientras se cargan los datos del paciente',
            style: AppText.bodyM.copyWith(
              color: AppColors.neutral500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary500),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final VoidCallback? onExport;

  const _TopBar({required this.title, this.onExport});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: AppColors.neutral200, width: 1),
          ),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: AppText.titleM.copyWith(
                color: AppColors.neutral900,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (onExport != null)
              TextButton.icon(
                onPressed: onExport,
                icon: const Icon(Icons.description_outlined),
                label: const Text('Exportar historia'),
              ),
            const SizedBox(width: 16),
            const CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage('Assets/Images/ProfileImage.png'),
            ),
          ],
        ),
      ),
    );
  }
}
