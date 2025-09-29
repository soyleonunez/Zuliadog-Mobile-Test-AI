// =====================================================
// SEEDER DE DATOS PARA EL NUEVO ESQUEMA UNIFICADO
// Sistema de datos de prueba para Zuliadog
// =====================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config.dart';

/// Servicio para crear datos de prueba reales en el nuevo esquema
class NewDataSeeder {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Crea datos de prueba completos en el nuevo esquema
  Future<void> seedCompleteTestData() async {
    try {
      print(
          '🌱 Iniciando creación de datos de prueba para el nuevo esquema...');

      // 1. Verificar que las especies existen
      await _ensureSpeciesExist();
      print('✅ Especies verificadas');

      // 2. Verificar que las razas existen
      await _ensureBreedsExist();
      print('✅ Razas verificadas');

      // 3. Crear propietarios de ejemplo
      final owners = await _createTestOwners();
      print('✅ ${owners.length} propietarios creados');

      // 4. Crear pacientes de ejemplo
      final patients = await _createTestPatients(owners);
      print('✅ ${patients.length} pacientes creados');

      // 5. Crear historias médicas
      await _createTestMedicalRecords(patients);
      print('✅ Historias médicas creadas');

      // 6. Crear hospitalizaciones
      await _createTestHospitalizations(patients);
      print('✅ Hospitalizaciones creadas');

      // 7. Crear tratamientos
      await _createTestTreatments(patients);
      print('✅ Tratamientos creados');

      // 8. Crear notas
      await _createTestNotes(patients);
      print('✅ Notas creadas');

      print('🎉 Datos de prueba creados exitosamente');
    } catch (e) {
      print('❌ Error al crear datos de prueba: $e');
      rethrow;
    }
  }

  /// Verifica que las razas básicas existen (ya no hay tabla species)
  Future<void> _ensureSpeciesExist() async {
    // Las especies ahora están en la tabla breeds con species_code
    print('ℹ️ Las especies ahora están integradas en la tabla breeds');
  }

  /// Verifica que las razas básicas existen
  Future<void> _ensureBreedsExist() async {
    final breeds = [
      // Razas caninas
      {
        'species_code': 'CAN',
        'species_label': 'Canino',
        'label': 'Labrador Retriever',
        'description': 'Raza mediana-grande, muy sociable y activa'
      },
      {
        'species_code': 'CAN',
        'species_label': 'Canino',
        'label': 'Golden Retriever',
        'description': 'Raza mediana-grande, amigable y leal'
      },
      {
        'species_code': 'CAN',
        'species_label': 'Canino',
        'label': 'Pastor Alemán',
        'description': 'Raza grande, inteligente y protectora'
      },
      {
        'species_code': 'CAN',
        'species_label': 'Canino',
        'label': 'Bulldog Francés',
        'description': 'Raza pequeña, tranquila y cariñosa'
      },
      {
        'species_code': 'CAN',
        'species_label': 'Canino',
        'label': 'Beagle',
        'description': 'Raza mediana, enérgica y curiosa'
      },

      // Razas felinas
      {
        'species_code': 'FEL',
        'species_label': 'Felino',
        'label': 'Persa',
        'description': 'Raza de pelo largo, tranquila y elegante'
      },
      {
        'species_code': 'FEL',
        'species_label': 'Felino',
        'label': 'Siamés',
        'description': 'Raza elegante, vocal y activa'
      },
      {
        'species_code': 'FEL',
        'species_label': 'Felino',
        'label': 'Maine Coon',
        'description': 'Raza grande, amigable y juguetona'
      },
      {
        'species_code': 'FEL',
        'species_label': 'Felino',
        'label': 'British Shorthair',
        'description': 'Raza robusta, tranquila y cariñosa'
      },
      {
        'species_code': 'FEL',
        'species_label': 'Felino',
        'label': 'Ragdoll',
        'description': 'Raza grande, dócil y relajada'
      },
    ];

    for (final breed in breeds) {
      try {
        await _supabase.from('breeds').insert({
          'species_code': breed['species_code'],
          'species_label': breed['species_label'],
          'label': breed['label'],
          'description': breed['description'],
        });
        print('✅ Raza creada: ${breed['label']}');
      } catch (e) {
        // La raza ya existe, continuar
        print('ℹ️ Raza ya existe: ${breed['label']}');
      }
    }
  }

