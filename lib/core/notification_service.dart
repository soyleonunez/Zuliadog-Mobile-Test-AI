import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _supa = Supabase.instance.client;

class NotificationItem {
  final String id;
  final String title;
  final String description;
  final NotificationType type;
  final NotificationPriority priority;
  final DateTime scheduledTime;
  final String? patientId;
  final String? hospitalizationId;
  final Map<String, dynamic>? metadata;

  NotificationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    required this.scheduledTime,
    this.patientId,
    this.hospitalizationId,
    this.metadata,
  });

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: NotificationType.fromString(map['task_type'] ?? 'medication'),
      priority: NotificationPriority.fromString(map['priority'] ?? 'normal'),
      scheduledTime: DateTime.parse(
          map['scheduled_time'] ?? DateTime.now().toIso8601String()),
      patientId: map['patient_id'],
      hospitalizationId: map['hospitalization_id'],
      metadata: map,
    );
  }
}

enum NotificationType {
  medication,
  feeding,
  exercise,
  monitoring,
  treatment,
  examination,
  vaccination,
  surgery,
  consultation,
  followUp,
  labTest,
  imaging,
  therapy,
  grooming,
  boarding;

  static NotificationType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'medication':
        return NotificationType.medication;
      case 'feeding':
        return NotificationType.feeding;
      case 'exercise':
        return NotificationType.exercise;
      case 'monitoring':
        return NotificationType.monitoring;
      case 'treatment':
        return NotificationType.treatment;
      case 'examination':
        return NotificationType.examination;
      case 'vaccination':
        return NotificationType.vaccination;
      case 'surgery':
        return NotificationType.surgery;
      case 'consultation':
        return NotificationType.consultation;
      case 'follow_up':
        return NotificationType.followUp;
      case 'lab_test':
        return NotificationType.labTest;
      case 'imaging':
        return NotificationType.imaging;
      case 'therapy':
        return NotificationType.therapy;
      case 'grooming':
        return NotificationType.grooming;
      case 'boarding':
        return NotificationType.boarding;
      default:
        return NotificationType.medication;
    }
  }

  String get displayName {
    switch (this) {
      case NotificationType.medication:
        return 'Medicamento';
      case NotificationType.feeding:
        return 'Alimentación';
      case NotificationType.exercise:
        return 'Ejercicio';
      case NotificationType.monitoring:
        return 'Monitoreo';
      case NotificationType.treatment:
        return 'Tratamiento';
      case NotificationType.examination:
        return 'Examen';
      case NotificationType.vaccination:
        return 'Vacunación';
      case NotificationType.surgery:
        return 'Cirugía';
      case NotificationType.consultation:
        return 'Consulta';
      case NotificationType.followUp:
        return 'Seguimiento';
      case NotificationType.labTest:
        return 'Laboratorio';
      case NotificationType.imaging:
        return 'Imagenología';
      case NotificationType.therapy:
        return 'Terapia';
      case NotificationType.grooming:
        return 'Aseo';
      case NotificationType.boarding:
        return 'Hospedaje';
    }
  }
}

enum NotificationPriority {
  low,
  normal,
  high,
  urgent;

  static NotificationPriority fromString(String value) {
    switch (value.toLowerCase()) {
      case 'low':
        return NotificationPriority.low;
      case 'normal':
        return NotificationPriority.normal;
      case 'high':
        return NotificationPriority.high;
      case 'urgent':
        return NotificationPriority.urgent;
      default:
        return NotificationPriority.normal;
    }
  }

  String get displayName {
    switch (this) {
      case NotificationPriority.low:
        return 'Baja';
      case NotificationPriority.normal:
        return 'Normal';
      case NotificationPriority.high:
        return 'Alta';
      case NotificationPriority.urgent:
        return 'Urgente';
    }
  }
}

class NotificationService {
  static Future<List<NotificationItem>> getNotifications() async {
    try {
      final response = await _supa
          .from('treatments')
          .select('*')
          .eq('status', 'pending')
          .order('scheduled_time', ascending: true)
          .limit(20);

      return (response as List)
          .map((item) => NotificationItem.fromMap(item))
          .toList();
    } catch (e) {
      print('Error obteniendo notificaciones: $e');
      return [];
    }
  }

  static Future<void> markAsRead(String notificationId) async {
    try {
      await _supa
          .from('treatments')
          .update({'status': 'completed'}).eq('id', notificationId);
    } catch (e) {
      print('Error marcando notificación como leída: $e');
    }
  }

  static Future<void> markAsCompleted(String notificationId) async {
    try {
      await _supa.from('treatments').update({
        'status': 'completed',
        'completed_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', notificationId);
    } catch (e) {
      print('Error completando notificación: $e');
    }
  }

  static void handleNotificationAction(
      NotificationItem notification, BuildContext context) {
    // Navegar a la sección específica basada en el tipo de notificación
    switch (notification.type) {
      case NotificationType.medication:
      case NotificationType.treatment:
        // Navegar a la sección de tratamientos
        Navigator.pushNamed(context, '/hospitalizacion');
        break;
      case NotificationType.examination:
      case NotificationType.consultation:
        // Navegar a la sección de historias médicas
        Navigator.pushNamed(context, '/historias');
        break;
      case NotificationType.labTest:
        // Navegar a la sección de laboratorio
        Navigator.pushNamed(context, '/laboratorio');
        break;
      case NotificationType.vaccination:
        // Navegar a la sección de vacunaciones
        Navigator.pushNamed(context, '/vacunaciones');
        break;
      default:
        // Navegar a la sección principal
        Navigator.pushNamed(context, '/home');
        break;
    }
  }

  static void showSuccess(String message) {
    // Implementar notificación de éxito
    print('Success: $message');
  }

  static void showError(String message) {
    // Implementar notificación de error
    print('Error: $message');
  }
}
