// lib/features/data/repository.dart
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'buscador.dart';

final supa = Supabase.instance.client;

/// Buckets disponibles en tu proyecto
enum ZBucket { profiles, patients, medical_records, billing_docs, system_files }

extension ZBucketX on ZBucket {
  String get name => switch (this) {
        ZBucket.profiles => 'profiles',
        ZBucket.patients => 'patients',
        ZBucket.medical_records => 'medical_records',
        ZBucket.billing_docs => 'billing_docs',
        ZBucket.system_files => 'system_files',
      };

  /// Solo estos buckets son públicos
  bool get isPublic => this == ZBucket.profiles || this == ZBucket.patients;
}

/// ===============
/// Helpers de PATH
/// ===============
class ZPaths {
  /// Clave para el inbox: system_files/<clinicId>/inbox/<uploadId>.<ext>
  static String inbox(String clinicId, String ext, {String? uploadId}) {
    final id = uploadId ?? DateTime.now().millisecondsSinceEpoch.toString();
    return '$clinicId/inbox/$id.$ext';
  }

  /// Clave destino cuando se asigna a una historia:
  /// medical_records/<clinicId>/patients/<patientId>/records/<recordId>/docs/<documentId>.<ext>
  static String recordDoc(String clinicId, String patientId, String recordId,
      String documentId, String ext) {
    return '$clinicId/patients/$patientId/records/$recordId/docs/$documentId.$ext';
  }

  static String normalizeForFs(String input, {int maxLen = 48}) {
    final a = input
        .toLowerCase()
        .replaceAll(RegExp(r'[áàä]'), 'a')
        .replaceAll(RegExp(r'[éèë]'), 'e')
        .replaceAll(RegExp(r'[íìï]'), 'i')
        .replaceAll(RegExp(r'[óòö]'), 'o')
        .replaceAll(RegExp(r'[úùü]'), 'u')
        .replaceAll('ñ', 'n');
    final b = a
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return b.substring(0, b.length > maxLen ? maxLen : b.length);
  }

  /// Nombre legible para export/local (opcional)
  static String humanFileName({
    required String history,
    required String patientName,
    required String ownerName,
    required String tipo,
    required DateTime createdAt,
    required String docId,
    required String ext,
  }) {
    String two(int n) => n.toString().padLeft(2, '0');
    final d = '${createdAt.year}${two(createdAt.month)}${two(createdAt.day)}';
    final t = '${two(createdAt.hour)}${two(createdAt.minute)}';
    return 'H${normalizeForFs(history, maxLen: 20)}-'
        '${normalizeForFs(patientName, maxLen: 32)}-'
        '${normalizeForFs(ownerName, maxLen: 32)}-'
        '${normalizeForFs(tipo, maxLen: 24)}-'
        '$d-$t-${docId.substring(0, 8)}.$ext';
  }
}

/// =======================
/// Servicios de almacenamiento
/// =======================
class StorageService {
  /// Sube un archivo a un bucket/clave concretos
  static Future<String> upload({
    required ZBucket bucket,
    required String storageKey,
    required File file,
    bool upsert = false,
  }) async {
    await supa.storage
        .from(bucket.name)
        .upload(storageKey, file, fileOptions: FileOptions(upsert: upsert));
    return storageKey;
  }

  /// Devuelve URL pública o firmada según el bucket
  static Future<String> getUrl({
    required ZBucket bucket,
    required String storageKey,
    int expiresInSeconds = 900,
  }) async {
    return bucket.isPublic
        ? supa.storage.from(bucket.name).getPublicUrl(storageKey)
        : await supa.storage
            .from(bucket.name)
            .createSignedUrl(storageKey, expiresInSeconds);
  }

  /// Descarga a la carpeta temporal de la app
  static Future<String> downloadToCache(
      {required String url, required String filename}) async {
    final dir = await getTemporaryDirectory();
    final savePath = p.join(dir.path, filename);
    await Dio().download(url, savePath,
        options: Options(responseType: ResponseType.bytes));
    return savePath;
  }

