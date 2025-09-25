import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:iconsax/iconsax.dart';
import 'package:file_picker/file_picker.dart';
import 'package:zuliadog/core/notifications.dart';
import 'package:zuliadog/features/data/data_service.dart';

final _supa = Supabase.instance.client;

/// Widget de edición de texto global reutilizable
/// Configurable para diferentes tablas y contextos
class TextEditor extends StatefulWidget {
  final Map<String, dynamic> data;
  final String tableName; // Tabla a editar (ej: 'medical_records')
  final String recordId; // ID del registro
  final String? clinicId; // ID de la clínica (opcional)
  final DateFormat? dateFormat; // Formato de fecha personalizado
  final VoidCallback? onEdit; // Callback para editar
  final VoidCallback? onSaved; // Callback después de guardar
  final VoidCallback? onDeleted; // Callback después de eliminar
  final bool showAttachments; // Mostrar zona de adjuntos
  final bool showLockToggle; // Mostrar toggle de bloqueo
  final bool showDeleteButton; // Mostrar botón de eliminar
  final String? titleField; // Campo del título (opcional)
  final String? summaryField; // Campo del resumen (opcional)
  final String? contentField; // Campo del contenido (opcional)
  final String? dateField; // Campo de fecha (opcional)
  final String? authorField; // Campo del autor (opcional)
  final String? departmentField; // Campo del departamento (opcional)
  final String? lockedField; // Campo de bloqueo (opcional)

  const TextEditor({
    super.key,
    required this.data,
    required this.tableName,
    required this.recordId,
    this.clinicId,
    this.dateFormat,
    this.onEdit,
    this.onSaved,
    this.onDeleted,
    this.showAttachments = false,
    this.showLockToggle = true,
    this.showDeleteButton = true,
    this.titleField = 'title',
    this.summaryField = 'summary',
    this.contentField = 'content_delta',
    this.dateField = 'date',
    this.authorField = 'created_by',
    this.departmentField = 'department_code',
    this.lockedField = 'locked',
  });

  @override
  State<TextEditor> createState() => _TextEditorState();
}

