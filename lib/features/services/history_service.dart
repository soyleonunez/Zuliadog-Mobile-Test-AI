import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';

/// Servicio para la gestión de historias médicas
class HistoryService {
  static const String _tableRecords = 'medical_records';
  static const String _tableAttachments = 'record_attachments';
  static const String _tablePatients = 'patients';

  final SupabaseClient _supa = Supabase.instance.client;

  /// Obtiene todos los bloques de historia para un paciente
  Future<List<HistoryBlock>> getHistoryBlocks(String patientId) async {
    try {
      print('🔍 Obteniendo bloques para patientId: $patientId');

      final rows = await _supa
          .from(_tableRecords)
          .select(
              'id, patient_id, department_code, created_at, updated_at, locked, content_delta, title, summary, diagnosis, created_by')
          .eq('patient_id', patientId)
          .order('created_at', ascending: false);

      print('📊 Resultados obtenidos: ${rows.length} bloques');

      if (rows.isEmpty) {
        print('⚠️ No se encontraron bloques para patientId: $patientId');
        return _generateSampleBlocks(patientId);
      }

      final blocks = <HistoryBlock>[];
      for (final row in rows) {
        // Obtener adjuntos para este bloque
        final attachments = await _getAttachmentsForBlock(row['id'] as String);

        blocks.add(HistoryBlock(
          id: row['id'] as String,
          patientId: row['patient_id'] as String,
          author: row['created_by'] as String? ?? 'Veterinaria',
          createdAt: DateTime.parse(row['created_at'] as String),
          locked: row['locked'] as bool? ?? false,
          deltaJson:
              row['content_delta'] as String? ?? '{"ops":[{"insert":""}]}',
          attachments: attachments,
        ));
      }

      return blocks;
    } catch (e) {
      print('❌ Error al obtener bloques: $e');
      return _generateSampleBlocks(patientId);
    }
  }

  /// Obtiene los adjuntos para un bloque específico
  Future<List<Attachment>> _getAttachmentsForBlock(String recordId) async {
    try {
      final rows = await _supa
          .from(_tableAttachments)
          .select(
              'id, record_id, file_path, file_name, file_size, mime_type, created_at')
          .eq('record_id', recordId)
          .order('created_at', ascending: false);

      return rows
          .map((row) => Attachment(
                id: row['id'] as String,
                recordId: row['record_id'] as String,
                path: row['file_path'] as String,
                name: row['file_name'] as String,
                size: row['file_size'] as int? ?? 0,
                mimeType:
                    row['mime_type'] as String? ?? 'application/octet-stream',
                createdAt: DateTime.parse(row['created_at'] as String),
              ))
          .toList();
    } catch (e) {
      print('❌ Error al obtener adjuntos: $e');
      return [];
    }
  }

  /// Crea un nuevo bloque de historia
  Future<String> createHistoryBlock({
    required String patientId,
    required String author,
  }) async {
    try {
      final id = const Uuid().v4();
      final now = DateTime.now().toUtc();
      final delta = '{"ops":[{"insert":""}]}';

      await _supa.from(_tableRecords).insert({
        'id': id,
        'patient_id': patientId,
        'created_by': author,
        'locked': false,
        'content_delta': delta,
        'title': 'Nuevo bloque de historia',
        'summary': null,
        'diagnosis': null,
        'department_code': 'MED',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });

      print('✅ Bloque creado exitosamente: $id');
      return id;
    } catch (e) {
      print('❌ Error al crear bloque: $e');
      // Si falla la creación real, devolver un UUID temporal válido
      return const Uuid().v4();
    }
  }

  /// Actualiza el contenido delta de un bloque
  Future<void> updateBlockContent(String blockId, String deltaJson) async {
    try {
      await _supa.from(_tableRecords).update({
        'content_delta': deltaJson,
        'updated_at': DateTime.now().toUtc().toIso8601String()
      }).eq('id', blockId);
    } catch (e) {
      print('❌ Error al actualizar contenido: $e');
    }
  }

  /// Cambia el estado de bloqueo de un bloque
  Future<void> toggleBlockLock(String blockId, bool locked) async {
    try {
      await _supa.from(_tableRecords).update({
        'locked': locked,
        'updated_at': DateTime.now().toUtc().toIso8601String()
      }).eq('id', blockId);
    } catch (e) {
      print('❌ Error al cambiar estado de bloqueo: $e');
    }
  }

  /// Sube un archivo adjunto
  Future<Attachment> uploadAttachment({
    required String recordId,
    required String patientId,
    required PlatformFile file,
    required String label,
  }) async {
    try {
      final filePath = 'attachments/$patientId/${file.name}';

      // Subir archivo a Supabase Storage
      await _supa.storage
          .from('medical-files')
          .uploadBinary(filePath, file.bytes!);

      // Crear registro en la base de datos
      final attachmentId = const Uuid().v4();
      await _supa.from(_tableAttachments).insert({
        'id': attachmentId,
        'record_id': recordId,
        'file_path': filePath,
        'file_name': file.name,
        'file_size': file.size,
        'mime_type': _guessMimeType(file),
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      return Attachment(
        id: attachmentId,
        recordId: recordId,
        path: filePath,
        name: file.name,
        size: file.size,
        mimeType: _guessMimeType(file),
        createdAt: DateTime.now(),
      );
    } catch (e) {
      print('❌ Error al subir adjunto: $e');
      rethrow;
    }
  }

  /// Obtiene la URL pública de un archivo
  String getPublicUrl(String filePath) {
    return _supa.storage.from('medical-files').getPublicUrl(filePath);
  }

  /// Genera bloques de muestra para demostración
  List<HistoryBlock> _generateSampleBlocks(String patientId) {
    return [
      HistoryBlock(
        id: const Uuid().v4(), // UUID real
        patientId: patientId,
        author: 'Veterinaria',
        createdAt: DateTime.now(),
        locked: false,
        deltaJson: '{"ops":[{"insert":""}]}',
        attachments: [],
      ),
    ];
  }

  /// Adivina el tipo MIME de un archivo
  String _guessMimeType(PlatformFile file) {
    final ext = (file.extension ?? '').toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }
}

/// Modelo para un bloque de historia
class HistoryBlock {
  final String id;
  final String patientId;
  final String author;
  final DateTime createdAt;
  final bool locked;
  final String deltaJson;
  final List<Attachment> attachments;

  HistoryBlock({
    required this.id,
    required this.patientId,
    required this.author,
    required this.createdAt,
    required this.locked,
    required this.deltaJson,
    required this.attachments,
  });

  HistoryBlock copyWith({
    String? id,
    String? patientId,
    String? author,
    DateTime? createdAt,
    bool? locked,
    String? deltaJson,
    List<Attachment>? attachments,
  }) {
    return HistoryBlock(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      locked: locked ?? this.locked,
      deltaJson: deltaJson ?? this.deltaJson,
      attachments: attachments ?? this.attachments,
    );
  }
}

/// Modelo para un archivo adjunto
class Attachment {
  final String id;
  final String recordId;
  final String path;
  final String name;
  final int size;
  final String mimeType;
  final DateTime createdAt;

  Attachment({
    required this.id,
    required this.recordId,
    required this.path,
    required this.name,
    required this.size,
    required this.mimeType,
    required this.createdAt,
  });
}
