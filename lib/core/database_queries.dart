import 'package:supabase_flutter/supabase_flutter.dart';

/// Archivo centralizado de queries para todo el proyecto Zuliadog
/// Este archivo contiene todas las consultas SQL y operaciones de base de datos
/// para mantener consistencia y facilitar el mantenimiento
class DatabaseQueries {
  static final SupabaseClient _supa = Supabase.instance.client;

  // ========================================
  // QUERIES DE PACIENTES
  // ========================================

  /// Obtiene un paciente por MRN o ID
  static Future<Map<String, dynamic>?> getPatientByMrnOrId({
    required String patientIdOrMrn,
    required String clinicId,
  }) async {
    try {
      final row = await _supa
          .from('patients')
          .select()
          .or('id.eq.$patientIdOrMrn,mrn.eq.$patientIdOrMrn')
          .eq('clinic_id', clinicId)
          .maybeSingle();
      return row;
    } catch (e) {
      rethrow;
    }
  }

  /// Busca pacientes por nombre, MRN o dueño
  static Future<List<Map<String, dynamic>>> searchPatients({
    required String query,
    required String clinicId,
    int limit = 30,
  }) async {
    try {
      final q = query.trim();
      final isNumeric = int.tryParse(q.replaceAll(RegExp(r'\D'), '')) != null;

      var queryBuilder = _supa.from('patients').select('''
            id, mrn, name, species, breed, sex, age_label,
            temperature, respiration, pulse, hydration,
            owner_name, owner_phone, owner_email,
            created_at, updated_at
          ''').eq('clinic_id', clinicId);

      if (q.isEmpty) {
        // Lista inicial ordenada por nombre
        final rows =
            await queryBuilder.order('name', ascending: true).limit(limit);
        return List<Map<String, dynamic>>.from(rows);
      }

      // Búsqueda con OR compuesto
      final ors = <String>[
        "name.ilike.%$q%",
        "owner_name.ilike.%$q%",
        "mrn.eq.$q",
        if (isNumeric)
          "mrn_int.eq.${int.parse(q.replaceAll(RegExp(r'\\D'), ''))}",
      ];

      final rows = await queryBuilder
          .or(ors.join(','))
          .order('name', ascending: true)
          .limit(limit);

      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      rethrow;
    }
  }

  /// Actualiza información de un paciente
  static Future<void> updatePatient({
    required String patientMrn,
    required String clinicId,
    required Map<String, dynamic> patientData,
  }) async {
    try {
      await _supa
          .from('patients')
          .update(patientData)
          .eq('mrn', patientMrn)
          .eq('clinic_id', clinicId);
    } catch (e) {
      rethrow;
    }
  }

  // ========================================
  // QUERIES DE HISTORIAS MÉDICAS
  // ========================================

