// lib/auth/service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  /// Último error de inicialización/ping (para mostrarlo en UI)
  static Object? lastInitError;
  static StackTrace? lastInitStack;

  static bool _initialized = false;

  /// Inicializa Supabase con credenciales directas
  static Future<void> init({bool forceReinit = false}) async {
    if (_initialized && !forceReinit) return;

    // Credenciales directas (más simple y confiable)
    const url = 'https://oeqemxsjnpuclkmllacx.supabase.co';
    const key =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9lcWVteHNqbnB1Y2xrbWxsYWN4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgwMjkyMDgsImV4cCI6MjA3MzYwNTIwOH0.kD88szLnjuK51nDn3u6_wg0ej-HGe6MV2TwF24lxcfs';

    await Supabase.initialize(
      url: url,
      anonKey: key,
      // debug: true, // opcional para verbose logs
    );

    _initialized = true;
  }

  static SupabaseClient get client => Supabase.instance.client;

  /// Valida conectividad/ACL haciendo selects livianos.
  /// Pasa aquí los nombres de tus tablas; si no quieres comprobar nada, déjalo vacío.
  static Future<void> ping({List<String> tablesToCheck = const []}) async {
    // Si no pasas tablas, no hacemos nada (evita errores por schemas desconocidos)
    if (tablesToCheck.isEmpty) return;

    for (final t in tablesToCheck) {
      // Ajusta la columna a una que exista (id, uuid, etc.)
      await client.from(t).select('id').limit(1);
    }
  }
}
