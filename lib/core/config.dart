// lib/core/config.dart
/// Configuración centralizada de la aplicación
class AppConfig {
  /// ID de la clínica actual
  /// TODO: Reemplazar con el UUID real de tu clínica
  static const String clinicId = '4c17fddf-24ab-4a8d-9343-4cc4f6a4a203';

  /// Nombre amigable de la clínica para rutas de storage (más seguro)
  static const String clinicName = 'veterinaria-zuliadog';

  /// URL de Supabase
  static const String supabaseUrl = 'https://oeqemxsjnpuclkmllacx.supabase.co';

  /// Clave anónima de Supabase
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9lcWVteHNqbnB1Y2xrbWxsYWN4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgwMjkyMDgsImV4cCI6MjA3MzYwNTIwOH0.kD88szLnjuK51nDn3u6_wg0ej-HGe6MV2TwF24lxcfs';

  /// Configuración de buckets de Supabase Storage
  static const Map<String, String> storageBuckets = {
    'profiles': 'profiles',
    'patients': 'patients',
    'medical_records': 'medical_records',
    'billing_docs': 'billing_docs',
    'system_files': 'system_files',
  };
}