  /// Mover objetos entre ubicaciones (entre buckets distintos hace download+upload)
  static Future<void> move({
    required ZBucket from,
    required String fromKey,
    required ZBucket to,
    required String toKey,
  }) async {
    if (from == to) {
      await supa.storage.from(from.name).move(fromKey, toKey);
      return;
    }
    final url =
        await getUrl(bucket: from, storageKey: fromKey, expiresInSeconds: 120);
    final tmp = await downloadToCache(url: url, filename: p.basename(fromKey));
    await upload(bucket: to, storageKey: toKey, file: File(tmp), upsert: false);
    await supa.storage.from(from.name).remove([fromKey]);
  }
}

/// ===============
/// Modelos de datos
/// ===============
class DocumentRow {
  final String id;
  final String name;
  final String bucket;
  final String key;
  final String ext;
  final int size;
  final DateTime createdAt;
  final String? patientId;
  final String? patientName;
  final String? ownerName;
  final String? historyNumber;
  final String? tipo;

  DocumentRow({
    required this.id,
    required this.name,
    required this.bucket,
    required this.key,
    required this.ext,
    required this.size,
    required this.createdAt,
    this.patientId,
    this.patientName,
    this.ownerName,
    this.historyNumber,
    this.tipo,
  });

  factory DocumentRow.fromExport(Map<String, dynamic> r) {
    return DocumentRow(
      id: r['document_id'] as String,
      name: r['original_name'] as String,
      bucket: r['storage_bucket'] as String,
      key: r['storage_key'] as String,
      ext: (r['ext'] as String).toLowerCase(),
      size: (r['size_bytes'] as num).toInt(),
      createdAt: DateTime.parse(r['created_at'] as String),
      patientId: r['patient_id'] as String?,
      patientName: r['patient_name'] as String?,
      ownerName: r['owner_name'] as String?,
      historyNumber: r['history_number'] as String?,
      tipo: r['tipo'] as String?,
    );
  }

  factory DocumentRow.fromDocumentsTable(Map<String, dynamic> r) {
    return DocumentRow(
      id: r['id'] as String,
      name: r['name'] as String,
      bucket: r['storage_bucket'] as String,
      key: r['storage_key'] as String,
      ext: (r['ext'] as String).toLowerCase(),
      size: (r['size_bytes'] as num).toInt(),
      createdAt: DateTime.parse(r['created_at'] as String),
      patientId: r['patient_id'] as String?,
      patientName: null, // No disponible en la tabla documents
      ownerName: null, // No disponible en la tabla documents
      historyNumber: null, // No disponible en la tabla documents
      tipo: null, // No disponible en la tabla documents
    );
  }
}

/// =======================
/// Repositorio simplificado para documentos públicos
/// =======================
class DocItem {
  final String name; // "1758142080787.pdf"
  final String path; // "veterinaria-zuliadog/inbox/1758142080787.pdf"
  final String publicUrl; // URL lista para la UI
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;

  DocItem({
    required this.name,
    required this.path,
    required this.publicUrl,
    this.updatedAt,
    this.metadata,
  });
}

class DocsRepository {
  final SupabaseClient _supa;
  static const String _bucket = 'system_files';

  DocsRepository(this._supa);

  Future<String> uploadPublic({
    required String clinicSlug,
    required File file,
    required String filename,
    String area = 'inbox',
  }) async {
    final objectPath = '$clinicSlug/$area/$filename';
    final bytes = await file.readAsBytes();

    await _supa.storage.from(_bucket).uploadBinary(objectPath, bytes,
        fileOptions: const FileOptions(upsert: true));

    return _supa.storage.from(_bucket).getPublicUrl(objectPath);
  }

  Future<List<DocItem>> listPublic({
    required String clinicSlug,
    String area = 'inbox',
    int limit = 100,
  }) async {
    final prefix = '$clinicSlug/$area';
    final result = await _supa.storage.from(_bucket).list(
          path: prefix,
          searchOptions: SearchOptions(
            limit: limit,
            offset: 0,
            sortBy: const SortBy(column: 'updated_at', order: 'desc'),
          ),
        );
    return result.map((it) {
      final path = '$prefix/${it.name}';
      final url = _supa.storage.from(_bucket).getPublicUrl(path);
      return DocItem(
        name: it.name,
        path: path,
        publicUrl: url,
        updatedAt: it.updatedAt is DateTime ? it.updatedAt as DateTime : null,
        metadata: it.metadata,
      );
    }).toList();
  }