  /// Obtiene historias médicas de un paciente
  static Future<List<Map<String, dynamic>>> getMedicalRecords({
    required String patientMrn,
    required String clinicId,
    int? limit,
    int? offset,
  }) async {
    try {
      dynamic query = _supa.from('medical_records').select('''
            id, patient_id, created_at, updated_at, locked, 
            content_delta, title, summary, diagnosis, 
            department_code, created_by
          ''').eq('clinic_id', clinicId).eq('patient_id', patientMrn);

      query = query.order('created_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 50) - 1);
      }

      final rows = await query;
      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene una historia médica específica con adjuntos
  static Future<Map<String, dynamic>?> getMedicalRecordWithAttachments({
    required String recordId,
    required String clinicId,
  }) async {
    try {
      // Obtener el record
      final record = await _supa
          .from('medical_records')
          .select()
          .eq('id', recordId)
          .eq('clinic_id', clinicId)
          .single();

      // Obtener adjuntos
      final attachments = await _supa
          .from('record_attachments')
          .select()
          .eq('record_id', recordId);

      // Obtener información del paciente
      final patient = await getPatientByMrnOrId(
        patientIdOrMrn: record['patient_id'],
        clinicId: clinicId,
      );

      return {
        ...record,
        'attachments': attachments,
        'patient': patient,
      };
    } catch (e) {
      return null;
    }
  }

  /// Crea una nueva historia médica
  static Future<String> createMedicalRecord({
    required String clinicId,
    required String patientMrn,
    required String contentDelta,
    String? title,
    String? summary,
    String? diagnosis,
    String? departmentCode,
    bool locked = false,
    DateTime? date,
    String? createdBy,
  }) async {
    try {
      final result = await _supa
          .from('medical_records')
          .insert({
            'clinic_id': clinicId,
            'patient_id': patientMrn,
            'date': date?.toIso8601String().substring(0, 10),
            'title': title,
            'summary': summary,
            'diagnosis': diagnosis,
            'department_code': departmentCode ?? 'MED',
            'locked': locked,
            'content_delta': contentDelta,
            'created_by': createdBy,
            'created_at': DateTime.now().toUtc().toIso8601String(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .select()
          .single();

      return result['id'] as String;
    } catch (e) {
      rethrow;
    }
  }

  /// Actualiza el contenido de una historia médica
  static Future<void> updateMedicalRecordContent({
    required String recordId,
    required String clinicId,
    required String contentDelta,
  }) async {
    try {
      await _supa
          .from('medical_records')
          .update({
            'content_delta': contentDelta,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', recordId)
          .eq('clinic_id', clinicId);
    } catch (e) {
      rethrow;
    }
  }

  /// Cambia el estado de bloqueo de una historia médica
  static Future<void> toggleMedicalRecordLock({
    required String recordId,
    required String clinicId,
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

  // ========================================
  // QUERIES DE ADJUNTOS
  // ========================================

  /// Obtiene adjuntos de una historia médica
  static Future<List<Map<String, dynamic>>> getRecordAttachments({
    required String recordId,
  }) async {
    try {
      final rows = await _supa
          .from('record_attachments')
          .select()
          .eq('record_id', recordId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      rethrow;
    }
  }

  /// Crea un adjunto para una historia médica
  static Future<Map<String, dynamic>> createRecordAttachment({
    required String recordId,
    required String filePath,
    required String docType,
    required String label,
  }) async {
    try {
      final result = await _supa
          .from('record_attachments')
          .insert({
            'record_id': recordId,
            'path': filePath,
            'doc_type': docType,
            'label': label,
            'created_at': DateTime.now().toUtc().toIso8601String(),
          })
          .select()
          .single();

      return Map<String, dynamic>.from(result);
    } catch (e) {
      rethrow;
    }
  }

  // ========================================
  // QUERIES DE TIMELINE
  // ========================================

  /// Obtiene el timeline de un paciente
  static Future<List<Map<String, dynamic>>> getPatientTimeline({
    required String patientMrn,
    required String clinicId,
    int? limit,
  }) async {
    try {
      // Obtener historias médicas
      final records = await getMedicalRecords(
        patientMrn: patientMrn,
        clinicId: clinicId,
        limit: limit,
      );

      // Convertir a formato de timeline
      final timeline = records
          .map((record) => {
                'id': record['id'],
                'type': 'medical_record',
                'title': record['title'] ?? 'Historia médica',
                'description': record['summary'] ?? 'Sin descripción',
                'date': record['created_at'],
                'author': record['created_by'] ?? 'Sistema',
                'locked': record['locked'],
              })
          .toList();

      // Ordenar por fecha descendente
      timeline
          .sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));

      return timeline;
    } catch (e) {
      rethrow;
    }
  }

  // ========================================
  // QUERIES DE ESTADÍSTICAS
  // ========================================

  /// Obtiene estadísticas generales de la clínica
  static Future<Map<String, dynamic>> getClinicStats({
    required String clinicId,
  }) async {
    try {
      // Contar pacientes
      final patientsResult =
          await _supa.from('patients').select('id').eq('clinic_id', clinicId);

      // Contar historias médicas
      final recordsResult = await _supa
          .from('medical_records')
          .select('id')
          .eq('clinic_id', clinicId);

      // Contar historias de hoy
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final todayRecordsResult = await _supa
          .from('medical_records')
          .select('id')
          .eq('clinic_id', clinicId)
          .eq('date', today);

      return {
        'total_patients': (patientsResult as List).length,
        'total_records': (recordsResult as List).length,
        'today_records': (todayRecordsResult as List).length,
      };
    } catch (e) {
      rethrow;
    }
  }

  // ========================================
  // QUERIES DE VALIDACIÓN
  // ========================================

  /// Verifica si un MRN existe
  static Future<bool> mrnExists({
    required String mrn,
    required String clinicId,
  }) async {
    try {
      final result = await _supa
          .from('patients')
          .select('id')
          .eq('mrn', mrn)
          .eq('clinic_id', clinicId)
          .maybeSingle();

      return result != null;
    } catch (e) {
      return false;
    }
  }

  /// Verifica si una historia médica existe
  static Future<bool> medicalRecordExists({
    required String recordId,
    required String clinicId,
  }) async {
    try {
      final result = await _supa
          .from('medical_records')
          .select('id')
          .eq('id', recordId)
          .eq('clinic_id', clinicId)
          .maybeSingle();

      return result != null;
    } catch (e) {
      return false;
    }
  }

  // ========================================
  // QUERIES DE LIMPIEZA
  // ========================================

  /// Elimina una historia médica y sus adjuntos
  static Future<void> deleteMedicalRecord({
    required String recordId,
    required String clinicId,
  }) async {
    try {
      // Eliminar adjuntos primero
      await _supa.from('record_attachments').delete().eq('record_id', recordId);

      // Eliminar la historia médica
      await _supa
          .from('medical_records')
          .delete()
          .eq('id', recordId)
          .eq('clinic_id', clinicId);
    } catch (e) {
      rethrow;
    }
  }

  /// Elimina un paciente y todas sus historias médicas
  static Future<void> deletePatient({
    required String patientMrn,
    required String clinicId,
  }) async {
    try {
      // Obtener todas las historias médicas del paciente
      final records = await getMedicalRecords(
        patientMrn: patientMrn,
        clinicId: clinicId,
      );

      // Eliminar cada historia médica y sus adjuntos
      for (final record in records) {
        await deleteMedicalRecord(
          recordId: record['id'],
          clinicId: clinicId,
        );
      }

      // Eliminar el paciente
      await _supa
          .from('patients')
          .delete()
          .eq('mrn', patientMrn)
          .eq('clinic_id', clinicId);
    } catch (e) {
      rethrow;
    }
  }
}