  /// Crea propietarios de prueba
  Future<List<Map<String, dynamic>>> _createTestOwners() async {
    final ownersData = [
      {
        'name': 'María García López',
        'phone': '+58 412 123 4567',
        'email': 'maria.garcia@email.com',
        'address': 'Av. Principal #123, Caracas',
      },
      {
        'name': 'Carlos Eduardo Rodríguez',
        'phone': '+58 414 987 6543',
        'email': 'carlos.rodriguez@email.com',
        'address': 'Calle 2 #45, Maracaibo',
      },
      {
        'name': 'Ana Sofía Martínez',
        'phone': '+58 416 555 1234',
        'email': 'ana.martinez@email.com',
        'address': 'Res. Los Próceres, Valencia',
      },
      {
        'name': 'Roberto José Silva',
        'phone': '+58 424 789 0123',
        'email': 'roberto.silva@email.com',
        'address': 'Urb. La Floresta, Barquisimeto',
      },
      {
        'name': 'Isabel Cristina Herrera',
        'phone': '+58 426 321 9876',
        'email': 'isabel.herrera@email.com',
        'address': 'Av. Bolívar #789, Ciudad Bolívar',
      },
    ];

    final createdOwners = <Map<String, dynamic>>[];

    for (final ownerData in ownersData) {
      try {
        final owner = {
          'clinic_id': AppConfig.clinicId,
          ...ownerData,
        };

        final result =
            await _supabase.from('owners').insert(owner).select().single();
        createdOwners.add(result);
        print('✅ Propietario creado: ${ownerData['name']}');
      } catch (e) {
        print('⚠️ Error al crear propietario ${ownerData['name']}: $e');
      }
    }

    return createdOwners;
  }

  /// Crea pacientes de prueba
  Future<List<Map<String, dynamic>>> _createTestPatients(
      List<Map<String, dynamic>> owners) async {
    final patientsData = [
      {
        'history_number': '4C17-000001',
        'name': 'Max',
        'species_code': 'CAN',
        'breed_name': 'Labrador Retriever',
        'birth_date': '2020-03-15',
        'sex': 'M',
        'weight_kg': 28.5,
        'notes':
            'Perro muy activo y sociable. Le gusta jugar con pelotas y nadar. Vacunas al día.',
        'owner_index': 0,
      },
      {
        'history_number': '4C17-000002',
        'name': 'Luna',
        'species_code': 'FEL',
        'breed_name': 'Persa',
        'birth_date': '2021-07-22',
        'sex': 'F',
        'weight_kg': 4.2,
        'notes':
            'Gata tranquila y cariñosa. Requiere cepillado diario por su pelaje largo.',
        'owner_index': 1,
      },
      {
        'history_number': '4C17-000003',
        'name': 'Rocky',
        'species_code': 'CAN',
        'breed_name': 'Pastor Alemán',
        'birth_date': '2019-11-08',
        'sex': 'M',
        'weight_kg': 35.8,
        'notes':
            'Perro muy inteligente y leal. Excelente guardián. Entrenado en obediencia básica.',
        'owner_index': 2,
      },
      {
        'history_number': '4C17-000004',
        'name': 'Bella',
        'species_code': 'CAN',
        'breed_name': 'Golden Retriever',
        'birth_date': '2021-01-20',
        'sex': 'F',
        'weight_kg': 26.3,
        'notes':
            'Perra muy amigable y paciente. Ideal para familias con niños.',
        'owner_index': 3,
      },
      {
        'history_number': '4C17-000005',
        'name': 'Simba',
        'species_code': 'FEL',
        'breed_name': 'Siamés',
        'birth_date': '2020-09-12',
        'sex': 'M',
        'weight_kg': 5.1,
        'notes': 'Gato vocal y activo. Muy curioso y juguetón.',
        'owner_index': 4,
      },
    ];

    final createdPatients = <Map<String, dynamic>>[];

    for (final patientData in patientsData) {
      try {
        // Obtener ID de la raza
        final breedResult = await _supabase
            .from('breeds')
            .select('id')
            .eq('species_code', patientData['species_code'] as String)
            .eq('label', patientData['breed_name'] as String)
            .single();

        final patient = {
          'clinic_id': AppConfig.clinicId,
          'owner_id': owners[patientData['owner_index'] as int]['id'],
          'history_number': patientData['history_number'],
          'name': patientData['name'],
          'species_code': patientData['species_code'],
          'breed_id': breedResult['id'],
          'birth_date': patientData['birth_date'],
          'sex': patientData['sex'],
          'weight_kg': patientData['weight_kg'],
          'notes': patientData['notes'],
        };

        final result =
            await _supabase.from('patients').insert(patient).select().single();
        createdPatients.add(result);
        print(
            '✅ Paciente creado: ${patientData['name']} (${patientData['history_number']})');
      } catch (e) {
        print('⚠️ Error al crear paciente ${patientData['name']}: $e');
      }
    }

    return createdPatients;
  }

