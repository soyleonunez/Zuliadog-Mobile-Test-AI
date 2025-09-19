import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio para la gestión del timeline de cambios
class TimelineService {
  static const String _tableRecords = 'medical_records';
  static const String _tableAttachments = 'record_attachments';

  final SupabaseClient _supa = Supabase.instance.client;

  /// Obtiene el timeline de cambios para un paciente
  Future<List<TimelineEvent>> getTimeline(String patientId) async {
    try {
      print('🔍 Construyendo timeline para patientId: $patientId');

      final recs = await _supa
          .from(_tableRecords)
          .select('id, created_at, updated_at, locked, created_by')
          .eq('patient_id', patientId)
          .order('created_at', ascending: true);

      if (recs.isEmpty) {
        print('🧪 Generando timeline de prueba para demostración...');
        return _generateSampleTimeline(patientId);
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
      return _generateSampleTimeline(patientId);
    }
  }

  /// Obtiene los adjuntos para un paciente
  Future<List<AttachmentTimeline>> _getAttachmentsForPatient(
      String patientId) async {
    try {
      final rows = await _supa
          .from(_tableAttachments)
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
          .from(_tableRecords)
          .select('id')
          .eq('patient_id', patientId);

      return rows.map((row) => row['id'] as String).toList();
    } catch (e) {
      print('❌ Error al obtener IDs de registros: $e');
      return [];
    }
  }

  /// Genera un timeline de muestra para demostración
  List<TimelineEvent> _generateSampleTimeline(String patientId) {
    return [
      TimelineEvent(
        at: DateTime.now(),
        title: 'Primer bloque de historia creado',
        dotColor: const Color(0xFF4F46E5),
      ),
    ];
  }
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
