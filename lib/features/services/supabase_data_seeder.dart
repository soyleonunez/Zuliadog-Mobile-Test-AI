import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Servicio para crear datos de prueba reales en Supabase
class SupabaseDataSeeder {
  static const String _tablePatients = 'patients';
  static const String _tableRecords = 'medical_records';
  static const String _tableAttachments = 'record_attachments';

  final SupabaseClient _supa = Supabase.instance.client;

  /// Crea datos de prueba reales en Supabase
  Future<void> seedTestData() async {
    try {
      print('🌱 Iniciando creación de datos de prueba...');

      // 1. Crear pacientes de prueba
      final patients = await _createTestPatients();
      print('✅ ${patients.length} pacientes creados');

      // 2. Crear historias médicas para cada paciente
      for (final patient in patients) {
        await _createTestMedicalRecords(patient['id'] as String);
      }
      print('✅ Historias médicas creadas');

      print('🎉 Datos de prueba creados exitosamente');
    } catch (e) {
      print('❌ Error al crear datos de prueba: $e');
    }
  }

  /// Crea pacientes de prueba
  Future<List<Map<String, dynamic>>> _createTestPatients() async {
    final patients = [
      {
        'id': const Uuid().v4(),
        'name': 'Max',
        'species': 'Canino',
        'breed': 'Labrador',
        'sex': 'Macho',
        'owner_name': 'María García',
        'owner_phone': '+58 412 123 4567',
        'birth_date': '2020-03-15',
        'temperature': 38.5,
        'respiration': 22,
        'pulse': 90,
        'hydration': 'Normal',
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      {
        'id': const Uuid().v4(),
        'name': 'Luna',
        'species': 'Felino',
        'breed': 'Persa',
        'sex': 'Hembra',
        'owner_name': 'Carlos López',
        'owner_phone': '+58 414 987 6543',
        'birth_date': '2021-07-22',
        'temperature': 38.8,
        'respiration': 25,
        'pulse': 120,
        'hydration': 'Normal',
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      {
        'id': const Uuid().v4(),
        'name': 'Bella',
        'species': 'Canino',
        'breed': 'Golden Retriever',
        'sex': 'Hembra',
        'owner_name': 'Ana Martínez',
        'owner_phone': '+58 416 555 1234',
        'birth_date': '2019-11-08',
        'temperature': 38.2,
        'respiration': 20,
        'pulse': 85,
        'hydration': 'Normal',
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
    ];

    final createdPatients = <Map<String, dynamic>>[];

    for (final patient in patients) {
      try {
        await _supa.from(_tablePatients).insert(patient);
        createdPatients.add(patient);
        print('✅ Paciente creado: ${patient['name']} (${patient['id']})');
      } catch (e) {
        print('⚠️ Error al crear paciente ${patient['name']}: $e');
      }
    }

    return createdPatients;
  }

  /// Crear un paciente individual
  Future<void> createPatient({
    required String name,
    required String species,
    required String breed,
  }) async {
    final patient = {
      'id': const Uuid().v4(),
      'name': name,
      'species': species,
      'breed': breed,
      'sex': 'No especificado',
      'owner_name': 'Propietario',
      'owner_phone': '+58 000 000 0000',
      'birth_date': DateTime.now()
          .subtract(const Duration(days: 365))
          .toIso8601String()
          .split('T')[0],
      'temperature': 38.5,
      'respiration': 22,
      'pulse': 90,
      'hydration': 'Normal',
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      await _supa.from(_tablePatients).insert(patient);
      print('✅ Paciente creado: $name (${patient['id']})');
    } catch (e) {
      print('⚠️ Error al crear paciente $name: $e');
      rethrow;
    }
  }

  /// Crea historias médicas de prueba para un paciente
  Future<void> _createTestMedicalRecords(String patientId) async {
    final records = [
      {
        'id': const Uuid().v4(),
        'patient_id': patientId,
        'created_by': 'Dr. Veterinario',
        'locked': false,
        'content_delta':
            '{"ops":[{"insert":"Consulta de rutina. Paciente en buen estado general.\\n\\n• Apetito: Normal\\n• Comportamiento: Activo y alerta\\n• Peso: Estable\\n\\nRecomendaciones: Continuar con la dieta actual y ejercicio regular."}]}',
        'title': 'Consulta de rutina',
        'summary': 'Paciente en buen estado general',
        'diagnosis': 'Estado de salud normal',
        'department_code': 'MED',
        'created_at': DateTime.now()
            .subtract(const Duration(days: 7))
            .toUtc()
            .toIso8601String(),
        'updated_at': DateTime.now()
            .subtract(const Duration(days: 7))
            .toUtc()
            .toIso8601String(),
      },
      {
        'id': const Uuid().v4(),
        'patient_id': patientId,
        'created_by': 'Dr. Veterinario',
        'locked': false,
        'content_delta':
            '{"ops":[{"insert":"Seguimiento post-tratamiento.\\n\\n• Mejora notable en el estado general\\n• Apetito restaurado\\n• Actividad normal\\n\\nPróxima cita en 2 semanas."}]}',
        'title': 'Seguimiento post-tratamiento',
        'summary': 'Mejora notable en el estado general',
        'diagnosis': 'Recuperación exitosa',
        'department_code': 'MED',
        'created_at': DateTime.now()
            .subtract(const Duration(days: 3))
            .toUtc()
            .toIso8601String(),
        'updated_at': DateTime.now()
            .subtract(const Duration(days: 3))
            .toUtc()
            .toIso8601String(),
      },
    ];

    for (final record in records) {
      try {
        await _supa.from(_tableRecords).insert(record);
        print(
            '✅ Historia médica creada: ${record['title']} para paciente $patientId');
      } catch (e) {
        print('⚠️ Error al crear historia médica: $e');
      }
    }
  }

  /// Limpia todos los datos de prueba
  Future<void> clearTestData() async {
    try {
      print('🧹 Limpiando datos de prueba...');

      // Eliminar historias médicas
      await _supa.from(_tableRecords).delete().neq('id', '');

      // Eliminar pacientes
      await _supa.from(_tablePatients).delete().neq('id', '');

      print('✅ Datos de prueba eliminados');
    } catch (e) {
      print('❌ Error al limpiar datos: $e');
    }
  }
}
