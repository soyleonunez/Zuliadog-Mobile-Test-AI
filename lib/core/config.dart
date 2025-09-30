// lib/core/config.dart
import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuración centralizada de la aplicación - NUEVO ESQUEMA UNIFICADO
class AppConfig {
  /// ID de la clínica actual (ya configurado en el nuevo esquema)
  static const String clinicId = '4c17fddf-24ab-4a8d-9343-4cc4f6a4a203';

  /// Nombre amigable de la clínica para rutas de storage (más seguro)
  static const String clinicName = 'Zuliadog';

  /// URL de Supabase
  static const String supabaseUrl = 'https://ehmgsqdfzbeaqhswswyx.supabase.co';

  /// Clave anónima de Supabase
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVobWdzcWRmemJlYXFoc3dzd3l4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkwODQ2OTQsImV4cCI6MjA3NDY2MDY5NH0.xjw4o7yBZ5gx2pL0BYx_usmUISsLLPHaA6EThFurfIU';

  /// Configuración de buckets de Supabase Storage
  static const Map<String, String> storageBuckets = {
    'profiles': 'profiles',
    'patients': 'patients',
    'medical_records': 'medical_records',
    'billing_docs': 'billing_docs',
    'system_files': 'system_files',
    'lab_results': 'lab_results',
  };

  // =====================================================
  // CONFIGURACIÓN DEL NUEVO ESQUEMA
  // =====================================================

  /// Nombres de tablas del nuevo esquema
  static const Map<String, String> tableNames = {
    'users': 'users',
    'clinics': 'clinics',
    'user_clinic_roles': 'user_clinic_roles',
    'species': 'species',
    'breeds': 'breeds',
    'owners': 'owners',
    'patients': 'patients',
    'medical_records': 'medical_records',
    'hospitalizations': 'hospitalizations',
    'treatments': 'treatments',
    'notes': 'notes',
  };

  /// Roles de usuario
  static const Map<String, String> userRoles = {
    'admin': 'admin',
    'veterinarian': 'veterinarian',
    'assistant': 'assistant',
  };

  /// Códigos de especies
  static const Map<String, String> speciesCodes = {
    'CAN': 'Canino',
    'FEL': 'Felino',
    'AVE': 'Ave',
    'EQU': 'Equino',
    'EXO': 'Exótico',
  };

  /// Estados de hospitalización
  static const Map<String, String> hospitalizationStatus = {
    'active': 'Activa',
    'discharged': 'Dada de alta',
    'cancelled': 'Cancelada',
  };

  /// Estados de tratamiento
  static const Map<String, String> treatmentStatus = {
    'scheduled': 'Programado',
    'completed': 'Completado',
    'cancelled': 'Cancelado',
  };

  /// Niveles de prioridad
  static const Map<String, String> priorityLevels = {
    'low': 'Baja',
    'normal': 'Normal',
    'high': 'Alta',
    'urgent': 'Urgente',
  };

  // =====================================================
  // MÉTODOS DE INICIALIZACIÓN
  // =====================================================

  /// Inicializar Supabase
  static Future<void> initializeSupabase() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: true,
    );
  }

  /// Obtener cliente de Supabase
  static SupabaseClient get supabase => Supabase.instance.client;

  /// Verificar si Supabase está inicializado
  static bool get isInitialized {
    try {
      Supabase.instance.client;
      return true;
    } catch (e) {
      return false;
    }
  }

  // =====================================================
  // MÉTODOS DE UTILIDAD
  // =====================================================

  /// Obtener nombre de tabla
  static String getTableName(String key) => tableNames[key] ?? key;

  /// Obtener nombre de rol
  static String getRoleName(String role) => userRoles[role] ?? role;

  /// Obtener nombre de especie
  static String getSpeciesName(String code) => speciesCodes[code] ?? code;

  /// Obtener nombre de estado de hospitalización
  static String getHospitalizationStatusName(String status) =>
      hospitalizationStatus[status] ?? status;

  /// Obtener nombre de estado de tratamiento
  static String getTreatmentStatusName(String status) =>
      treatmentStatus[status] ?? status;

  /// Obtener nombre de prioridad
  static String getPriorityName(String priority) =>
      priorityLevels[priority] ?? priority;
}
