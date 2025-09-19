import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:file_picker/file_picker.dart';
import 'package:iconsax/iconsax.dart';
import 'package:zuliadog/features/services/history_service.dart';
import 'package:zuliadog/features/services/patient_service.dart';
import 'package:zuliadog/features/services/timeline_service.dart';
import 'package:zuliadog/features/services/supabase_data_seeder.dart';
import '../menu.dart';
import '../../core/navigation.dart';
import '../data/buscador.dart';

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
  final _patientService = PatientService();
  final _timelineService = TimelineService();

  PatientSummary? _patient;
  List<HistoryBlock> _blocks = [];
  List<TimelineEvent> _timeline = [];
  bool _loading = true;
  String? _selectedPatientId;
  bool _showHistoryEditor = false;
  bool _showLitterCreator = false;
  bool _showPatientEditor = false;
  String _currentHistoryNumber = '';

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

  Future<void> _initializeDateFormatting() async {
    await initializeDateFormatting('es_VE', null);
  }

  Future<void> _loadAll() async {
    final patientId = _selectedPatientId;
    if (patientId == null) {
      setState(() => _loading = false);
      return;
    }

    setState(() => _loading = true);
    try {
      final p = await _patientService.getPatientSummary(patientId);
      final list = await _historyService.getHistoryBlocks(patientId);
      final tl = await _timelineService.getTimeline(patientId);
      setState(() {
        _patient = p;
        _blocks = list;
        _timeline = tl;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar historias: $e')),
      );
    }
  }

  void _onPatientSelected(String patientId) {
    setState(() {
      _selectedPatientId = patientId;
    });
    _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF4F46E5),
            ),
      ),
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
                      ? _LoadingState()
                      : _selectedPatientId == null
                          ? _NoPatientSelectedView(
                              onPatientSelected: _onPatientSelected,
                            )
                          : Row(
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
                            ),
                ),
              ],
            ),
            // Modales
            if (_showHistoryEditor) _buildHistoryEditorModal(),
            if (_showLitterCreator) _buildLitterCreatorModal(),
            if (_showPatientEditor) _buildPatientEditorModal(),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoriaMedica(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con búsqueda
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar por MRN o nombre de mascota...',
              prefixIcon: const Icon(Iconsax.search_normal),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 24),

          // Lista de bloques
          Expanded(
            child: _blocks.isEmpty
                ? _EmptyState()
                : ListView.builder(
                    itemCount: _blocks.length,
                    itemBuilder: (context, index) {
                      final block = _blocks[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: HistoryBlockCard(
                          block: block,
                          dateFmt: DateFormat('d MMMM y, h:mm a', 'es_VE'),
                          onToggleLock: (locked) async {
                            await _historyService.toggleBlockLock(
                                block.id, locked);
                            setState(() {
                              final idx =
                                  _blocks.indexWhere((b) => b.id == block.id);
                              if (idx != -1) {
                                _blocks[idx] =
                                    _blocks[idx].copyWith(locked: locked);
                              }
                            });
                          },
                          onSaveDelta: (deltaJson) async {
                            await _historyService.updateBlockContent(
                                block.id, deltaJson);
                          },
                          onAddFiles: (files) async {
                            // TODO: Implementar carga de archivos
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFichaPaciente(BuildContext context) {
    if (_patient == null) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Ficha del Paciente
          Card(
            margin: const EdgeInsets.all(16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar y nombre
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor:
                            const Color(0xFF4F46E5).withOpacity(0.1),
                        child: const Icon(
                          Iconsax.pet,
                          size: 40,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _patient!.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'N° de historia: ${_patient!.id}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  // Información del paciente
                  _buildInfoRow('Especie', _patient!.species),
                  _buildInfoRow('Raza', _patient!.breed),
                  _buildInfoRow('Sexo', _patient!.sex),
                  _buildInfoRow('Edad', _patient!.ageLabel),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  // Signos vitales
                  Text(
                    'Signos Vitales',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildVitalSign('Temperatura', '${_patient!.temperature} °C',
                      Colors.green),
                  _buildVitalSign('Respiración', '${_patient!.respiration} rpm',
                      Colors.green),
                  _buildVitalSign(
                      'Pulso', '${_patient!.pulse} ppm', Colors.green),
                  _buildVitalSign(
                      'Hidratación', _patient!.hydration, Colors.green),
                ],
              ),
            ),
          ),
          // Historial de Cambios
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Historial de Cambios',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _timeline.length,
                      itemBuilder: (context, index) {
                        final event = _timeline[index];
                        return _TimelineItem(event: event);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalSign(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsRow() {
    return Row(
      children: [
        _QuickActionButton(
          icon: Iconsax.add_circle,
          label: 'Nueva Historia',
          color: const Color(0xFF4F46E5),
          onPressed: () {
            setState(() {
              _showHistoryEditor = true;
              _currentHistoryNumber = '';
            });
          },
        ),
        const SizedBox(width: 8),
        _QuickActionButton(
          icon: Iconsax.pet,
          label: 'Crear Camada',
          color: Colors.orange,
          onPressed: () {
            setState(() {
              _showLitterCreator = true;
            });
          },
        ),
        const SizedBox(width: 8),
        _QuickActionButton(
          icon: Iconsax.edit,
          label: 'Editar Paciente',
          color: Colors.blue,
          onPressed: () {
            setState(() {
              _showPatientEditor = true;
            });
          },
        ),
      ],
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Historia'),
        content: const Text(
            '¿Estás seguro de que quieres eliminar esta historia médica? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Historia eliminada'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeceasedConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Marcar como Fallecido'),
        content: const Text(
            '¿Estás seguro de que quieres marcar este paciente como fallecido?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Paciente marcado como fallecido'),
                  backgroundColor: Colors.grey,
                ),
              );
            },
            child:
                const Text('Confirmar', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
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
                          hintText: 'Ej: 001515',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) => _currentHistoryNumber = value,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: TextField(
                          maxLines: null,
                          decoration: InputDecoration(
                            labelText: 'Contenido de la Historia',
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
                              onPressed: () {
                                setState(() => _showHistoryEditor = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Historia guardada exitosamente'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
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

  Widget _buildLitterCreatorModal() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 500,
          height: 400,
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
                    const Icon(Iconsax.pet, color: Colors.orange),
                    const SizedBox(width: 12),
                    const Text(
                      'Crear Camada',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () =>
                          setState(() => _showLitterCreator = false),
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
                          labelText: 'Número de Historia de la Madre',
                          hintText: 'Ej: 001515',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Cantidad de Cachorros',
                          hintText: 'Ej: 8',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ejemplo de numeración:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Si la madre es 001515 y hay 8 cachorros:\n• 001515 A\n• 001515 B\n• 001515 C\n• ... hasta 001515 H',
                              style: TextStyle(color: Colors.orange[700]),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  setState(() => _showLitterCreator = false),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() => _showLitterCreator = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Camada creada exitosamente'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Crear Camada'),
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

  Widget _buildPatientEditorModal() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 500,
          height: 600,
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
                    const Icon(Iconsax.edit, color: Colors.blue),
                    const SizedBox(width: 12),
                    const Text(
                      'Editar Información del Paciente',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () =>
                          setState(() => _showPatientEditor = false),
                      icon: const Icon(Iconsax.close_circle),
                    ),
                  ],
                ),
              ),
              // Contenido
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Nombre',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Especie',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Raza',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Propietario',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Teléfono',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Fecha de Nacimiento',
                            hintText: 'YYYY-MM-DD',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    setState(() => _showPatientEditor = false),
                                child: const Text('Cancelar'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() => _showPatientEditor = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Información del paciente actualizada'),
                                      backgroundColor: Colors.blue,
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Guardar Cambios'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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

class _NoPatientSelectedView extends StatefulWidget {
  final Function(String) onPatientSelected;

  const _NoPatientSelectedView({required this.onPatientSelected});

  @override
  State<_NoPatientSelectedView> createState() => _NoPatientSelectedViewState();
}

class _NoPatientSelectedViewState extends State<_NoPatientSelectedView> {
  final _searchController = TextEditingController();
  final _searchRepo = SearchRepository();
  List<PatientSearchRow> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      final results = await _searchRepo.search(query);
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selecciona un Paciente',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por MRN o nombre de mascota...',
              prefixIcon: const Icon(Iconsax.search_normal),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: _searchPatients,
          ),
          const SizedBox(height: 24),

          // Acciones rápidas
          _buildQuickActionsRow(),
          const SizedBox(height: 24),

          // Área de historias recientes
          _buildRecentHistoriesSection(),
          const SizedBox(height: 24),
          if (_isSearching)
            const Center(child: CircularProgressIndicator())
          else if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
            const Center(
              child: Text('No se encontraron pacientes'),
            )
          else if (_searchResults.isEmpty)
            const Center(
              child: Text('Ingresa un término de búsqueda para comenzar'),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final patient = _searchResults[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF4F46E5),
                        child: Icon(
                          Iconsax.pet,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(patient.patientName),
                      subtitle: Text('MRN: ${patient.historyNumber ?? 'N/A'}'),
                      onTap: () => widget.onPatientSelected(patient.patientId),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsRow() {
    return Row(
      children: [
        _QuickActionButton(
          icon: Iconsax.add_circle,
          label: 'Nueva Historia',
          color: const Color(0xFF4F46E5),
          onPressed: () {
            // TODO: Implementar nueva historia
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Nueva Historia (pendiente)')),
            );
          },
        ),
        const SizedBox(width: 8),
        _QuickActionButton(
          icon: Iconsax.pet,
          label: 'Crear Camada',
          color: Colors.orange,
          onPressed: () {
            // TODO: Implementar crear camada
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Crear Camada (pendiente)')),
            );
          },
        ),
        const SizedBox(width: 8),
        _QuickActionButton(
          icon: Iconsax.edit,
          label: 'Editar Paciente',
          color: Colors.blue,
          onPressed: () {
            // TODO: Implementar editar paciente
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Editar Paciente (pendiente)')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentHistoriesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.clock, color: Colors.grey[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Últimas 5 Historias',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ver todas las historias')),
                  );
                },
                child: const Text('Ver todas'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Tabla de historias médicas
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1.5),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(1.2),
              3: FlexColumnWidth(1.2),
              4: FlexColumnWidth(1.2),
              5: FlexColumnWidth(1.5),
              6: FlexColumnWidth(1),
            },
            children: [
              // Header
              TableRow(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                ),
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Número de Historia',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Nombre',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Especie',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Edad',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Raza',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Última Edición',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Acciones',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              // Filas de datos - últimas 5 historias
              ...List.generate(5, (index) {
                final histories = [
                  {
                    'name': 'Max',
                    'mrn': '001515',
                    'lastEdit': 'Hoy 14:30',
                    'species': 'Canino',
                    'age': '3 años',
                    'breed': 'Golden Retriever',
                  },
                  {
                    'name': 'Luna',
                    'mrn': '001516',
                    'lastEdit': 'Ayer 16:45',
                    'species': 'Felino',
                    'age': '2 años',
                    'breed': 'Persa',
                  },
                  {
                    'name': 'Bella',
                    'mrn': '001517',
                    'lastEdit': '2 días',
                    'species': 'Canino',
                    'age': '5 años',
                    'breed': 'Labrador',
                  },
                  {
                    'name': 'Simba',
                    'mrn': '001518',
                    'lastEdit': '3 días',
                    'species': 'Felino',
                    'age': '1 año',
                    'breed': 'Siamés',
                  },
                  {
                    'name': 'Rocky',
                    'mrn': '001519',
                    'lastEdit': '1 semana',
                    'species': 'Canino',
                    'age': '4 años',
                    'breed': 'Pastor Alemán',
                  },
                ];

                final history = histories[index];

                return TableRow(
                  decoration: BoxDecoration(
                    border:
                        Border(bottom: BorderSide(color: Colors.grey[200]!)),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        history['mrn'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        history['name'] as String,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        history['species'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        history['age'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        history['breed'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        history['lastEdit'] as String,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Ver historia de ${history['name']}')),
                              );
                            },
                            icon: Icon(
                              Iconsax.eye,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(
                              minWidth: 24,
                              minHeight: 24,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Descargar historia de ${history['name']}')),
                              );
                            },
                            icon: Icon(
                              Iconsax.document_download,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(
                              minWidth: 24,
                              minHeight: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}

class HistoryBlockCard extends StatefulWidget {
  final HistoryBlock block;
  final DateFormat dateFmt;
  final Function(bool) onToggleLock;
  final Function(String) onSaveDelta;
  final Function(List<PlatformFile>) onAddFiles;

  const HistoryBlockCard({
    super.key,
    required this.block,
    required this.dateFmt,
    required this.onToggleLock,
    required this.onSaveDelta,
    required this.onAddFiles,
  });

  @override
  State<HistoryBlockCard> createState() => _HistoryBlockCardState();
}

class _HistoryBlockCardState extends State<HistoryBlockCard> {
  late TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Limpiar el JSON y mostrar solo el contenido real
    String displayText = widget.block.deltaJson;
    if (displayText.startsWith('{"ops":[{"insert":"') &&
        displayText.endsWith('"}]}')) {
      // Extraer el texto real del JSON
      try {
        final jsonData = jsonDecode(displayText);
        if (jsonData['ops'] != null && jsonData['ops'].isNotEmpty) {
          displayText = jsonData['ops'][0]['insert'] ?? '';
        }
      } catch (e) {
        displayText = '';
      }
    }
    _controller = TextEditingController(text: displayText);
    _controller.addListener(() {
      if (widget.block.locked) return;
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 700), () async {
        // Convertir a formato delta cuando se guarde
        final deltaJson =
            '{"ops":[{"insert":"${_controller.text.replaceAll('"', '\\"').replaceAll('\n', '\\n')}"}]}';
        await widget.onSaveDelta(deltaJson);
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.block;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // HEADER con borde inferior
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.dateFmt.format(b.createdAt),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      b.author,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Estado clickeable
                    GestureDetector(
                      onTap: () async {
                        await widget.onToggleLock(!b.locked);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: b.locked
                              ? Colors.red.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: b.locked ? Colors.red : Colors.green,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              b.locked ? Iconsax.lock : Iconsax.unlock,
                              size: 16,
                              color: b.locked ? Colors.red : Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              b.locked ? 'Bloqueado' : 'Editable',
                              style: TextStyle(
                                color: b.locked ? Colors.red : Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        // TODO: Menú de opciones
                      },
                      icon: const Icon(Iconsax.more),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Contenido del bloque
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Editor
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Toolbar simple
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Spacer(),
                            GestureDetector(
                              onTap: () async {
                                await widget.onToggleLock(!b.locked);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: b.locked
                                      ? Colors.red.withOpacity(0.1)
                                      : Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: b.locked ? Colors.red : Colors.green,
                                    width: 1,
                                  ),
                                ),
                                child: Container(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Editor
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: TextField(
                          controller: _controller,
                          readOnly: b.locked,
                          maxLines: null,
                          minLines: 3,
                          decoration: InputDecoration(
                            hintText: b.locked
                                ? 'Este bloque está bloqueado y no se puede editar'
                                : 'Ingresa la información aquí...\n\nEjemplo:\n• Síntomas observados\n• Diagnóstico\n• Tratamiento aplicado\n• Recomendaciones',
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              color: b.locked
                                  ? Colors.grey[400]
                                  : Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Adjuntos
                if (b.attachments.isNotEmpty) ...[
                  const Text(
                    'Archivos adjuntos:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: b.attachments.map((att) {
                      return GestureDetector(
                        onTap: () async {
                          // TODO: Implementar apertura de archivos
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border:
                                Border.all(color: Colors.blue.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Iconsax.attach_circle,
                                  size: 16, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text(
                                att.name,
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 12),
                // Área de drag & drop
                _FileDropArea(
                  onFilesSelected: widget.onAddFiles,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FileDropArea extends StatelessWidget {
  final Function(List<PlatformFile>) onFilesSelected;

  const _FileDropArea({required this.onFilesSelected});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await FilePicker.platform.pickFiles(
          allowMultiple: true,
          type: FileType.any,
        );
        if (result != null) {
          onFilesSelected(result.files);
        }
      },
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 80,
          maxHeight: 120,
        ),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Iconsax.cloud_add,
                  size: 32,
                  color: Theme.of(context).hintColor,
                ),
                const SizedBox(height: 8),
                Text(
                  'Arrastra y suelta archivos aquí',
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'o haz clic para seleccionar',
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Cargando historias médicas...'),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.health,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay historias médicas',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selecciona un paciente para ver su historial médico',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final TimelineEvent event;
  const _TimelineItem({required this.event});

  @override
  Widget build(BuildContext context) {
    final date =
        DateFormat('d MMM y, HH:mm', 'es_VE').format(event.at.toLocal());
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Container(
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.only(left: 14, bottom: 14),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (event.subtitle != null)
                  Text(
                    event.subtitle!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                Text(
                  date,
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ),
        ),
        // Punto
        Positioned(
          top: 2,
          left: 2,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: event.dotColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

/// Canvas flotante para crear historias médicas y pacientes
class _FloatingHistoryCreator extends StatefulWidget {
  final VoidCallback onHistoryCreated;

  const _FloatingHistoryCreator({required this.onHistoryCreated});

  @override
  State<_FloatingHistoryCreator> createState() =>
      _FloatingHistoryCreatorState();
}

class _FloatingHistoryCreatorState extends State<_FloatingHistoryCreator> {
  bool _isExpanded = false;
  String _selectedAction = 'history'; // 'history' o 'patient'
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _patientNameController = TextEditingController();
  final TextEditingController _patientSpeciesController =
      TextEditingController();
  final TextEditingController _patientBreedController = TextEditingController();
  final _historyService = HistoryService();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _patientNameController.dispose();
    _patientSpeciesController.dispose();
    _patientBreedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isExpanded ? 450 : 60,
      height: _isExpanded ? 600 : 60,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(_isExpanded ? 16 : 30),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_isExpanded ? 16 : 30),
            border: Border.all(
              color: const Color(0xFF4F46E5).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: _isExpanded ? _buildExpandedView() : _buildCollapsedView(),
        ),
      ),
    );
  }

  Widget _buildCollapsedView() {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = true),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF4F46E5),
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Center(
          child: Icon(
            Iconsax.add,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedView() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                _selectedAction == 'history'
                    ? Iconsax.document_text
                    : Iconsax.pet,
                color: const Color(0xFF4F46E5),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _selectedAction == 'history'
                    ? 'Nueva Historia'
                    : 'Nuevo Paciente',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4F46E5),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _isExpanded = false),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Iconsax.close_circle,
                    size: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Selector de acción
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedAction = 'history'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _selectedAction == 'history'
                          ? const Color(0xFF4F46E5).withOpacity(0.1)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedAction == 'history'
                            ? const Color(0xFF4F46E5)
                            : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.document_text,
                          size: 16,
                          color: _selectedAction == 'history'
                              ? const Color(0xFF4F46E5)
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Historia',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _selectedAction == 'history'
                                ? const Color(0xFF4F46E5)
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedAction = 'patient'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _selectedAction == 'patient'
                          ? const Color(0xFF4F46E5).withOpacity(0.1)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedAction == 'patient'
                            ? const Color(0xFF4F46E5)
                            : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.pet,
                          size: 16,
                          color: _selectedAction == 'patient'
                              ? const Color(0xFF4F46E5)
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Paciente',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _selectedAction == 'patient'
                                ? const Color(0xFF4F46E5)
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Formulario dinámico
          Expanded(
            child: _selectedAction == 'history'
                ? _buildHistoryForm()
                : _buildPatientForm(),
          ),
          const SizedBox(height: 16),

          // Botones
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _isExpanded = false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _createHistory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(_selectedAction == 'history'
                      ? 'Crear Historia'
                      : 'Crear Paciente'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryForm() {
    return Column(
      children: [
        // Título
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'Título de la historia',
            hintText: 'Ej: Consulta de rutina',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Contenido
        Expanded(
          child: TextField(
            controller: _contentController,
            maxLines: null,
            decoration: InputDecoration(
              labelText: 'Contenido',
              hintText:
                  'Escribe la historia médica aquí...\n\nEjemplo:\n• Síntomas observados\n• Diagnóstico\n• Tratamiento\n• Recomendaciones',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.all(12),
              alignLabelWithHint: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPatientForm() {
    return Column(
      children: [
        // Nombre del paciente
        TextField(
          controller: _patientNameController,
          decoration: InputDecoration(
            labelText: 'Nombre del paciente',
            hintText: 'Ej: Max, Luna, Bella',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Especie
        TextField(
          controller: _patientSpeciesController,
          decoration: InputDecoration(
            labelText: 'Especie',
            hintText: 'Ej: Canino, Felino, Ave',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Raza
        TextField(
          controller: _patientBreedController,
          decoration: InputDecoration(
            labelText: 'Raza',
            hintText: 'Ej: Labrador, Persa, Golden Retriever',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Información adicional
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Información adicional',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Se creará un MRN automático\n• Los signos vitales se establecerán como normales\n• Podrás editar toda la información después',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _createHistory() async {
    if (_selectedAction == 'history') {
      // Validar formulario de historia
      if (_titleController.text.trim().isEmpty ||
          _contentController.text.trim().isEmpty) {
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
        final blockId = await _historyService.createHistoryBlock(
          patientId: 'demo-patient-${DateTime.now().millisecondsSinceEpoch}',
          author: 'Dr. Veterinario',
        );

        // Actualizar el contenido
        final deltaJson =
            '{"ops":[{"insert":"${_contentController.text.replaceAll('"', '\\"').replaceAll('\n', '\\n')}"}]}';
        await _historyService.updateBlockContent(blockId, deltaJson);

        // Limpiar formulario
        _titleController.clear();
        _contentController.clear();

        // Cerrar el canvas
        setState(() => _isExpanded = false);

        // Notificar que se creó la historia
        widget.onHistoryCreated();

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
    } else {
      // Validar formulario de paciente
      if (_patientNameController.text.trim().isEmpty ||
          _patientSpeciesController.text.trim().isEmpty ||
          _patientBreedController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor completa todos los campos del paciente'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      try {
        // Crear paciente usando el seeder
        final seeder = SupabaseDataSeeder();
        await seeder.createPatient(
          name: _patientNameController.text.trim(),
          species: _patientSpeciesController.text.trim(),
          breed: _patientBreedController.text.trim(),
        );

        // Limpiar formulario
        _patientNameController.clear();
        _patientSpeciesController.clear();
        _patientBreedController.clear();

        // Cerrar el canvas
        setState(() => _isExpanded = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paciente creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear paciente: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
