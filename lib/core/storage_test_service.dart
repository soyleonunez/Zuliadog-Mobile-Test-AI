// lib/core/storage_test_service.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';

/// Servicio para probar el funcionamiento de los buckets de Storage
class StorageTestService {
  final SupabaseClient _supa = Supabase.instance.client;

  /// Prueba todos los buckets configurados
  Future<Map<String, dynamic>> testAllBuckets() async {
    final results = <String, dynamic>{};

    print('🔄 INICIANDO PRUEBA DE STORAGE BUCKETS...');

    try {
      // Probar cada bucket configurado
      for (final bucketName in AppConfig.storageBuckets.values) {
        print('📦 Probando bucket: $bucketName');
        results[bucketName] = await _testBucket(bucketName);
      }

      results['overall_status'] = 'success';
      results['timestamp'] = DateTime.now().toIso8601String();

      print('✅ PRUEBA DE STORAGE COMPLETADA');
      print('📊 Resultados: $results');
    } catch (e) {
      results['overall_status'] = 'error';
      results['error'] = e.toString();
      print('❌ ERROR EN PRUEBA DE STORAGE: $e');
    }

    return results;
  }

  /// Genera archivo de prueba según el tipo de bucket
  Map<String, dynamic> _generateTestFile(String bucketName) {
    final timestamp = DateTime.now().toIso8601String();
    final testFileName = 'test_${DateTime.now().millisecondsSinceEpoch}.json';
    
    // Crear contenido JSON apropiado para cada tipo de bucket
    String testContent;
    switch (bucketName) {
      case 'profiles':
        testContent = '''{
          "type": "profile_metadata",
          "bucket": "$bucketName",
          "timestamp": "$timestamp",
          "description": "Archivo de prueba para perfiles de usuario",
          "test_data": {
            "user_id": "test_user_123",
            "profile_type": "veterinarian"
          }
        }''';
        break;
      case 'patients':
        testContent = '''{
          "type": "patient_metadata", 
          "bucket": "$bucketName",
          "timestamp": "$timestamp",
          "description": "Archivo de prueba para imágenes de pacientes",
          "test_data": {
            "patient_id": "test_patient_456",
            "image_type": "profile_photo"
          }
        }''';
        break;
      case 'medical_records':
        testContent = '''{
          "type": "medical_document",
          "bucket": "$bucketName", 
          "timestamp": "$timestamp",
          "description": "Archivo de prueba para registros médicos",
          "test_data": {
            "patient_id": "test_patient_789",
            "document_type": "medical_report",
            "veterinarian": "Dr. Test"
          }
        }''';
        break;
      case 'billing_docs':
        testContent = '''{
          "type": "billing_document",
          "bucket": "$bucketName",
          "timestamp": "$timestamp", 
          "description": "Archivo de prueba para documentos de facturación",
          "test_data": {
            "invoice_id": "INV-001",
            "amount": 150.00,
            "currency": "USD"
          }
        }''';
        break;
      case 'system_files':
        testContent = '''{
          "type": "system_file",
          "bucket": "$bucketName",
          "timestamp": "$timestamp",
          "description": "Archivo de prueba para archivos del sistema",
          "test_data": {
            "file_category": "configuration",
            "system_version": "1.0.0"
          }
        }''';
        break;
      default:
        testContent = '''{
          "type": "unknown",
          "bucket": "$bucketName", 
          "timestamp": "$timestamp",
          "description": "Archivo de prueba genérico"
        }''';
    }
    
    return {
      'fileName': testFileName,
      'content': testContent,
      'bytes': Uint8List.fromList(testContent.codeUnits)
    };
  }

  /// Prueba un bucket específico
  Future<Map<String, dynamic>> _testBucket(String bucketName) async {
    final result = <String, dynamic>{
      'bucket_name': bucketName,
      'tests': <String, dynamic>{}
    };

    try {
      final bucket = _supa.storage.from(bucketName);

      // Test 1: Listar archivos existentes
      result['tests']['list_files'] = await _testListFiles(bucket, bucketName);

      // Test 2: Subir archivo de prueba
      result['tests']['upload_file'] =
          await _testUploadFile(bucket, bucketName);

      // Test 3: Descargar archivo de prueba
      result['tests']['download_file'] =
          await _testDownloadFile(bucket, bucketName);

      // Test 4: Obtener URL pública/firmada
      result['tests']['get_url'] = await _testGetUrl(bucket, bucketName);

      // Test 5: Eliminar archivo de prueba
      result['tests']['delete_file'] =
          await _testDeleteFile(bucket, bucketName);

      result['status'] = 'success';
    } catch (e) {
      result['status'] = 'error';
      result['error'] = e.toString();
      print('❌ Error en bucket $bucketName: $e');
    }

    return result;
  }

  /// Test 1: Listar archivos en el bucket
  Future<Map<String, dynamic>> _testListFiles(
      StorageFileApi bucket, String bucketName) async {
    try {
      final files = await bucket.list();
      return {
        'status': 'success',
        'file_count': files.length,
        'files': files.map((f) => f.name).toList()
      };
    } catch (e) {
      return {'status': 'error', 'error': e.toString()};
    }
  }

  /// Test 2: Subir archivo de prueba
  Future<Map<String, dynamic>> _testUploadFile(
      StorageFileApi bucket, String bucketName) async {
    try {
      final testFile = _generateTestFile(bucketName);
      final testFileName = testFile['fileName'] as String;
      final bytes = testFile['bytes'] as Uint8List;

      await bucket.uploadBinary(testFileName, bytes);

      return {
        'status': 'success',
        'file_name': testFileName,
        'file_size': bytes.length,
        'file_type': testFileName.split('.').last
      };
    } catch (e) {
      return {'status': 'error', 'error': e.toString()};
    }
  }

