import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:iconsax/iconsax.dart';
import 'package:zuliadog/core/theme.dart';
import 'package:zuliadog/features/data/buscador.dart';

final _supa = Supabase.instance.client;

/// Pantalla principal de historias médicas optimizada
/// Diseño de 2 columnas: historias médicas + ficha del paciente
class OptimizedHistoriasPage extends StatefulWidget {
  final String clinicId; // Oculto en UI
  final String? mrn; // MRN de 6 dígitos (opcional)

  const OptimizedHistoriasPage({super.key, required this.clinicId, this.mrn});

  @override
  State<OptimizedHistoriasPage> createState() => _OptimizedHistoriasPageState();
}

class _OptimizedHistoriasPageState extends State<OptimizedHistoriasPage> {
  late Future<List<Map<String, dynamic>>> _future;
  late Future<Map<String, dynamic>?> _patientFuture;
  final _df = DateFormat('d MMMM y, hh:mm a', 'es');
  final _searchController = TextEditingController();
  String? _currentMrn;
  final _searchRepository = SearchRepository();
  List<PatientSearchRow> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _currentMrn = widget.mrn;
    print('🔍 OptimizedHistoriasPage initState:');
    print('  - widget.mrn: ${widget.mrn}');
    print('  - _currentMrn: $_currentMrn');
    _loadData();
  }

  void _loadData() {
    print('🔍 _loadData: _currentMrn = $_currentMrn');
    if (_currentMrn != null) {
      print('🔍 _loadData: Cargando datos para MRN: $_currentMrn');
      _future = _fetchHistories();
      _patientFuture = _fetchPatient();
    } else {
      print('🔍 _loadData: No hay MRN, inicializando con datos vacíos');
      _future = Future.value([]);
      _patientFuture = Future.value(null);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchHistories() async {
    if (_currentMrn == null) return [];

    try {
      final rows = await _supa
          .from('medical_records')
          .select(
              'id,date,title,summary,diagnosis,department_code,locked,created_by,created_at,content_delta')
          .eq('clinic_id', widget.clinicId)
          .eq('patient_id', _currentMrn!)
          .order('date', ascending: false)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (e) {
      print('Error al cargar historias: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> _fetchPatient() async {
    if (_currentMrn == null) {
      print('🔍 _fetchPatient: _currentMrn es null');
      return null;
    }

    print('🔍 _fetchPatient: Buscando paciente con MRN: $_currentMrn');

    try {
      // Buscar por MRN (mrn) en la tabla patients
      print(
          '🔍 _fetchPatient: Buscando en tabla patients con mrn = $_currentMrn');

      final rows = await _supa
          .from('patients')
          .select('id,name,species,breed,sex,birth_date,mrn')
          .eq('mrn', _currentMrn!)
          .limit(1);

      print('🔍 _fetchPatient: Resultados encontrados: ${rows.length}');

      // Si no encontramos nada, vamos a ver qué MRNs existen en la tabla
      if (rows.isEmpty) {
        print(
            '🔍 _fetchPatient: No se encontró paciente con MRN: $_currentMrn');
        print('🔍 _fetchPatient: Verificando qué MRNs existen en la tabla...');

        final allPatients = await _supa
            .from('patients')
            .select('id,name,history_number')
            .limit(5);

        print('🔍 _fetchPatient: Primeros 5 pacientes en la tabla:');
        for (var patient in allPatients) {
          print(
              '  - ID: ${patient['id']}, Name: ${patient['name']}, history_number: ${patient['history_number']}');
        }
      } else {
        print('🔍 _fetchPatient: Datos del paciente: ${rows.first}');
        return Map<String, dynamic>.from(rows.first);
      }

      return null;
    } catch (e) {
      print('🔍 Error al cargar paciente: $e');
      return null;
    }
  }

  String _calculateAge(String? birthDate) {
    if (birthDate == null || birthDate.isEmpty) {
      return 'No especificada';
    }

    try {
      final birth = DateTime.parse(birthDate);
      final now = DateTime.now();
      int age = now.year - birth.year;

      // Ajustar si aún no ha cumplido años este año
      if (now.month < birth.month ||
          (now.month == birth.month && now.day < birth.day)) {
        age--;
      }

      if (age < 0) {
        return 'Fecha inválida';
      } else if (age == 0) {
        // Calcular meses si es menor de 1 año
        int months = now.month - birth.month;
        if (now.day < birth.day) months--;
        if (months <= 0) months = 1;
        return '$months ${months == 1 ? 'mes' : 'meses'}';
      } else {
        return '$age ${age == 1 ? 'año' : 'años'}';
      }
    } catch (e) {
      print('Error al calcular edad: $e');
      return 'Fecha inválida';
    }
  }

  Future<void> _searchPatients(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _searchRepository.search(query, limit: 10);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      print('Error en búsqueda: $e');
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  void _openHistoryEditor({Map<String, dynamic>? record}) async {
    // Si no hay paciente seleccionado, crear uno nuevo primero
    if (_currentMrn == null) {
      final newPatient = await _createNewPatient();
      if (newPatient == null) return; // Usuario canceló
    }

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      builder: (_) => _HistoryEditor(
        clinicId: widget.clinicId,
        mrn: _currentMrn!,
        record: record,
      ),
    );
    if (saved == true) {
      setState(() {
        _future = _fetchHistories();
      });
    }
  }

  Future<Map<String, dynamic>?> _createNewPatient() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      builder: (_) => _NewPatientForm(
        clinicId: widget.clinicId,
      ),
    );

    if (result != null) {
      // Actualizar la lista de pacientes y seleccionar el nuevo
      setState(() {
        _currentMrn = result['mrn'];
        _loadData();
      });
    }

    return result;
  }

  void _createLitter() {
    // TODO: Implementar creación de camada
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Crear Camada (pendiente)')),
    );
  }

  void _exportHistory() {
    // TODO: Implementar exportación de historia
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exportar Historia (pendiente)')),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: onTap != null
                ? color.withOpacity(.08)
                : const Color(0xFFE5E7EB).withOpacity(.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: onTap != null
                  ? color.withOpacity(.2)
                  : const Color(0xFF6B7280).withOpacity(.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: onTap != null ? color : const Color(0xFF6B7280),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: onTap != null ? color : const Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResultItem(PatientSearchRow patient) {
    final name = patient.patientName;
    final species = patient.species ?? 'No especificada';
    final breed = patient.breed ?? 'No especificada';
    final mrn = patient.historyNumber ?? 'N/A';
    final ownerName = patient.ownerName ?? 'No especificado';

    return InkWell(
      onTap: () {
        print('🔍 Paciente seleccionado:');
        print('  - patientId: ${patient.patientId}');
        print('  - historyNumber: ${patient.historyNumber}');
        print('  - mrnInt: ${patient.mrnInt}');
        print('  - patientName: ${patient.patientName}');
        print('  - MRN a usar: $mrn');

        setState(() {
          _currentMrn = mrn;
          _searchResults = [];
          _searchController.clear();
          _loadData();
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppTheme.neutral200, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primary500.withOpacity(0.1),
              child: Icon(
                Iconsax.pet,
                color: AppTheme.primary500,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.neutral900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$species - $breed',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.neutral500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Dueño: $ownerName',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.neutral500,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'MRN: $mrn',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.neutral500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      body: Row(
        children: [
          // Columna izquierda: Historias Médicas (70%)
          Expanded(
            flex: 7,
            child: _buildHistoriesColumn(),
          ),
          // Columna derecha: Ficha del Paciente (30%)
          Expanded(
            flex: 3,
            child: _buildPatientPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoriesColumn() {
    return Container(
      color: const Color(0xFFF8F9FA), // background-light
      child: Column(
        children: [
          // Header con título y botones
          Container(
            padding: const EdgeInsets.all(32), // p-8
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: Column(
              children: [
                // Primera fila: Título y quick actions
                Row(
                  children: [
                    Text(
                      'Historias Médicas',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937), // text-light
                      ),
                    ),
                    const Spacer(),
                    // Quick actions para crear historias
                    _buildQuickActionButton(
                      icon: Iconsax.add,
                      label: 'Nueva Historia',
                      color: const Color(0xFF4F46E5),
                      onTap: () => _openHistoryEditor(),
                    ),
                    const SizedBox(width: 8),
                    _buildQuickActionButton(
                      icon: Iconsax.pet,
                      label: 'Crear Camada',
                      color: Colors.orange,
                      onTap: _currentMrn == null ? null : () => _createLitter(),
                    ),
                  ],
                ),
                const SizedBox(height: 24), // mb-6
                // Segunda fila: Barra de búsqueda con icono de exportar
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48, // py-3
                        decoration: BoxDecoration(
                          color: Colors.white, // bg-card-light
                          borderRadius: BorderRadius.circular(12), // rounded-xl
                          border: Border.all(
                              color: const Color(0xFFE5E7EB)), // border-light
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _searchPatients,
                          decoration: InputDecoration(
                            hintText: 'Buscar por MRN o nombre de mascota...',
                            hintStyle: const TextStyle(
                              color: Color(0xFF6B7280), // text-muted-light
                            ),
                            prefixIcon: _isSearching
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Color(0xFF4F46E5)),
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Iconsax.search_normal,
                                    color: Color(0xFF6B7280),
                                    size: 20,
                                  ),
                            suffixIcon: _currentMrn != null
                                ? IconButton(
                                    onPressed: () => _exportHistory(),
                                    icon: const Icon(
                                      Iconsax.export_2,
                                      color: Color(0xFF6B7280),
                                      size: 20,
                                    ),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Resultados de búsqueda
          if (_searchResults.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16), // rounded-2xl
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Iconsax.search_normal_1,
                            color: Color(0xFF4F46E5), size: 16),
                        const SizedBox(width: 8),
                        const Text(
                          'Resultados de búsqueda',
                          style: TextStyle(
                            color: Color(0xFF4F46E5),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_searchResults.length}',
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ..._searchResults
                      .take(5)
                      .map((patient) => _buildSearchResultItem(patient)),
                ],
              ),
            ),
          // Lista de historias o mensaje de selección
          Expanded(
            child: _currentMrn == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Iconsax.user_search,
                            size: 64, color: Color(0xFF6B7280)),
                        const SizedBox(height: 16),
                        const Text(
                          'Selecciona un paciente',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937)),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Para ver sus historias médicas',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  )
                : FutureBuilder(
                    future: _future,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap.hasError) {
                        return Center(child: Text('Error: ${snap.error}'));
                      }
                      final items = snap.data ?? [];
                      if (items.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Iconsax.note_2,
                                  size: 64, color: AppTheme.neutral500),
                              const SizedBox(height: 16),
                              const Text('Sin historias aún',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              const Text(
                                  'Crea la primera historia médica para este paciente'),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () => _openHistoryEditor(),
                                icon: const Icon(Iconsax.add, size: 20),
                                label: const Text('Crear Primera Historia'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary500,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return Container(
                        padding: const EdgeInsets.all(32), // p-8
                        child: Column(
                          children: [
                            // Espaciado entre cards
                            ...items.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              return Column(
                                children: [
                                  _HistoryBlock(
                                    data: item,
                                    df: _df,
                                    onEdit: () =>
                                        _openHistoryEditor(record: item),
                                  ),
                                  if (index < items.length - 1)
                                    const SizedBox(height: 24), // space-y-6
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientPanel() {
    return Container(
      color: Colors.white, // bg-card-light
      child: Column(
        children: [
          // Header del panel
          Container(
            padding: const EdgeInsets.all(24), // p-6
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                  bottom: BorderSide(
                      color: Color(0xFFE5E7EB), width: 1)), // border-light
            ),
            child: Row(
              children: [
                const Text(
                  'Ficha del Paciente',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937), // text-light
                  ),
                ),
              ],
            ),
          ),
          // Contenido del panel
          Expanded(
            child: _currentMrn == null
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.user_search,
                            size: 48, color: AppTheme.neutral500),
                        SizedBox(height: 16),
                        Text('Ficha del Paciente'),
                      ],
                    ),
                  )
                : FutureBuilder(
                    future: _patientFuture,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap.hasError) {
                        return const Center(
                            child: Text('Error al cargar paciente'));
                      }
                      if (snap.data == null) {
                        return const Center(
                            child: Text('Paciente no encontrado'));
                      }
                      final patient = snap.data!;
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(24), // p-6
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Foto del paciente y nombre
                            Row(
                              children: [
                                Container(
                                  width: 64, // w-16
                                  height: 64, // h-16
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF4F46E5)
                                        .withOpacity(0.1),
                                    border: Border.all(
                                        color: const Color(0xFF4F46E5),
                                        width: 2),
                                  ),
                                  child: const Icon(Iconsax.pet,
                                      size: 32, color: Color(0xFF4F46E5)),
                                ),
                                const SizedBox(width: 16), // gap-4
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        patient['name'] ?? 'Sin nombre',
                                        style: const TextStyle(
                                          fontSize: 20, // text-xl
                                          fontWeight: FontWeight.bold,
                                          color:
                                              Color(0xFF1F2937), // text-light
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'MRN: ${patient['mrn']?.toString().padLeft(6, '0') ?? _currentMrn!.padLeft(6, '0')}',
                                        style: const TextStyle(
                                          fontSize: 12, // text-sm
                                          color: Color(
                                              0xFF6B7280), // text-muted-light
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32), // mb-8
                            // Información básica en grid 2x2
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildInfoRow(
                                            'Especie',
                                            patient['species'] ??
                                                'No especificada'),
                                      ),
                                      Expanded(
                                        child: _buildInfoRow(
                                            'Raza',
                                            patient['breed'] ??
                                                'No especificada'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildInfoRow(
                                            'Sexo',
                                            patient['sex'] ??
                                                'No especificado'),
                                      ),
                                      Expanded(
                                        child: _buildInfoRow(
                                            'Edad',
                                            _calculateAge(patient['birth_date']
                                                ?.toString())),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32), // mb-8
                            // Signos vitales
                            const Text(
                              'Signos Vitales',
                              style: TextStyle(
                                fontSize: 16, // text-md
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937), // text-light
                              ),
                            ),
                            const SizedBox(height: 16), // mb-4
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  _buildVitalSign('Temperatura', '38.5 °C'),
                                  _buildVitalSign('Respiración', '22 rpm'),
                                  _buildVitalSign('Pulso', '90 ppm'),
                                  _buildVitalSign('Hidratación', 'Normal',
                                      isNormal: true),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32), // mb-8
                            // Historial de cambios
                            const Text(
                              'Historial de Cambios',
                              style: TextStyle(
                                fontSize: 16, // text-md
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937), // text-light
                              ),
                            ),
                            const SizedBox(height: 16), // mb-4
                            _buildChangeItem('Bloque de historia creado',
                                'Dr. Smith - Hoy a las 10:30 AM'),
                            _buildChangeItem('Archivo adjuntado',
                                'analisis_sangre_max.pdf Dr. Smith - Hoy a las 10:32 AM'),
                            _buildChangeItem('Bloque de historia bloqueado',
                                'Dr. Smith - 15 Sep a las 09:15 AM'),
                            _buildChangeItem('Bloque de historia creado',
                                'Dr. Smith - 15 Sep a las 09:00 AM'),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12, // text-sm
            color: Color(0xFF6B7280), // text-muted-light
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12, // text-sm
            fontWeight: FontWeight.w500,
            color: Color(0xFF1F2937), // text-light
          ),
        ),
      ],
    );
  }

  Widget _buildVitalSign(String label, String value, {bool isNormal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12, // text-sm
              color: Color(0xFF6B7280), // text-muted-light
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12, // text-sm
              fontWeight: FontWeight.w500,
              color: isNormal
                  ? const Color(0xFF16A34A)
                  : const Color(0xFF1F2937), // green-600 : text-light
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangeItem(String action, String details) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24), // space-y-6
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Punto del timeline
          Container(
            width: 8, // w-2
            height: 8, // h-2
            margin: const EdgeInsets.only(top: 4, right: 16), // pl-6
            decoration: const BoxDecoration(
              color: Color(0xFF4F46E5), // primary-DEFAULT
              shape: BoxShape.circle,
            ),
          ),
          // Línea vertical del timeline
          Container(
            width: 1, // w-px
            height: 20,
            margin: const EdgeInsets.only(left: 3, top: 8),
            color: const Color(0xFFE5E7EB), // border-light
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action,
                  style: const TextStyle(
                    fontSize: 12, // text-sm
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2937), // text-light
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  details,
                  style: const TextStyle(
                    fontSize: 10, // text-xs
                    color: Color(0xFF6B7280), // text-muted-light
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bloque de historia médica individual
class _HistoryBlock extends StatefulWidget {
  final Map<String, dynamic> data;
  final DateFormat df;
  final VoidCallback onEdit;

  const _HistoryBlock(
      {required this.data, required this.df, required this.onEdit});

  @override
  State<_HistoryBlock> createState() => _HistoryBlockState();
}

class _HistoryBlockState extends State<_HistoryBlock> {
  late QuillController _controller;
  bool _isEditing = false;
  bool _isLocked = true; // Por defecto bloqueado

  @override
  void initState() {
    super.initState();
    _initializeController();
    // Por defecto todos están bloqueados, solo se desbloquean si locked = false en BD
    _isLocked = widget.data['locked'] != true;
  }

  void _initializeController() {
    final initialDelta = widget.data['content_delta']?.toString();
    List<dynamic> deltaData;

    if (initialDelta != null && initialDelta.isNotEmpty) {
      try {
        deltaData = jsonDecode(initialDelta) as List;
        if (deltaData.isEmpty) {
          deltaData = [
            {'insert': '\n'}
          ];
        }
      } catch (e) {
        deltaData = [
          {'insert': '\n'}
        ];
      }
    } else {
      deltaData = [
        {'insert': '\n'}
      ];
    }

    _controller = QuillController(
      document: Document.fromJson(deltaData),
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _toggleLock() {
    setState(() {
      _isLocked = !_isLocked;
    });
  }

  Future<void> _save() async {
    // TODO: Implementar guardado
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final date = widget.data['date']?.toString() ?? '';
    final title =
        (widget.data['title'] ?? 'Consulta de seguimiento').toString();
    final summary = (widget.data['summary'] ?? '').toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // bg-card-light
        borderRadius: BorderRadius.circular(16), // rounded-2xl
        border: Border.all(color: const Color(0xFFE5E7EB)), // border-light
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del bloque
          Container(
            padding: const EdgeInsets.all(16), // p-4
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: Color(0xFFE5E7EB), width: 1), // border-light
              ),
            ),
            child: Row(
              children: [
                // Fecha y autor
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('d MMMM y, hh:mm a', 'es')
                            .format(DateTime.tryParse(date) ?? DateTime.now()),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937), // text-light
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Autor: Dr. Smith',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280), // text-muted-light
                        ),
                      ),
                    ],
                  ),
                ),
                // Badge de estado y botón menú
                Row(
                  children: [
                    // Badge de estado
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isLocked
                            ? const Color(0xFFFEE2E2) // red-100
                            : const Color(0xFFDCFCE7), // green-100
                        borderRadius: BorderRadius.circular(20), // rounded-full
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isLocked ? Iconsax.lock : Iconsax.unlock,
                            size: 12,
                            color: _isLocked
                                ? const Color(0xFFDC2626) // red-700
                                : const Color(0xFF16A34A), // green-700
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isLocked ? 'Bloqueado' : 'Editable',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _isLocked
                                  ? const Color(0xFFDC2626) // red-700
                                  : const Color(0xFF16A34A), // green-700
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Botón menú
                    GestureDetector(
                      onTap: _isLocked ? _toggleLock : _toggleEdit,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Iconsax.more_2,
                          size: 20,
                          color: const Color(0xFF6B7280), // text-muted-light
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Contenido del bloque
          Padding(
            padding: const EdgeInsets.all(16), // p-4
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937), // text-light
                  ),
                ),
                const SizedBox(height: 8),
                // Resumen
                if (summary.isNotEmpty)
                  Text(
                    summary,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1F2937), // text-light
                      height: 1.5,
                    ),
                  ),
                const SizedBox(height: 12),
                // Editor Quill
                if (_isEditing) ...[
                  QuillToolbar.simple(
                    configurations: QuillSimpleToolbarConfigurations(
                      controller: _controller,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: QuillEditor.basic(
                      configurations: QuillEditorConfigurations(
                        controller: _controller,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Guardar'),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: _toggleEdit,
                        child: const Text('Cancelar'),
                      ),
                    ],
                  ),
                ] else ...[
                  // Vista previa del contenido
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Text(
                      _controller.document.toPlainText().isEmpty
                          ? 'Sin contenido'
                          : _controller.document.toPlainText(),
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF6B7280)),
                    ),
                  ),
                ],
                // Zona de adjuntos solo si no está bloqueado
                if (!_isLocked) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(24), // p-6
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFD1D5DB), // gray-300
                        style: BorderStyle.solid,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12), // rounded-xl
                    ),
                    child: InkWell(
                      onTap: () {
                        // TODO: Implementar file picker
                      },
                      child: Container(
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Iconsax.cloud_add,
                                size: 48, color: Color(0xFF9CA3AF)), // gray-400
                            const SizedBox(height: 8),
                            const Text(
                              'Arrastrar y soltar archivos aquí',
                              style: TextStyle(
                                  fontSize: 14, color: Color(0xFF6B7280)),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'o haz clic para seleccionar',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF9CA3AF)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Editor de historias médicas
class _HistoryEditor extends StatefulWidget {
  final String clinicId;
  final String mrn;
  final Map<String, dynamic>? record;

  const _HistoryEditor(
      {required this.clinicId, required this.mrn, this.record});

  @override
  State<_HistoryEditor> createState() => _HistoryEditorState();
}

class _HistoryEditorState extends State<_HistoryEditor> {
  late QuillController _controller;
  late TextEditingController _titleCtrl, _dxCtrl;
  String _dept = 'MED';
  bool _locked = false;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initializeController();
    _titleCtrl = TextEditingController(text: widget.record?['title'] ?? '');
    _dxCtrl = TextEditingController(text: widget.record?['diagnosis'] ?? '');
    _dept = (widget.record?['department_code'] ?? 'MED').toString();
    _locked = widget.record?['locked'] == true;
    _date = DateTime.tryParse(widget.record?['date']?.toString() ?? '') ??
        DateTime.now();
  }

  void _initializeController() {
    final initialDelta = widget.record?['content_delta']?.toString();
    List<dynamic> deltaData;

    if (initialDelta != null && initialDelta.isNotEmpty) {
      try {
        deltaData = jsonDecode(initialDelta) as List;
        if (deltaData.isEmpty) {
          deltaData = [
            {'insert': '\n'}
          ];
        }
      } catch (e) {
        deltaData = [
          {'insert': '\n'}
        ];
      }
    } else {
      deltaData = [
        {'insert': '\n'}
      ];
    }

    _controller = QuillController(
      document: Document.fromJson(deltaData),
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleCtrl.dispose();
    _dxCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final payload = {
      'clinic_id': widget.clinicId,
      'patient_id': widget.mrn,
      'date': _date.toIso8601String().substring(0, 10),
      'title': _titleCtrl.text.isEmpty ? null : _titleCtrl.text,
      'summary': _controller.document.toPlainText().trim().isEmpty
          ? null
          : _controller.document.toPlainText().trim(),
      'diagnosis': _dxCtrl.text.isEmpty ? null : _dxCtrl.text,
      'department_code': _dept,
      'locked': _locked,
      'content_delta': jsonEncode(_controller.document.toDelta().toJson()),
      'created_by': null,
    };

    try {
      if (widget.record == null) {
        await _supa.from('medical_records').insert(payload);
      } else {
        await _supa
            .from('medical_records')
            .update(payload)
            .eq('id', widget.record!['id']);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.record == null
            ? 'Nuevo bloque de historia'
            : 'Editar historia'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          ElevatedButton.icon(
            onPressed: _editPatient,
            icon: const Icon(Iconsax.edit),
            label: const Text('Editar Paciente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Iconsax.save_2),
            label: const Text('Guardar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary500,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(children: [
          // Campos de entrada
          Row(children: [
            Expanded(
              child: TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Título',
                ),
              ),
            ),
            const SizedBox(width: 12),
            DropdownButtonFormField<String>(
              value: _dept,
              decoration: const InputDecoration(
                labelText: 'Departamento',
              ),
              items: const ['MED', 'DERM', 'CIR', 'LAB']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _dept = v ?? 'MED'),
            ),
            const SizedBox(width: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Bloquear'),
              value: _locked,
              onChanged: (v) => setState(() => _locked = v),
            ),
          ]),

          const SizedBox(height: 12),

          TextField(
            controller: _dxCtrl,
            decoration: const InputDecoration(
              labelText: 'Diagnóstico',
            ),
          ),

          const SizedBox(height: 16),

          // Editor Quill
          QuillToolbar.simple(
            configurations: QuillSimpleToolbarConfigurations(
              controller: _controller,
            ),
          ),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.neutral200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: QuillEditor.basic(
              configurations: QuillEditorConfigurations(
                controller: _controller,
              ),
            ),
          ),
        ]),
      ),
    );
  }

  void _editPatient() {
    // TODO: Implementar edición de paciente
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Editar Paciente (pendiente)')),
    );
  }
}

/// Formulario para crear un nuevo paciente
class _NewPatientForm extends StatefulWidget {
  final String clinicId;

  const _NewPatientForm({required this.clinicId});

  @override
  State<_NewPatientForm> createState() => _NewPatientFormState();
}

class _NewPatientFormState extends State<_NewPatientForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mrnController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _ownerEmailController = TextEditingController();

  String _selectedSpecies = 'Canino';
  String _selectedSex = 'Macho';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _mrnController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _ownerNameController.dispose();
    _ownerPhoneController.dispose();
    _ownerEmailController.dispose();
    super.dispose();
  }

  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Usar MRN manual o generar uno automático
      String mrn = _mrnController.text.trim();
      if (mrn.isEmpty) {
        mrn = await _generateUniqueMRN();
      } else {
        // Validar que el MRN no exista
        final existingPatient = await _supa
            .from('patients')
            .select('id')
            .eq('clinic_id', widget.clinicId)
            .eq('mrn', mrn)
            .maybeSingle();

        if (existingPatient != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('El MRN ya existe. Por favor, use otro número.')),
          );
          return;
        }
      }

      // Crear paciente
      final patientData = {
        'clinic_id': widget.clinicId,
        'name': _nameController.text.trim(),
        'species': _selectedSpecies,
        'breed': _breedController.text.trim(),
        'sex': _selectedSex,
        'birth_date': _ageController.text.trim().isNotEmpty
            ? DateTime.parse(_ageController.text.trim())
            : null,
        'mrn': mrn,
        'created_at': DateTime.now().toIso8601String(),
      };

      final patientResponse = await _supa
          .from('patients')
          .insert(patientData)
          .select('id')
          .single();

      // Crear propietario si se proporcionó información
      if (_ownerNameController.text.trim().isNotEmpty) {
        final ownerData = {
          'clinic_id': widget.clinicId,
          'patient_id': patientResponse['id'],
          'name': _ownerNameController.text.trim(),
          'phone': _ownerPhoneController.text.trim(),
          'email': _ownerEmailController.text.trim(),
          'created_at': DateTime.now().toIso8601String(),
        };

        await _supa.from('owners').insert(ownerData);
      }

      if (mounted) {
        Navigator.pop(
            context, {'mrn': mrn, 'patientId': patientResponse['id']});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paciente creado exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear paciente: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String> _generateUniqueMRN() async {
    // Obtener el último MRN de la clínica
    final lastPatient = await _supa
        .from('patients')
        .select('mrn')
        .eq('clinic_id', widget.clinicId)
        .order('mrn', ascending: false)
        .limit(1)
        .maybeSingle();

    int nextNumber = 1;
    if (lastPatient != null && lastPatient['mrn'] != null) {
      final lastMRN = lastPatient['mrn'].toString();
      if (lastMRN.length >= 6) {
        nextNumber =
            int.parse(lastMRN.substring(2)) + 1; // Asumiendo formato 00XXXX
      }
    }

    return nextNumber.toString().padLeft(6, '0');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Paciente'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _savePatient,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Iconsax.save_2),
            label: const Text('Guardar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información del Paciente
              const Text(
                'Información del Paciente',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Paciente *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El nombre es requerido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _mrnController,
                      decoration: const InputDecoration(
                        labelText: 'MRN (6 dígitos)',
                        border: OutlineInputBorder(),
                        helperText: 'Dejar vacío para generar automáticamente',
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          if (value.trim().length != 6) {
                            return 'El MRN debe tener 6 dígitos';
                          }
                          if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
                            return 'El MRN debe contener solo números';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedSpecies,
                      decoration: const InputDecoration(
                        labelText: 'Especie *',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Canino', 'Felino', 'Ave', 'Reptil', 'Otro']
                          .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedSpecies = value!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(), // Espacio vacío para mantener el layout
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _breedController,
                      decoration: const InputDecoration(
                        labelText: 'Raza',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedSex,
                      decoration: const InputDecoration(
                        labelText: 'Sexo *',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Macho', 'Hembra']
                          .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedSex = value!),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: 'Fecha de Nacimiento (YYYY-MM-DD)',
                  border: OutlineInputBorder(),
                  helperText: 'Formato: 2020-01-15',
                ),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    try {
                      DateTime.parse(value.trim());
                    } catch (e) {
                      return 'Formato de fecha inválido';
                    }
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Información del Propietario
              const Text(
                'Información del Propietario',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _ownerNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Propietario',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ownerPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _ownerEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
