import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:iconsax/iconsax.dart';
import 'package:zuliadog/features/services/history_service.dart';
import 'package:zuliadog/features/widgets/history_widgets.dart';
import 'package:zuliadog/features/widgets/search_widgets.dart';
import 'package:zuliadog/features/widgets/patient_panel_widgets.dart';
import 'package:zuliadog/features/widgets/medical_records_list.dart';
import '../menu.dart';
import '../../core/navigation.dart';
import '../../core/responsive_wrapper.dart';

/// =========================
/// WIDGETS PRINCIPALES
/// =========================

class HistoriasPage extends StatefulWidget {
  static const String route = '/historias';

  final String? patientId;
  final String authorName;

  const HistoriasPage({
    super.key,
    this.patientId,
    this.authorName = 'Veterinaria',
  });

  @override
  State<HistoriasPage> createState() => _HistoriasPageState();
}

class _HistoriasPageState extends State<HistoriasPage> {
  final _historyService = HistoryService();

  // Estado de la UI
  PatientSummary? _patient;
  List<TimelineEvent> _timeline = [];
  bool _loading = true;
  String? _selectedPatientId;
  bool _showHistoryEditor = false;

  // Variables para búsqueda
  final _searchController = TextEditingController();
  List<PatientSearchRow> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _initializeDateFormatting();
    _selectedPatientId = widget.patientId;
    if (_selectedPatientId != null) {
      _loadAll();
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeDateFormatting() async {
    await initializeDateFormatting('es_VE', null);
  }

  Future<void> _loadAll() async {
    final patientMrn = _selectedPatientId;
    if (patientMrn == null) {
      setState(() => _loading = false);
      return;
    }

    setState(() => _loading = true);
    try {
      // TODO: Obtener clinicId del contexto de usuario
      final clinicId = '4c17fddf-24ab-4a8d-9343-4cc4f6a4a203';

      print('🔄 Cargando datos para paciente: $patientMrn');

      // Usar el nuevo método fetchRecords para obtener historias
      final records = await _historyService.fetchRecords(
        clinicId: clinicId,
        mrn: patientMrn,
      );

      // Obtener información del paciente
      final p = await _historyService.getPatientSummary(patientMrn);

      // Convertir records a HistoryBlocks si es necesario
      final list = await _historyService.getHistoryBlocks(patientMrn,
          clinicId: clinicId);

      // Obtener timeline
      final tl = await _historyService.getTimeline(patientMrn);

      print(
          '📊 Datos cargados - Paciente: ${p?.name}, Historias: ${records.length}, Bloques: ${list.length}');

      setState(() {
        _patient = p;
        _timeline = tl;
        _loading = false;
      });
    } catch (e) {
      print('❌ Error al cargar historias: $e');
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar historias: $e')),
      );
    }
  }

  void _onPatientSelected(String patientMrn) {
    setState(() {
      _selectedPatientId = patientMrn;
    });
    _loadAll();
  }

  Future<void> _searchPatients(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await _historyService.searchPatients(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      print('Error en búsqueda: $e');
    }
  }

