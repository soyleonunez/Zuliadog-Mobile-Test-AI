// =====================================================
// PRUEBA DE ACCESO A BUCKETS DE STORAGE
// =====================================================
// Archivo para probar el acceso a los buckets configurados

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageTestService {
  final SupabaseClient supabase = Supabase.instance.client;

  // =====================================================
  // FUNCIÓN PRINCIPAL DE PRUEBA
  // =====================================================

  Future<void> testAllBuckets() async {
    try {
      // Verificar autenticación
      final user = supabase.auth.currentUser;
      if (user == null) {
        return;
      }

      // Obtener clinic_id del usuario (necesario para los paths)
      final clinicId = await _getUserClinicId();
      if (clinicId == null) {
        return;
      }

      // Probar cada bucket
      await _testDeptFiles(clinicId);
      await _testPatientsMedia(clinicId);
      await _testAdminDocs(clinicId);
      await _testSystem(clinicId);
      await _testMedRecords(clinicId);
    } catch (e) {}
  }

  // =====================================================
  // FUNCIONES DE PRUEBA POR BUCKET
  // =====================================================

  Future<void> _testDeptFiles(String clinicId) async {
    try {
      final bucket = supabase.storage.from('dept_files');

      // Test 1: Listar archivos
      await bucket.list();

      // Test 2: Subir archivo
      final testPath = '$clinicId/departments/radiologia/test_dept.txt';
      await bucket.uploadBinary(
        testPath,
        Uint8List.fromList(
            [72, 101, 108, 108, 111, 32, 68, 101, 112, 116]), // "Hello Dept"
        fileOptions: const FileOptions(upsert: true),
      );

      // Test 3: Descargar archivo
      await bucket.download(testPath);

      // Test 4: Eliminar archivo
      await bucket.remove([testPath]);
    } catch (e) {}
  }

  Future<void> _testPatientsMedia(String clinicId) async {
    try {
      final bucket = supabase.storage.from('patients_media');

      await bucket.list();

      final testPath = '$clinicId/patients/MRN-2024-001/test_image.jpg';
      await bucket.uploadBinary(
        testPath,
        Uint8List.fromList([255, 216, 255, 224]), // JPEG header
        fileOptions: const FileOptions(upsert: true),
      );

      await bucket.download(testPath);

      await bucket.remove([testPath]);
    } catch (e) {}
  }

  Future<void> _testAdminDocs(String clinicId) async {
    print('📋 Probando bucket: admin_docs (Solo Administradores)');
    try {
      final bucket = supabase.storage.from('admin_docs');

      await bucket.list();

      final testPath = '$clinicId/admin/facturas/test_invoice.pdf';
      await bucket.uploadBinary(
        testPath,
        Uint8List.fromList([37, 80, 68, 70]), // PDF header
        fileOptions: const FileOptions(upsert: true),
      );

      await bucket.download(testPath);

      await bucket.remove([testPath]);
    } catch (e) {}
  }

  Future<void> _testSystem(String clinicId) async {
    try {
      final bucket = supabase.storage.from('system');

      await bucket.list();

      final testPath = '$clinicId/temp/user123/test_config.json';
      await bucket.uploadBinary(
        testPath,
        Uint8List.fromList([
          123,
          34,
          116,
          101,
          115,
          116,
          34,
          58,
          116,
          114,
          117,
          101,
          125
        ]), // {"test":true}
        fileOptions: const FileOptions(upsert: true),
      );

      await bucket.download(testPath);

      await bucket.remove([testPath]);
    } catch (e) {}
  }

  Future<void> _testMedRecords(String clinicId) async {
    try {
      final bucket = supabase.storage.from('med_records');

      await bucket.list();

      final testPath = '$clinicId/records/MRN-2024-001/test_record.pdf';
      await bucket.uploadBinary(
        testPath,
        Uint8List.fromList([37, 80, 68, 70]), // PDF header
        fileOptions: const FileOptions(upsert: true),
      );

      await bucket.download(testPath);

      await bucket.remove([testPath]);
    } catch (e) {}
  }

  // =====================================================
  // FUNCIONES AUXILIARES
  // =====================================================

  Future<String?> _getUserClinicId() async {
    try {
      final response = await supabase
          .from('clinic_roles')
          .select('clinic_id')
          .eq('user_id', supabase.auth.currentUser!.id)
          .eq('is_active', true)
          .limit(1)
          .single();

      return response['clinic_id'] as String?;
    } catch (e) {
      return null;
    }
  }

  // =====================================================
  // FUNCIÓN DE PRUEBA SIMPLE (Solo listar)
  // =====================================================

  Future<void> testSimpleAccess() async {
    final buckets = [
      'dept_files',
      'patients_media',
      'admin_docs',
      'system',
      'med_records'
    ];

    for (final bucketName in buckets) {
      try {
        final bucket = supabase.storage.from(bucketName);
        await bucket.list();
      } catch (e) {}
    }
  }
}

// =====================================================
// WIDGET DE PRUEBA (Opcional)
// =====================================================

class StorageTestWidget extends StatelessWidget {
  const StorageTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final testService = StorageTestService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prueba de Storage'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Prueba de Acceso a Buckets',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => testService.testSimpleAccess(),
              child: const Text('Prueba Simple (Solo Listar)'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => testService.testAllBuckets(),
              child: const Text('Prueba Completa (CRUD)'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Revisa la consola para ver los resultados de las pruebas.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
