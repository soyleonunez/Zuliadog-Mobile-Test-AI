import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:zuliadog/core/theme.dart';
import 'package:zuliadog/core/notifications.dart';
import 'package:zuliadog/core/pdf_service.dart';
import 'package:zuliadog/features/data/data_service.dart';
import 'package:zuliadog/features/widgets/text_editor.dart';
import 'package:zuliadog/features/widgets/patient_form.dart';

final _supa = Supabase.instance.client;

/// Pantalla principal de historias médicas optimizada
/// Diseño de 2 columnas: historias médicas + ficha del paciente
class OptimizedHistoriasPage extends StatefulWidget {
  final String clinicId; // Oculto en UI
  final String? historyNumber; // history_number de 6 dígitos (opcional)

  const OptimizedHistoriasPage({
    super.key,
    required this.clinicId,
    this.historyNumber,
  });

  @override
  State<OptimizedHistoriasPage> createState() => _OptimizedHistoriasPageState();
}

class _OptimizedHistoriasPageState extends State<OptimizedHistoriasPage> {
  late Future<List<Map<String, dynamic>>> _future;
  late Future<Map<String, dynamic>?> _patientFuture;
  final _df = DateFormat('d MMMM y, hh:mm a', 'es');
  final _searchController = TextEditingController();
  String? _currentHistoryNumber;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String? _clinicId;

  // Cache local de historias para optimizar eliminaciones
  List<Map<String, dynamic>> _cachedHistories = [];
  bool _isLoadingHistories = false;

  @override
  void initState() {
    super.initState();
    _currentHistoryNumber = widget.historyNumber;
    _loadClinicId();
  }

