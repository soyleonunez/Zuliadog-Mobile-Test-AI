import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme.dart';
import '../../core/doc_theme.dart';
import '../../core/navigation.dart';
import '../menu.dart';

class DocumentItem {
  final String id;
  final String name; // p.ej. "Consentimiento Cirugía - Luna.pdf"
  final String? paciente; // "Luna (Gato)"
  final DateTime createdAt; // fecha
  final int sizeBytes; // tamaño
  final String? localPath; // ruta local si ya está descargado
  final String? previewUrl; // opcional: miniatura o dataURL

  const DocumentItem({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.sizeBytes,
    this.paciente,
    this.localPath,
    this.previewUrl,
  });
}

class VisorMedicoPage extends StatefulWidget {
  const VisorMedicoPage({super.key});

  static const route = '/visor-medico';

  @override
  State<VisorMedicoPage> createState() => _VisorMedicoPageState();
}

class _VisorMedicoPageState extends State<VisorMedicoPage> {
  // Supabase client
  final SupabaseClient _db = Supabase.instance.client;

  // Documentos desde Supabase
  List<DocumentItem> _docs = [];
  bool _loading = true;

  String _tableQuery = '';
  int? _selectedIndex;
  bool _gridView = false;
  bool _isFullscreen = false;

  // PDF state
  PdfControllerPinch? _pdfController;
  int _pdfPageCount = 0;
  int _pdfPage = 1;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    try {
      setState(() => _loading = true);

      // Cargar documentos desde Supabase
      final response = await _db
          .from('documents')
          .select('*')
          .order('created_at', ascending: false);

      final documents = response.map<DocumentItem>((doc) {
        return DocumentItem(
          id: doc['id'].toString(),
          name: doc['name'] ?? 'Sin nombre',
          paciente: doc['patient_name'],
          createdAt: DateTime.parse(doc['created_at']),
          sizeBytes: doc['size_bytes'] ?? 0,
          localPath: doc['local_path'],
          previewUrl: doc['preview_url'],
        );
      }).toList();

      setState(() {
        _docs = documents;
        _loading = false;
      });
    } catch (e) {
      print('Error cargando documentos: $e');
      setState(() {
        _loading = false;
        // Datos de ejemplo como fallback
        _docs = [
          DocumentItem(
            id: '1',
            name: 'Análisis de sangre - Max.pdf',
            paciente: 'Max (Perro)',
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
            sizeBytes: 2200000,
            localPath: null,
          ),
          DocumentItem(
            id: '2',
            name: 'Consentimiento Cirugía - Luna.pdf',
            paciente: 'Luna (Gato)',
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
            sizeBytes: 850000,
            localPath: null,
          ),
        ];
      });
    }
  }

  List<DocumentItem> get _filtered {
    final q = _tableQuery.trim().toLowerCase();
    final result = _docs.where((d) {
      if (q.isEmpty) return true;
      final inName = d.name.toLowerCase().contains(q);
      final inPac = (d.paciente ?? '').toLowerCase().contains(q);
      return inName || inPac;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  void _onSelect(int idx) {
    setState(() {
      _selectedIndex = idx;
      _loadPreviewFor(_filtered[idx]);
    });
  }

  Future<void> _loadPreviewFor(DocumentItem d) async {
    _pdfController?.dispose();
    _pdfController = null;
    _pdfPage = 1;
    _pdfPageCount = 0;

    final kind = kindFromName(d.name);
    if (kind == DocKind.pdf) {
      // Si tienes d.localPath, úsala. Si no, podrías cargar desde bytes/red.
      // Para demo, si no hay ruta, el PdfController no se carga (mostrar placeholder).
      if (d.localPath != null && await File(d.localPath!).exists()) {
        final controller = PdfControllerPinch(
          document: PdfDocument.openFile(d.localPath!),
          initialPage: 1,
        );
        controller.loadDocument(PdfDocument.openFile(d.localPath!));
        _pdfController = controller;
        // TODO: Implementar listener para pageCount
        setState(() {});
      }
    }
  }

  String _fmtSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    final gb = mb / 1024;
    return '${gb.toStringAsFixed(1)} GB';
  }

  // ==== UI ====

  @override
  Widget build(BuildContext context) {
    final selDoc = _selectedIndex != null && _selectedIndex! < _filtered.length
        ? _filtered[_selectedIndex!]
        : null;

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
            // ==== SIDEBAR ====
            AppSidebar(
              activeRoute: 'frame_visor_medico',
              onTap: (route) {
                if (route == 'frame_home') {
                  NavigationHelper.navigateToRoute(context, '/home');
                } else if (route == 'frame_visor_medico') {
                  // Ya estamos en el visor médico
                } else {
                  // Navegar a la página correspondiente
                  String routePath = '/home'; // fallback
                  switch (route) {
                    case 'frame_pacientes':
                      routePath = '/pacientes';
                      break;
                    case 'frame_historias':
                      routePath = '/historias';
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
              },
              userRole: UserRole.doctor,
            ),
            // ==== CONTENIDO PRINCIPAL ====
            Expanded(
              child: Column(
                children: [
                  _TopBar(
                    onRefresh: _loadDocuments,
                    onUpload: () {
                      // TODO: Implementar subida de archivos
                    },
                  ),
                  const Divider(height: 1, color: AppColors.neutral200),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ==== LISTA DE DOCUMENTOS ====
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _centerToolbar(),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: Card(
                                    elevation: 0,
                                    color: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: _loading
                                        ? const Center(
                                            child: CircularProgressIndicator(),
                                          )
                                        : _gridView
                                            ? _gridList(selDoc)
                                            : _tableList(selDoc),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // ==== PANEL DE PREVIEW ====
                          SizedBox(
                            width: 380,
                            child: _previewPanel(selDoc),
                          ),
                        ],
                      ),
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

  Widget _centerToolbar() {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: () {}, // TODO: subir (selector/drag)
          icon: const Icon(Icons.upload_file),
          label: const Text('Subir'),
        ),
        const SizedBox(width: AppTheme.space8),
        OutlinedButton.icon(
          onPressed: () {}, // TODO: filtros avanzados
          icon: const Icon(Icons.filter_list),
          label: const Text('Filtros'),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Refrescar',
          onPressed: () {},
          icon: const Icon(Icons.refresh),
        ),
        const SizedBox(width: AppTheme.space8),
        ToggleButtons(
          isSelected: [_gridView == false, _gridView == true],
          onPressed: (idx) => setState(() => _gridView = idx == 1),
          borderRadius: BorderRadius.circular(8),
          constraints: const BoxConstraints(minHeight: 38, minWidth: 44),
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.list),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.grid_view),
            ),
          ],
        ),
      ],
    );
  }

  // ==== Tabla (Lista densa) ====
  Widget _tableList(DocumentItem? selected) {
    final rows = _filtered;
    return Column(
      children: [
        // buscador tabla
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Buscar por nombre, paciente...',
                  ),
                  onChanged: (v) => setState(() => _tableQuery = v),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final d = rows[i];
              final isSel = selected != null && d.id == selected.id;
              final kind = kindFromName(d.name);
              final iconColor = colorForKind(kind);

              return InkWell(
                onTap: () => _onSelect(i),
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        isSel ? AppColors.primary500.withOpacity(0.07) : null,
                    border: Border(
                      left: BorderSide(
                        color:
                            isSel ? AppColors.primary500 : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(iconForKind(kind), color: iconColor, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: Text(
                          d.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.neutral900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: (d.paciente != null)
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(.12),
                                  border: Border.all(
                                      color: Colors.green.withOpacity(.35)),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  d.paciente!,
                                  style: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )
                            : Text('No asignado',
                                style: TextStyle(
                                  color: AppColors.neutral500,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: Text(
                          _fmtDate(d.createdAt),
                          style: const TextStyle(color: AppColors.neutral500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: Text(
                          _fmtSize(d.sizeBytes),
                          style: const TextStyle(color: AppColors.neutral500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Más',
                        onPressed: () {}, // TODO: menú ⋮
                        icon: const Icon(Icons.more_vert),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ==== Grid (Cards) ====
  Widget _gridList(DocumentItem? selected) {
    final rows = _filtered;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Buscar por nombre, paciente...',
                  ),
                  onChanged: (v) => setState(() => _tableQuery = v),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4,
            ),
            itemCount: rows.length,
            itemBuilder: (_, i) {
              final d = rows[i];
              final k = kindFromName(d.name);
              final c = colorForKind(k);
              final isSel = selected != null && d.id == selected.id;

              return InkWell(
                onTap: () => _onSelect(i),
                child: Card(
                  color: isSel
                      ? AppColors.primary500.withOpacity(0.05)
                      : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(iconForKind(k), color: c, size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                d.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.more_horiz),
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            DocBadge(d.name),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                d.paciente ?? 'No asignado',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: AppColors.neutral500),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _fmtDate(d.createdAt),
                                style: const TextStyle(
                                    color: AppColors.neutral500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _fmtSize(d.sizeBytes),
                              style:
                                  const TextStyle(color: AppColors.neutral500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ==== Panel de previsualización ====
  Widget _previewPanel(DocumentItem? d) {
    return Card(
      child: Column(
        children: [
          // header
          Container(
            padding: const EdgeInsets.all(AppTheme.space12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppTheme.neutral200),
              ),
            ),
            child: Row(
              children: [
                if (d != null) ...[
                  Icon(iconForKind(kindFromName(d.name)),
                      color: colorForKind(kindFromName(d.name))),
                  const SizedBox(width: AppTheme.space8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.headlineSmall),
                        Text(
                          '${_labelForName(d.name)} - ${_fmtSize(d.sizeBytes)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ] else
                  Text('Selecciona un documento',
                      style: Theme.of(context).textTheme.bodyMedium),
                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: () => setState(() => _selectedIndex = null),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // visor
          Expanded(
            child: Container(
              color: AppTheme.neutral50,
              padding: const EdgeInsets.all(AppTheme.space12),
              child: d == null ? const SizedBox.shrink() : _buildViewer(d),
            ),
          ),

          // acciones inferiores
          Container(
            padding: const EdgeInsets.all(AppTheme.space12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppTheme.neutral200),
              ),
            ),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: d == null
                      ? null
                      : () {
                          // TODO: descargar
                        },
                  icon: const Icon(Icons.download),
                  label: const Text(''),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space12,
                        vertical: AppTheme.space8),
                    minimumSize: const Size(44, 40),
                  ),
                ),
                const SizedBox(width: AppTheme.space8),
                OutlinedButton.icon(
                  onPressed: d == null
                      ? null
                      : () {
                          // TODO: imprimir
                        },
                  icon: const Icon(Icons.print),
                  label: const Text(''),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space12,
                        vertical: AppTheme.space8),
                    minimumSize: const Size(44, 40),
                  ),
                ),
                const SizedBox(width: AppTheme.space8),
                OutlinedButton.icon(
                  onPressed: d == null ? null : () {},
                  icon: const Icon(Icons.edit),
                  label: const Text(''),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space12,
                        vertical: AppTheme.space8),
                    minimumSize: const Size(44, 40),
                  ),
                ),
                const Spacer(),
                if (d != null && kindFromName(d.name) == DocKind.pdf)
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Zoom +',
                        onPressed: _pdfController == null
                            ? null
                            : () {
                                // TODO: Implementar zoom in
                              },
                        icon: const Icon(Icons.zoom_in),
                      ),
                      IconButton(
                        tooltip: 'Zoom -',
                        onPressed: _pdfController == null
                            ? null
                            : () {
                                // TODO: Implementar zoom out
                              },
                        icon: const Icon(Icons.zoom_out),
                      ),
                      const SizedBox(width: AppTheme.space8),
                      IconButton(
                        tooltip: 'Anterior',
                        onPressed: _pdfController == null || _pdfPage <= 1
                            ? null
                            : () {
                                _pdfController!.previousPage(
                                    curve: Curves.easeInOut,
                                    duration:
                                        const Duration(milliseconds: 150));
                                setState(() => _pdfPage =
                                    (_pdfPage - 1).clamp(1, _pdfPageCount));
                              },
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text(
                          '$_pdfPage / ${_pdfPageCount == 0 ? '-' : _pdfPageCount}',
                          style: Theme.of(context).textTheme.bodyMedium),
                      IconButton(
                        tooltip: 'Siguiente',
                        onPressed: _pdfController == null ||
                                (_pdfPageCount > 0 && _pdfPage >= _pdfPageCount)
                            ? null
                            : () {
                                _pdfController!.nextPage(
                                    curve: Curves.easeInOut,
                                    duration:
                                        const Duration(milliseconds: 150));
                                setState(() => _pdfPage = _pdfPage + 1);
                              },
                        icon: const Icon(Icons.chevron_right),
                      ),
                      const SizedBox(width: AppTheme.space8),
                      IconButton(
                        tooltip: 'Pantalla completa',
                        onPressed: () =>
                            setState(() => _isFullscreen = !_isFullscreen),
                        icon: const Icon(Icons.fullscreen),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // formulario de metadatos (debajo de acciones, como en tu HTML)
          Container(
            padding: const EdgeInsets.all(AppTheme.space12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.neutral200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fieldLabel('Tipo'),
                const SizedBox(height: AppTheme.space8),
                DropdownButtonFormField<String>(
                  initialValue: _guessTypeForSelected(),
                  items: const [
                    DropdownMenuItem(
                        value: 'Análisis', child: Text('Análisis')),
                    DropdownMenuItem(
                        value: 'Consentimiento', child: Text('Consentimiento')),
                    DropdownMenuItem(value: 'Receta', child: Text('Receta')),
                    DropdownMenuItem(value: 'Imagen', child: Text('Imagen')),
                  ],
                  onChanged: (v) {/* TODO: persistir */},
                ),
                const SizedBox(height: AppTheme.space12),
                _fieldLabel('Paciente/Mascota'),
                const SizedBox(height: AppTheme.space8),
                TextFormField(
                  initialValue: _selectedIndex != null &&
                          _selectedIndex! < _filtered.length
                      ? _filtered[_selectedIndex!].paciente
                      : '',
                  onChanged: (v) {/* TODO: persistir */},
                ),
                const SizedBox(height: AppTheme.space12),
                _fieldLabel('Tags'),
                const SizedBox(height: AppTheme.space8),
                TextFormField(
                  initialValue: 'cirugía, felino, urgente', // demo
                  onChanged: (v) {/* TODO: persistir */},
                ),
                const SizedBox(height: AppTheme.space12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {/* TODO: guardar (Ctrl+S) */},
                    child: const Text('Guardar Cambios (Ctrl+S)'),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildViewer(DocumentItem d) {
    final kind = kindFromName(d.name);
    if (kind == DocKind.pdf) {
      if (_pdfController == null) {
        // Placeholder si aún no hay ruta/ctrl PDF
        return _emptyPreview(
            'PDF no cargado (asigna d.localPath o carga desde red)');
      }
      return PdfViewPinch(
        controller: _pdfController!,
        onDocumentLoaded: (doc) async {
          // TODO: Implementar pageCount
          setState(() {
            _pdfPageCount = 1; // Placeholder
            _pdfPage = 1;
          });
        },
        onPageChanged: (page) => setState(() => _pdfPage = page),
      );
    } else if (kind == DocKind.image) {
      // Si tienes una ruta local
      if (d.localPath != null && File(d.localPath!).existsSync()) {
        return InteractiveViewer(
          child: Image.file(
            File(d.localPath!),
            fit: BoxFit.contain,
          ),
        );
      }
      // O puedes usar previewUrl (network) si tienes
      return _emptyPreview(
          'Imagen no disponible (asigna localPath o previewUrl)');
    } else {
      return _emptyPreview('Tipo no previsualizable. Usa “Descargar/Abrir”.');
    }
  }

  Widget _emptyPreview(String msg) {
    return Center(
      child: Text(
        msg,
        textAlign: TextAlign.center,
        style: TextStyle(color: AppTheme.neutral500),
      ),
    );
  }

  String _labelForName(String name) {
    final k = kindFromName(name);
    return switch (k) {
      DocKind.pdf => 'PDF Document',
      DocKind.word => 'Word Document',
      DocKind.sheets => 'Spreadsheet',
      DocKind.image => 'Image',
      DocKind.slides => 'Presentation',
      DocKind.text => 'Text File',
      DocKind.other => 'File',
    };
  }

  String _fmtDate(DateTime d) {
    // Simple dd MMM yyyy (puedes usar intl si prefieres)
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic'
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  String? _guessTypeForSelected() {
    if (_selectedIndex == null || _selectedIndex! >= _filtered.length) {
      return null;
    }
    final k = kindFromName(_filtered[_selectedIndex!].name);
    return switch (k) {
      DocKind.pdf => 'Consentimiento', // demo; mapea según tu lógica real
      DocKind.word => 'Análisis',
      DocKind.sheets => 'Análisis',
      DocKind.image => 'Imagen',
      DocKind.slides => 'Presentación',
      DocKind.text => 'Texto',
      DocKind.other => null,
    };
  }

  Widget _fieldLabel(String text) => Text(
        text,
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: AppTheme.neutral700, fontWeight: FontWeight.w600),
      );
}

// ==== TOPBAR ====
class _TopBar extends StatelessWidget {
  final VoidCallback onRefresh;
  final VoidCallback onUpload;

  const _TopBar({
    required this.onRefresh,
    required this.onUpload,
  });

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
            // Breadcrumb
            Row(
              children: [
                Text('Home',
                    style: AppText.bodyM.copyWith(color: AppColors.neutral500)),
                const SizedBox(width: 8),
                Icon(Iconsax.arrow_right_3,
                    size: 16, color: AppColors.neutral400),
                const SizedBox(width: 8),
                Text('Visor Médico',
                    style: AppText.bodyM.copyWith(
                        color: AppColors.neutral900,
                        fontWeight: FontWeight.w500)),
              ],
            ),
            const Spacer(),
            // Botones de acción
            _TopBarButton(
              icon: Iconsax.add,
              tooltip: 'Subir documento',
              onPressed: onUpload,
            ),
            const SizedBox(width: 8),
            _TopBarButton(
              icon: Iconsax.refresh,
              tooltip: 'Actualizar',
              onPressed: onRefresh,
            ),
            const SizedBox(width: 8),
            _TopBarButton(
              icon: Iconsax.notification,
              tooltip: 'Notificaciones',
              badge: '3',
              onPressed: () {},
            ),
            const SizedBox(width: 16),
            // Avatar de usuario
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary500, width: 2),
                ),
                child: const CircleAvatar(
                  radius: 16,
                  backgroundImage: AssetImage('Assets/Images/ProfileImage.png'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final String? badge;
  final VoidCallback onPressed;

  const _TopBarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          tooltip: tooltip,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.neutral50,
            foregroundColor: AppColors.neutral700,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            minimumSize: const Size(40, 40),
            padding: EdgeInsets.zero,
          ),
        ),
        if (badge != null)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: const BoxDecoration(
                color: AppColors.danger500,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                badge!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

// Intent classes for keyboard shortcuts
class SearchIntent extends Intent {
  const SearchIntent();
}

class SaveIntent extends Intent {
  const SaveIntent();
}

class PreviousPageIntent extends Intent {
  const PreviousPageIntent();
}

class NextPageIntent extends Intent {
  const NextPageIntent();
}