  Future<void> _createHistoryFromModal() async {
    // Crear controladores para el modal
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    // Mostrar el modal con los controladores
    await showDialog(
      context: context,
      builder: (context) => HistoryEditorDialog(
        titleController: titleController,
        contentController: contentController,
        onSave: () async {
          // Validar formulario
          if (titleController.text.trim().isEmpty ||
              contentController.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Por favor completa el título y contenido'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }

          try {
            // Crear el bloque de historia
            final deltaJson =
                '{"ops":[{"insert":"${contentController.text.replaceAll('"', '\\"').replaceAll('\n', '\\n')}"}]}';

            final blockId = await _historyService.createHistoryBlock(
              patientMrn: _selectedPatientId ?? 'test-patient-1',
              author: 'Dr. Veterinario',
              title: titleController.text.trim().isNotEmpty
                  ? titleController.text.trim()
                  : 'Nueva historia médica',
              clinicId: '4c17fddf-24ab-4a8d-9343-4cc4f6a4a203',
            );

            // Actualizar el contenido
            await _historyService.updateBlockContent(
              blockId,
              deltaJson,
              clinicId: '4c17fddf-24ab-4a8d-9343-4cc4f6a4a203',
            );

            // Cerrar el modal
            Navigator.of(context).pop();

            // Recargar los datos
            await _loadAll();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Historia creada exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al crear historia: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _savePatientInfo(Map<String, dynamic> patientData) async {
    if (_patient == null) return;

    try {
      // Usar el servicio consolidado
      await _historyService.updatePatientInfo(
        _selectedPatientId ?? _patient!.id,
        patientData,
      );

      // Recargar los datos
      await _loadAll();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Información del paciente actualizada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar paciente: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF4F46E5),
            ),
      ),
      child: MinSizePage(
        minWidth: 1200.0, // Mismo tamaño que el resto de la app
        minHeight: 800.0,
        child: Scaffold(
          backgroundColor: Colors.grey[50],
          body: Stack(
            children: [
              Row(
                children: [
                  // Sidebar
                  AppSidebar(
                    activeRoute: 'frame_historias',
                    onTap: (route) {
                      if (route != 'frame_historias') {
                        NavigationHelper.navigateToRoute(context, '/home');
                      }
                    },
                    userRole: UserRole.doctor,
                  ),
                  // Contenido principal
                  Expanded(
                    child: _loading
                        ? const LoadingHistoryState()
                        : _selectedPatientId == null
                            ? NoPatientSelectedView(
                                onPatientSelected: _onPatientSelected,
                              )
                            : _buildPatientHistoryView(context),
                  ),
                ],
              ),
              // Modales
              if (_showHistoryEditor) _buildHistoryEditorModal(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientHistoryView(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Columna izquierda (historia): 70% del ancho
        Expanded(
          flex: 7,
          child: _buildHistoriaMedica(context),
        ),
        // Columna derecha (ficha del paciente): 30% del ancho
        Expanded(
          flex: 3,
          child: _buildFichaPaciente(context),
        ),
      ],
    );
  }

  Widget _buildHistoriaMedica(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con búsqueda funcional y botón para volver
          Row(
            children: [
              Expanded(
                child: PatientSearchField(
                  searchController: _searchController,
                  searchResults: _searchResults,
                  isSearching: _isSearching,
                  onSearchChanged: _searchPatients,
                  onPatientSelected: (patient) {
                    _searchController.clear();
                    _onPatientSelected(patient.patientId);
                    setState(() {
                      _searchResults = [];
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Botón para volver a la vista de búsqueda
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedPatientId = null;
                    _patient = null;
                    _timeline = [];
                    _searchController.clear();
                    _searchResults = [];
                  });
                },
                icon: const Icon(Iconsax.arrow_left_2),
                label: const Text('Cambiar Paciente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  foregroundColor: Colors.grey[700],
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Lista de historias médicas usando el nuevo widget
          Expanded(
            child: MedicalRecordsList(
              clinicId:
                  '4c17fddf-24ab-4a8d-9343-4cc4f6a4a203', // TODO: Obtener del contexto
              mrn: _selectedPatientId!,
              historyService: _historyService,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFichaPaciente(BuildContext context) {
    return Column(
      children: [
        // Panel de información del paciente
        PatientInfoPanel(
          patient: _patient,
          onSavePatientInfo: _savePatientInfo,
        ),
        // Panel del timeline
        PatientTimelinePanel(timeline: _timeline),
      ],
    );
  }

  Widget _buildHistoryEditorModal() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 600,
          height: 500,
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Row(
                  children: [
                    const Icon(Iconsax.document_text, color: Color(0xFF4F46E5)),
                    const SizedBox(width: 12),
                    const Text(
                      'Editor de Historia Médica',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () =>
                          setState(() => _showHistoryEditor = false),
                      icon: const Icon(Iconsax.close_circle),
                    ),
                  ],
                ),
              ),
              // Contenido
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Número de Historia',
                          hintText: 'Ingresa el número de historia',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          // TODO: Manejar cambio de número de historia
                        },
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: TextField(
                          maxLines: null,
                          decoration: InputDecoration(
                            labelText: 'Describe la consulta o tratamiento',
                            hintText: 'Escribe aquí la historia médica...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignLabelWithHint: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  setState(() => _showHistoryEditor = false),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                await _createHistoryFromModal();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Guardar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
