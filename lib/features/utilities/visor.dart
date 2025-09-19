// lib/visor.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdfx/pdfx.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/theme.dart';
import '../../core/navigation.dart';
import '../../features/data/storage_helper.dart';
import '../../features/data/file_service.dart';
// import '../../features/widgets/file_viewer_dialog.dart'; // Archivo eliminado
import '../menu.dart';

// ======= Utils de tipo de documento =======
enum DocKind { pdf, image, table, word, other }

DocKind kindFromName(String name) {
  final parts = name.split('.');
  final ext = parts.length > 1 ? parts.last.toLowerCase() : '';
  if (ext == 'pdf') return DocKind.pdf;
  if (['png', 'jpg', 'jpeg', 'webp', 'gif'].contains(ext)) return DocKind.image;
  if (['csv', 'xls', 'xlsx'].contains(ext)) return DocKind.table;
  if (['doc', 'docx', 'rtf'].contains(ext)) return DocKind.word;
  return DocKind.other;
}

IconData iconForKind(DocKind k) {
  switch (k) {
    case DocKind.pdf:
      return Icons.picture_as_pdf;
    case DocKind.image:
      return Icons.image;
    case DocKind.table:
      return Icons.grid_on;
    case DocKind.word:
      return Icons.description;
    case DocKind.other:
      return Icons.insert_drive_file;
  }
}

Color colorForKind(DocKind k) {
  switch (k) {
    case DocKind.pdf:
      return AppTheme.danger500; // rojo
    case DocKind.word:
      return const Color(0xFF3B82F6); // azul
    case DocKind.table:
      return AppTheme.success500; // verde
    case DocKind.image:
      return AppTheme.warning500; // amarillo
    case DocKind.other:
      return AppTheme.neutral500; // gris
  }
}

// ======= Modelo de ítem en UI =======
// Ya no se usa, reemplazado por DocItem del storage_helper

// ======= Variables de estado =======
List<DocItem> _docs = [];
int? _selectedIndex;
PdfControllerPinch? _pdfController;
bool _isLoading = false;
String? _errorMessage;

// ======= Pantalla principal del visor =======
class VisorPage extends StatefulWidget {
  const VisorPage({super.key});

  @override
  State<VisorPage> createState() => _VisorPageState();
}

