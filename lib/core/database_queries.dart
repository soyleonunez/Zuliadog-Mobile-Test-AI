import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

/// Archivo centralizado de queries para todo el proyecto Zuliadog
/// Este archivo contiene todas las consultas SQL y operaciones de base de datos
/// para mantener consistencia y facilitar el mantenimiento
class DatabaseQueries {
  static final SupabaseClient _supa = Supabase.instance.client;

  // ========================================
  // QUERIES DE PACIENTES
  // ========================================

  /// Obtiene un paciente por history_number o ID
  static Future<Map<String, dynamic>?> getPatientByHistoryNumberOrId({
    required String patientIdOrHistoryNumber,
    required String clinicId,
  }) async {
    try {
      final row = await _supa
          .from('patients')
          .select()
          .or('id.eq.$patientIdOrHistoryNumber,history_number.eq.$patientIdOrHistoryNumber')
          .eq('clinic_id', clinicId)
          .maybeSingle();
      return row;
    } catch (e) {
      rethrow;
    }
  }

  /// Busca pacientes por nombre, history_number o dueño
  static Future<List<Map<String, dynamic>>> searchPatients({
    required String query,
    required String clinicId,
    int limit = 30,
  }) async {
    try {
      final q = query.trim();

      // Usar JOIN directo en lugar de vista
      var queryBuilder = _supa.from('patients').select('''
            id,
            history_number,
            name,
            species_code,
            breed_id,
            breed,
            sex,
            birth_date,
            weight_kg,
            notes,
            owner_id,
            clinic_id,
            history_number,
            temper,
            temperature,
            respiration,
            pulse,
            hydration,
            weight,
            admission_date,
            _patient_id,
            created_at,
            updated_at,
            owners:owner_id (
              name,
              phone,
              email
            ),
            breeds:breed_id (
              label,
              species_code,
              species_label
            )
          ''').eq('clinic_id', clinicId);

      if (q.isEmpty) {
        // Lista inicial ordenada por nombre
        final rows =
            await queryBuilder.order('name', ascending: true).limit(limit);
        return _processPatientResults(rows);
      }

      // Búsqueda con OR compuesto
      final ors = <String>[
        "name.ilike.%$q%",
        "history_number.ilike.%$q%",
        "history_number.ilike.%$q%",
        "history_number.eq.$q",
        "species_label.ilike.%$q%",
        "breed_label.ilike.%$q%",
      ];

      final rows = await queryBuilder
          .or(ors.join(','))
          .order('name', ascending: true)
          .limit(limit);

      return _processPatientResults(rows);
    } catch (e) {
      rethrow;
    }
  }

  /// Procesa los resultados de pacientes para crear el formato esperado
  static List<Map<String, dynamic>> _processPatientResults(List<dynamic> rows) {
    return rows.map((record) {
      final owner = record['owners'] as Map<String, dynamic>?;
      final breed = record['breeds'] as Map<String, dynamic>?;

      return {
        'patient_id': record['id'],
        'patient_uuid': record['id'],
        'clinic_id': record['clinic_id'],
        'patient_name': record['name'],
        'paciente_name_snapshot': record['name'],
        'history_number': record['history_number'],
        'history_number_snapshot': record['history_number'],
        'history_number_int': record['history_number'],
        'owner_name': owner?['name'],
        'owner_name_snapshot': owner?['name'],
        'owner_phone': owner?['phone'],
        'owner_email': owner?['email'],
        'species_code': record['species_code'],
        'species_label': breed?['species_label'],
        'breed_label': breed?['label'],
        'breed': breed?['label'],
        'breed_id': record['breed_id'],
        'sex': record['sex'],
        'weight_kg': record['weight_kg'],
        'notes': record['notes'],
        'status': 'active',
        'last_visit_at': record['created_at'],
        'photo_path': null,
      };
    }).toList();
  }

