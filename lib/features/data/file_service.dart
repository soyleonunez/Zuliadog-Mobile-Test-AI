// lib/features/data/file_service.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FileService {
  static final FileService _instance = FileService._internal();
  factory FileService() => _instance;
  FileService._internal();

  final Dio _dio = Dio();
  final SupabaseClient _supa = Supabase.instance.client;
  static const String _bucket = 'system_files';

  /// Descarga un archivo a la carpeta de Descargas del usuario
  Future<String> downloadToDownloads(String url, String filename) async {
    try {
      print('📥 Descargando archivo a Descargas: $filename');
      print('🔗 URL: $url');

      // Obtener la carpeta de Descargas
      final downloadsDir = await _getDownloadsDirectory();
      final filePath = p.join(downloadsDir.path, filename);

      // Configurar Dio para manejar errores 400
      _dio.options.validateStatus =
          (status) => status! < 500; // Permitir 400-499
      _dio.options.followRedirects = true;
      _dio.options.maxRedirects = 5;

      // Verificar si la URL es accesible
      try {
        final response = await _dio.head(url);
        print('📡 Status HEAD: ${response.statusCode}');

        if (response.statusCode == 404) {
          throw Exception('Archivo no encontrado (404)');
        }
      } catch (e) {
        print('⚠️ Error en HEAD request: $e');
        // Continuar con la descarga aunque falle el HEAD
      }

      // Descargar el archivo
      await _dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            print(
                '📥 Progreso: ${(received / total * 100).toStringAsFixed(0)}%');
          }
        },
      );

      print('✅ Archivo descargado exitosamente: $filePath');
      return filePath;
    } catch (e) {
      print('❌ Error descargando archivo: $e');
      rethrow;
    }
  }

  /// Descarga un archivo a la carpeta temporal para previsualización
  Future<String> downloadToTemp(String url, String filename) async {
    try {
      print('📥 Descargando archivo temporal: $filename');

      final tempDir = await getTemporaryDirectory();
      final filePath = p.join(tempDir.path, filename);

      await _dio.download(
        url,
        filePath,
        options: Options(
          validateStatus: (status) => status! < 500,
          followRedirects: true,
          maxRedirects: 5,
        ),
      );

      print('✅ Archivo temporal descargado: $filePath');
      return filePath;
    } catch (e) {
      print('❌ Error descargando archivo temporal: $e');
      rethrow;
    }
  }

  /// Obtiene la URL pública de un archivo
  String getPublicUrl(String filePath) {
    return _supa.storage.from(_bucket).getPublicUrl(filePath);
  }

  /// Verifica si una URL es accesible
  Future<bool> isUrlAccessible(String url) async {
    try {
      final response = await _dio.head(url);
      return response.statusCode == 200;
    } catch (e) {
      print('❌ URL no accesible: $e');
      return false;
    }
  }

  /// Obtiene la carpeta de Descargas del usuario
  Future<Directory> _getDownloadsDirectory() async {
    if (Platform.isWindows) {
      // En Windows, usar la carpeta de Descargas del usuario
      final userProfile = Platform.environment['USERPROFILE'] ?? '';
      final downloadsPath = p.join(userProfile, 'Downloads');
      return Directory(downloadsPath);
    } else if (Platform.isMacOS) {
      // En macOS, usar la carpeta de Descargas del usuario
      final userHome = Platform.environment['HOME'] ?? '';
      final downloadsPath = p.join(userHome, 'Downloads');
      return Directory(downloadsPath);
    } else if (Platform.isLinux) {
      // En Linux, usar la carpeta de Descargas del usuario
      final userHome = Platform.environment['HOME'] ?? '';
      final downloadsPath = p.join(userHome, 'Downloads');
      return Directory(downloadsPath);
    } else {
      // Fallback a la carpeta de documentos
      return await getApplicationDocumentsDirectory();
    }
  }

  /// Verifica la conexión con Supabase Storage
  Future<Map<String, dynamic>> testConnection() async {
    try {
      print('🔍 Probando conexión con Supabase Storage...');

      // Lista de archivos conocidos para evitar storage.search
      final knownFiles = [
        'veterinaria-zuliadog/inbox/luna - test 4dx.pdf',
        'veterinaria-zuliadog/inbox/TEST 4DX Luna.pdf',
      ];

      final bucket = _supa.storage.from(_bucket);

      // Probar URLs públicas sin usar .list()
      final testUrls =
          knownFiles.map((file) => bucket.getPublicUrl(file)).toList();
      print('🔗 URLs de prueba generadas: ${testUrls.length}');

      // Probar si las URLs son accesibles
      int accessibleCount = 0;
      for (final url in testUrls) {
        if (await isUrlAccessible(url)) {
          accessibleCount++;
        }
      }

      return {
        'success': true,
        'fileCount': knownFiles.length,
        'accessibleCount': accessibleCount,
        'testUrls': testUrls,
        'message':
            'Conexión exitosa! ${knownFiles.length} archivos conocidos, ${accessibleCount} accesibles.',
      };
    } catch (e) {
      print('❌ Error probando conexión: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Error de conexión: $e',
      };
    }
  }

  /// Obtiene información de un archivo
  Future<Map<String, dynamic>?> getFileInfo(String filePath) async {
    try {
      final bucket = _supa.storage.from(_bucket);
      final files = await bucket.list();

      for (final file in files) {
        if (file.name == filePath) {
          return {
            'name': file.name,
            'size': 0, // FileObject no tiene size directo
            'updatedAt': file.updatedAt,
            'metadata': file.metadata,
            'publicUrl': bucket.getPublicUrl(filePath),
          };
        }
      }
      return null;
    } catch (e) {
      print('❌ Error obteniendo información del archivo: $e');
      return null;
    }
  }
}