  /// Lista archivos del inbox usando el SDK nativo (recomendado)
  Future<List<FileObject>> listInbox(String clinicSlug) async {
    final prefix = '$clinicSlug/inbox';
    final result = await _supa.storage.from(_bucket).list(
          path: prefix,
          searchOptions: const SearchOptions(
            limit: 100,
            offset: 0,
            sortBy: SortBy(column: 'updated_at', order: 'desc'),
          ),
        );
    return result;
  }

  /// Genera URL pública para un archivo
  String publicUrlFor(String clinicSlug, String name) {
    final path = '$clinicSlug/inbox/$name';
    return _supa.storage.from(_bucket).getPublicUrl(path);
  }

  /// Subida correcta para DEV (público) - versión mejorada
  Future<String> uploadPublicFile({
    required String clinicSlug,
    required File file,
    String area = 'inbox',
  }) async {
    final name =
        '${DateTime.now().millisecondsSinceEpoch}.${file.path.split('.').last}';
    final path = '$clinicSlug/$area/$name';
    await _supa.storage.from(_bucket).uploadBinary(
          path,
          await file.readAsBytes(),
          fileOptions: const FileOptions(upsert: true),
        );
    return _supa.storage.from(_bucket).getPublicUrl(path);
  }
}

/// =======================
/// Repositorio principal
/// =======================
class Repository {
  // Función removida - usar storage_helper.dart en su lugar

  // Función removida - usar storage_helper.dart en su lugar

  /// 1) Indexa archivos sueltos en system_files/<clinicId>/inbox
  /// creando filas en `documents` si no existen.
  static Future<int> indexSystemInbox({
    required String clinicId,
    int pageLimit = 1000,
  }) async {
    final bucket = ZBucket.system_files;
    final path = '$clinicId/inbox';

    final listed = await supa.storage.from(bucket.name).list(
          path: path,
          searchOptions: SearchOptions(limit: pageLimit),
        );

    int created = 0;

    for (final obj in listed) {
      final key = '$path/${obj.name}';

      final exists = await supa
          .from('documents')
          .select('id')
          .eq('storage_bucket', bucket.name)
          .eq('storage_key', key)
          .maybeSingle();

      if (exists != null) continue;

      final ext = obj.name.contains('.')
          ? obj.name.split('.').last.toLowerCase()
          : 'bin';

      await supa.from('documents').insert({
        'clinic_id': clinicId,
        'name': obj.name,
        'ext': ext,
        'size_bytes':
            obj.metadata?['size'] ?? obj.metadata?['contentLength'] ?? 0,
        'storage_bucket': bucket.name,
        'storage_key': key,
        'uploaded_by': supa.auth.currentUser?.id,
      });
      created++;
    }
    return created;
  }

  // Función removida - usar storage_helper.dart en su lugar

  // Función removida - usar storage_helper.dart en su lugar

  /// 4) Mueve un documento del inbox a medical_records y actualiza tabla
  static Future<void> moveInboxToRecord({
    required String clinicId,
    required String patientId,
    required String recordId,
    required DocumentRow doc,
  }) async {
    final newKey =
        ZPaths.recordDoc(clinicId, patientId, recordId, doc.id, doc.ext);

    await StorageService.move(
      from: ZBucket.system_files,
      fromKey: doc.key,
      to: ZBucket.medical_records,
      toKey: newKey,
    );

    await supa.from('documents').update({
      'storage_bucket': ZBucket.medical_records.name,
      'storage_key': newKey,
      'paciente_id': patientId,
    }).eq('id', doc.id);
  }
}

/// Repositorio principal para operaciones de base de datos
class DataRepository {
  final SupabaseClient _db = Supabase.instance.client;

