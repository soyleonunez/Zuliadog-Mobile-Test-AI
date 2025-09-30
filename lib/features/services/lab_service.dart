import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio para gestión de laboratorio
class LabService {
  final SupabaseClient _supa = Supabase.instance.client;

  /// Busca pacientes por history_number o nombre usando la tabla patients real
  Future<List<Map<String, dynamic>>> searchPatients(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      print('🔍 Buscando pacientes con query: $query');

      // Buscar directamente en patients con JOIN a owners y breeds
      final response = await _supa
          .from('patients')
          .select('''
            id,
            name,
            history_number,
            species_code,
            breed_id,
            breed,
            sex,
            birth_date,
            weight_kg,
            notes,
            owner_id,
            clinic_id,
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
          ''')
          .eq('clinic_id', '4c17fddf-24ab-4a8d-9343-4cc4f6a4a203')
          .or('name.ilike.%$query%,history_number.ilike.%$query%')
          .order('name')
          .limit(20);

      print(
          '📋 Respuesta de búsqueda: ${response.length} pacientes encontrados');

      final patients = List<Map<String, dynamic>>.from(response);

      // Transformar para que coincida con el formato esperado por LabUploadFlow
      final transformedPatients = patients.map((patient) {
        final owner = patient['owners'] as Map<String, dynamic>?;
        final breed = patient['breeds'] as Map<String, dynamic>?;

        return {
          'id': patient['id'], // ID real del paciente (UUID)
          'mrn': patient['history_number'], // Usar history_number como MRN
          'name': patient['name'],
          'species_code': patient['species_code'],
          'breed_id': patient['breed_id'],
          'breed': breed?['label'] ?? patient['breed'],
          'sex': patient['sex'],
          'birth_date': patient['birth_date'],
          'owner_name': owner?['name'],
          'owner_phone': owner?['phone'],
          'owner_email': owner?['email'],
          'created_at': patient['created_at'],
          'history_number': patient['history_number'],
          'medical_record_id':
              patient['id'], // Usar el ID del paciente como medical_record_id
        };
      }).toList();

      print('✅ Pacientes transformados: ${transformedPatients.length}');
      return transformedPatients;
    } catch (e) {
      print('❌ Error buscando pacientes: $e');
      // Fallback a datos mock si falla la conexión
      return _getMockPatients()
          .where((p) =>
              p['mrn'].toString().contains(query) ||
              p['name'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  /// Datos mock para desarrollo/testing
  List<Map<String, dynamic>> _getMockPatients() {
    return [
      {
        'mrn': '74321',
        'name': 'Rocky',
        'species_code': 'Canino',
        'breed_id': 'Golden Retriever',
        'photo_path':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAL7WTvuMT96JGl-dm2PwunhxSsUNnj_GHASrJ8pr60_dTL0ZXqRwPMg5BZF2KS7YreiLoSraQb2Y7oC_gpBF_W8EWaJLG2rbevTDnbagWLcmCgHxhGxvFnNpXTYpdTzKAIX8TAkLN5ajnFcyAUEBS9QIWIgjYC2jiqLO7yskRUzcHDBdd3EZaYN8r2QulXsHALaL7WP1kK8u5f5ZX4whoqiSapfgu4m4fsukxrwQNniC7wfCjUrR6Kly7a-yCAhIpCi_vtA5sorvhE',
        'created_at': DateTime.now().toIso8601String(),
        'history_number': 'H001',
        'medical_record_id': 'mr_rocky_001',
      },
      {
        'mrn': '74320',
        'name': 'Mochi',
        'species_code': 'Felino',
        'breed_id': 'Siamés',
        'photo_path':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuB9qcxedOW1xtR2gko-BbGB51CP6Lle2FAKTpY0mjF0TubTqryO6bFqQHZzfk4iTJkujXRPDXkD3_AyjBhiDQJKop-Dyp3sDo1DI-a4p69zw59GIx9gAl4URcOu8gEHvARmc8_U7lqCv9bmX4yqIF2lX5LZ41VhlLWMswoZCYTpUcyqKIoUay5vYdzC0GN-_OER-_Xnvmu8HVrYeY0out6lyoBUIbB8wolgpYqwdyWP-M6InI0vhOrPUCa2kJbxBw1asXhqPN01mTdY',
        'created_at': DateTime.now().toIso8601String(),
        'history_number': 'H002',
        'medical_record_id': 'mr_mochi_002',
      },
      {
        'mrn': '74319',
        'name': 'Buddy',
        'species_code': 'Canino',
        'breed_id': 'Beagle',
        'photo_path':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAVlOfQ8a8Zr_CDf05Dosi0QGY8BIjtOcvI8DCEBKsr3mINDY9pXPrxszOJtMlPp1FXkrqbmS1SKVGLSulUo5npPH4QibbEyKsAgUU89C7Xo--AKb1RijWZFKSJSCM6HjIAnR1YcgX3IO-81qmx0jA5GW83wuqvAtWMrTsLGqAsxS5uYuoC3lsV7VEKVOwVapL4z0K_ccYO6MFDPuyW1bdGjlqC0cjzUvIC4uiPJ3DTVtxC1xjTOhG7M85gz-Z3f20r8x0ZLCyIcw6v',
        'created_at': DateTime.now().toIso8601String(),
        'history_number': 'H003',
        'medical_record_id': 'mr_buddy_003',
      },
    ];
  }

  /// Genera URL firmada para archivo
  Future<String> getSignedUrl(String bucket, String key) async {
    try {
      final response =
          await _supa.storage.from(bucket).createSignedUrl(key, 3600); // 1 hora
      return response;
    } catch (e) {
      print('Error generando URL firmada: $e');
      rethrow;
    }
  }

  /// Obtiene plantillas de pruebas sugeridas
  Future<List<String>> getSuggestedTests(String clinicId) async {
    try {
      // Por ahora retorna lista hardcoded
      // TODO: Implementar consulta a tests_templates
      return [
        'Hemograma completo',
        'Perfil bioquímico',
        'Uroanálisis',
        'Parasitología',
        'Cultivo y antibiograma',
      ];
    } catch (e) {
      return ['Hemograma completo', 'Perfil bioquímico'];
    }
  }

  /// Firma y bloquea resultado
  Future<void> signAndLockResult(String orderId) async {
    try {
      await _supa.from('lab_results').update({
        'locked': true,
        'signed_by_role_id': _supa.auth.currentUser?.id ?? '',
        'signed_at': DateTime.now().toIso8601String(),
      }).eq('order_id', orderId);
    } catch (e) {
      print('Error firmando resultado: $e');
      rethrow;
    }
  }

  /// Obtiene estadísticas del laboratorio
  Future<Map<String, int>> getLabStats() async {
    try {
      print('🔍 Consultando estadísticas de lab_documents...');
      final clinicId = await _getCurrentClinicId();
      print('🏥 Clinic ID: $clinicId');

      // Primero verificar si hay datos en la tabla
      final allData = await _supa
          .from('lab_documents')
          .select('id, clinic_id, status')
          .limit(5);

      print('🔍 Todos los datos en lab_documents (stats): $allData');

      // Consulta simplificada sin filtro de clinic_id para debug
      final response = await _supa.from('lab_documents').select('status');

      print('📊 Respuesta de lab_documents: ${response.length} documentos');

      final stats = <String, int>{
        'pending': 0,
        'processing': 0,
        'completed': 0,
        'critical': 0,
      };

      for (final doc in response) {
        final status = doc['status'] as String?;
        print('📋 Documento con status: $status');
        switch (status) {
          case 'Pendiente':
            stats['pending'] = (stats['pending'] ?? 0) + 1;
            break;
          case 'En Proceso':
            stats['processing'] = (stats['processing'] ?? 0) + 1;
            break;
          case 'Completada':
            stats['completed'] = (stats['completed'] ?? 0) + 1;
            break;
          case 'Crítico':
            stats['critical'] = (stats['critical'] ?? 0) + 1;
            break;
        }
      }

      print('📈 Estadísticas calculadas: $stats');
      return stats;
    } catch (e) {
      print('❌ Error obteniendo estadísticas: $e');
      return {
        'pending': 12,
        'processing': 8,
        'completed': 45,
        'critical': 2,
      };
    }
  }

  /// Obtiene órdenes recientes
  Future<List<Map<String, dynamic>>> getRecentOrders() async {
    try {
      print('🔍 Consultando órdenes recientes de lab_documents...');
      final clinicId = await _getCurrentClinicId();
      print('🏥 Clinic ID: $clinicId');

      // Consulta completa con JOIN a patients para obtener información completa
      final response = await _supa
          .from('lab_documents')
          .select('''
            id,
            history_number,
            title,
            status,
            created_at,
            updated_at,
            responsible_vet,
            tests_requested,
            file_name,
            file_type,
            patients!inner(
              id,
              name,
              history_number,
              species_code,
              breed_id,
              breed,
              sex,
              birth_date,
              weight_kg,
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
            )
          ''')
          .eq('clinic_id', clinicId)
          .order('created_at', ascending: false)
          .limit(10);

      print('📋 Respuesta de órdenes: ${response.length} órdenes');
      print('📋 Datos de respuesta: $response');

      final orders = List<Map<String, dynamic>>.from(response);

      if (orders.isEmpty) {
        print('⚠️ No hay órdenes reales en la base de datos');
        return [];
      }

      print('🔄 Transformando ${orders.length} órdenes reales...');

      // Transformar la respuesta para que coincida con el formato esperado
      final transformedOrders = orders.map((order) {
        final patient = order['patients'] as Map<String, dynamic>?;
        final owner = patient?['owners'] as Map<String, dynamic>?;
        final breed = patient?['breeds'] as Map<String, dynamic>?;

        final patientName = patient?['name'] as String? ?? 'Sin nombre';
        final historyNumber = order['history_number'] as String? ?? '';
        final breedLabel =
            breed?['label'] as String? ?? patient?['breed'] as String? ?? 'N/A';
        final speciesCode = patient?['species_code'] as String? ?? '';
        final responsible =
            order['responsible_vet'] as String? ?? 'Dr. Sin asignar';
        final status = order['status'] as String? ?? 'Pendiente';
        final testsRequested = order['tests_requested'] as String? ?? '';

        print(
            '🔄 Transformando orden: ${order['id']} - $patientName ($historyNumber)');

        return {
          'id': order['id'] as String? ?? '',
          'order_number':
              'LAB-${(order['id'] as String? ?? '').substring(0, 8).toUpperCase()}',
          'history_number': historyNumber,
          'patient_name': patientName,
          'mrn': historyNumber, // Usar history_number como MRN
          'breed': breedLabel,
          'species_code': speciesCode,
          'birth_date': patient?['birth_date'] as String? ?? '',
          'responsible': responsible,
          'status': status,
          'status_color': _getStatusColor(status),
          'last_update': _formatLastUpdate(order['updated_at'] as String?),
          'photo_path': '', // No hay foto en la tabla patients
          'tests_requested': testsRequested,
          'owner_name': owner?['name'] as String? ?? 'N/A',
          'owner_phone': owner?['phone'] as String? ?? 'N/A',
          'file_name': order['file_name'] as String? ?? '',
          'file_type': order['file_type'] as String? ?? '',
        };
      }).toList();

      print('✅ Órdenes transformadas: ${transformedOrders.length}');
      print('✅ Datos transformados: $transformedOrders');
      return transformedOrders;
    } catch (e) {
      print('❌ Error obteniendo órdenes: $e');
      print('❌ Stack trace: ${e.toString()}');
      return [];
    }
  }

  /// Obtiene clinic_id actual del usuario
  Future<String> _getCurrentClinicId() async {
    try {
      // Por ahora usar un clinic_id fijo para desarrollo
      // TODO: Implementar lógica real de obtención de clinic_id
      print('🔍 Usando clinic_id fijo: 4c17fddf-24ab-4a8d-9343-4cc4f6a4a203');
      return '4c17fddf-24ab-4a8d-9343-4cc4f6a4a203';
    } catch (e) {
      // Fallback para desarrollo
      print('🔍 Fallback clinic_id: 4c17fddf-24ab-4a8d-9343-4cc4f6a4a203');
      return '4c17fddf-24ab-4a8d-9343-4cc4f6a4a203';
    }
  }

  /// Helper para obtener color de estado
  String _getStatusColor(String? status) {
    switch (status) {
      case 'Completada':
        return 'success';
      case 'En Proceso':
        return 'warning';
      case 'Crítico':
        return 'danger';
      case 'Colectada':
        return 'info';
      default:
        return 'warning';
    }
  }

  /// Helper para extraer nombre del paciente del título

  /// Helper para formatear última actualización
  String _formatLastUpdate(String? updatedAt) {
    if (updatedAt == null) return 'Desconocido';

    final now = DateTime.now();
    final updated = DateTime.parse(updatedAt);
    final difference = now.difference(updated);

    if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} minutos';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} horas';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else {
      return 'Hace ${difference.inDays} días';
    }
  }

  /// Subir resultado de laboratorio
  Future<String> uploadLabResult({
    required String historyNumber,
    required String patientId,
    required String title,
    required String fileName,
    required String filePath,
    required String fileType,
    required int fileSize,
    required String storageKey,
    String? testsRequested,
    String? responsibleVet,
  }) async {
    try {
      final response = await _supa
          .from('lab_documents')
          .insert({
            'history_number': historyNumber,
            'patient_id': patientId,
            'clinic_id': await _getCurrentClinicId(),
            'title': title,
            'file_name': fileName,
            'file_path': filePath,
            'file_type': fileType,
            'file_size': fileSize,
            'storage_key': storageKey,
            'status': 'Pendiente',
            'tests_requested': testsRequested,
            'responsible_vet': responsibleVet,
            'uploaded_by': _supa.auth.currentUser?.id,
          })
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      print('Error subiendo resultado: $e');
      throw Exception('Error al subir el resultado: $e');
    }
  }

  // ========================================
  // MÉTODOS DE INTEGRACIÓN CON HISTORIAS
  // ========================================

  /// Obtiene documentos de laboratorio por history_number
  Future<List<Map<String, dynamic>>> getDocumentsByHistoryNumber(
      String historyNumber) async {
    try {
      final response = await _supa
          .from('lab_documents')
          .select('*')
          .eq('history_number', historyNumber)
          .eq('clinic_id', await _getCurrentClinicId())
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error obteniendo documentos por history_number: $e');
      return [];
    }
  }

  /// Vincular documento de laboratorio con historia médica
  Future<void> linkDocumentToHistory({
    required String documentId,
    required String historyNumber,
    required String recordId,
  }) async {
    try {
      // Actualizar el documento de laboratorio para vincularlo con la historia
      await _supa
          .from('lab_documents')
          .update({
            'history_number': historyNumber,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', documentId)
          .eq('clinic_id', await _getCurrentClinicId());

      // Crear un registro en documents para que aparezca en el text_editor
      await _supa.from('documents').insert({
        'clinic_id': await _getCurrentClinicId(),
        'record_id': recordId,
        'file_name': 'Documento de laboratorio vinculado',
        'file_path': 'lab_results/linked/$documentId',
        'file_size': 0,
        'file_type': 'lab_link',
        'uploaded_at': DateTime.now().toIso8601String(),
        'lab_document_id': documentId, // Referencia al documento original
      });
    } catch (e) {
      print('Error vinculando documento a historia: $e');
      throw Exception('Error al vincular documento: $e');
    }
  }

  /// Obtener documentos de laboratorio vinculados a una historia
  Future<List<Map<String, dynamic>>> getLinkedLabDocuments(
      String recordId) async {
    try {
      final response = await _supa
          .from('documents')
          .select('''
            *,
            lab_documents!inner(*)
          ''')
          .eq('clinic_id', await _getCurrentClinicId())
          .eq('record_id', recordId)
          .eq('file_type', 'lab_link');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error obteniendo documentos vinculados: $e');
      return [];
    }
  }

  /// Subir resultado de laboratorio y vincularlo automáticamente
  Future<String> uploadAndLinkResult({
    required String historyNumber,
    required String patientId,
    required String title,
    required String fileName,
    required String filePath,
    required String fileType,
    required int fileSize,
    required String storageKey,
    String? testsRequested,
    String? responsibleVet,
    String? recordId, // ID del registro médico para vincular
  }) async {
    try {
      // Subir el documento de laboratorio
      final documentId = await uploadLabResult(
        historyNumber: historyNumber,
        patientId: patientId,
        title: title,
        fileName: fileName,
        filePath: filePath,
        fileType: fileType,
        fileSize: fileSize,
        storageKey: storageKey,
        testsRequested: testsRequested,
        responsibleVet: responsibleVet,
      );

      // Si se proporciona recordId, vincular automáticamente
      if (recordId != null) {
        await linkDocumentToHistory(
          documentId: documentId,
          historyNumber: historyNumber,
          recordId: recordId,
        );
      }

      return documentId;
    } catch (e) {
      print('Error subiendo y vinculando resultado: $e');
      throw Exception('Error al subir y vincular resultado: $e');
    }
  }

  /// Sube resultado de laboratorio para un paciente específico
  Future<String> uploadResultForPatient({
    required Map<String, dynamic> patient,
    required String title,
    required String fileName,
    required String filePath,
    required String fileType,
    required int fileSize,
    String? testsRequested,
    String? responsibleVet,
  }) async {
    try {
      print('📤 Subiendo resultado para paciente: ${patient['name']}');
      print('📋 Datos completos del paciente: $patient');
      print('📋 History Number: ${patient['history_number']}');
      print('📋 Patient ID: ${patient['id']}');

      // Validar que tenemos el ID del paciente
      if (patient['id'] == null) {
        throw Exception('El paciente no tiene un ID válido. Datos: $patient');
      }

      final historyNumber = patient['history_number'] as String? ?? '000000';
      final patientId = patient['id'] as String; // Usar el ID real del paciente
      final clinicId = await _getCurrentClinicId();

      print('🔍 Usando clinic_id: $clinicId');
      print('🔍 Patient ID para insertar: $patientId');

      // Generar storage key único
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storageKey =
          'lab_results/clinic/$clinicId/orders/$historyNumber/${timestamp}_$fileName';

      print('📁 Subiendo archivo al bucket lab_results...');
      print('📁 Storage key: $storageKey');
      print('📁 File path: $filePath');

      // Leer el archivo como bytes
      final fileBytes = await File(filePath).readAsBytes();

      try {
        // Intentar subir el archivo al bucket lab_results
        await _supa.storage
            .from('lab_results')
            .uploadBinary(storageKey, fileBytes);

        print('✅ Archivo subido exitosamente al bucket lab_results');
      } catch (e) {
        print('❌ Error subiendo al bucket lab_results: $e');

        // Si el bucket no existe o hay problemas de RLS, intentar crear el bucket
        if (e.toString().contains('403') ||
            e.toString().contains('Unauthorized')) {
          print('🔧 Intentando crear bucket lab_results...');
          await _createLabResultsBucket();

          // Reintentar la subida
          await _supa.storage
              .from('lab_results')
              .uploadBinary(storageKey, fileBytes);

          print('✅ Archivo subido exitosamente después de crear bucket');
        } else {
          rethrow;
        }
      }

      // Obtener la URL pública del archivo
      final publicUrl =
          _supa.storage.from('lab_results').getPublicUrl(storageKey);

      print('🔗 URL pública: $publicUrl');

      // Insertar el documento en la base de datos
      final response = await _supa
          .from('lab_documents')
          .insert({
            'history_number': historyNumber,
            'patient_id': patientId, // Usar el ID real del paciente
            'clinic_id': clinicId,
            'title': title,
            'file_name': fileName,
            'file_path':
                publicUrl, // Usar la URL pública en lugar de la ruta local
            'file_type': fileType,
            'file_size': fileSize,
            'storage_key': storageKey,
            'storage_bucket': 'lab_results',
            'status': 'Pendiente',
            'tests_requested': testsRequested,
            'responsible_vet': responsibleVet,
            'uploaded_by': _supa.auth.currentUser?.id,
          })
          .select('id')
          .single();

      final documentId = response['id'] as String;
      print('✅ Documento guardado en base de datos con ID: $documentId');

      return documentId;
    } catch (e) {
      print('❌ Error subiendo resultado para paciente: $e');
      throw Exception('Error al subir resultado: $e');
    }
  }

  /// Crea el bucket lab_results si no existe
  Future<void> _createLabResultsBucket() async {
    try {
      print('🔧 Creando bucket lab_results...');

      // Intentar crear el bucket
      await _supa.storage.createBucket('lab_results');

      print('✅ Bucket lab_results creado exitosamente');

      // Configurar políticas RLS para el bucket
      await _configureLabResultsBucketPolicies();
    } catch (e) {
      print('❌ Error creando bucket lab_results: $e');
      // Si el bucket ya existe, continuar
      if (!e.toString().contains('already exists')) {
        rethrow;
      }
    }
  }

  /// Configura las políticas RLS para el bucket lab_results
  Future<void> _configureLabResultsBucketPolicies() async {
    try {
      print('🔧 Configurando políticas RLS para lab_results...');

      // Nota: Las políticas RLS se configuran en Supabase Dashboard
      // Aquí solo mostramos un mensaje informativo
      print('ℹ️  Las políticas RLS deben configurarse en Supabase Dashboard:');
      print('   1. Ir a Storage > lab_results > Policies');
      print(
          '   2. Crear política para permitir INSERT, SELECT, UPDATE, DELETE');
      print('   3. Usar: auth.uid() IS NOT NULL');
    } catch (e) {
      print('❌ Error configurando políticas: $e');
    }
  }
}