  /// Test 3: Descargar archivo de prueba
  Future<Map<String, dynamic>> _testDownloadFile(
      StorageFileApi bucket, String bucketName) async {
    try {
      final testFile = _generateTestFile(bucketName);
      final testFileName = testFile['fileName'] as String;
      final bytes = testFile['bytes'] as Uint8List;

      // Primero subir el archivo
      await bucket.uploadBinary(testFileName, bytes);

      // Luego descargarlo
      final downloadedBytes = await bucket.download(testFileName);

      return {
        'status': 'success',
        'file_name': testFileName,
        'downloaded_size': downloadedBytes.length,
        'original_size': bytes.length,
        'match': downloadedBytes.length == bytes.length
      };
    } catch (e) {
      return {'status': 'error', 'error': e.toString()};
    }
  }

  /// Test 4: Obtener URL pública/firmada
  Future<Map<String, dynamic>> _testGetUrl(
      StorageFileApi bucket, String bucketName) async {
    try {
      final testFile = _generateTestFile(bucketName);
      final testFileName =
          'test_url_${DateTime.now().millisecondsSinceEpoch}.${testFile['fileName'].split('.').last}';
      final bytes = testFile['bytes'] as Uint8List;

      // Subir archivo
      await bucket.uploadBinary(testFileName, bytes);

      // Obtener URL pública
      final publicUrl = bucket.getPublicUrl(testFileName);

      // Para buckets privados, también probar URL firmada
      String? signedUrl;
      try {
        signedUrl = await bucket.createSignedUrl(testFileName, 3600); // 1 hora
      } catch (e) {
        // Si es bucket público, puede no soportar URLs firmadas
        signedUrl = null;
      }

      return {
        'status': 'success',
        'file_name': testFileName,
        'public_url': publicUrl,
        'signed_url': signedUrl,
        'has_public_url': publicUrl.isNotEmpty,
        'has_signed_url': signedUrl != null
      };
    } catch (e) {
      return {'status': 'error', 'error': e.toString()};
    }
  }

  /// Test 5: Eliminar archivo de prueba
  Future<Map<String, dynamic>> _testDeleteFile(
      StorageFileApi bucket, String bucketName) async {
    try {
      final testFile = _generateTestFile(bucketName);
      final testFileName =
          'test_delete_${DateTime.now().millisecondsSinceEpoch}.${testFile['fileName'].split('.').last}';
      final bytes = testFile['bytes'] as Uint8List;

      // Subir archivo
      await bucket.uploadBinary(testFileName, bytes);

      // Verificar que existe
      final filesBefore = await bucket.list();
      final existsBefore = filesBefore.any((f) => f.name == testFileName);

      // Eliminar archivo
      await bucket.remove([testFileName]);

      // Verificar que ya no existe
      final filesAfter = await bucket.list();
      final existsAfter = filesAfter.any((f) => f.name == testFileName);

      return {
        'status': 'success',
        'file_name': testFileName,
        'existed_before': existsBefore,
        'exists_after': existsAfter,
        'deletion_successful': existsBefore && !existsAfter
      };
    } catch (e) {
      return {'status': 'error', 'error': e.toString()};
    }
  }

  /// Obtener información de los buckets configurados
  Future<Map<String, dynamic>> getBucketsInfo() async {
    final info = <String, dynamic>{};

    try {
      for (final bucketName in AppConfig.storageBuckets.values) {
        final bucket = _supa.storage.from(bucketName);
        final files = await bucket.list();

        info[bucketName] = {
          'name': bucketName,
          'file_count': files.length,
          'files': files
              .map((f) => {
                    'name': f.name,
                    'size': f.metadata?['size'],
                    'updated_at': f.updatedAt,
                    'content_type': f.metadata?['mimetype']
                  })
              .toList()
        };
      }

      info['overall_status'] = 'success';
      info['timestamp'] = DateTime.now().toIso8601String();
    } catch (e) {
      info['overall_status'] = 'error';
      info['error'] = e.toString();
    }

    return info;
  }
}

/// Widget para mostrar los resultados de las pruebas de Storage
class StorageTestResultsWidget extends StatelessWidget {
  final Map<String, dynamic> results;

  const StorageTestResultsWidget({
    super.key,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  results['overall_status'] == 'success'
                      ? Icons.check_circle
                      : Icons.error,
                  color: results['overall_status'] == 'success'
                      ? Colors.green
                      : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Resultados de Prueba de Storage',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (results['overall_status'] == 'error') ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  'Error: ${results['error']}',
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            ] else ...[
              // Mostrar resultados por bucket
              ...AppConfig.storageBuckets.values.map((bucketName) {
                final bucketResults =
                    results[bucketName] as Map<String, dynamic>?;
                if (bucketResults == null) return const SizedBox.shrink();

                return _buildBucketResult(bucketName, bucketResults);
              }).toList(),
            ],
            const SizedBox(height: 16),
            Text(
              'Última actualización: ${results['timestamp'] ?? 'N/A'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBucketResult(
      String bucketName, Map<String, dynamic> bucketResults) {
    final isSuccess = bucketResults['status'] == 'success';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSuccess ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSuccess ? Icons.storage : Icons.error,
                color: isSuccess ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Bucket: $bucketName',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          if (isSuccess) ...[
            const SizedBox(height: 8),
            ...bucketResults['tests'].entries.map((test) {
              final testName = test.key as String;
              final testResult = test.value as Map<String, dynamic>;
              final testSuccess = testResult['status'] == 'success';

              return Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Row(
                  children: [
                    Icon(
                      testSuccess ? Icons.check : Icons.close,
                      color: testSuccess ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      testName.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            }).toList(),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'Error: ${bucketResults['error']}',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ],
        ],
      ),
    );
  }
}
