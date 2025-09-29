import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zuliadog/core/database_queries.dart';
import 'package:flutter/material.dart';

/// Servicio para la gestión de historias médicas
class HistoryService {
  final SupabaseClient _supa = Supabase.instance.client;

  /// Método de diagnóstico para verificar la conexión a Supabase
  Future<Map<String, dynamic>> diagnoseConnection() async {
    try {
      // 1. Verificar conexión básica
      await _supa.from('clinics').select('id').limit(1);

      // 2. Verificar tablas principales
      final tables = [
        'patients',
        'medical_records',
        'record_attachments',
        'clinic_roles',
        'owners',
        'species',
        'breeds',
        'documents'
      ];
      final tableStatus = <String, bool>{};

      for (final table in tables) {
        try {
          await _supa.from(table).select('id').limit(1);
          tableStatus[table] = true;
        } catch (e) {
          tableStatus[table] = false;
        }
      }

      // 3. Verificar vistas esenciales
      final views = [
        'v_app', // Vista de pacientes optimizada para búsquedas
        'v_hosp' // Vista de hospitalización
      ];
      final viewStatus = <String, bool>{};

      for (final view in views) {
        try {
          await _supa.from(view).select('*').limit(1);
          viewStatus[view] = true;
        } catch (e) {
          viewStatus[view] = false;
        }
      }

      return {
        'connection': true,
        'tables': tableStatus,
        'views': viewStatus,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'connection': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Obtiene todos los bloques de historia para un paciente usando history_number
  Future<List<HistoryBlock>> getHistoryBlocks(String patientHistoryNumber,
      {String? clinicId}) async {
    try {
      final clinicIdValue = clinicId ?? '4c17fddf-24ab-4a8d-9343-4cc4f6a4a203';

      // Usar directamente la tabla medical_records
      final rows = await _supa
          .from('medical_records')
          .select()
          .eq('clinic_id', clinicIdValue)
          .eq('patient_id', patientHistoryNumber)
          .order('date', ascending: false)
          .order('created_at', ascending: false);

      if (rows.isNotEmpty) {
        return _processHistoryBlocks(rows);
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  /// Procesa los bloques de historia desde los datos de la BD
  List<HistoryBlock> _processHistoryBlocks(List<dynamic> rows) {
    final blocks = <HistoryBlock>[];
    for (final row in rows) {
      // Los adjuntos ya vienen incluidos en v_records_full, o vacíos en medical_records
      final attachments = <Attachment>[];
      if (row['attachments'] != null) {
        final attList = row['attachments'] as List;
        for (final att in attList) {
          final attData = att as Map<String, dynamic>;
          attachments.add(Attachment(
            id: attData['id'] as String,
            recordId: attData['record_id'] as String,
            path: attData['path'] as String,
            name: attData['label'] as String? ?? 'Archivo',
            size: 0, // No se almacena en la BD actual
            mimeType: _getMimeTypeFromDocType(
                attData['doc_type'] as String? ?? 'other'),
            createdAt: DateTime.parse(attData['created_at'] as String),
          ));
        }
      }

      blocks.add(HistoryBlock(
        id: row['id'] as String,
        patientId: row['patient_id'] as String,
        author: row['created_by'] as String? ?? 'Veterinaria',
        createdAt: DateTime.parse(row['created_at'] as String),
        locked: row['locked'] as bool? ?? false,
        deltaJson: row['notes'] as String? ?? '{"ops":[{"insert":""}]}',
        attachments: attachments,
        title: row['title'] as String?,
        summary: row['summary'] as String?,
        diagnosis: row['diagnosis'] as String?,
      ));
    }

    return blocks;
  }

  /// Crea un nuevo bloque de historia usando RPC
  Future<String> createHistoryBlock({
    required String patientHistoryNumber,
    required String author,
    String? title,
    String? summary,
    String? diagnosis,
    String? departmentCode,
    String? clinicId,
    Map<String, dynamic>? patientPatch,
    List<Map<String, dynamic>> attachments = const [],
  }) async {
    try {
      final result = await saveMedicalRecord(
        clinicId: clinicId ??
            '4c17fddf-24ab-4a8d-9343-4cc4f6a4a203', // TODO: Obtener del contexto
        patientHistoryNumber: patientHistoryNumber,
        contentDelta: '{"ops":[{"insert":""}]}',
        title: title ?? 'Nueva historia médica',
        summary: summary,
        diagnosis: diagnosis,
        departmentCode: departmentCode ?? 'MED',
        locked: false,
        patientPatch: patientPatch,
        attachments: attachments,
      );

      final recordId = result['record_id'] as String;

      return recordId;
    } catch (e) {
      rethrow;
    }
  }

  /// Actualiza el contenido delta de un bloque usando RPC
  Future<void> updateBlockContent(String blockId, String deltaJson,
      {String? clinicId}) async {
    try {
      await updateRecordContent(
        clinicId: clinicId ??
            '4c17fddf-24ab-4a8d-9343-4cc4f6a4a203', // TODO: Obtener del contexto
        recordId: blockId,
        contentDelta: deltaJson,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Cambia el estado de bloqueo de un bloque usando RPC
  Future<void> toggleBlockLock(String blockId, bool locked,
      {String? clinicId}) async {
    try {
      await toggleRecordLock(
        clinicId: clinicId ??
            '4c17fddf-24ab-4a8d-9343-4cc4f6a4a203', // TODO: Obtener del contexto
        recordId: blockId,
        locked: locked,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene la URL pública de un archivo
  String getPublicUrl(String filePath) {
    return _supa.storage.from('medical_records').getPublicUrl(filePath);
  }

  /// Convierte doc_type a MIME type
  String _getMimeTypeFromDocType(String docType) {
    switch (docType) {
      case 'pdf':
        return 'application/pdf';
      case 'image':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }

  // ========================================
  // MÉTODOS DE TIMELINE
  // ========================================

  /// Obtiene el timeline de cambios para un paciente
  Future<List<TimelineEvent>> getTimeline(String patientId) async {
    try {
      final recs = await _supa
          .from('medical_records')
          .select('id, created_at, updated_at, locked, created_by')
          .eq('patient_id', patientId)
          .order('created_at', ascending: true);

      if (recs.isEmpty) {
        return [];
      }

      final events = <TimelineEvent>[];

      // Agregar eventos de creación de bloques
      for (final rec in recs) {
        events.add(TimelineEvent(
          at: DateTime.parse(rec['created_at'] as String),
          title: 'Bloque de historia creado',
          subtitle: '${rec['created_by'] ?? 'Veterinaria'}',
          dotColor: const Color(0xFF4F46E5),
        ));

        // Si está bloqueado, agregar evento de bloqueo
        if (rec['locked'] == true) {
          events.add(TimelineEvent(
            at: DateTime.parse(rec['updated_at'] as String),
            title: 'Bloque de historia bloqueado',
            subtitle: '${rec['created_by'] ?? 'Veterinaria'}',
            dotColor: const Color(0xFF9CA3AF),
          ));
        }
      }

      // Obtener adjuntos
      final attachments = await _getAttachmentsForPatient(patientId);
      for (final att in attachments) {
        events.add(TimelineEvent(
          at: att.createdAt,
          title: 'Archivo adjuntado',
          subtitle: att.name,
          dotColor: const Color(0xFF4F46E5),
        ));
      }

      // Ordenar por fecha
      events.sort((a, b) => a.at.compareTo(b.at));

      return events;
    } catch (e) {
      return [];
    }
  }

  /// Obtiene los adjuntos para un paciente
  Future<List<AttachmentTimeline>> _getAttachmentsForPatient(
      String patientId) async {
    try {
      final rows = await _supa
          .from('record_attachments')
          .select('id, record_id, file_name, created_at')
          .inFilter('record_id', await _getRecordIdsForPatient(patientId))
          .order('created_at', ascending: true);

      return rows
          .map((row) => AttachmentTimeline(
                id: row['id'] as String,
                recordId: row['record_id'] as String,
                name: row['file_name'] as String,
                createdAt: DateTime.parse(row['created_at'] as String),
              ))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Obtiene los IDs de registros para un paciente
  Future<List<String>> _getRecordIdsForPatient(String patientId) async {
    try {
      final rows = await _supa
          .from('medical_records')
          .select('id')
          .eq('patient_id', patientId);

      return rows.map((row) => row['id'] as String).toList();
    } catch (e) {
      return [];
    }
  }

  // ========================================
  // MÉTODOS DE BÚSQUEDA DE PACIENTES
  // ========================================

  /// Busca pacientes por nombre, history_number o dueño usando v_app
  Future<List<PatientSearchRow>> searchPatients(String query,
      {int limit = 30}) async {
    try {
      final clinicId =
          '4c17fddf-24ab-4a8d-9343-4cc4f6a4a203'; // TODO: Obtener del contexto

      final q = query.trim();

      // Usar v_app y misma lógica simple que pacientes.dart
      var queryBuilder =
          _supa.from('v_app').select('*').eq('clinic_id', clinicId);

      if (q.isNotEmpty) {
        // Usar la misma lógica simple que funciona en pacientes.dart
        queryBuilder = queryBuilder.or(
            'patient_name.ilike.%$q%,history_number.ilike.%$q%,owner_name.ilike.%$q%');
      }

      final rows = await queryBuilder
          .order('patient_name', ascending: true)
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
          .map((row) => PatientSearchRow.fromJson(row))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene historias médicas de un paciente usando medical_records
  Future<List<Map<String, dynamic>>> fetchRecords({
    required String clinicId,
    required String historyNumber,
  }) async {
    try {
      // Consulta directa a medical_records
      final res = await _supa
          .from('medical_records')
          .select('*')
          .eq('clinic_id', clinicId)
          .eq('patient_id', historyNumber);

      final records = List<Map<String, dynamic>>.from(res as List);

      // Ordenar por fecha (más reciente primero)
      records.sort((a, b) {
        final dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime(1900);
        final dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime(1900);
        return dateB.compareTo(dateA);
      });

      return records;
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene un paciente por history_number usando v_app
  Future<PatientSummary?> getPatientSummary(String patientHistoryNumber) async {
    try {
      final clinicId =
          '4c17fddf-24ab-4a8d-9343-4cc4f6a4a203'; // TODO: Obtener del contexto

      // Usar v_app que tiene toda la información necesaria
      try {
        var queryBuilder =
            _supa.from('v_app').select('*').eq('clinic_id', clinicId);

        // Si parece ser un UUID, buscar por patient_id, sino por history_number
        if (patientHistoryNumber.contains('-')) {
          queryBuilder = queryBuilder.eq('patient_id', patientHistoryNumber);
        } else {
          queryBuilder =
              queryBuilder.eq('history_number', patientHistoryNumber);
        }

        final rows = await queryBuilder.limit(1);

        if (rows.isNotEmpty) {
          final row = rows.first;

          return PatientSummary.fromJson(row);
        }
      } catch (e) {}

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Actualiza información de un paciente
  Future<void> updatePatientInfo(
      String patientHistoryNumber, Map<String, dynamic> patientData) async {
    try {
      final clinicId =
          '4c17fddf-24ab-4a8d-9343-4cc4f6a4a203'; // TODO: Obtener del contexto
      await DatabaseQueries.updatePatient(
        patientHistoryNumber: patientHistoryNumber,
        clinicId: clinicId,
        patientData: patientData,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene roles activos de la clínica usando la nueva tabla clinic_roles
  Future<List<Map<String, dynamic>>> getClinicRoles({
    required String clinicId,
    bool activeOnly = true,
  }) async {
    try {
      var query = _supa.from('clinic_roles').select().eq('clinic_id', clinicId);

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      final rows = await query.order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene un rol específico por email (útil para created_by)
  Future<Map<String, dynamic>?> getRoleByEmail({
    required String clinicId,
    required String email,
  }) async {
    try {
      final rows = await _supa
          .from('clinic_roles')
          .select()
          .eq('clinic_id', clinicId)
          .eq('email', email)
          .eq('is_active', true)
          .limit(1);

      if (rows.isNotEmpty) {
        final role = rows.first;

        return role;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // ========================================
  // MÉTODOS RPC Y TRANSACCIONALES
  // ========================================

  /// Guarda un record médico completo con paciente y adjuntos en una sola transacción
  Future<Map<String, dynamic>> saveMedicalRecord({
    required String clinicId,
    required String patientHistoryNumber,
    required String contentDelta,
    String? title,
    String? summary,
    String? diagnosis,
    String? departmentCode,
    bool locked = false,
    DateTime? date,
    Map<String, dynamic>? patientPatch,
    List<Map<String, dynamic>> attachments = const [],
  }) async {
    try {
      // Usar el snippet optimizado para guardar historia + patch + adjuntos
      final result = await saveMedicalRecordSnippet(
        clinicId: clinicId,
        historyNumber: patientHistoryNumber,
        contentDelta: contentDelta,
        departmentCode: departmentCode ?? 'MED',
        locked: locked,
        date: date,
        patientPatch: patientPatch,
        attachments: attachments,
      );

      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// Actualiza solo el contenido de un record existente
  Future<void> updateRecordContent({
    required String clinicId,
    required String recordId,
    required String contentDelta,
    String? title,
    String? summary,
    String? diagnosis,
    bool? locked,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'notes': contentDelta,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      if (title != null) updateData['title'] = title;
      if (summary != null) updateData['summary'] = summary;
      if (diagnosis != null) updateData['diagnosis'] = diagnosis;
      if (locked != null) updateData['locked'] = locked;

      await _supa
          .from('medical_records')
          .update(updateData)
          .eq('id', recordId)
          .eq('clinic_id', clinicId);
    } catch (e) {
      rethrow;
    }
  }

  /// Cambia el estado de bloqueo de un record
  Future<void> toggleRecordLock({
    required String clinicId,
    required String recordId,
    required bool locked,
  }) async {
    try {
      await _supa
          .from('medical_records')
          .update({
            'locked': locked,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', recordId)
          .eq('clinic_id', clinicId);
    } catch (e) {
      rethrow;
    }
  }

  /// Sube un archivo adjunto a un record
  Future<Map<String, dynamic>> uploadAttachment({
    required String clinicId,
    required String recordId,
    required String filePath,
    required String docType,
    required String label,
  }) async {
    try {
      final attachment = await _supa
          .from('record_attachments')
          .insert({
            'record_id': recordId,
            'path': filePath,
            'doc_type': docType,
            'label': label,
          })
          .select()
          .single();

      return Map<String, dynamic>.from(attachment);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene adjuntos de un record específico
  Future<List<Map<String, dynamic>>> getRecordAttachments({
    required String clinicId,
    required String recordId,
  }) async {
    try {
      final rows = await _supa
          .from('record_attachments')
          .select()
          .eq('record_id', recordId);

      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      rethrow;
    }
  }

  // ========================================
  // MÉTODOS DE BÚSQUEDA Y CONSULTA
  // ========================================

  /// Guardar historia + patch + adjuntos (RPC)
  Future<Map<String, dynamic>> saveMedicalRecordSnippet({
    required String clinicId,
    required String historyNumber,
    required String contentDelta,
    String departmentCode = 'MED',
    bool locked = false,
    DateTime? date,
    Map<String, dynamic>? patientPatch,
    List<Map<String, dynamic>> attachments = const [],
  }) async {
    final payload = {
      'record': {
        'clinic_id': clinicId,
        'patient_id': historyNumber,
        'date': date?.toIso8601String().substring(0, 10),
        'department_code': departmentCode,
        'locked': locked,
        'notes': contentDelta,
      },
      if (patientPatch != null) 'patient_patch': patientPatch,
      if (attachments.isNotEmpty) 'attachments': attachments,
    };
    final res =
        await _supa.rpc('save_medical_record', params: {'payload': payload});
    return Map<String, dynamic>.from(res as Map);
  }

  /// Crear receta + items (RPC, opcional)
  Future<Map<String, dynamic>> createPrescription({
    required String clinicId,
    required String historyNumber,
    String? notes,
    List<Map<String, String>> items = const [],
  }) async {
    final res = await _supa.rpc('create_prescription', params: {
      'payload': {
        'clinic_id': clinicId,
        'historyNumber': historyNumber,
        if (notes != null) 'notes': notes,
        if (items.isNotEmpty) 'items': items,
      }
    });
    return Map<String, dynamic>.from(res as Map);
  }

  /// Obtiene la URL pública de un archivo usando la convención de Storage
  String getPublicUrlForRecord(
      String historyNumber, String recordId, String fileName) {
    // Convención: records/<historyNumber>/<RECORD_ID>/<archivo.ext>
    final filePath = 'records/$historyNumber/$recordId/$fileName';
    return _supa.storage.from('medical_records').getPublicUrl(filePath);
  }

  /// Sube un PDF de receta a Storage usando la convención recomendada
  Future<String> uploadPrescriptionPdf({
    required String bucket,
    required String path,
    required File file,
  }) async {
    try {
      await _supa.storage
          .from(bucket)
          .upload(path, file, fileOptions: const FileOptions(upsert: true));

      final publicUrl = _supa.storage.from(bucket).getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      rethrow;
    }
  }

  /// Registra un attachment de receta usando RPC
  Future<Map<String, dynamic>> addPrescriptionAttachment({
    required String clinicId,
    String? recordId,
    String? historyNumber,
    required String storagePath,
    Map<String, dynamic>? meta,
  }) async {
    try {
      final payload = <String, dynamic>{
        'clinic_id': clinicId,
        'path': storagePath,
        if (recordId != null) 'record_id': recordId,
        if (historyNumber != null) 'historyNumber': historyNumber,
        'label': 'Receta',
        if (meta != null) 'meta': meta,
      };

      final res = await _supa
          .rpc('add_prescription_attachment', params: {'payload': payload});

      return Map<String, dynamic>.from(res as Map);
    } catch (e) {
      rethrow;
    }
  }

  /// Método completo para subir PDF de receta y registrarlo
  Future<Map<String, dynamic>> uploadAndRegisterPrescription({
    required String clinicId,
    required String historyNumber,
    required File pdfFile,
    String? recordId,
    Map<String, dynamic>? meta,
  }) async {
    try {
      // 1. Generar ruta de storage con convención
      final fileName = 'receta_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final storagePath = recordId != null
          ? 'records/$historyNumber/$recordId/$fileName'
          : 'records/$historyNumber/tmp/$fileName';

      // 2. Subir archivo a Storage
      await uploadPrescriptionPdf(
        bucket: 'medical',
        path: storagePath,
        file: pdfFile,
      );

      // 3. Registrar como attachment
      final result = await addPrescriptionAttachment(
        clinicId: clinicId,
        recordId: recordId,
        historyNumber: historyNumber,
        storagePath: storagePath,
        meta: meta ??
            {
              'type': 'prescription',
              'doctor': 'Dr. Veterinario', // TODO: Obtener del contexto
              'valid_until': DateTime.now()
                  .add(const Duration(days: 30))
                  .toIso8601String(),
            },
      );

      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene solo recetas de un paciente por history_number
  Future<List<Map<String, dynamic>>> getPrescriptionsByHistoryNumber({
    required String clinicId,
    required String historyNumber,
  }) async {
    try {
      final rows = await _supa
          .from('record_attachments')
          .select('''
            *,
            medical_records!inner(
              id,
              clinic_id,
              patient_id
            )
          ''')
          .eq('medical_records.clinic_id', clinicId)
          .eq('medical_records.patient_id', historyNumber)
          .or('meta->>type.eq.prescription,label.ilike.Receta%')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      return [];
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
  final String? title;
  final String? summary;
  final String? diagnosis;

  HistoryBlock({
    required this.id,
    required this.patientId,
    required this.author,
    required this.createdAt,
    required this.locked,
    required this.deltaJson,
    required this.attachments,
    this.title,
    this.summary,
    this.diagnosis,
  });

  HistoryBlock copyWith({
    String? id,
    String? patientId,
    String? author,
    DateTime? createdAt,
    bool? locked,
    String? deltaJson,
    List<Attachment>? attachments,
    String? title,
    String? summary,
    String? diagnosis,
  }) {
    return HistoryBlock(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      locked: locked ?? this.locked,
      deltaJson: deltaJson ?? this.deltaJson,
      attachments: attachments ?? this.attachments,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      diagnosis: diagnosis ?? this.diagnosis,
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

/// Modelo para un evento del timeline
class TimelineEvent {
  final DateTime at;
  final String title;
  final String? subtitle;
  final Color dotColor;

  TimelineEvent({
    required this.at,
    required this.title,
    this.subtitle,
    this.dotColor = const Color(0xFF4F46E5),
  });
}

/// Modelo para adjuntos en el timeline
class AttachmentTimeline {
  final String id;
  final String recordId;
  final String name;
  final DateTime createdAt;

  AttachmentTimeline({
    required this.id,
    required this.recordId,
    required this.name,
    required this.createdAt,
  });
}

/// Modelo para búsqueda de pacientes usando v_app
class PatientSearchRow {
  final String patientId;
  final String? historyNumber;
  final String patientName;
  final String? ownerName;
  final String? species;
  final String? breed;
  final String? breedId;
  final String? ownerPhone;
  final String? ownerEmail;
  final String? sex;

  PatientSearchRow({
    required this.patientId,
    this.historyNumber,
    required this.patientName,
    this.ownerName,
    this.species,
    this.breed,
    this.breedId,
    this.ownerPhone,
    this.ownerEmail,
    this.sex,
  });

  factory PatientSearchRow.fromJson(Map<String, dynamic> json) {
    return PatientSearchRow(
      patientId: json['patient_id']?.toString() ??
          json['patient_uuid']?.toString() ??
          '',
      historyNumber: json['history_number']?.toString() ??
          json['history_number_snapshot']?.toString(),
      patientName: json['patient_name']?.toString() ??
          json['paciente_name_snapshot']?.toString() ??
          '',
      ownerName: json['owner_name']?.toString() ??
          json['owner_name_snapshot']?.toString(),
      species: _getSpeciesLabel(json['species_code']),
      breed: json['breed_label']?.toString() ?? json['breed']?.toString(),
      breedId: json['breed_id']?.toString(),
      ownerPhone: json['owner_phone']?.toString(),
      ownerEmail: json['owner_email']?.toString(),
      sex: json['sex']?.toString(),
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

/// Modelo para resumen de paciente
class PatientSummary {
  final String id;
  final String? name;
  final String? species;
  final String? breed;
  final String? sex;
  final String? ageLabel;
  final double? temperature;
  final int? respiration;
  final int? pulse;
  final String? hydration;

  PatientSummary({
    required this.id,
    this.name,
    this.species,
    this.breed,
    this.sex,
    this.ageLabel,
    this.temperature,
    this.respiration,
    this.pulse,
    this.hydration,
  });

  factory PatientSummary.fromJson(Map<String, dynamic> json) {
    return PatientSummary(
      id: json['patient_uuid'] ?? json['patient_id'] ?? json['id'] as String,
      name: json['patient_name'] ?? json['name'] as String?,
      species: json['species_label'] ?? json['species'] as String?,
      breed: json['breed_label'] ?? json['breed'] as String?,
      sex: json['sex'] as String?,
      ageLabel: json['age_label'] as String?,
      temperature: (json['temperature'] as num?)?.toDouble(),
      respiration: json['respiration'] as int?,
      pulse: json['pulse'] as int?,
      hydration: json['hydration'] as String?,
    );
  }
}

/// Diagnóstico: obtener todos los registros médicos para debug
Future<void> debugAllRecords() async {
  try {
    final _supa = Supabase.instance.client;
    final allRecords = await _supa.from('medical_records').select('*');

    for (var record in allRecords) {
      // TODO: Process record if needed
      print('Record: $record'); // Temporary fix for linter warning
    }
  } catch (e) {}
}