  /// Crea historias médicas de prueba
  Future<void> _createTestMedicalRecords(
      List<Map<String, dynamic>> patients) async {
    final recordsData = [
      {
        'patient_index': 0, // Max
        'title': 'Consulta de rutina y vacunación',
        'content': '''EXAMEN FÍSICO COMPLETO:

Constantes vitales:
- Temperatura: 38.5°C (normal)
- Frecuencia cardíaca: 90 lpm (normal)
- Frecuencia respiratoria: 22 rpm (normal)
- Peso: 28.5 kg

EXAMEN GENERAL:
- Estado general: Bueno
- Hidratación: Normal
- Mucosas: Rosa húmedas
- Ganglios: No palpables
- Estado nutricional: Óptimo

SISTEMAS:
- Cardiovascular: Sin alteraciones
- Respiratorio: Sin alteraciones
- Digestivo: Sin alteraciones
- Urológico: Sin alteraciones
- Neurológico: Sin alteraciones
- Musculoesquelético: Sin alteraciones

PLAN DE TRATAMIENTO:
- Vacuna antirrábica aplicada
- Desparasitación interna y externa
- Control en 6 meses para siguiente vacuna

RECOMENDACIONES:
- Mantener dieta balanceada
- Ejercicio diario moderado
- Control de peso mensual''',
        'doctor_name': 'Dr. Carlos Mendoza',
        'days_ago': 15,
      },
      {
        'patient_index': 1, // Luna
        'title': 'Consulta por problemas respiratorios',
        'content': '''MOTIVO DE CONSULTA:
La propietaria refiere que Luna presenta tos seca intermitente desde hace 3 días, especialmente después de comer o beber agua.

EXAMEN FÍSICO:
- Temperatura: 39.2°C (elevada)
- Frecuencia cardíaca: 140 lpm (elevada)
- Frecuencia respiratoria: 35 rpm (elevada)
- Peso: 4.2 kg

HALLAZGOS:
- Tos seca y persistente
- Ligero aumento de la frecuencia respiratoria
- No se observan secreciones nasales
- Apetito conservado

DIAGNÓSTICO PRESUNTIVO:
Traqueobronquitis infecciosa felina

PLAN DE TRATAMIENTO:
- Antibiótico: Amoxicilina 20mg/kg cada 12 horas x 7 días
- Antiinflamatorio: Meloxicam 0.1mg/kg cada 24 horas x 3 días
- Expectorante: Bromhexina 1ml cada 12 horas x 5 días

CONTROL:
Revisión en 5 días para evaluar evolución''',
        'doctor_name': 'Dra. Ana Herrera',
        'days_ago': 8,
      },
      {
        'patient_index': 2, // Rocky
        'title': 'Cirugía de esterilización',
        'content': '''PROCEDIMIENTO QUIRÚRGICO:
Orquiectomía bilateral realizada bajo anestesia general.

PRE-OPERATORIO:
- Ayuno de 12 horas
- Exámenes prequirúrgicos: normales
- Peso: 35.8 kg

TÉCNICA QUIRÚRGICA:
- Anestesia: Isoflurano
- Técnica: Orquiectomía bilateral estándar
- Tiempo quirúrgico: 45 minutos
- Complicaciones: Ninguna

POST-OPERATORIO:
- Recuperación anestésica: Sin complicaciones
- Analgesia: Meloxicam 0.1mg/kg cada 24 horas x 5 días
- Antibiótico: Cefalexina 25mg/kg cada 12 horas x 7 días
- Cuidados: Evitar ejercicio intenso por 10 días

EVOLUCIÓN:
Paciente evoluciona favorablemente. Suturas en buen estado.''',
        'doctor_name': 'Dr. Luis Fernández',
        'days_ago': 12,
      },
    ];

    for (final recordData in recordsData) {
      try {
        final patient = patients[recordData['patient_index'] as int];
        final recordDate = DateTime.now()
            .subtract(Duration(days: recordData['days_ago'] as int));

        final record = {
          'patient_id': patient['id'],
          'clinic_id': AppConfig.clinicId,
          'visit_date': recordDate.toIso8601String().substring(0, 10),
          'diagnosis': recordData['title'],
          'treatment': recordData['content'],
          'veterinarian': recordData['doctor_name'],
        };

        await _supabase.from('medical_records').insert(record);
        print(
            '✅ Historia médica creada: ${recordData['title']} para ${patient['name']}');
      } catch (e) {
        print('⚠️ Error al crear historia médica: $e');
      }
    }
  }