  @override
  void didUpdateWidget(OptimizedHistoriasPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.historyNumber != oldWidget.historyNumber) {
      _currentHistoryNumber = widget.historyNumber;
      _loadData(); // Reload data when historyNumber changes
    }
  }

  Future<void> _loadClinicId() async {
    try {
      // Para ambiente controlado: usar clinic_id hardcodeado
      _clinicId = '4c17fddf-24ab-4a8d-9343-4cc4f6a4a203';
      _loadData();
    } catch (e) {
      throw Exception('No se pudo cargar el clinic_id: $e');
    }
  }

  void _loadData() {
    if (_currentHistoryNumber != null && _clinicId != null) {
      _future = _fetchHistories();
      _patientFuture = _fetchPatient();
    } else {
      _future = Future.value([]);
      _patientFuture = Future.value(null);
      _cachedHistories = [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchHistories() async {
    if (_currentHistoryNumber == null || _clinicId == null) return [];

    setState(() {
      _isLoadingHistories = true;
    });

    try {
      // Consultar medical_records con RLS

      // Primero obtener el UUID del paciente por history_number
      final patientResult = await _supa
          .from('patients')
          .select('id')
          .eq('clinic_id', _clinicId!)
          .eq('history_number', _currentHistoryNumber!)
          .single();

      final patientId = patientResult['id'] as String;

      // Luego buscar los registros médicos por el UUID del paciente
      final rows = await _supa
          .from('medical_records')
          .select('*')
          .eq('clinic_id', _clinicId!)
          .eq('patient_id', patientId)
          .order('visit_date', ascending: false)
          .order('created_at', ascending: false);

      // Los datos ya están en el formato correcto de medical_records
      final histories = List<Map<String, dynamic>>.from(rows as List);

      setState(() {
        _cachedHistories = [
          ...histories,
          ..._cachedHistories.where((h) => h['is_temp'] == true).toList(),
        ];
        _isLoadingHistories = false;
      });

      return histories;
    } catch (e) {
      setState(() {
        _isLoadingHistories = false;
      });
      return [];
    }
  }

  Future<Map<String, dynamic>?> _fetchPatient() async {
    if (_currentHistoryNumber == null || _clinicId == null) {
      return null;
    }

    try {
      // Buscar directamente en patients con JOIN a owners y breeds
      final rows = await _supa
          .from('patients')
          .select('''
            id,
            name,
            history_number,
            species_code,
            breed_id,
            breed,
            sex,
            birth_date,
            weight_kg,
            notes,
            owner_id,
            clinic_id,
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
          ''')
          .eq('clinic_id', _clinicId!)
          .eq('history_number', _currentHistoryNumber!)
          .limit(1);

      if (rows.isNotEmpty) {
        final record = rows.first;
        final owner = record['owners'] as Map<String, dynamic>?;
        final breed = record['breeds'] as Map<String, dynamic>?;

        // Procesar el resultado para que coincida con el formato esperado
        final patient = {
          'patient_id': record['id'],
          'patient_uuid': record['id'],
          'patient_name': record['name'],
          'history_number': record['history_number'],
          'species_code': record['species_code'],
          'breed_id': record['breed_id'],
          'breed': breed?['label'] ?? record['breed'],
          'breed_label': breed?['label'] ?? record['breed'],
          'sex': record['sex'],
          'birth_date': record['birth_date'],
          'owner_name': owner?['name'],
          'owner_phone': owner?['phone'],
          'owner_email': owner?['email'],
          'species_label': breed?['species_label'],
          'patient_breed_id': record['breed_id'],
        };

        return patient;
      }
      return null;
    } catch (e) {
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
      return 'Fecha inválida';
    }
  }

  String _getSpeciesLabel(String? speciesCode) {
    switch (speciesCode?.toUpperCase()) {
      case 'CAN':
        return 'Canino';
      case 'FEL':
        return 'Felino';
      case 'AVE':
        return 'Ave';
      case 'EQU':
        return 'Equino';
      case 'BOV':
        return 'Bovino';
      case 'POR':
        return 'Porcino';
      case 'CAP':
        return 'Caprino';
      case 'OVI':
        return 'Ovino';
      default:
        return speciesCode ?? 'Sin especificar';
    }
  }

  Future<void> _searchPatients(String query) async {
    if (query.trim().isEmpty || _clinicId == null) {
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
      final q = query.trim();

      // Buscar directamente en patients con JOIN a owners y breeds
      final results = await _supa
          .from('patients')
          .select('''
            id,
            name,
            history_number,
            species_code,
            breed_id,
            breed,
            sex,
            birth_date,
            weight_kg,
            notes,
            owner_id,
            clinic_id,
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
          ''')
          .eq('clinic_id', _clinicId!)
          .or('name.ilike.%$q%,history_number.ilike.%$q%')
          .limit(10);

      // Procesar los resultados para que coincidan con el formato esperado
      final processedResults = results.map((record) {
        final owner = record['owners'] as Map<String, dynamic>?;
        final breed = record['breeds'] as Map<String, dynamic>?;

        return {
          'patient_id': record['id'],
          'patient_uuid': record['id'],
          'patient_name': record['name'],
          'history_number': record['history_number'],
          'species_code': record['species_code'],
          'breed_id': record['breed_id'],
          'breed': breed?['label'] ?? record['breed'],
          'breed_label': breed?['label'] ?? record['breed'],
          'sex': record['sex'],
          'birth_date': record['birth_date'],
          'owner_name': owner?['name'],
          'owner_phone': owner?['phone'],
          'owner_email': owner?['email'],
          'species_label': breed?['species_label'],
          'patient_breed_id': record['breed_id'],
        };
      }).toList();

      setState(() {
        _searchResults = processedResults;
        _isSearching = false;
      });
    } catch (e) {
      if (mounted) {
        NotificationService.showError('Error al buscar pacientes: $e');
      }
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  Future<void> _createNewBlock() async {
    // Verificar que hay un paciente seleccionado
    if (_currentHistoryNumber == null || _clinicId == null) {
      NotificationService.showWarning('Primero selecciona un paciente');
      return;
    }

    try {
      // Crear un nuevo bloque completamente vacío
      final now = DateTime.now();
      final newBlock = {
        'id': 'temp_${now.millisecondsSinceEpoch}', // ID temporal
        'clinic_id': _clinicId!,
        'patient_id':
            _currentHistoryNumber!, // En medical_records, patient_id es el history_number
        'date': now.toIso8601String().substring(0, 10), // Solo fecha, no hora
        'title': null,
        'summary': null,
        'doctor': null,
        'department_code': 'MED',
        'locked': false,
        'created_by': null,
        'created_at': now.toIso8601String(),
        'notes': null,
        'is_new': true, // Marcar como nuevo para identificar
        'is_temp': true, // Marcar como temporal para no duplicar
      };

      // Agregar al cache local inmediatamente
      setState(() {
        _cachedHistories.insert(0, newBlock);
      });

      NotificationService.showSuccess(
        'Nuevo bloque creado. Puedes editarlo ahora.',
      );
    } catch (e) {
      if (mounted) {
        NotificationService.showError('Error al crear bloque: $e');
      }
    }
  }

  void _exportHistory() {
    // TODO: Implementar exportación de historia
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exportar Historia (pendiente)')),
    );
  }

  void _navigateToPatients() {
    // Navegar a la pantalla de pacientes
    Navigator.pushNamed(context, '/pacientes');
  }

  void _openNewPatientForm() {
    // Abrir formulario de nuevo paciente
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ModernPatientForm(
          onPatientCreated: () async {
            // Callback cuando se crea un paciente exitosamente
            Navigator.of(context).pop();
            NotificationService.showSuccess('Paciente creado exitosamente');

            // Obtener el último paciente creado para seleccionarlo automáticamente
            try {
              final lastPatient = await _supa
                  .from('v_app')
                  .select('*')
                  .eq('clinic_id', _clinicId!)
                  .order('created_at', ascending: false)
                  .limit(1)
                  .single();

              if (lastPatient.isNotEmpty) {
                setState(() {
                  _currentHistoryNumber =
                      lastPatient['history_number']?.toString();
                  _searchResults = [];
                  _searchController.clear();
                });

                // Cargar datos del nuevo paciente
                _loadData();

                // Crear automáticamente un nuevo bloque de historia
                await _createNewBlock();
              }
            } catch (e) {
              // Si no se puede obtener el último paciente, solo recargar datos
              _loadData();
            }
          },
          onCancel: () {
            // Callback cuando se cancela la creación
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  Future<void> _exportToPDF() async {
    if (_currentHistoryNumber == null) {
      NotificationService.showWarning('Primero selecciona un paciente');
      return;
    }

    try {
      // Mostrar indicador de carga
      NotificationService.showInfo('Generando PDF...');

      // Obtener datos del paciente
      final patient = await _patientFuture;
      if (patient == null) {
        NotificationService.showError(
          'No se pudo obtener información del paciente',
        );
        return;
      }

      // Obtener historias médicas
      final histories = await _future;

      // Datos de la clínica (hardcodeados por ahora)
      const clinicName = 'ZULIA DOG - Clínica Veterinaria';
      const clinicAddress = 'Dirección de la clínica';
      const clinicPhone = 'Teléfono de la clínica';

      // Exportar PDF
      await PDFService.exportMedicalHistory(
        patient: patient,
        medicalRecords: histories,
        clinicName: clinicName,
        clinicAddress: clinicAddress,
        clinicPhone: clinicPhone,
        clinicEmail: 'contacto@zuliadog.com', // Email de la clínica
      );

      NotificationService.showSuccess('PDF generado correctamente');
    } catch (e) {
      NotificationService.showError('Error al generar PDF: $e');
    }
  }

  /// Elimina una historia del cache local de manera eficiente
  void _removeHistoryFromCache(String historyId) {
    setState(() {
      _cachedHistories.removeWhere((history) => history['id'] == historyId);
    });
  }

  /// Construye la lista de historias de manera optimizada
  Widget _buildHistoriesList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.note_2, size: 64, color: AppTheme.neutral500),
            const SizedBox(height: 16),
            const Text(
              'Sin historias aún',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text('Crea la primera historia médica para este paciente'),
            const SizedBox(height: 24),
            _buildQuickActionButton(
              icon: Iconsax.add,
              text: 'Crear Primera Historia',
              tooltip: 'Crear Primera Historia',
              color: AppTheme.primary500,
              onTap: () => _createNewBlock(),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32), // p-8
      child: Column(
        children: [
          // Espaciado entre cards
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Column(
              children: [
                TextEditor(
                  key: ValueKey(item['id']), // Clave única para cada TextEditor
                  data: item,
                  tableName: 'medical_records',
                  recordId: item['id'],
                  clinicId: _clinicId!,
                  dateFormat: _df,
                  onEdit: () {
                    // El TextEditor maneja la edición internamente
                    // No se necesita acción adicional
                  },
                  onSaved: () {
                    // Recargar datos para actualizar la información del paciente y el cache
                    setState(() {
                      _future = _fetchHistories();
                      _patientFuture = _fetchPatient();
                    });
                  },
                  onDeleted: () {
                    // Eliminar del cache local de manera eficiente
                    _removeHistoryFromCache(item['id']);
                  },
                  showAttachments: true,
                  showLockToggle: true,
                  showDeleteButton: true,
                ),
                if (index < items.length - 1)
                  const SizedBox(height: 24), // space-y-6
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPatientInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  void _selectBreedImage() {
    // TODO: Implementar selección de imagen de breeds
    NotificationService.showInfo('Seleccionar Imagen de Raza (pendiente)');
  }

  Widget _buildSearchResultItem(Map<String, dynamic> patient) {
    final name = patient['patient_name'] ??
        patient['paciente_name_snapshot'] ??
        'Sin nombre';
    final species = _getSpeciesLabel(patient['species_code']);
    final breed =
        patient['breed_label'] ?? patient['breed'] ?? 'Sin especificar';
    final historyNumber = patient['history_number'] ??
        patient['history_number_snapshot'] ??
        'N/A';
    final ownerName = patient['owner_name'] ??
        patient['owner_name_snapshot'] ??
        'No especificado';

    return InkWell(
      onTap: () {
        setState(() {
          _currentHistoryNumber = historyNumber;
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
            // Avatar con imagen de raza o fallback por especie
            DataService().buildBreedImageWidget(
              breedId: patient['patient_breed_id'],
              species: species,
              width: 40,
              height: 40,
              borderRadius: 20,
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
              'Historia: $historyNumber',
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
    return Column(
      children: [
        // Topbar para toda la ventana
        _buildTopBar(),
        // Contenido principal
        Expanded(
          child: Row(
            children: [
              // Columna izquierda: Historias Médicas (70%)
              Expanded(flex: 7, child: _buildHistoriesColumn()),
              // Columna derecha: Ficha del Paciente (30%)
              Expanded(flex: 3, child: _buildPatientPanel()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: Row(
        children: [
          // Título
          Text(
            'Historias Médicas',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(width: 24),
          // Barra de búsqueda
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _searchPatients,
                decoration: InputDecoration(
                  hintText: 'Buscar por historia o nombre de mascota...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 14,
                  ),
                  prefixIcon: _isSearching
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF4F46E5),
                              ),
                            ),
                          ),
                        )
                      : const Icon(
                          Iconsax.search_normal,
                          color: Color(0xFF6B7280),
                          size: 18,
                        ),
                  suffixIcon: _currentHistoryNumber != null
                      ? IconButton(
                          onPressed: () => _exportHistory(),
                          icon: const Icon(
                            Iconsax.export_2,
                            color: Color(0xFF6B7280),
                            size: 18,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Botones de acción con diseño quick actions
          // 1. Nuevo Bloque (solo icono)
          _buildQuickActionButton(
            icon: Iconsax.add_square,
            tooltip: 'Nuevo Bloque',
            color: const Color(0xFF16A34A),
            onTap: _currentHistoryNumber == null
                ? null
                : () {
                    _createNewBlock();
                  },
          ),
          const SizedBox(width: 8),
          // 2. Nueva Historia (formulario de nuevo paciente)
          _buildQuickActionButton(
            icon: Iconsax.user_add,
            text: 'Nueva Historia',
            tooltip: 'Crear Nuevo Paciente',
            color: const Color(0xFF3B82F6),
            onTap: () => _openNewPatientForm(),
          ),
          const SizedBox(width: 8),
          // 3. Exportar PDF
          _buildQuickActionButton(
            icon: Iconsax.document_download,
            text: 'Exportar PDF',
            tooltip: 'Exportar Historia a PDF',
            color: const Color(0xFFDC2626),
            onTap: _currentHistoryNumber == null ? null : () => _exportToPDF(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    String? text,
    required String tooltip,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: _AnimatedButton(
        onTap: onTap ?? () {},
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: onTap != null
                ? color.withValues(alpha: .1)
                : const Color(0xFFE5E7EB).withValues(alpha: .5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: onTap != null
                  ? color.withValues(alpha: .3)
                  : const Color(0xFF6B7280).withValues(alpha: .3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: onTap != null ? color : const Color(0xFF6B7280),
              ),
              if (text != null) ...[
                const SizedBox(width: 6),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: onTap != null ? color : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallActionButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: _AnimatedButton(
        onTap: onTap,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: .3), width: 1),
          ),
          child: Icon(icon, size: 12, color: color),
        ),
      ),
    );
  }

  Widget _buildHistoriesColumn() {
    return Container(
      color: AppTheme.neutral50, // background-light
      child: Column(
        children: [
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
                    color: Colors.black.withValues(alpha: 0.05),
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
                        const Icon(
                          Iconsax.search_normal_1,
                          color: Color(0xFF4F46E5),
                          size: 16,
                        ),
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
            child: _currentHistoryNumber == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Iconsax.user_search,
                          size: 64,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Selecciona un paciente',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Para ver sus historias médicas',
                          style: TextStyle(color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  )
                : _isLoadingHistories
                    ? const Center(child: CircularProgressIndicator())
                    : _cachedHistories.isNotEmpty
                        ? _buildHistoriesList(_cachedHistories)
                        : FutureBuilder(
                            future: _future,
                            builder: (context, snap) {
                              if (snap.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              if (snap.hasError) {
                                return Center(
                                    child: Text('Error: ${snap.error}'));
                              }
                              final items = snap.data ?? [];
                              return _buildHistoriesList(items);
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
          // Contenido del panel
          Expanded(
            child: _currentHistoryNumber == null
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.user_search,
                          size: 48,
                          color: AppTheme.neutral500,
                        ),
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
                          child: Text('Error al cargar paciente'),
                        );
                      }
                      if (snap.data == null) {
                        return const Center(
                          child: Text('Paciente no encontrado'),
                        );
                      }
                      final patient = snap.data!;
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(24), // p-6
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Información del paciente
                            Container(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      // Círculo para seleccionar imagen de raza
                                      GestureDetector(
                                        onTap: () => _selectBreedImage(),
                                        child: Container(
                                          width: 64,
                                          height: 64,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: const Color(0xFF4F46E5),
                                              width: 2,
                                            ),
                                          ),
                                          child: ClipOval(
                                            child: DataService()
                                                .buildBreedImageWidget(
                                              breedId: patient['breed_id']
                                                  ?.toString(),
                                              species: patient['species_code']
                                                  ?.toString(),
                                              width: 64,
                                              height: 64,
                                              borderRadius: 32,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    patient['patient_name'] ??
                                                        'Sin nombre',
                                                    style: const TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF1F2937),
                                                    ),
                                                  ),
                                                ),
                                                // Botones de acción como iconos pequeños
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    // Botón Editar
                                                    _buildSmallActionButton(
                                                      icon: Iconsax.edit,
                                                      tooltip:
                                                          'Editar Paciente',
                                                      color: const Color(
                                                        0xFF3B82F6,
                                                      ),
                                                      onTap: () =>
                                                          _navigateToPatients(),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Historia: ${patient['history_number']?.toString().padLeft(6, '0') ?? _currentHistoryNumber!.padLeft(6, '0')}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Información básica en dos filas
                                  _buildPatientInfoRow(
                                    'Especie',
                                    patient['species_label'] ??
                                        'No especificada',
                                  ),
                                  _buildPatientInfoRow(
                                    'Raza',
                                    patient['breed_label'] ?? 'No especificada',
                                  ),
                                  _buildPatientInfoRow(
                                    'Sexo',
                                    patient['sex'] ?? 'No especificado',
                                  ),
                                  _buildPatientInfoRow(
                                    'Temperamento',
                                    patient['temper'] ?? 'No especificado',
                                  ),
                                  _buildPatientInfoRow(
                                    'Edad',
                                    _calculateAge(
                                      patient['birth_date']?.toString(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Signos vitales
                            const Text(
                              'Signos Vitales',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _buildVitalSign('Temperatura', '38.5 °C'),
                                  _buildVitalSign('Respiración', '22 rpm'),
                                  _buildVitalSign('Pulso', '90 ppm'),
                                  _buildVitalSign(
                                    'Hidratación',
                                    'Normal',
                                    isNormal: true,
                                  ),
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
                            _buildChangeItem(
                              'Bloque de historia creado',
                              'Dr. Smith - Hoy a las 10:30 AM',
                            ),
                            _buildChangeItem(
                              'Archivo adjuntado',
                              'analisis_sangre_max.pdf Dr. Smith - Hoy a las 10:32 AM',
                            ),
                            _buildChangeItem(
                              'Bloque de historia bloqueado',
                              'Dr. Smith - 15 Sep a las 09:15 AM',
                            ),
                            _buildChangeItem(
                              'Bloque de historia creado',
                              'Dr. Smith - 15 Sep a las 09:00 AM',
                            ),
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

  Widget _buildVitalSign(String label, String value, {bool isNormal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color:
                  isNormal ? const Color(0xFF16A34A) : const Color(0xFF1F2937),
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
  final _historyNumberController = TextEditingController();
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
    _historyNumberController.dispose();
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
      // Usar history_number manual o generar uno automático
      String historyNumber = _historyNumberController.text.trim();
      if (historyNumber.isEmpty) {
        historyNumber = await _generateUniqueHistoryNumber();
      } else {
        // Validar que el history_number no exista
        final existingPatient = await _supa
            .from('patients')
            .select('id')
            .eq('clinic_id', widget.clinicId)
            .eq('history_number', historyNumber)
            .maybeSingle();

        if (existingPatient != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'El número de historia ya existe. Por favor, use otro número.',
              ),
            ),
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
        'history_number': historyNumber,
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
        Navigator.pop(context, {
          'historyNumber': historyNumber,
          'patientId': patientResponse['id'],
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paciente creado exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al crear paciente: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String> _generateUniqueHistoryNumber() async {
    // Obtener el último history_number de la clínica
    final lastPatient = await _supa
        .from('patients')
        .select('history_number')
        .eq('clinic_id', widget.clinicId)
        .order('history_number', ascending: false)
        .limit(1)
        .maybeSingle();

    int nextNumber = 1;
    if (lastPatient != null && lastPatient['history_number'] != null) {
      final lastHistoryNumber = lastPatient['history_number'].toString();
      if (lastHistoryNumber.length >= 6) {
        nextNumber = int.parse(lastHistoryNumber.substring(2)) +
            1; // Asumiendo formato 00XXXX
      }
    }

    return nextNumber.toString().padLeft(6, '0');
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    String? text,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Tooltip(
      message: text ?? '',
      child: GestureDetector(
        onTap: onTap ?? () {},
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: onTap != null
                ? color.withValues(alpha: .1)
                : const Color(0xFFE5E7EB).withValues(alpha: .5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: onTap != null
                  ? color.withValues(alpha: .3)
                  : const Color(0xFF6B7280).withValues(alpha: .3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: onTap != null ? color : const Color(0xFF6B7280),
              ),
              if (text != null) ...[
                const SizedBox(width: 6),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: onTap != null ? color : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Paciente'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          _buildQuickActionButton(
            icon: Iconsax.save_2,
            text: 'Guardar',
            color: const Color(0xFF4F46E5),
            onTap: _isLoading ? null : _savePatient,
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
                      controller: _historyNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Número de Historia (6 dígitos)',
                        border: OutlineInputBorder(),
                        helperText: 'Dejar vacío para generar automáticamente',
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          if (value.trim().length != 6) {
                            return 'El número de historia debe tener 6 dígitos';
                          }
                          if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
                            return 'El número de historia debe contener solo números';
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
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
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
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
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

/// Widget de botón animado reutilizable
class _AnimatedButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const _AnimatedButton({required this.onTap, required this.child});

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _controller.forward();
    await _controller.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleTap,
              borderRadius: BorderRadius.circular(8),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}