class _VisorPageState extends State<VisorPage> {
  // Carga inicial: indexar inbox y cargar lista
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Agregar timeout para evitar que se cuelgue
      await _fetchDocs().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout: La operación tardó demasiado');
        },
      );
    } catch (e) {
      print('❌ Error en bootstrap del visor: $e');
      setState(() {
        _errorMessage = 'Error inicializando: $e';
        _isLoading = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchDocs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Usar el método de emergencia para evitar storage.search
      final list = await listDocsEmergency();

      setState(() {
        _docs = list;
        _selectedIndex = _docs.isEmpty ? null : 0;
        _isLoading = false;
      });
      if (_selectedIndex != null) {
        try {
          await _loadPreviewFor(_docs[_selectedIndex!]);
        } catch (e) {
          print('❌ Error al cargar preview: $e');
          setState(() {
            _errorMessage = 'Error al cargar preview: $e';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar documentos: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPreviewFor(DocItem d) async {
    // limpia PDF previo
    _pdfController?.dispose();
    _pdfController = null;

    // descarga a cache usando la URL pública
    final local = await _downloadToCache(d.url, d.name);
    final idx = _docs.indexOf(d);
    if (idx != -1) {
      // Crear nuevo DocItem con localPath
      final updatedDoc = DocItem(
        name: d.name,
        path: d.path,
        url: d.url,
        updatedAt: d.updatedAt,
      );
      _docs[idx] = updatedDoc;
    }

    // si es PDF, crea controlador con manejo de errores
    final ext = d.name.split('.').last.toLowerCase();
    if (ext == 'pdf') {
      try {
        // Verificar que el archivo local existe
        final file = File(local);
        if (!await file.exists()) {
          throw Exception('El archivo PDF no existe localmente: $local');
        }

        // Verificar que el archivo no esté vacío
        final fileSize = await file.length();
        if (fileSize == 0) {
          throw Exception('El archivo PDF está vacío');
        }

        print('📄 Intentando abrir PDF: $local (${fileSize} bytes)');

        // Crear el controlador PDF con manejo de errores
        _pdfController =
            PdfControllerPinch(document: PdfDocument.openFile(local));

        print('✅ PDF abierto exitosamente');
      } catch (e) {
        print('❌ Error al abrir PDF: $e');

        // Limpiar el controlador si falla
        _pdfController?.dispose();
        _pdfController = null;

        // Mostrar mensaje de error al usuario
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al abrir el archivo PDF: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }
    }
    setState(() {});
  }

  Future<String> _downloadToCache(String url, String filename) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final localPath = p.join(tempDir.path, filename);

      print('📥 Descargando archivo: $url -> $localPath');

      final dio = Dio();

      // Configurar opciones para manejar errores 400
      final response = await dio.download(
        url,
        localPath,
        options: Options(
          validateStatus: (status) => status! < 500, // Aceptar códigos < 500
          followRedirects: true,
          maxRedirects: 5,
        ),
      );

      // Verificar que la descarga fue exitosa
      if (response.statusCode != 200) {
        throw Exception('Error de descarga: ${response.statusCode}');
      }

      // Verificar que el archivo se creó y no está vacío
      final file = File(localPath);
      if (!await file.exists()) {
        throw Exception('El archivo no se creó después de la descarga');
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        throw Exception('El archivo descargado está vacío');
      }

      print(
          '✅ Archivo descargado exitosamente: $localPath (${fileSize} bytes)');
      return localPath;
    } catch (e) {
      print('❌ Error al descargar archivo: $e');

      // Crear un archivo temporal vacío para evitar crashes
      final tempDir = await getTemporaryDirectory();
      final localPath = p.join(tempDir.path, 'error_$filename');
      await File(localPath).writeAsString('Error al descargar: $e');

      return localPath;
    }
  }

  Future<void> _refresh() async {
    await _fetchDocs();
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.neutral50,
      child: Row(
        children: [
          // ====== Panel izquierdo: tabla/lista ======
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space16),
              child: Column(
                children: [
                  _buildToolbar(),
                  const SizedBox(height: AppTheme.space12),
                  Expanded(child: _buildTable()),
                ],
              ),
            ),
          ),

          // ====== Panel derecho: preview y metadatos ======
          SizedBox(
            width: 380,
            child: _buildRightPanel(),
          ),
        ],
      ),
    );
  }

  // ======= Toolbar con filtros y acciones =======
  Widget _buildToolbar() {
    return Column(
      children: [
        // Barra de búsqueda
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Buscar por nombre, paciente, tags...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (v) {
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (mounted) _fetchDocs();
                  });
                },
              ),
            ),
            const SizedBox(width: AppTheme.space12),
            IconButton(
              tooltip: 'Refrescar',
              icon: const Icon(Icons.refresh),
              onPressed: _refresh,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFF3F4F6),
                foregroundColor: const Color(0xFF374151),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space12),
        // Filtros y acciones
        Wrap(
          spacing: AppTheme.space12,
          runSpacing: AppTheme.space8,
          children: [
            // Filtro por tipo
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Todos')),
                  DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                  DropdownMenuItem(value: 'image', child: Text('Imágenes')),
                  DropdownMenuItem(
                      value: 'document', child: Text('Documentos')),
                ],
                onChanged: (value) {
                  // TODO: Implementar filtro por tipo
                },
              ),
            ),
            // Filtro por fecha
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Fecha',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Todas')),
                  DropdownMenuItem(value: 'today', child: Text('Hoy')),
                  DropdownMenuItem(value: 'week', child: Text('Semana')),
                  DropdownMenuItem(value: 'month', child: Text('Mes')),
                ],
                onChanged: (value) {
                  // TODO: Implementar filtro por fecha
                },
              ),
            ),
            // Botón de subir
            ElevatedButton.icon(
              onPressed: _onUpload,
              icon: const Icon(Icons.upload_file),
              label: const Text('Subir'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary500,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            // Botón de prueba de conexión
            ElevatedButton.icon(
              onPressed: _testConnection,
              icon: const Icon(Icons.network_check),
              label: const Text('Probar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warning500,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ======= Tabla de documentos =======
  Widget _buildTable() {
    if (_isLoading) {
      return const Card(
        child: SizedBox(
          width: double.infinity,
          height: 260,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Cargando documentos...'),
              ],
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Card(
        child: SizedBox(
          width: double.infinity,
          height: 260,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red, size: 48),
                SizedBox(height: 16),
                Text(_errorMessage!, textAlign: TextAlign.center),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _fetchDocs,
                  child: Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_docs.isEmpty) {
      return const Card(
        child: SizedBox(
          width: double.infinity,
          height: 260,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('No hay documentos para mostrar'),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space16,
              vertical: AppTheme.space12,
            ),
            color: AppTheme.neutral50,
            child: Row(
              children: [
                _cellHeader('Nombre', flex: 4),
                _cellHeader('Paciente', flex: 3),
                _cellHeader('Fecha', flex: 2),
                _cellHeader('Tamaño', flex: 2),
                const SizedBox(width: AppTheme.space16),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: _docs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final d = _docs[index];
                final kind = kindFromName(d.name);
                final color = colorForKind(kind);
                final isSelected = _selectedIndex == index;

                return InkWell(
                  onTap: () async {
                    setState(() => _selectedIndex = index);
                    await _loadPreviewFor(d);
                  },
                  child: Container(
                    color: isSelected ? const Color(0xFFEFF2FF) : null,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space16,
                      vertical: AppTheme.space12,
                    ),
                    child: Row(
                      children: [
                        // Nombre + icono
                        Expanded(
                          flex: 4,
                          child: Row(
                            children: [
                              Icon(iconForKind(kind), color: color),
                              const SizedBox(width: AppTheme.space12),
                              Flexible(
                                child: Text(
                                  d.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.neutral900,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Paciente
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              _chip(
                                text: 'No asignado',
                                bg: const Color(0xFFF3F4F6),
                                fg: AppTheme.neutral500,
                              ),
                            ],
                          ),
                        ),
                        // Fecha
                        Expanded(
                          flex: 2,
                          child: Text(
                            d.updatedAt != null
                                ? _formatDate(d.updatedAt!)
                                : 'N/A',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppTheme.neutral500),
                          ),
                        ),
                        // Tamaño
                        Expanded(
                          flex: 2,
                          child: Text(
                            'N/A',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppTheme.neutral500),
                          ),
                        ),
                        const SizedBox(width: AppTheme.space16),
                        // Iconos de acción
                        IconButton(
                          tooltip: 'Descargar',
                          icon: const Icon(Icons.download, size: 20),
                          onPressed: () => _downloadFile(d),
                          style: IconButton.styleFrom(
                            foregroundColor: AppTheme.primary500,
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                        const SizedBox(width: AppTheme.space8),
                        IconButton(
                          tooltip: 'Abrir',
                          icon: const Icon(Icons.open_in_new, size: 20),
                          onPressed: () => _openFile(d),
                          style: IconButton.styleFrom(
                            foregroundColor: AppTheme.success500,
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _cellHeader(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.neutral500,
        ),
      ),
    );
  }

  Widget _chip({required String text, required Color bg, required Color fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space8,
        vertical: AppTheme.space4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w600, color: fg),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // ======= Panel derecho =======
  Widget _buildRightPanel() {
    if (_selectedIndex == null || _docs.isEmpty) {
      return Container(
        color: Colors.white,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.folder_open, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Selecciona un documento',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'para ver detalles y previsualizar',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final item = _docs[_selectedIndex!];
    final kind = kindFromName(item.name);
    final color = colorForKind(kind);

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Header con botón de cerrar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: AppTheme.neutral200),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Detalles del documento',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.neutral900,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _selectedIndex = null),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF3F4F6),
                    foregroundColor: const Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
          ),

          // Canvas principal con información del archivo
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Canvas rectangular con icono centrado
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.neutral200),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icono cuadrado centrado
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            iconForKind(kind),
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          kind.name.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4B5563),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Información del archivo
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.neutral200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Información del archivo',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.neutral900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow('Nombre', item.name),
                        _buildInfoRow('Tamaño', _formatFileSize(item.name)),
                        _buildInfoRow('Tipo', kind.name.toUpperCase()),
                        _buildInfoRow('Fecha',
                            _formatDate(item.updatedAt ?? DateTime.now())),
                        _buildInfoRow('Estado', 'Disponible'),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Botones de acción
                  Row(
                    children: [
                      // Botón de descarga
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _downloadFile(item),
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text('Descargar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary500,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Botón de apertura
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openFile(item),
                          icon: const Icon(Icons.open_in_new, size: 18),
                          label: const Text('Abrir'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success500,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Botón circular de edición
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: IconButton(
                          onPressed: () => _showAssignDialog(item),
                          icon: const Icon(Icons.edit,
                              color: Colors.white, size: 20),
                          tooltip: 'Editar',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ======= Asignar (mock simple: mueve de inbox a medical_records) =======
  Future<void> _showAssignDialog(DocItem d) async {
    // En producción muestra buscador de paciente y record reales.
    final patientIdCtrl = TextEditingController();
    final recordIdCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Asignar documento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: patientIdCtrl,
              decoration: const InputDecoration(labelText: 'patient_id (UUID)'),
            ),
            const SizedBox(height: AppTheme.space8),
            TextField(
              controller: recordIdCtrl,
              decoration: const InputDecoration(labelText: 'record_id (UUID)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (patientIdCtrl.text.isEmpty || recordIdCtrl.text.isEmpty)
                return;
              // TODO: Implementar asignación usando el nuevo DocsRepository
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Asignación de ${d.name} pendiente de implementar')),
                );
              }
              await _fetchDocs();
            },
            child: const Text('Asignar'),
          ),
        ],
      ),
    );
  }

  // ======= Subir a inbox (opcional) =======
  Future<void> _onUpload() async {
    // Si quieres habilitar subida directa desde desktop/mobile:
    // - agrega file_selector u otro picker
    // - aquí solo dejo un placeholder de ejemplo
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Implementa el picker y usa StorageService.upload(...)'),
      ));
    }
  }

  Future<void> _testConnection() async {
    try {
      final fileService = FileService();
      final result = await fileService.testConnection();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: result['success']
                ? (result['isAccessible']
                    ? AppTheme.success500
                    : AppTheme.warning500)
                : AppTheme.danger500,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de conexión: $e'),
            backgroundColor: AppTheme.danger500,
          ),
        );
      }
    }
  }

  // ======= Funciones de acción =======
  Future<void> _downloadFile(DocItem item) async {
    try {
      final fileService = FileService();
      await fileService.downloadToDownloads(item.url, item.name);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Archivo descargado a Descargas: ${item.name}'),
            backgroundColor: AppTheme.success500,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error descargando: $e'),
            backgroundColor: AppTheme.danger500,
          ),
        );
      }
    }
  }

  Future<void> _openFile(DocItem item) async {
    try {
      // Mostrar el visor de archivos en ventana emergente
      // TODO: Implementar FileViewerDialog o usar alternativa
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Visor de archivos no disponible: ${item.name}'),
          backgroundColor: Colors.orange,
        ),
      );
      // await showDialog(
      //   context: context,
      //   builder: (context) => FileViewerDialog(
      //     fileName: item.name,
      //     fileUrl: item.url,
      //     fileType: fileType,
      //   ),
      // );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error abriendo archivo: $e'),
            backgroundColor: AppTheme.danger500,
          ),
        );
      }
    }
  }

  // ignore: unused_element
  Widget _buildSimplePreview(DocItem item, DocKind kind) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorForKind(kind).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(iconForKind(kind), color: colorForKind(kind), size: 16),
                const SizedBox(width: 8),
                Text(
                  'Vista previa de ${kind.name.toUpperCase()}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorForKind(kind),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(iconForKind(kind), size: 48, color: colorForKind(kind)),
                  const SizedBox(height: 12),
                  Text(
                    item.name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.neutral900,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${kind.name.toUpperCase()} • ${_formatFileSize(item.name)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.neutral500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ======= Menú fila =======
  // ignore: unused_element
  void _showRowMenu(DocItem d) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Descargar'),
              onTap: () async {
                Navigator.pop(context);
                await _loadPreviewFor(d);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Descargado: ${d.name}')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Asignar a paciente/record'),
              onTap: () {
                Navigator.pop(context);
                _showAssignDialog(d);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Future<void> _shareFile(DocItem item) async {
    // TODO: Implementar compartir archivo
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Compartiendo archivo: ${item.name}'),
          backgroundColor: AppTheme.warning500,
        ),
      );
    }
  }

  // ignore: unused_element
  Future<void> _editMetadata(DocItem item) async {
    final nameController = TextEditingController(text: item.name);
    final patientController = TextEditingController();
    final tagsController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar metadatos'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration:
                  const InputDecoration(labelText: 'Nombre del archivo'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: patientController,
              decoration: const InputDecoration(labelText: 'Paciente asignado'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tagsController,
              decoration: const InputDecoration(
                  labelText: 'Tags (separados por comas)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implementar actualización de metadatos
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Metadatos actualizados')),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Future<void> _deleteFile(DocItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar archivo'),
        content: Text('¿Estás seguro de que quieres eliminar "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger500,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // TODO: Implementar eliminación de archivo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Archivo eliminado: ${item.name}'),
          backgroundColor: AppTheme.danger500,
        ),
      );
      await _fetchDocs();
    }
  }

  // ======= Widgets auxiliares =======
  // ignore: unused_element
  Widget _infoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppTheme.neutral700,
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _infoRow(String label, String value, {bool isUrl = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4B5563),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isUrl ? AppTheme.primary500 : AppTheme.neutral900,
              ),
              maxLines: isUrl ? 2 : 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool isSecondary = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSecondary ? Colors.transparent : color,
        foregroundColor: isSecondary ? color : Colors.white,
        side: isSecondary ? BorderSide(color: color) : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // ======= Helpers =======
  Widget _buildInfoRow(String label, String value, {bool isUrl = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4B5563),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isUrl ? AppTheme.primary500 : AppTheme.neutral900,
              ),
              maxLines: isUrl ? 2 : 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final two = (int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year}';
  }

  String _formatFileSize(String filename) {
    // Simulación de tamaño de archivo
    final random = filename.hashCode % 1000;
    if (random < 100) return '${random}KB';
    if (random < 1000) return '${(random / 1024).toStringAsFixed(1)}MB';
    return '${(random / 1024 / 1024).toStringAsFixed(1)}GB';
  }
}

// ======= Clase para navegación =======
class VisorMedicoPage extends StatelessWidget {
  const VisorMedicoPage({super.key});

  static const route = '/visor-medico';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      body: Row(
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
                // TopBar
                _TopBar(
                  title: 'Visor Médico',
                  onBack: () =>
                      NavigationHelper.navigateToRoute(context, '/home'),
                ),
                // Contenido del visor
                const Expanded(
                  child: VisorPage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _TopBar({
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppTheme.neutral200),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Volver',
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.neutral900,
            ),
          ),
        ],
      ),
    );
  }
}