  /// Crea hospitalizaciones de prueba
  Future<void> _createTestHospitalizations(
      List<Map<String, dynamic>> patients) async {
    try {
      final luna = patients.firstWhere((p) => p['name'] == 'Luna');
      final recordDate = DateTime.now().subtract(const Duration(days: 2));

      final hospitalization = {
        'patient_id': luna['id'],
        'clinic_id': AppConfig.clinicId,
        'admission_date': recordDate.toIso8601String().substring(0, 10),
        'status': 'active',
        'priority': 'high',
        'room_number': 'Sala 1',
        'bed_number': 'Cama A',
        'diagnosis': 'Traqueobronquitis infecciosa felina',
        'treatment_plan': 'Antibiótico + Antiinflamatorio + Expectorante',
        'special_instructions':
            'Monitorear temperatura cada 4 horas. Mantener hidratación.',
        'assigned_vet': 'Dr. García',
      };

      final result = await _supabase
          .from('hospitalizations')
          .insert(hospitalization)
          .select()
          .single();
      print('✅ Hospitalización creada: Luna en Sala 1, Cama A');

      // Crear tratamientos para la hospitalización
      await _createTestTreatments(patients, result['id']);
    } catch (e) {
      print('⚠️ Error al crear hospitalización: $e');
    }
  }

