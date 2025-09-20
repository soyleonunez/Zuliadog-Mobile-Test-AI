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
      print('🔍 Iniciando diagnóstico de conexión...');

      // 1. Verificar conexión básica
      await _supa.from('clinics').select('id').limit(1);

      print('✅ Conexión básica exitosa');

      // 2. Verificar tablas principales
      final tables = [
        'patients',
        'medical_records',
        'record_attachments',
        'clinic_roles', // Nueva tabla (antes clinic_members)
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
          print('✅ Tabla $table accesible');
        } catch (e) {
          tableStatus[table] = false;
          print('❌ Tabla $table no accesible: $e');
        }
      }

      // 3. Verificar vistas
      final views = [
        'v_patient_owner',
        'v_records_full',
        'patients_search' // Nueva vista optimizada para búsquedas
      ];
      final viewStatus = <String, bool>{};

      for (final view in views) {
        try {
          await _supa.from(view).select('*').limit(1);
          viewStatus[view] = true;
          print('✅ Vista $view accesible');
        } catch (e) {
          viewStatus[view] = false;
          print('❌ Vista $view no accesible: $e');
        }
      }

      return {
        'connection': true,
        'tables': tableStatus,
        'views': viewStatus,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ Error en diagnóstico: $e');
      return {
        'connection': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Obtiene todos los bloques de historia para un paciente usando MRN
  Future<List<HistoryBlock>> getHistoryBlocks(String patientMrn,
      {String? clinicId}) async {
    try {
      print('🔍 Obteniendo bloques para patientMrn: $patientMrn');

      final clinicIdValue = clinicId ?? '4c17fddf-24ab-4a8d-9343-4cc4f6a4a203';

      // Primero intentar con la vista v_records_full
      try {
        final rows = await _supa
            .from('v_records_full')
            .select()
            .eq('clinic_id', clinicIdValue)
            .eq('patient_id', patientMrn)
            .order('date', ascending: false)
            .order('created_at', ascending: false);

        print(
            '📊 Resultados obtenidos de v_records_full: ${rows.length} bloques');

        if (rows.isNotEmpty) {
          return _processHistoryBlocks(rows);
        }
      } catch (e) {
        print(
            '⚠️ Error con v_records_full, intentando con tabla medical_records: $e');
      }

      // Si falla la vista, intentar con la tabla medical_records directamente
      try {
        final rows = await _supa
            .from('medical_records')
            .select()
            .eq('clinic_id', clinicIdValue)
            .eq('patient_id', patientMrn)
            .order('date', ascending: false)
            .order('created_at', ascending: false);

        print(
            '📊 Resultados obtenidos de medical_records: ${rows.length} bloques');

        if (rows.isNotEmpty) {
          return _processHistoryBlocks(rows);
        }
      } catch (e) {
        print('⚠️ Error con tabla medical_records: $e');
      }

      print('⚠️ No se encontraron bloques para patientMrn: $patientMrn');
      return [];
    } catch (e) {
      print('❌ Error al obtener bloques: $e');
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
        deltaJson: row['content_delta'] as String? ?? '{"ops":[{"insert":""}]}',
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
    required String patientMrn,
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
        patientMrn: patientMrn,
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
      print('✅ Bloque creado exitosamente: $recordId');
      return recordId;
    } catch (e) {
      print('❌ Error al crear bloque: $e');
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
      print('❌ Error al actualizar contenido: $e');
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
      print('❌ Error al cambiar estado de bloqueo: $e');
      rethrow;
    }
  }

  /// Obtiene la URL pública de un archivo
  String getPublicUrl(String filePath) {
    return _supa.storage.from('medical-files').getPublicUrl(filePath);
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
      print('🔍 Construyendo timeline para patientId: $patientId');

      final recs = await _supa
          .from('medical_records')
          .select('id, created_at, updated_at, locked, created_by')
          .eq('patient_id', patientId)
          .order('created_at', ascending: true);

      if (recs.isEmpty) {
        print('📝 No hay historias médicas para este paciente');
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

      print('📊 Timeline construido: ${events.length} eventos');
      return events;
    } catch (e) {
      print('❌ Error en getTimeline: $e');
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
      print('❌ Error al obtener adjuntos: $e');
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
      print('❌ Error al obtener IDs de registros: $e');
      return [];
    }
  }

  // ========================================
  // MÉTODOS DE BÚSQUEDA DE PACIENTES
  // ========================================

  /// Busca pacientes por nombre, MRN o dueño usando la vista patients_search
  Future<List<PatientSearchRow>> searchPatients(String query,
      {int limit = 30}) async {
    try {
      final clinicId =
          '4c17fddf-24ab-4a8d-9343-4cc4f6a4a203'; // TODO: Obtener del contexto

      print('🔍 Buscando pacientes con query: "$query" en clinicId: $clinicId');

      // Si no hay query, devolver lista vacía
      if (query.trim().isEmpty) {
        print('⚠️ Query vacío, devolviendo lista vacía');
        return [];
      }

      final q = query.trim();

      // Usar la vista patients_search que tiene todos los datos necesarios
      var queryBuilder = _supa.from('patients_search').select('''
            patient_id, history_number, patient_name, species_code, species_label, 
            breed_id, breed_label, sex, birth_date, color, weight_kg,
            owner_id, owner_name, owner_phone, owner_email
          ''').eq('clinic_id', clinicId);

      // Búsqueda con OR compuesto
      final ors = <String>[
        "patient_name.ilike.%$q%",
        "owner_name.ilike.%$q%",
        "history_number.ilike.%$q%", // Búsqueda parcial en número de historia
        "history_number.eq.$q", // Búsqueda exacta en número de historia
      ];

      final rows = await queryBuilder
          .or(ors.join(','))
          .order('patient_name', ascending: true)
          .limit(limit);

      print('📊 Resultados encontrados: ${rows.length}');
      return rows.map((row) => PatientSearchRow.fromJson(row)).toList();
    } catch (e) {
      print('❌ Error en searchPatients: $e');
      rethrow;
    }
  }

  /// Obtiene historias médicas de un paciente usando v_records_full
  Future<List<Map<String, dynamic>>> fetchRecords({
    required String clinicId,
    required String mrn,
  }) async {
    try {
      print('🔍 Obteniendo historias para MRN: $mrn en clinicId: $clinicId');

      // Consulta directa sin filtros complejos para evitar problemas de RLS
      print('🔄 Consultando tabla medical_records...');

      final res =
          await _supa.from('medical_records').select('*').eq('patient_id', mrn);

      final records = List<Map<String, dynamic>>.from(res as List);
      print('📊 Historias encontradas (sin filtros): ${records.length}');

      // Debug: mostrar todos los registros encontrados
      if (records.isNotEmpty) {
        print('🔍 Registros encontrados:');
        for (var record in records) {
          print(
              '  - ID: ${record['id']}, patient_id: ${record['patient_id']}, title: ${record['title']}');
        }
      } else {
        print('❌ No se encontraron registros con patient_id: $mrn');

        // Ejecutar diagnóstico completo
        await debugAllRecords();
      }

      // Filtrar por clinic_id en el código
      final filteredRecords =
          records.where((record) => record['clinic_id'] == clinicId).toList();

      // Ordenar por fecha (más reciente primero)
      filteredRecords.sort((a, b) {
        final dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime(1900);
        final dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime(1900);
        return dateB.compareTo(dateA);
      });

      print('📊 Historias filtradas y ordenadas: ${filteredRecords.length}');
      return filteredRecords;
    } catch (e) {
      print('❌ Error general en fetchRecords: $e');
      rethrow;
    }
  }

  /// Obtiene un paciente por MRN usando la vista v_patient_owner
  Future<PatientSummary?> getPatientSummary(String patientMrn) async {
    try {
      final clinicId =
          '4c17fddf-24ab-4a8d-9343-4cc4f6a4a203'; // TODO: Obtener del contexto

      print('🔍 Buscando paciente con MRN: $patientMrn en clinicId: $clinicId');

      // Primero intentar con la vista v_patient_owner
      try {
        // Intentar buscar por patient_uuid (si es UUID) o por history_number (si es número)
        var queryBuilder =
            _supa.from('v_patient_owner').select().eq('clinic_id', clinicId);

        // Si parece ser un UUID, buscar por patient_uuid, sino por history_number
        if (patientMrn.contains('-')) {
          queryBuilder = queryBuilder.eq('patient_uuid', patientMrn);
        } else {
          queryBuilder = queryBuilder.eq('history_number', patientMrn);
        }

        final rows = await queryBuilder.limit(1);

        if (rows.isNotEmpty) {
          final row = rows.first;
          print(
              '✅ Paciente encontrado en v_patient_owner: ${row['patient_name']}');
          return PatientSummary.fromJson(row);
        }
      } catch (e) {
        print(
            '⚠️ Error con v_patient_owner, intentando con tabla patients: $e');
      }

      // Si falla la vista, intentar con la tabla patients directamente
      try {
        var queryBuilder =
            _supa.from('patients').select().eq('clinic_id', clinicId);

        // Si parece ser un UUID, buscar por id, sino por mrn
        if (patientMrn.contains('-')) {
          queryBuilder = queryBuilder.eq('id', patientMrn);
        } else {
          queryBuilder = queryBuilder.eq('mrn', patientMrn);
        }

        final rows = await queryBuilder.limit(1);

        if (rows.isNotEmpty) {
          final row = rows.first;
          print('✅ Paciente encontrado en tabla patients: ${row['name']}');
          return PatientSummary.fromJson(row);
        }
      } catch (e) {
        print('⚠️ Error con tabla patients: $e');
      }

      print('⚠️ No se encontró paciente con MRN: $patientMrn');
      return null;
    } catch (e) {
      print('❌ Error en getPatientSummary: $e');
      return null;
    }
  }

  /// Actualiza información de un paciente
  Future<void> updatePatientInfo(
      String patientMrn, Map<String, dynamic> patientData) async {
    try {
      final clinicId =
          '4c17fddf-24ab-4a8d-9343-4cc4f6a4a203'; // TODO: Obtener del contexto
      await DatabaseQueries.updatePatient(
        patientMrn: patientMrn,
        clinicId: clinicId,
        patientData: patientData,
      );
    } catch (e) {
      print('❌ Error en updatePatientInfo: $e');
      rethrow;
    }
  }

  /// Obtiene roles activos de la clínica usando la nueva tabla clinic_roles
  Future<List<Map<String, dynamic>>> getClinicRoles({
    required String clinicId,
    bool activeOnly = true,
  }) async {
    try {
      print('🔍 Obteniendo roles de clínica: $clinicId');

      var query = _supa.from('clinic_roles').select().eq('clinic_id', clinicId);

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      final rows = await query.order('created_at', ascending: false);

      print('📊 Roles encontrados: ${rows.length}');
      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      print('❌ Error en getClinicRoles: $e');
      rethrow;
    }
  }

  /// Obtiene un rol específico por email (útil para created_by)
  Future<Map<String, dynamic>?> getRoleByEmail({
    required String clinicId,
    required String email,
  }) async {
    try {
      print('🔍 Buscando rol por email: $email en clínica: $clinicId');

      final rows = await _supa
          .from('clinic_roles')
          .select()
          .eq('clinic_id', clinicId)
          .eq('email', email)
          .eq('is_active', true)
          .limit(1);

      if (rows.isNotEmpty) {
        final role = rows.first;
        print('✅ Rol encontrado: ${role['role']} para ${role['email']}');
        return role;
      }

      print('⚠️ No se encontró rol para email: $email');
      return null;
    } catch (e) {
      print('❌ Error en getRoleByEmail: $e');
      return null;
    }
  }

  // ========================================
  // MÉTODOS RPC Y TRANSACCIONALES
  // ========================================

  /// Guarda un record médico completo con paciente y adjuntos en una sola transacción
  Future<Map<String, dynamic>> saveMedicalRecord({
    required String clinicId,
    required String patientMrn,
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
        mrn: patientMrn,
        contentDelta: contentDelta,
        departmentCode: departmentCode ?? 'MED',
        locked: locked,
        date: date,
        patientPatch: patientPatch,
        attachments: attachments,
      );

      print('✅ Record guardado exitosamente: $result');
      return result;
    } catch (e) {
      print('❌ Error en saveMedicalRecord: $e');
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
        'content_delta': contentDelta,
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

      print('✅ Contenido del record actualizado: $recordId');
    } catch (e) {
      print('❌ Error en updateRecordContent: $e');
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

      print('✅ Estado de bloqueo actualizado: $recordId -> $locked');
    } catch (e) {
      print('❌ Error en toggleRecordLock: $e');
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

      print('✅ Adjunto subido: $label');
      return Map<String, dynamic>.from(attachment);
    } catch (e) {
      print('❌ Error en uploadAttachment: $e');
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
      print('❌ Error en getRecordAttachments: $e');
      rethrow;
    }
  }

  // ========================================
  // MÉTODOS DE BÚSQUEDA Y CONSULTA
  // ========================================

  /// Guardar historia + patch + adjuntos (RPC)
  Future<Map<String, dynamic>> saveMedicalRecordSnippet({
    required String clinicId,
    required String mrn,
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
        'patient_id': mrn,
        'date': date?.toIso8601String().substring(0, 10),
        'department_code': departmentCode,
        'locked': locked,
        'content_delta': contentDelta,
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
    required String mrn,
    String? notes,
    List<Map<String, String>> items = const [],
  }) async {
    final res = await _supa.rpc('create_prescription', params: {
      'payload': {
        'clinic_id': clinicId,
        'mrn': mrn,
        if (notes != null) 'notes': notes,
        if (items.isNotEmpty) 'items': items,
      }
    });
    return Map<String, dynamic>.from(res as Map);
  }

  /// Obtiene la URL pública de un archivo usando la convención de Storage
  String getPublicUrlForRecord(String mrn, String recordId, String fileName) {
    // Convención: records/<MRN>/<RECORD_ID>/<archivo.ext>
    final filePath = 'records/$mrn/$recordId/$fileName';
    return _supa.storage.from('medical-files').getPublicUrl(filePath);
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
      print('✅ PDF subido exitosamente: $path');
      return publicUrl;
    } catch (e) {
      print('❌ Error al subir PDF: $e');
      rethrow;
    }
  }

  /// Registra un attachment de receta usando RPC
  Future<Map<String, dynamic>> addPrescriptionAttachment({
    required String clinicId,
    String? recordId,
    String? mrn,
    required String storagePath,
    Map<String, dynamic>? meta,
  }) async {
    try {
      final payload = <String, dynamic>{
        'clinic_id': clinicId,
        'path': storagePath,
        if (recordId != null) 'record_id': recordId,
        if (mrn != null) 'mrn': mrn,
        'label': 'Receta',
        if (meta != null) 'meta': meta,
      };

      final res = await _supa
          .rpc('add_prescription_attachment', params: {'payload': payload});
      print('✅ Attachment de receta registrado: $storagePath');
      return Map<String, dynamic>.from(res as Map);
    } catch (e) {
      print('❌ Error al registrar attachment de receta: $e');
      rethrow;
    }
  }

  /// Método completo para subir PDF de receta y registrarlo
  Future<Map<String, dynamic>> uploadAndRegisterPrescription({
    required String clinicId,
    required String mrn,
    required File pdfFile,
    String? recordId,
    Map<String, dynamic>? meta,
  }) async {
    try {
      // 1. Generar ruta de storage con convención
      final fileName = 'receta_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final storagePath = recordId != null
          ? 'records/$mrn/$recordId/$fileName'
          : 'records/$mrn/tmp/$fileName';

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
        mrn: mrn,
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

      print('✅ Receta subida y registrada exitosamente');
      return result;
    } catch (e) {
      print('❌ Error en uploadAndRegisterPrescription: $e');
      rethrow;
    }
  }

  /// Obtiene solo recetas de un paciente por MRN
  Future<List<Map<String, dynamic>>> getPrescriptionsByMrn({
    required String clinicId,
    required String mrn,
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
          .eq('medical_records.patient_id', mrn)
          .or('meta->>type.eq.prescription,label.ilike.Receta%')
          .order('created_at', ascending: false);

      print('📋 Recetas encontradas: ${rows.length}');
      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      print('❌ Error al obtener recetas: $e');
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

/// Modelo para búsqueda de pacientes
class PatientSearchRow {
  final String patientId;
  final String? historyNumber;
  final String patientName;
  final String? ownerName;
  final String? species;

  PatientSearchRow({
    required this.patientId,
    this.historyNumber,
    required this.patientName,
    this.ownerName,
    this.species,
  });

  factory PatientSearchRow.fromJson(Map<String, dynamic> json) {
    return PatientSearchRow(
      patientId: json['patient_id'] as String,
      historyNumber: json['history_number'] as String?,
      patientName: json['patient_name'] as String,
      ownerName: json['owner_name'] as String?,
      species: json['species_label'] as String?,
    );
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
    print('🔍 DIAGNÓSTICO: Obteniendo todos los registros médicos...');
    final _supa = Supabase.instance.client;
    final allRecords = await _supa.from('medical_records').select('*');
    print('📊 Total de registros en medical_records: ${allRecords.length}');

    for (var record in allRecords) {
      print('  - ID: ${record['id']}');
      print('    patient_id: ${record['patient_id']}');
      print('    clinic_id: ${record['clinic_id']}');
      print('    title: ${record['title']}');
      print('    date: ${record['date']}');
      print('    ---');
    }
  } catch (e) {
    print('❌ Error en diagnóstico: $e');
  }
}