  /// Busca pacientes por múltiples criterios usando v_app
  Future<List<PatientSearchRow>> searchPatients(String query,
      {int limit = 30}) async {
    final q = query.trim();

    var baseSel = _db.from('patients').select('''
          id,
          history_number,
          name,
          species_code,
          breed_id,
          breed,
          sex,
          birth_date,
          weight_kg,
          notes,
          owner_id,
          clinic_id,
          history_number,
          temper,
          temperature,
          respiration,
          pulse,
          hydration,
          weight,
          admission_date,
          _patient_id,
          created_at,
          updated_at,
          owners:owner_id (
            name,
            phone,
            email
          ),
          breeds:breed_id (
            label,
            species_code,
            species_label
          )
        ''');

    if (q.isEmpty) {
      // Lista inicial: algunos pacientes ordenados por nombre
      final rows = await baseSel.order('name', ascending: true).limit(limit);
      return _processSearchResults(rows);
    }

    // Usar la misma lógica simple que funciona en pacientes.dart
    final rows = await baseSel
        .or('name.ilike.%$q%,history_number.ilike.%$q%')
        .order('name', ascending: true)
        .limit(limit);

    return _processSearchResults(rows);
  }

  /// Procesa los resultados de búsqueda y los convierte al formato esperado
  List<PatientSearchRow> _processSearchResults(List<dynamic> rows) {
    return rows.map((record) {
      final owner = record['owners'] as Map<String, dynamic>?;
      final breed = record['breeds'] as Map<String, dynamic>?;

      final processedRecord = {
        'patient_id': record['id'],
        'patient_uuid': record['id'],
        'clinic_id': record['clinic_id'],
        'patient_name': record['name'],
        'paciente_name_snapshot': record['name'],
        'history_number': record['history_number'],
        'history_number_snapshot': record['history_number'],
        'history_number_int': record['history_number'],
        'owner_name': owner?['name'],
        'owner_name_snapshot': owner?['name'],
        'owner_phone': owner?['phone'],
        'owner_email': owner?['email'],
        'species_code': record['species_code'],
        'breed_label': breed?['label'],
        'breed': breed?['label'],
        'breed_id': record['breed_id'],
        'sex': record['sex'],
        'status': 'active',
        'last_visit_at': record['created_at'],
        'photo_path': null,
      };

      return PatientSearchRow.fromJson(processedRecord);
    }).toList();
  }

  /// Obtiene estadísticas del dashboard
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      // Aquí puedes agregar consultas para estadísticas
      // Por ejemplo: pacientes atendidos hoy, pendientes, etc.
      return {
        'attended_today': 18,
        'pending': 7,
        'notes': 3,
      };
    } catch (e) {
      print('Error obteniendo estadísticas: $e');
      return {
        'attended_today': 0,
        'pending': 0,
        'notes': 0,
      };
    }
  }

  /// Obtiene actividades recientes
  Future<List<Map<String, dynamic>>> getRecentActivities(
      {int limit = 8}) async {
    try {
      // Aquí puedes agregar consultas para actividades recientes
      // Por ahora retornamos datos mock
      return List.generate(
          limit,
          (i) => {
                'id': i,
                'type': [
                  'patient_added',
                  'appointment_created',
                  'document_uploaded',
                  'ticket_opened'
                ][i % 4],
                'description': [
                  'Alta de paciente: Max (Canino)',
                  'Cita creada para Luna',
                  'Documento subido: RX_1234.pdf',
                  'Ticket abierto para Simba',
                ][i % 4],
                'status': ['completed', 'pending', 'in_progress'][i % 3],
                'time': 'Hoy 10:${(i + 1).toString().padLeft(2, '0')}',
              });
    } catch (e) {
      print('Error obteniendo actividades: $e');
      return [];
    }
  }

  /// Obtiene tareas del día
  Future<List<Map<String, dynamic>>> getTodayTasks() async {
    try {
      // Aquí puedes agregar consultas para tareas
      return [
        {'title': 'Llamar al dueño de Luna', 'time': '10:30', 'done': false},
        {'title': 'Revisar análisis de Max', 'time': '11:15', 'done': true},
        {'title': 'Confirmar cita de Simba', 'time': '14:00', 'done': false},
        {'title': 'Subir RX Bella', 'time': '15:20', 'done': false},
        {'title': 'Receta para Coco', 'time': '17:00', 'done': false},
      ];
    } catch (e) {
      print('Error obteniendo tareas: $e');
      return [];
    }
  }
}