  /// Crea tratamientos de prueba
  Future<void> _createTestTreatments(List<Map<String, dynamic>> patients,
      [String? hospitalizationId]) async {
    final treatmentsData = [
      {
        'patient_name': 'Luna',
        'medication_name': 'Amoxicilina',
        'dosage': '84mg (20mg/kg)',
        'route': 'oral',
        'frequency': 'cada 12 horas',
        'scheduled_date': DateTime.now(),
        'scheduled_time': '08:00:00',
        'status': 'completed',
        'notes': 'Primera dosis administrada correctamente',
      },
      {
        'patient_name': 'Luna',
        'medication_name': 'Meloxicam',
        'dosage': '0.42mg (0.1mg/kg)',
        'route': 'oral',
        'frequency': 'cada 24 horas',
        'scheduled_date': DateTime.now(),
        'scheduled_time': '08:30:00',
        'status': 'completed',
        'notes': 'Antiinflamatorio administrado con comida',
      },
      {
        'patient_name': 'Luna',
        'medication_name': 'Amoxicilina',
        'dosage': '84mg (20mg/kg)',
        'route': 'oral',
        'frequency': 'cada 12 horas',
        'scheduled_date': DateTime.now(),
        'scheduled_time': '20:00:00',
        'status': 'scheduled',
        'notes': 'Segunda dosis del día',
      },
    ];

    for (final treatmentData in treatmentsData) {
      try {
        final treatment = {
          'hospitalization_id': hospitalizationId,
          'medication_name': treatmentData['medication_name'],
          'dosage': treatmentData['dosage'],
          'route': treatmentData['route'],
          'frequency': treatmentData['frequency'],
          'scheduled_date': (treatmentData['scheduled_date'] as DateTime)
              .toIso8601String()
              .substring(0, 10),
          'scheduled_time': treatmentData['scheduled_time'],
          'status': treatmentData['status'],
          'completion_notes': treatmentData['notes'],
        };

        if (treatmentData['status'] == 'completed') {
          treatment['completed_at'] = DateTime.now().toUtc().toIso8601String();
        }

        await _supabase.from('follows').insert(treatment);
        print(
            '✅ Tratamiento creado: ${treatmentData['medication_name']} para ${treatmentData['patient_name']}');
      } catch (e) {
        print('⚠️ Error al crear tratamiento: $e');
      }
    }
  }

  /// Crea notas de prueba
  Future<void> _createTestNotes(List<Map<String, dynamic>> patients) async {
    try {
      final luna = patients.firstWhere((p) => p['name'] == 'Luna');
      final hospitalization = await _supabase
          .from('hospitalizations')
          .select('id')
          .eq('patient_id', luna['id'])
          .single();

      final notesData = [
        {
          'hospitalization_id': hospitalization['id'],
          'content':
              'Temperatura: 38.8°C (mejoría). Apetito normal. Tos menos frecuente.',
          'note_type': 'vital_signs',
          'is_important': false,
        },
        {
          'hospitalization_id': hospitalization['id'],
          'content':
              'IMPORTANTE: Continuar con el tratamiento antibiótico completo. No suspender aunque mejoren los síntomas.',
          'note_type': 'general',
          'is_important': true,
        },
      ];

      for (final noteData in notesData) {
        await _supabase.from('notes').insert(noteData);
        print('✅ Nota creada: ${noteData['note_type']}');
      }
    } catch (e) {
      print('⚠️ Error al crear notas: $e');
    }
  }

  /// Limpia todos los datos de prueba
  Future<void> clearAllTestData() async {
    try {
      print('🧹 Limpiando todos los datos de prueba...');

      // Eliminar en orden inverso debido a las foreign keys
      await _supabase.from('notes').delete().neq('id', '');
      print('✅ Notas eliminadas');

      await _supabase.from('follows').delete().neq('id', '');
      print('✅ Tratamientos eliminados');

      await _supabase.from('hospitalizations').delete().neq('id', '');
      print('✅ Hospitalizaciones eliminadas');

      await _supabase.from('medical_records').delete().neq('id', '');
      print('✅ Historias médicas eliminadas');

      await _supabase.from('patients').delete().neq('id', '');
      print('✅ Pacientes eliminados');

      await _supabase.from('owners').delete().neq('id', '');
      print('✅ Propietarios eliminados');

      print('🎉 Todos los datos de prueba eliminados');
    } catch (e) {
      print('❌ Error al limpiar datos: $e');
      rethrow;
    }
  }
}
