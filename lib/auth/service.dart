// lib/auth/service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseService {
  /// Último error de inicialización/ping (para mostrarlo en UI)
  static Object? lastInitError;
  static StackTrace? lastInitStack;

  static bool _initialized = false;

  /// Inicializa Supabase usando variables del .env
  static Future<void> init({bool forceReinit = false}) async {
    if (_initialized && !forceReinit) return;

    final url = dotenv.env['SUPABASE_URL'];
    final key = dotenv.env['SUPABASE_ANON_KEY'];

    if (url == null || key == null) {
      throw Exception('Faltan SUPABASE_URL o SUPABASE_ANON_KEY en .env');
    }

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
