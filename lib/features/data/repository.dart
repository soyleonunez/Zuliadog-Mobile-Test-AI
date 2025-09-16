// lib/features/data/repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'buscador.dart';

/// Repositorio principal para operaciones de base de datos
class DataRepository {
  final SupabaseClient _db = Supabase.instance.client;

  /// Busca pacientes por múltiples criterios
  Future<List<PatientSearchRow>> searchPatients(String query,
      {int limit = 30}) async {
    final q = query.trim();
    final isNumeric = int.tryParse(q.replaceAll(RegExp(r'\D'), '')) != null;

    final baseSel = _db.from('patients_search').select(
      '''
      patient_id, clinic_id, patient_name, history_number, mrn_int,
      owner_name, owner_phone, owner_email, species_label, breed_label, sex
      ''',
    );

    if (q.isEmpty) {
      // Lista inicial: algunos pacientes ordenados por nombre
      final rows =
          await baseSel.order('patient_name', ascending: true).limit(limit);
      return rows.map((e) => PatientSearchRow.fromJson(e)).toList();
    }

    // Búsqueda con OR compuesto
    final ors = <String>[
      "patient_name.ilike.%$q%",
      "owner_name.ilike.%$q%",
      "history_number.eq.$q",
      if (isNumeric)
        "mrn_int.eq.${int.parse(q.replaceAll(RegExp(r'\\D'), ''))}",
    ];

    final rows = await baseSel
        .or(ors.join(','))
        .order('mrn_int', ascending: true, nullsFirst: true)
        .limit(limit);

    return rows.map((e) => PatientSearchRow.fromJson(e)).toList();
  }

  /// Obtiene estadísticas del dashboard
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      // Aquí puedes agregar consultas para estadísticas
      // Por ejemplo: pacientes atendidos hoy, pendientes, etc.
      return {
        'attended_today': 18,
        'pending': 7,
        'notes': 3,
      };
    } catch (e) {
      print('Error obteniendo estadísticas: $e');
      return {
        'attended_today': 0,
        'pending': 0,
        'notes': 0,
      };
    }
  }

  /// Obtiene actividades recientes
  Future<List<Map<String, dynamic>>> getRecentActivities(
      {int limit = 8}) async {
    try {
      // Aquí puedes agregar consultas para actividades recientes
      // Por ahora retornamos datos mock
      return List.generate(
          limit,
          (i) => {
                'id': i,
                'type': [
                  'patient_added',
                  'appointment_created',
                  'document_uploaded',
                  'ticket_opened'
                ][i % 4],
                'description': [
                  'Alta de paciente: Max (Canino)',
                  'Cita creada para Luna',
                  'Documento subido: RX_1234.pdf',
                  'Ticket abierto para Simba',
                ][i % 4],
                'status': ['completed', 'pending', 'in_progress'][i % 3],
                'time': 'Hoy 10:${(i + 1).toString().padLeft(2, '0')}',
              });
    } catch (e) {
      print('Error obteniendo actividades: $e');
      return [];
    }
  }

  /// Obtiene tareas del día
  Future<List<Map<String, dynamic>>> getTodayTasks() async {
    try {
      // Aquí puedes agregar consultas para tareas
      return [
        {'title': 'Llamar al dueño de Luna', 'time': '10:30', 'done': false},
        {'title': 'Revisar análisis de Max', 'time': '11:15', 'done': true},
        {'title': 'Confirmar cita de Simba', 'time': '14:00', 'done': false},
        {'title': 'Subir RX Bella', 'time': '15:20', 'done': false},
        {'title': 'Receta para Coco', 'time': '17:00', 'done': false},
      ];
    } catch (e) {
      print('Error obteniendo tareas: $e');
      return [];
    }
  }
}