class _TextEditorState extends State<TextEditor> {
  late QuillController _summaryController;
  late QuillController _contentDeltaController;
  late TextEditingController _titleController;
  late TextEditingController _doctorController;
  bool _isEditing = false;
  bool _isLocked = true; // Por defecto bloqueado
  List<PlatformFile> _selectedFiles = []; // Lista de archivos seleccionados
  List<Map<String, dynamic>> _attachedFiles =
      []; // Lista de archivos ya subidos
  bool _isLoadingAttachments = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    // Estado inicial: bloqueado por defecto, a menos que el campo locked sea explícitamente false
    _isLocked = widget.data[widget.lockedField] != false;
    // Si es un bloque nuevo, empezar en modo edición
    _isEditing = widget.data['is_new'] == true;
    _loadAttachedFiles(); // Cargar archivos adjuntos existentes
  }

  void _initializeControllers() {
    // Debug: verificar si es un bloque nuevo
    print(
        '🔍 TextEditor - is_new: ${widget.data['is_new']} (type: ${widget.data['is_new'].runtimeType})');
    print('🔍 TextEditor - data keys: ${widget.data.keys.toList()}');
    

    // Inicializar controlador para summary usando DataService
    final summaryDelta = widget.data['is_new'] == true
        ? [
            {'insert': 'Escribe el resumen de la consulta...\n'}
          ]
        : DataService.cleanDelta(widget.data[widget.summaryField]);
    _summaryController = QuillController(
      document: Document.fromJson(summaryDelta),
      selection: const TextSelection.collapsed(offset: 0),
    );

    // Inicializar controlador para content_delta usando DataService
    final contentDelta = widget.data['is_new'] == true
        ? [
            {'insert': 'Escribe las acotaciones adicionales...\n'}
          ]
        : DataService.cleanDelta(widget.data[widget.contentField]);
    _contentDeltaController = QuillController(
      document: Document.fromJson(contentDelta),
      selection: const TextSelection.collapsed(offset: 0),
    );

    // Inicializar controlador para título
    final titleText = widget.data[widget.titleField]?.toString() ??
        (widget.data['is_new'] == true
            ? 'Escribe el título de la consulta...'
            : '');
    _titleController = TextEditingController(text: titleText);
    

    // Inicializar controlador para médico
    final doctorText = widget.data['doctor']?.toString() ??
        (widget.data['is_new'] == true ? 'Nombre del médico...' : '');
    _doctorController = TextEditingController(text: doctorText);
    
  }

  @override
  void dispose() {
    _summaryController.dispose();
    _contentDeltaController.dispose();
    _titleController.dispose();
    _doctorController.dispose();
    super.dispose();
  }

  Future<void> _toggleLock() async {
    final newLockState = !_isLocked;

    try {
      setState(() {
        _isLocked = newLockState;
        // Si se desbloquea, NO entrar automáticamente en modo edición
        // El usuario debe hacer clic en editar explícitamente
        if (newLockState) {
          _isEditing = false; // Si se bloquea, salir del modo edición
        }
      });

      // Mostrar notificación de estado
      if (mounted) {
        NotificationService.showHistoryStatus(
          newLockState
              ? 'Historia bloqueada correctamente'
              : 'Historia desbloqueada correctamente',
          newLockState,
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError('Error al cambiar el estado de bloqueo');
      }
    }
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      // Si está bloqueado, desbloquearlo automáticamente al editar
      if (_isLocked) {
        _isLocked = false;
        // Actualizar el estado en la base de datos
        _updateLockStatus(false);
      }
    });
  }

  Future<void> _updateLockStatus(bool locked) async {
    try {
      await _supa
          .from(widget.tableName)
          .update({'locked': locked.toString()}).eq('id', widget.recordId);

      // Actualizar el widget.data también
      widget.data['locked'] = locked;
    } catch (e) {
      
    }
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      // Restaurar valores originales
      _titleController.text = widget.data[widget.titleField]?.toString() ??
          (widget.data['is_new'] == true
              ? 'Escribe el título de la consulta...'
              : '');
      _doctorController.text = widget.data['doctor']?.toString() ??
          (widget.data['is_new'] == true ? 'Nombre del médico...' : '');
      _initializeControllers();
      _selectedFiles.clear(); // Limpiar archivos seleccionados
    });
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'txt',
          'jpg',
          'jpeg',
          'png',
          'gif',
          'xlsx',
          'xls'
        ],
      );

      if (result != null) {
        setState(() {
          _selectedFiles.addAll(result.files);
        });

        if (mounted) {
          NotificationService.showSuccess(
              '${result.files.length} archivo(s) seleccionado(s)');
        }
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError('Error al seleccionar archivos: $e');
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _loadAttachedFiles() async {
    if (widget.clinicId == null) return;

    setState(() {
      _isLoadingAttachments = true;
    });

    try {
      // Buscar archivos adjuntos en la tabla de documents
      final response = await _supa
          .from('documents')
          .select('*')
          .eq('clinic_id', widget.clinicId!)
          .eq('record_id', widget.recordId);

      setState(() {
        _attachedFiles = List<Map<String, dynamic>>.from(response);
        _isLoadingAttachments = false;
      });
    } catch (e) {
      
      setState(() {
        _isLoadingAttachments = false;
      });
    }
  }

  Future<void> _uploadFiles() async {
    if (_selectedFiles.isEmpty) return;

    setState(() {
      _isLoadingAttachments = true;
    });

    try {
      // Mostrar indicador de carga
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Subiendo archivos...'),
              ],
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Subir cada archivo a Supabase Storage
      for (final file in _selectedFiles) {
        try {
          // Verificar que el archivo tenga bytes
          if (file.bytes == null) {
            
            continue;
          }

          // Generar nombre único para el archivo
          final fileName =
              '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
          final filePath =
              'medical_records/${widget.clinicId}/${widget.recordId}/$fileName';

          // Subir archivo a Supabase Storage
          await _supa.storage
              .from('medical_files')
              .uploadBinary(filePath, file.bytes!);

          // Registrar en la base de datos
          await _supa.from('documents').insert({
            'clinic_id': widget.clinicId,
            'record_id': widget.recordId,
            'file_name': file.name,
            'file_path': filePath,
            'file_size': file.size,
            'file_type': file.extension,
            'uploaded_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          
        }
      }

      // Recargar archivos adjuntos
      await _loadAttachedFiles();

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        NotificationService.showSuccess('Archivos subidos correctamente');

        // Limpiar archivos seleccionados después de subir
        setState(() {
          _selectedFiles.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        NotificationService.showError('Error al subir archivos: $e');
      }
      setState(() {
        _isLoadingAttachments = false;
      });
    }
  }

  Future<void> _deleteAttachment(String attachmentId) async {
    try {
      // Obtener información del archivo
      final attachment = _attachedFiles.firstWhere(
        (file) => file['id'] == attachmentId,
      );

      // Eliminar de Supabase Storage
      await _supa.storage
          .from('medical_files')
          .remove([attachment['file_path']]);

      // Eliminar de la base de datos
      await _supa.from('documents').delete().eq('id', attachmentId);

      // Recargar archivos adjuntos
      await _loadAttachedFiles();

      if (mounted) {
        NotificationService.showSuccess('Archivo eliminado correctamente');
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError('Error al eliminar archivo: $e');
      }
    }
  }

  Future<void> _downloadAttachment(Map<String, dynamic> attachment) async {
    try {
      // Obtener URL de descarga
      final url = _supa.storage
          .from('medical_files')
          .getPublicUrl(attachment['file_path']);

      // TODO: Implementar descarga real
      // Por ahora solo mostramos la URL
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('URL de descarga: $url'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError('Error al descargar archivo: $e');
      }
    }
  }

  IconData _getFileIcon(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'pdf':
        return Iconsax.document_text;
      case 'doc':
      case 'docx':
        return Iconsax.document;
      case 'txt':
        return Iconsax.document_text;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Iconsax.image;
      case 'xlsx':
      case 'xls':
        return Iconsax.document_download;
      default:
        return Iconsax.document;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<void> _save() async {
    try {
      // Usar DataService para obtener el texto plano del summary
      final summaryText = DataService.getPlainText(
          _summaryController.document.toDelta().toJson());

      // Limpiar placeholders antes de guardar
      final cleanTitle = _titleController.text.trim();
      final cleanDoctor = _doctorController.text.trim();
      final cleanSummary = summaryText.trim();

      // Preparar datos para guardar
      final saveData = {
        widget.titleField!:
            cleanTitle.isEmpty || cleanTitle.contains('Escribe el título')
                ? null
                : cleanTitle,
        'doctor':
            cleanDoctor.isEmpty || cleanDoctor.contains('Nombre del médico')
                ? null
                : cleanDoctor,
        widget.summaryField!:
            cleanSummary.isEmpty || cleanSummary.contains('Escribe el resumen')
                ? null
                : cleanSummary,
        widget.contentField!:
            jsonEncode(_contentDeltaController.document.toDelta().toJson()),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Agregar clinic_id si está disponible
      if (widget.clinicId != null) {
        saveData['clinic_id'] = widget.clinicId;
      }

      // Verificar si es un bloque nuevo (ID temporal)
      final isNewBlock = widget.recordId.startsWith('temp_');
      
      
      

      if (isNewBlock) {
        // Es un bloque nuevo, crear en la base de datos
        saveData['patient_id'] = widget.data['patient_id'];
        saveData['date'] = widget.data['date'];
        saveData['department_code'] = widget.data['department_code'] ?? 'MED';
        saveData['locked'] = (widget.data['locked'] == true).toString();
        // Asegurar que created_at sea un string en formato ISO
        final createdAt = widget.data['created_at'];
        if (createdAt is DateTime) {
          saveData['created_at'] = createdAt.toIso8601String();
        } else if (createdAt is String) {
          saveData['created_at'] = createdAt;
        } else {
          saveData['created_at'] = DateTime.now().toIso8601String();
        }

        // Asegurar que los campos de texto sean strings o null
        if (saveData['title'] != null &&
            saveData['title'].toString().trim().isEmpty) {
          saveData['title'] = null;
        }
        if (saveData['doctor'] != null &&
            saveData['doctor'].toString().trim().isEmpty) {
          saveData['doctor'] = null;
        }
        if (saveData['summary'] != null &&
            saveData['summary'].toString().trim().isEmpty) {
          saveData['summary'] = null;
        }

        // Debug: verificar tipos de datos
        
        saveData.forEach((key, value) {
          
        });

        print(
            '🔍 _save - insertando en ${widget.tableName} con datos: $saveData');

        final response = await _supa
            .from(widget.tableName)
            .insert(saveData)
            .select('id')
            .single();

        

        // Actualizar el ID temporal con el ID real de la base de datos
        widget.data['id'] = response['id'];
        widget.data.remove('is_new'); // Remover la marca de nuevo
        widget.data.remove('is_temp'); // Remover la marca de temporal

        
      } else {
        // Es un bloque existente, actualizar
        // Asegurar que locked sea string para actualizaciones también
        if (saveData.containsKey('locked')) {
          saveData['locked'] = (saveData['locked'] == true).toString();
        }

        await _supa
            .from(widget.tableName)
            .update(saveData)
            .eq('id', widget.recordId);
      }

      setState(() {
        _isEditing = false;
        // Mantener el estado actual después de guardar
      });

      if (mounted) {
        NotificationService.showSuccess('Historia guardada correctamente');
        if (widget.onSaved != null) {
          widget.onSaved!();
        }
      }
    } catch (e) {
      
      if (mounted) {
        NotificationService.showError('Error al guardar la historia: $e');
      }
    }
  }

  void _deleteBlock() {
    // Mostrar diálogo de confirmación
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar Bloque'),
          content: const Text(
              '¿Estás seguro de que quieres eliminar este bloque? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _performDelete();
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performDelete() async {
    try {
      // Verificar si es un bloque temporal
      final isTempBlock = widget.recordId.startsWith('temp_');

      if (isTempBlock) {
        // Es un bloque temporal, solo eliminar del cache local
        if (mounted) {
          NotificationService.showSuccess('Bloque temporal eliminado');
          if (widget.onDeleted != null) {
            widget.onDeleted!();
          }
        }
      } else {
        // Es un bloque real, eliminar de la base de datos
        // Mostrar indicador de carga
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Eliminando bloque...'),
                ],
              ),
              duration: Duration(seconds: 2),
            ),
          );
        }

        await _supa.from(widget.tableName).delete().eq('id', widget.recordId);

        if (mounted) {
          // Cerrar el snackbar de carga
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          NotificationService.showSuccess('Bloque eliminado correctamente');
          if (widget.onDeleted != null) {
            widget.onDeleted!();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        // Cerrar el snackbar de carga
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        NotificationService.showError('Error al eliminar el bloque: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = widget.data[widget.dateField]?.toString() ?? '';
    final dateFormat =
        widget.dateFormat ?? DateFormat('d MMMM y, hh:mm a', 'es');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // bg-card-light
        borderRadius: BorderRadius.circular(16), // rounded-2xl
        border: Border.all(color: const Color(0xFFE5E7EB)), // border-light
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del bloque
          Container(
            padding: const EdgeInsets.all(16), // p-4
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: Color(0xFFE5E7EB), width: 1), // border-light
              ),
            ),
            child: Row(
              children: [
                // Fecha y autor
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateFormat
                            .format(DateTime.tryParse(date) ?? DateTime.now()),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937), // text-light
                        ),
                      ),
                    ],
                  ),
                ),
                // Badge de estado y botones de acción
                Row(
                  children: [
                    // Badge de estado clickeable (solo si showLockToggle es true)
                    if (widget.showLockToggle) ...[
                      Tooltip(
                        message: _isLocked
                            ? 'Hacer clic para desbloquear y editar'
                            : 'Hacer clic para bloquear',
                        child: GestureDetector(
                          onTap: _toggleLock,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _isLocked
                                  ? const Color(0xFFFEE2E2) // red-100
                                  : const Color(0xFFDCFCE7), // green-100
                              borderRadius:
                                  BorderRadius.circular(20), // rounded-full
                              border: Border.all(
                                color: _isLocked
                                    ? const Color(0xFFDC2626)
                                        .withValues(alpha: 0.3)
                                    : const Color(0xFF16A34A)
                                        .withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isLocked ? Iconsax.lock : Iconsax.unlock,
                                  size: 12,
                                  color: _isLocked
                                      ? const Color(0xFFDC2626) // red-700
                                      : const Color(0xFF16A34A), // green-700
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _isLocked ? 'Bloqueado' : 'Editable',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _isLocked
                                        ? const Color(0xFFDC2626) // red-700
                                        : const Color(0xFF16A34A), // green-700
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Contenido del bloque
          Padding(
            padding: const EdgeInsets.all(16), // p-4
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Campos de título y médico
                if (_isEditing) ...[
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Título de la consulta',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                isDense: true,
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Médico',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _doctorController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                isDense: true,
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          _titleController.text.isNotEmpty &&
                                  !_titleController.text
                                      .contains('Escribe el título')
                              ? _titleController.text
                              : 'Sin título',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      if (_doctorController.text.isNotEmpty &&
                          !_doctorController.text
                              .contains('Nombre del médico')) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Dr/Dra. ${_doctorController.text}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                      // Botones de acción juntos
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Botón de editar (siempre visible)
                          IconButton(
                            onPressed: _isLocked ? null : _startEditing,
                            icon: const Icon(Iconsax.edit_2, size: 18),
                            tooltip: _isLocked
                                ? 'Bloqueado - No se puede editar'
                                : 'Editar',
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                          // Botón de eliminar (solo si showDeleteButton es true y no está bloqueado)
                          if (widget.showDeleteButton)
                            IconButton(
                              onPressed: _isLocked ? null : _deleteBlock,
                              icon: const Icon(Iconsax.trash, size: 18),
                              tooltip: _isLocked
                                  ? 'Bloqueado - No se puede eliminar'
                                  : 'Eliminar Bloque',
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              color: _isLocked
                                  ? const Color(0xFF9CA3AF)
                                  : const Color(0xFFDC2626),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Campo de resumen (summary) editable
                if (_isEditing) ...[
                  const Text(
                    'Motivo de la consulta / Resumen',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 80, // Altura reducida
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: QuillEditor.basic(
                      controller: _summaryController,
                    ),
                  ),
                  const SizedBox(height: 8),
                ] else ...[
                  if (_summaryController.document
                          .toPlainText()
                          .trim()
                          .isNotEmpty &&
                      !_summaryController.document
                          .toPlainText()
                          .contains('Escribe el resumen')) ...[
                    const Text(
                      'Motivo de la consulta / Resumen',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Text(
                        _summaryController.document.toPlainText(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1F2937),
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],

                // Campo de acotaciones (content_delta) editable
                if (_isEditing) ...[
                  const Text(
                    'Hallazgos / Tratamiento / Acotaciones',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 60, // Altura reducida
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: QuillEditor.basic(
                      controller: _contentDeltaController,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                        child: const Text('Guardar'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _cancelEditing,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF3B82F6),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ],
                  ),
                ] else ...[
                  if (_contentDeltaController.document
                          .toPlainText()
                          .trim()
                          .isNotEmpty &&
                      !_contentDeltaController.document
                          .toPlainText()
                          .contains('Escribe las acotaciones')) ...[
                    const Text(
                      'Hallazgos / Tratamiento / Acotaciones',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Text(
                        _contentDeltaController.document.toPlainText(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1F2937),
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
                // Zona de adjuntos solo si no está bloqueado y showAttachments es true
                if (!_isLocked && widget.showAttachments && _isEditing) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFD1D5DB),
                        style: BorderStyle.solid,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título de la sección
                        Row(
                          children: [
                            const Icon(Iconsax.attach_square,
                                size: 16, color: Color(0xFF6B7280)),
                            const SizedBox(width: 8),
                            const Text(
                              'Archivos adjuntos',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: _pickFiles,
                              icon: const Icon(Iconsax.add, size: 16),
                              label: const Text('Seleccionar'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF3B82F6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Archivos ya subidos (siempre visibles)
                        if (_isLoadingAttachments) ...[
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ] else if (_attachedFiles.isNotEmpty) ...[
                          const Text(
                            'Archivos adjuntos:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 150),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _attachedFiles.length,
                              itemBuilder: (context, index) {
                                final attachment = _attachedFiles[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0F9FF),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: const Color(0xFFBFDBFE)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getFileIcon(attachment['file_type']),
                                        size: 18,
                                        color: const Color(0xFF3B82F6),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              attachment['file_name'] ??
                                                  'Archivo',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF1E40AF),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              _formatFileSize(
                                                  attachment['file_size'] ?? 0),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () =>
                                            _downloadAttachment(attachment),
                                        icon: const Icon(Iconsax.arrow_down_2,
                                            size: 16),
                                        color: const Color(0xFF3B82F6),
                                        padding: const EdgeInsets.all(4),
                                        constraints: const BoxConstraints(
                                          minWidth: 28,
                                          minHeight: 28,
                                        ),
                                        tooltip: 'Descargar',
                                      ),
                                      if (!_isLocked)
                                        IconButton(
                                          onPressed: () => _deleteAttachment(
                                              attachment['id']),
                                          icon: const Icon(Iconsax.trash,
                                              size: 16),
                                          color: const Color(0xFFDC2626),
                                          padding: const EdgeInsets.all(4),
                                          constraints: const BoxConstraints(
                                            minWidth: 28,
                                            minHeight: 28,
                                          ),
                                          tooltip: 'Eliminar',
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],

                        // Lista de archivos seleccionados
                        if (_selectedFiles.isNotEmpty) ...[
                          Container(
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _selectedFiles.length,
                              itemBuilder: (context, index) {
                                final file = _selectedFiles[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9FAFB),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: const Color(0xFFE5E7EB)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getFileIcon(file.extension),
                                        size: 20,
                                        color: const Color(0xFF6B7280),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              file.name,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF1F2937),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              _formatFileSize(file.size),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => _removeFile(index),
                                        icon: const Icon(Iconsax.close_circle,
                                            size: 18),
                                        color: const Color(0xFFDC2626),
                                        padding: const EdgeInsets.all(4),
                                        constraints: const BoxConstraints(
                                          minWidth: 32,
                                          minHeight: 32,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Botón para subir archivos
                          if (_selectedFiles.isNotEmpty)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _uploadFiles,
                                icon: const Icon(Iconsax.cloud_add, size: 16),
                                label: Text(
                                    'Subir ${_selectedFiles.length} archivo(s)'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3B82F6),
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                        ] else if (_attachedFiles.isEmpty) ...[
                          // Zona de selección cuando no hay archivos
                          InkWell(
                            onTap: _pickFiles,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Iconsax.cloud_add,
                                      size: 32, color: Color(0xFF9CA3AF)),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Arrastrar y soltar archivos aquí',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF6B7280)),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'o haz clic para seleccionar',
                                    style: TextStyle(
                                        fontSize: 12, color: Color(0xFF9CA3AF)),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'PDF, DOC, DOCX, TXT, JPG, PNG, XLS, XLSX',
                                    style: TextStyle(
                                        fontSize: 11, color: Color(0xFF9CA3AF)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