  /// Actualiza información de un paciente
  static Future<void> updatePatient({
    required String patientHistoryNumber,
    required String clinicId,
    required Map<String, dynamic> patientData,
  }) async {
    try {
      await _supa
          .from('patients')
          .update(patientData)
          .eq('history_number', patientHistoryNumber)
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
    required String patientHistoryNumber,
    required String clinicId,
    int? limit,
    int? offset,
  }) async {
    try {
      // Usar tabla directa de historias médicas
      dynamic query = _supa.from('medical_records').select('''
            id, title, notes, date, created_at, updated_at,
            doctor, patient_id, summary, locked
          ''').eq('clinic_id', clinicId).eq('patient_id', patientHistoryNumber);

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
      final patient = await getPatientByHistoryNumberOrId(
        patientIdOrHistoryNumber: record['patient_id'],
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
    required String patientHistoryNumber,
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
            'patient_id': patientHistoryNumber,
            'date': date?.toIso8601String().substring(0, 10),
            'title': title,
            'summary': summary,
            'diagnosis': diagnosis,
            'department_code': departmentCode ?? 'MED',
            'locked': locked,
            'notes': contentDelta,
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
            'notes': contentDelta,
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
  // QUERIES DE HOSPITALIZACIONES
  // ========================================

  /// Obtiene hospitalizaciones activas
  static Future<List<Map<String, dynamic>>> getActiveHospitalizations({
    required String clinicId,
  }) async {
    try {
      final rows = await _supa
          .from('v_hosp')
          .select()
          .eq('clinic_id', clinicId)
          .order('admission_date', ascending: false);

      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene hospitalizaciones de un paciente
  static Future<List<Map<String, dynamic>>> getPatientHospitalizations({
    required String patientHistoryNumber,
    required String clinicId,
  }) async {
    try {
      final rows = await _supa
          .from('hospitalizations')
          .select()
          .eq('clinic_id', clinicId)
          .eq(
              'patient_id',
              (await _supa
                  .from('patients')
                  .select('id')
                  .eq('history_number', patientHistoryNumber)
                  .eq('clinic_id', clinicId)
                  .single())['id'])
          .order('admission_date', ascending: false);

      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      rethrow;
    }
  }

  /// Crea una nueva hospitalización
  static Future<String> createHospitalization({
    required String clinicId,
    required String patientHistoryNumber,
    required String diagnosis,
    String? treatmentPlan,
    String? specialInstructions,
    String? roomNumber,
    String? bedNumber,
    String priority = 'normal',
    String? assignedVetId,
    String? createdBy,
  }) async {
    try {
      // Obtener ID del paciente
      final patientResult = await _supa
          .from('patients')
          .select('id')
          .eq('history_number', patientHistoryNumber)
          .eq('clinic_id', clinicId)
          .single();

      final result = await _supa
          .from('hospitalizations')
          .insert({
            'patient_id': patientResult['id'],
            'clinic_id': clinicId,
            'admission_date': DateTime.now().toIso8601String().substring(0, 10),
            'diagnosis': diagnosis,
            'treatment_plan': treatmentPlan,
            'special_instructions': specialInstructions,
            'room_number': roomNumber,
            'bed_number': bedNumber,
            'priority': priority,
            'assigned_vet_id': assignedVetId,
            'created_by': createdBy,
            'status': 'active',
          })
          .select()
          .single();

      return result['id'] as String;
    } catch (e) {
      rethrow;
    }
  }

  // ========================================
  // QUERIES DE TRATAMIENTOS
  // ========================================

  /// Obtiene tratamientos pendientes
  static Future<List<Map<String, dynamic>>> getPendingTreatments({
    required String clinicId,
  }) async {
    try {
      final rows = await _supa
          .from('follows')
          .select()
          .eq('clinic_id', clinicId)
          .eq('status', 'scheduled')
          .order('scheduled_date', ascending: true)
          .order('scheduled_time', ascending: true);

      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene tratamientos de un paciente
  static Future<List<Map<String, dynamic>>> getPatientTreatments({
    required String patientHistoryNumber,
    required String clinicId,
  }) async {
    try {
      // Obtener ID del paciente
      final patientResult = await _supa
          .from('patients')
          .select('id')
          .eq('history_number', patientHistoryNumber)
          .eq('clinic_id', clinicId)
          .single();

      final rows = await _supa
          .from('follows')
          .select()
          .eq('clinic_id', clinicId)
          .eq('patient_id', patientResult['id'])
          .order('scheduled_date', ascending: true)
          .order('scheduled_time', ascending: true);

      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      rethrow;
    }
  }

  /// Crea un nuevo tratamiento
  static Future<String> createTreatment({
    required String clinicId,
    required String patientHistoryNumber,
    required String medicationName,
    required String dosage,
    required String route,
    required String frequency,
    required DateTime scheduledDate,
    TimeOfDay? scheduledTime,
    String? hospitalizationId,
    String? notes,
    String? createdBy,
  }) async {
    try {
      // Obtener ID del paciente
      final patientResult = await _supa
          .from('patients')
          .select('id')
          .eq('history_number', patientHistoryNumber)
          .eq('clinic_id', clinicId)
          .single();

      final result = await _supa
          .from('follows')
          .insert({
            'patient_id': patientResult['id'],
            'hospitalization_id': hospitalizationId,
            'clinic_id': clinicId,
            'medication_name': medicationName,
            'medication_dosage': dosage,
            'administration_route': route,
            'frequency': frequency,
            'scheduled_date': scheduledDate.toIso8601String().substring(0, 10),
            'scheduled_time': scheduledTime != null
                ? '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}:00'
                : null,
            'completion_notes': notes,
            'status': 'scheduled',
          })
          .select()
          .single();

      return result['id'] as String;
    } catch (e) {
      rethrow;
    }
  }

  /// Marca un tratamiento como completado
  static Future<void> completeTreatment({
    required String treatmentId,
    required String clinicId,
    required String completedBy,
    String? notes,
  }) async {
    try {
      await _supa
          .from('follows')
          .update({
            'status': 'completed',
            'completed_at': DateTime.now().toUtc().toIso8601String(),
            'completed_by': completedBy,
            'completion_notes': notes,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', treatmentId)
          .eq('clinic_id', clinicId);
    } catch (e) {
      rethrow;
    }
  }

  // ========================================
  // QUERIES DE NOTAS
  // ========================================

  /// Obtiene notas importantes
  static Future<List<Map<String, dynamic>>> getImportantNotes({
    required String clinicId,
  }) async {
    try {
      final rows = await _supa
          .from('notes')
          .select()
          .eq('clinic_id', clinicId)
          .eq('is_important', true)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      rethrow;
    }
  }

  /// Crea una nueva nota
  static Future<String> createNote({
    required String clinicId,
    required String patientHistoryNumber,
    required String content,
    String? hospitalizationId,
    String noteType = 'general',
    bool isImportant = false,
    String? createdBy,
  }) async {
    try {
      // Obtener ID del paciente
      final patientResult = await _supa
          .from('patients')
          .select('id')
          .eq('history_number', patientHistoryNumber)
          .eq('clinic_id', clinicId)
          .single();

      final result = await _supa
          .from('notes')
          .insert({
            'patient_id': patientResult['id'],
            'hospitalization_id': hospitalizationId,
            'clinic_id': clinicId,
            'content': content,
            'note_type': noteType,
            'is_important': isImportant,
            'created_by': createdBy,
          })
          .select()
          .single();

      return result['id'] as String;
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
    required String patientHistoryNumber,
    required String clinicId,
    int? limit,
  }) async {
    try {
      // Obtener historias médicas
      final records = await getMedicalRecords(
        patientHistoryNumber: patientHistoryNumber,
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

      // Contar hospitalizaciones activas
      final hospitalizationsResult = await _supa
          .from('hospitalization')
          .select('id')
          .eq('clinic_id', clinicId)
          .eq('status', 'active');

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
        'active_hospitalizations': (hospitalizationsResult as List).length,
        'today_records': (todayRecordsResult as List).length,
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene actividad reciente de la clínica
  static Future<List<Map<String, dynamic>>> getRecentActivity({
    required String clinicId,
    int limit = 20,
  }) async {
    try {
      // Obtener historias médicas recientes
      final records = await _supa
          .from('medical_records')
          .select('id, title, created_at, patient_id')
          .eq('clinic_id', clinicId)
          .order('created_at', ascending: false)
          .limit(limit);

      // Obtener hospitalizaciones recientes
      final hospitalizations = await _supa
          .from('hospitalization')
          .select('id, admission_date, patient_id')
          .eq('clinic_id', clinicId)
          .order('created_at', ascending: false)
          .limit(limit);

      // Combinar y ordenar por fecha
      final activities = <Map<String, dynamic>>[];

      for (final record in records) {
        activities.add({
          'type': 'medical_record',
          'id': record['id'],
          'date': record['created_at'],
          'title': record['title'],
        });
      }

      for (final hosp in hospitalizations) {
        activities.add({
          'type': 'hospitalization',
          'id': hosp['id'],
          'date': hosp['admission_date'],
          'title': 'Hospitalización',
        });
      }

      // Ordenar por fecha y limitar
      activities
          .sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
      return activities.take(limit).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene reporte de pacientes por especie
  static Future<List<Map<String, dynamic>>> getPatientsBySpecies({
    required String clinicId,
  }) async {
    try {
      final rows = await _supa
          .from('v_app')
          .select('species_code, species_label, patient_id')
          .eq('clinic_id', clinicId);

      // Agrupar por especie
      final Map<String, Map<String, dynamic>> speciesMap = {};

      for (final row in rows) {
        final speciesCode = row['species_code'] as String;
        if (!speciesMap.containsKey(speciesCode)) {
          speciesMap[speciesCode] = {
            'species_code': speciesCode,
            'species_label': row['species_label'],
            'patient_count': 0,
          };
        }
        speciesMap[speciesCode]!['patient_count'] =
            (speciesMap[speciesCode]!['patient_count'] as int) + 1;
      }

      return speciesMap.values.toList();
    } catch (e) {
      rethrow;
    }
  }

  // ========================================
  // QUERIES DE VALIDACIÓN
  // ========================================

  /// Verifica si un history_number existe
  static Future<bool> historyNumberExists({
    required String historyNumber,
    required String clinicId,
  }) async {
    try {
      final result = await _supa
          .from('patients')
          .select('id')
          .eq('history_number', historyNumber)
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
    required String patientHistoryNumber,
    required String clinicId,
  }) async {
    try {
      // Obtener todas las historias médicas del paciente
      final records = await getMedicalRecords(
        patientHistoryNumber: patientHistoryNumber,
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
          .eq('history_number', patientHistoryNumber)
          .eq('clinic_id', clinicId);
    } catch (e) {
      rethrow;
    }
  }
}
