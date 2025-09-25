import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio unificado para manejo de datos, archivos e imágenes
class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  final Dio _dio = Dio();
  final SupabaseClient _supa = Supabase.instance.client;
  static const String _fileBucket = 'system_files';

  // ============================================================================
  // MÉTODOS DE ARCHIVOS (del FileService original)
  // ============================================================================

  /// Descarga un archivo a la carpeta de Descargas del usuario
  Future<String> downloadToDownloads(String url, String filename) async {
    try {
      
      

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
        

        if (response.statusCode == 404) {
          throw Exception('Archivo no encontrado (404)');
        }
      } catch (e) {
        
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

      
      return filePath;
    } catch (e) {
      
      rethrow;
    }
  }

  /// Descarga un archivo a la carpeta temporal para previsualización
  Future<String> downloadToTemp(String url, String filename) async {
    try {
      

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

      
      return filePath;
    } catch (e) {
      
      rethrow;
    }
  }

  /// Obtiene la URL pública de un archivo
  String getFilePublicUrl(String filePath) {
    return _supa.storage.from(_fileBucket).getPublicUrl(filePath);
  }

  /// Verifica si una URL es accesible
  Future<bool> isUrlAccessible(String url) async {
    try {
      final response = await _dio.head(url);
      return response.statusCode == 200;
    } catch (e) {
      
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
  Future<Map<String, dynamic>> testFileConnection() async {
    try {
      

      // Lista de archivos conocidos para evitar storage.search
      final knownFiles = [
        'veterinaria-zuliadog/inbox/luna - test 4dx.pdf',
        'veterinaria-zuliadog/inbox/TEST 4DX Luna.pdf',
      ];

      final bucket = _supa.storage.from(_fileBucket);

      // Probar URLs públicas sin usar .list()
      final testUrls =
          knownFiles.map((file) => bucket.getPublicUrl(file)).toList();
      

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
      final bucket = _supa.storage.from(_fileBucket);
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
      
      return null;
    }
  }

  // ============================================================================
  // MÉTODOS DE IMÁGENES DE RAZAS (del BreedImageService original)
  // ============================================================================

  /// Obtiene la URL de la imagen de una raza específica
  ///
  /// [breedId] - ID de la raza en la tabla breeds
  ///
  /// Retorna la URL de la imagen si existe, o null si no se encuentra
  Future<String?> getBreedImageUrl(String breedId) async {
    try {
      final row = await _supa
          .from('breeds')
          .select('image_bucket, image_key, image_url')
          .eq('id', breedId)
          .single();

      // Si ya hay una URL cacheada, usarla
      final cached = row['image_url'] as String?;
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }

      // Si no hay URL cacheada, construirla desde bucket y key
      final bucket = row['image_bucket'] as String?;
      final key = row['image_key'] as String?;

      if (bucket == null || key == null) {
        return null;
      }

      // El bucket de imágenes es público, generar URL pública inmediata
      return _supa.storage.from(bucket).getPublicUrl(key);
    } catch (e) {
      
      return null;
    }
  }

  /// Obtiene la URL de imagen de fallback basada en la especie
  ///
  /// [species] - Especie del animal (Canino, Felino, etc.)
  ///
  /// Retorna la ruta del asset de fallback
  String getSpeciesFallbackImage(String? species) {
    if (species == null) return 'Assets/Images/Other icon.png';

    switch (species.toLowerCase()) {
      case 'canino':
      case 'perro':
      case 'dog':
        return 'Assets/Icon/Dog.png';
      case 'felino':
      case 'gato':
      case 'cat':
        return 'Assets/Icon/Cat.png';
      case 'ave':
      case 'pájaro':
      case 'bird':
        return 'Assets/Images/Other icon.png';
      case 'reptil':
      case 'reptile':
        return 'Assets/Images/Other icon.png';
      default:
        return 'Assets/Images/Other icon.png';
    }
  }

  /// Widget helper para mostrar imagen de raza con fallback
  ///
  /// [breedId] - ID de la raza
  /// [species] - Especie para fallback
  /// [width] - Ancho del widget
  /// [height] - Alto del widget
  /// [borderRadius] - Radio de borde
  Widget buildBreedImageWidget({
    required String? breedId,
    required String? species,
    double width = 36,
    double height = 36,
    double borderRadius = 12,
  }) {
    if (breedId == null || breedId.isEmpty) {
      return _buildFallbackImage(
        species: species,
        width: width,
        height: height,
        borderRadius: borderRadius,
      );
    }

    return FutureBuilder<String?>(
      future: getBreedImageUrl(breedId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingWidget(
              width: width, height: height, borderRadius: borderRadius);
        }

        final imageUrl = snapshot.data;
        if (imageUrl != null && imageUrl.isNotEmpty) {
          return _buildNetworkImage(
            imageUrl: imageUrl,
            width: width,
            height: height,
            borderRadius: borderRadius,
            fallbackSpecies: species,
          );
        }

        return _buildFallbackImage(
          species: species,
          width: width,
          height: height,
          borderRadius: borderRadius,
        );
      },
    );
  }

  // ============================================================================
  // MÉTODOS PRIVADOS PARA IMÁGENES
  // ============================================================================

  Widget _buildNetworkImage({
    required String imageUrl,
    required double width,
    required double height,
    required double borderRadius,
    String? fallbackSpecies,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.network(
          imageUrl,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackImage(
              species: fallbackSpecies,
              width: width,
              height: height,
              borderRadius: borderRadius,
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildLoadingWidget(
              width: width,
              height: height,
              borderRadius: borderRadius,
            );
          },
        ),
      ),
    );
  }

  Widget _buildFallbackImage({
    required String? species,
    required double width,
    required double height,
    required double borderRadius,
  }) {
    final fallbackPath = getSpeciesFallbackImage(species);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: _getSpeciesColor(species).withOpacity(0.1),
        border: Border.all(
          color: _getSpeciesColor(species).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.asset(
          fallbackPath,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Si el asset no existe, mostrar inicial del nombre
            return Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: _getSpeciesColor(species).withOpacity(0.1),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: Center(
                child: Text(
                  species?.isNotEmpty == true ? species![0].toUpperCase() : '?',
                  style: TextStyle(
                    color: _getSpeciesColor(species),
                    fontWeight: FontWeight.bold,
                    fontSize: width * 0.4,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingWidget({
    required double width,
    required double height,
    required double borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: const Color(0xFFF3F4F6),
      ),
      child: const Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B7280)),
          ),
        ),
      ),
    );
  }

  Color _getSpeciesColor(String? species) {
    if (species == null) return const Color(0xFF6B7280);

    switch (species.toLowerCase()) {
      case 'canino':
      case 'perro':
      case 'dog':
        return const Color(0xFF8B5CF6); // Púrpura
      case 'felino':
      case 'gato':
      case 'cat':
        return const Color(0xFFF59E0B); // Naranja
      case 'ave':
      case 'pájaro':
      case 'bird':
        return const Color(0xFF10B981); // Verde
      case 'reptil':
      case 'reptile':
        return const Color(0xFFEF4444); // Rojo
      default:
        return const Color(0xFF6B7280); // Gris
    }
  }

  // ============================================================================
  // MÉTODOS PARA MANEJO DE CONTENIDO QUILL/DELTA
  // ============================================================================

  /// Convierte texto plano a formato Delta de Quill
  static List<dynamic> textToDelta(String text) {
    if (text.isEmpty) {
      return [
        {'insert': '\n'}
      ];
    }
    return [
      {'insert': text.endsWith('\n') ? text : '$text\n'}
    ];
  }

  /// Convierte Delta de Quill a texto plano
  static String deltaToText(List<dynamic> delta) {
    if (delta.isEmpty) return '';

    String text = '';
    for (final operation in delta) {
      if (operation is Map<String, dynamic> &&
          operation.containsKey('insert')) {
        text += operation['insert']?.toString() ?? '';
      }
    }
    return text.trim();
  }

  /// Valida y limpia contenido Delta
  static List<dynamic> cleanDelta(dynamic content) {
    if (content == null) {
      return [
        {'insert': '\n'}
      ];
    }

    if (content is String) {
      if (content.isEmpty) {
        return [
          {'insert': '\n'}
        ];
      }
      try {
        final parsed = jsonDecode(content);
        if (parsed is List && parsed.isNotEmpty) {
          return parsed;
        }
      } catch (e) {
        // Si no es JSON válido, tratarlo como texto plano
        return textToDelta(content);
      }
    }

    if (content is List && content.isNotEmpty) {
      return content;
    }

    return [
      {'insert': '\n'}
    ];
  }

  /// Obtiene el texto plano de un campo de contenido
  static String getPlainText(dynamic content) {
    final delta = cleanDelta(content);
    return deltaToText(delta);
  }

  // ============================================================================
  // MÉTODOS DE UTILIDAD GENERAL
  // ============================================================================

  /// Verifica la conexión general con Supabase
  Future<Map<String, dynamic>> testConnection() async {
    try {
      

      // Probar conexión de archivos
      final fileTest = await testFileConnection();

      // Probar conexión de base de datos
      final dbTest = await _testDatabaseConnection();

      return {
        'success': fileTest['success'] && dbTest['success'],
        'files': fileTest,
        'database': dbTest,
        'message': 'Prueba de conexión completada',
      };
    } catch (e) {
      
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Error de conexión general: $e',
      };
    }
  }

  Future<Map<String, dynamic>> _testDatabaseConnection() async {
    try {
      // Probar consulta simple a la tabla de razas
      await _supa.from('breeds').select('id').limit(1);
      return {
        'success': true,
        'message': 'Conexión a base de datos exitosa',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Error de conexión a base de datos: $e',
      };
    }
  }
}
