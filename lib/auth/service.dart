// lib/auth/service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config.dart';
import '../features/data/repository.dart';

class SupabaseService {
  /// Último error de inicialización/ping (para mostrarlo en UI)
  static Object? lastInitError;
  static StackTrace? lastInitStack;

  static bool _initialized = false;

  /// Inicializa Supabase con credenciales directas
  static Future<void> init({bool forceReinit = false}) async {
    if (_initialized && !forceReinit) return;

    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
        // debug: true, // opcional para verbose logs
      );

      _initialized = true;
      lastInitError = null;
      lastInitStack = null;
    } catch (e, stack) {
      lastInitError = e;
      lastInitStack = stack;
      rethrow;
    }
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

class StorageIndexer {
  /// Busca objetos en system_files/<clinicId>/inbox y crea filas en `documents`
  /// si no existen. Úsalo para "enganchar" archivos que se subieron directo al bucket.
  static Future<int> indexSystemInbox({
    required String clinicId,
    int limit = 200,
  }) async {
    return await Repository.indexSystemInbox(
      clinicId: clinicId,
      pageLimit: limit,
    );
  }
}
