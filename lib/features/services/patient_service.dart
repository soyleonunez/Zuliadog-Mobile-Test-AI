import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio para la gestión de pacientes
class PatientService {
  static const String _tablePatients = 'patients';

  final SupabaseClient _supa = Supabase.instance.client;

  /// Obtiene el resumen de un paciente por ID o MRN
  Future<PatientSummary?> getPatientSummary(String patientIdOrMrn) async {
    try {
      print('🔍 Buscando paciente: $patientIdOrMrn');

      final row = await _supa
          .from(_tablePatients)
          .select()
          .or('id.eq.$patientIdOrMrn,mrn.eq.$patientIdOrMrn')
          .maybeSingle();

      print('📊 Resultado paciente: $row');

      if (row == null) {
        print('❌ No se encontró paciente');
        return _generateSamplePatient(patientIdOrMrn);
      }

      return PatientSummary(
        id: row['id'] as String,
        name: row['name'] as String? ?? 'Sin nombre',
        species: row['species'] as String? ?? 'No especificado',
        breed: row['breed'] as String? ?? 'No especificado',
        sex: row['sex'] as String? ?? 'No especificado',
        ownerLastname: row['owner_lastname'] as String? ?? 'Sin dueño',
        ageLabel: _calculateAgeLabel(row['birth_date'] as String?),
        temperature: (row['temperature'] as num?)?.toDouble() ?? 38.0,
        respiration: (row['respiration'] as num?)?.toInt() ?? 20,
        pulse: (row['pulse'] as num?)?.toInt() ?? 80,
        hydration: row['hydration'] as String? ?? 'Normal',
      );
    } catch (e) {
      print('❌ Error al obtener paciente: $e');
      return _generateSamplePatient(patientIdOrMrn);
    }
  }

  /// Calcula la etiqueta de edad basada en la fecha de nacimiento
  String _calculateAgeLabel(String? birthDate) {
    if (birthDate == null) return 'No especificado';

    try {
      final birth = DateTime.parse(birthDate);
      final now = DateTime.now();
      final ageInYears = now.difference(birth).inDays / 365;

      if (ageInYears < 1) {
        final ageInMonths = (ageInYears * 12).round();
        return '$ageInMonths meses';
      } else {
        return '${ageInYears.round()} años';
      }
    } catch (e) {
      return 'No especificado';
    }
  }

  /// Genera un paciente de muestra para demostración
  PatientSummary _generateSamplePatient(String patientIdOrMrn) {
    final names = [
      'Max',
      'Luna',
      'Bella',
      'Rocky',
      'Mia',
      'Charlie',
      'Lola',
      'Zeus'
    ];
    final species = ['Canino', 'Felino', 'Ave', 'Reptil'];
    final breeds = [
      'Labrador',
      'Golden Retriever',
      'Pastor Alemán',
      'Persa',
      'Siamés',
      'Canario',
      'Iguana'
    ];
    final sexes = ['Macho', 'Hembra'];
    final owners = [
      'María García',
      'Carlos López',
      'Ana Martínez',
      'Pedro Rodríguez',
      'Laura Sánchez'
    ];

    final nameIndex = patientIdOrMrn.hashCode % names.length;
    final speciesIndex = patientIdOrMrn.hashCode % species.length;
    final breedIndex = patientIdOrMrn.hashCode % breeds.length;
    final sexIndex = patientIdOrMrn.hashCode % sexes.length;
    final ownerIndex = patientIdOrMrn.hashCode % owners.length;

    return PatientSummary(
      id: patientIdOrMrn,
      name: names[nameIndex],
      species: species[speciesIndex],
      breed: breeds[breedIndex],
      sex: sexes[sexIndex],
      ownerLastname: owners[ownerIndex],
      ageLabel: '${(patientIdOrMrn.hashCode % 10) + 1} años',
      temperature: 38.0 + (patientIdOrMrn.hashCode % 10) * 0.1,
      respiration: 15 + (patientIdOrMrn.hashCode % 10),
      pulse: 70 + (patientIdOrMrn.hashCode % 20),
      hydration: 'Normal',
    );
  }
}

/// Modelo para el resumen de un paciente
class PatientSummary {
  final String id;
  final String name;
  final String species;
  final String breed;
  final String sex;
  final String ownerLastname;
  final String ageLabel;
  final double temperature;
  final int respiration;
  final int pulse;
  final String hydration;

  PatientSummary({
    required this.id,
    required this.name,
    required this.species,
    required this.breed,
    required this.sex,
    required this.ownerLastname,
    required this.ageLabel,
    required this.temperature,
    required this.respiration,
    required this.pulse,
    required this.hydration,
  });
}
