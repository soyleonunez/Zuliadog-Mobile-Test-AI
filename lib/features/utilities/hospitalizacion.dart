import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/hospitalization_topbar.dart';
import 'widgets/hospitalized_patients_widget.dart';
import 'widgets/calendar_gantt_widget.dart';
import 'widgets/treatments_widget.dart';
import 'widgets/detail_panel_widget.dart';
import '../menu.dart';
import '../home.dart' as home;
import '../../core/navigation.dart';
import 'historias.dart';
import 'recetas.dart';
import 'laboratorio.dart';
import 'agenda.dart';
import 'recursos.dart';
import 'tickets.dart';
import 'reportes.dart';

final _supa = Supabase.instance.client;

class HospitalizacionPage extends StatelessWidget {
  const HospitalizacionPage({super.key});

  static const route = '/hospitalizacion';

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        focusColor: home.AppColors.primary500.withOpacity(.12),
        hoverColor: home.AppColors.neutral50,
        splashColor: home.AppColors.primary500.withOpacity(.08),
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: home.AppColors.primary500,
              secondary: home.AppColors.primary600,
              surface: Colors.white,
              onSurface: home.AppColors.neutral900,
            ),
      ),
      child: Scaffold(
        backgroundColor: home.AppColors.neutral50,
        body: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSidebar(
                  activeRoute: 'frame_hospitalizacion',
                  onTap: (route) => _handleNavigation(context, route),
                  userRole: UserRole.doctor,
                ),
                Expanded(
                  child: HospitalizacionPanel(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleNavigation(BuildContext context, String route) {
    if (route == 'frame_hospitalizacion') {
      // Ya estamos en hospitalización
    } else {
      // Navegar a la página correspondiente
      String routePath = '/home'; // fallback
      switch (route) {
        case 'frame_pacientes':
          routePath = '/pacientes';
          break;
        case 'frame_historias':
          routePath = HistoriasPage.route;
          break;
        case 'frame_recetas':
          routePath = RecetasPage.route;
          break;
        case 'frame_laboratorio':
          routePath = LaboratorioPage.route;
          break;
        case 'frame_agenda':
          routePath = AgendaPage.route;
          break;
        case 'frame_hospitalizacion':
          routePath = HospitalizacionPage.route;
          break;
        case 'frame_recursos':
          routePath = RecursosPage.route;
          break;
        case 'frame_tickets':
          routePath = TicketsPage.route;
          break;
        case 'frame_reportes':
          routePath = ReportesPage.route;
          break;
      }
      NavigationHelper.navigateToRoute(context, routePath);
    }
  }
}

// Modelos de datos actualizados para nuevas tablas
class HospitalizedPatient {
  final String id;
  final String patientName;
  final String mrn;
  final int? mrnInt;
  final String sex;
  final DateTime? birthDate;
  final String? speciesId;
  final String speciesLabel;
  final String? breedId;
  final String breedLabel;
  final String? breedImageUrl;
  final String? temperament;
  final String? ownerId;
  final String? ownerName;
  final String? ownerPhone;
  final String? ownerEmail;
  final String? ownerAddress;
  final String? hospitalizationId;
  final DateTime? admissionDate;
  final DateTime? dischargeDate;
  final String? hospitalizationStatus;
  final String? hospitalizationPriority;
  final String? roomNumber;
  final String? bedNumber;
  final String? diagnosis;
  final String? treatmentPlan;
  final String? specialInstructions;
  final String? assignedVet;
  final DateTime? hospitalizationCreatedAt;
  final String? assignedVetEmail;
  final String? assignedVetName;
  final int pendingTasks;
  final int completedTasks;
  final int overdueTasks;
  final int importantNotes;
  final int todayNotes;
  final int todayCompletions;
  final DateTime? lastActivity;

  HospitalizedPatient({
    required this.id,
    required this.patientName,
    required this.mrn,
    this.mrnInt,
    required this.sex,
    this.birthDate,
    this.speciesId,
    required this.speciesLabel,
    this.breedId,
    required this.breedLabel,
    this.breedImageUrl,
    this.temperament,
    this.ownerId,
    this.ownerName,
    this.ownerPhone,
    this.ownerEmail,
    this.ownerAddress,
    this.hospitalizationId,
    this.admissionDate,
    this.dischargeDate,
    this.hospitalizationStatus,
    this.hospitalizationPriority,
    this.roomNumber,
    this.bedNumber,
    this.diagnosis,
    this.treatmentPlan,
    this.specialInstructions,
    this.assignedVet,
    this.hospitalizationCreatedAt,
    this.assignedVetEmail,
    this.assignedVetName,
    required this.pendingTasks,
    required this.completedTasks,
    required this.overdueTasks,
    required this.importantNotes,
    required this.todayNotes,
    required this.todayCompletions,
    this.lastActivity,
  });

  factory HospitalizedPatient.fromJson(Map<String, dynamic> data) {
    return HospitalizedPatient(
      id: data['patient_id'] ?? '',
      patientName: data['patient_name'] ?? '',
      mrn: data['history_number'] ??
          data['mrn'] ??
          data['patient_mrn'] ??
          data['history_number_snapshot'] ??
          data['mrn_int']?.toString() ??
          '',
      mrnInt: data['mrn_int'],
      sex: data['sex'] ?? '',
      birthDate: data['birth_date'] != null
          ? DateTime.tryParse(data['birth_date'])
          : null,
      speciesId: data['species_code'],
      speciesLabel: data['species_label'] ?? 'Sin especificar',
      breedId: data['breed_id'],
      breedLabel: data['breed_label'] ?? 'Sin especificar',
      breedImageUrl: data['breed_image_url'],
      temperament:
          data['temper'] ?? data['temperament'] ?? 'Suave', // Ensure fallback
      ownerId: data['owner_id'],
      ownerName: data['owner_name'],
      ownerPhone: data['owner_phone'],
      ownerEmail: data['owner_email'],
      ownerAddress: data['owner_address'],
      hospitalizationId: data['hospitalization_id'],
      admissionDate: data['admission_date'] != null
          ? DateTime.tryParse(data['admission_date'])
          : null,
      dischargeDate: data['discharge_date'] != null
          ? DateTime.tryParse(data['discharge_date'])
          : null,
      hospitalizationStatus: data['hospitalization_status'],
      hospitalizationPriority: data['hospitalization_priority'],
      roomNumber: data['room_number'],
      bedNumber: data['bed_number'],
      diagnosis: data['diagnosis'],
      treatmentPlan: data['treatment_plan'],
      specialInstructions: data['special_instructions'],
      assignedVet: data['assigned_vet'],
      hospitalizationCreatedAt: data['hospitalization_created_at'] != null
          ? DateTime.tryParse(data['hospitalization_created_at'])
          : null,
      assignedVetEmail: data['assigned_vet_email'],
      assignedVetName: data['assigned_vet_name'],
      pendingTasks: data['pending_tasks'] ?? 0,
      completedTasks: data['completed_tasks'] ?? 0,
      overdueTasks: data['overdue_tasks'] ?? 0,
      importantNotes: data['important_notes'] ?? 0,
      todayNotes: data['today_notes'] ?? 0,
      todayCompletions: data['today_completions'] ?? 0,
      lastActivity: data['last_activity'] != null
          ? DateTime.tryParse(data['last_activity'])
          : null,
    );
  }
}

/// ===============================
/// HOSPITALIZACIÓN – PANEL OPTIMIZADO
/// Diseño basado en la imagen de referencia con widgets fusionados
/// ===============================

class HospitalizacionPanel extends StatefulWidget {
  const HospitalizacionPanel({super.key});

  @override
  State<HospitalizacionPanel> createState() => _HospitalizacionPanelState();
}

class _HospitalizacionPanelState extends State<HospitalizacionPanel> {
  // --- Estado UI ---
  HospitalizationView _currentView = HospitalizationView.patients;
  String? _selectedPatientId;
  String? _selectedHospitalizationId;
  String _selectedTreatmentId = '';
  DateTime _currentWeek = DateTime.now();

  // Streams para datos en tiempo real
  late Stream<List<HospitalizedPatient>> _patientsStream;

  // Funciones auxiliares para obtener campos con fallback
  String? _getPatientMrn(Map<String, dynamic> patient) {
    return patient['history_number'] ??
        patient['mrn'] ??
        patient['patient_mrn'] ??
        patient['mrn_int']?.toString() ??
        patient['patient_id'];
  }

  String? _getPatientId(Map<String, dynamic> patient) {
    return patient['patient_id'] ?? patient['id'] ?? patient['patient_uuid'];
  }

  @override
  void initState() {
    super.initState();
    _initializeStreams();
  }

  void _initializeStreams() {
    // Stream para pacientes hospitalizados usando v_hosp (vista original)
    _patientsStream = _supa
        .from('v_hosp')
        .stream(primaryKey: ['patient_id']).asyncExpand((data) async* {
      final hospitalizedPatients = data
          .where((item) => item['hospitalization_status'] == 'active')
          .toList();

      List<Map<String, dynamic>> enrichedPatients = [];

      for (final item in hospitalizedPatients) {
        try {
          // Obtener hospitalization_id real desde tabla hospitalization para writings
          var hospitalizationData = await _supa
              .from('hospitalization')
              .select('id')
              .eq('patient_id', item['patient_id'])
              .eq('status', 'active')
              .maybeSingle();

          // Obtener temper desde tabla patients
          var patientTemper = await _supa
              .from('patients')
              .select('temper')
              .eq('id', item['patient_id'])
              .maybeSingle();

          // Enriquecer datos originales de v_hosp con hospitalization_id real
          final enrichedItem = Map<String, dynamic>.from(item);
          enrichedItem['hospitalization_id'] = hospitalizationData?['id'];

          // Asegurar que el temper viene directamente de patients.temper
          if (patientTemper != null && patientTemper['temper'] != null) {
            enrichedItem['temper'] = patientTemper['temper'];
          }

          enrichedPatients.add(enrichedItem);
        } catch (e) {
          print(
              'Error al enriquecer datos de paciente ${item['patient_id']}: $e');
          // En caso de error, usar datos originales de v_hosp
          enrichedPatients.add(Map<String, dynamic>.from(item));
        }
      }

      yield enrichedPatients
          .map((item) => HospitalizedPatient.fromJson(item))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // TopBar con selector de vista
        HospitalizationTopBar(
          currentView: _currentView,
          onViewChanged: (view) => setState(() => _currentView = view),
        ),

        // Contenido principal según la vista
        Expanded(
          child: _buildMainContent(),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    switch (_currentView) {
      case HospitalizationView.patients:
        return _buildPatientsView();
      case HospitalizationView.gantt:
        return _buildGanttView();
      case HospitalizationView.calendar:
        return _buildCalendarView();
      case HospitalizationView.reports:
        return _buildReportsView();
    }
  }

  Widget _buildPatientsView() {
    return Column(
      children: [
        // Panel principal: Pacientes + Calendario - Sin panel de detalles por defecto
        Expanded(
          child: Column(
            children: [
              // Cards de pacientes
              HospitalizedPatientsWidget(
                patientsStream: _patientsStream,
                onShowPatientSelection: _showPatientSelectionDialog,
                onShowPatientDetail: _showPatientDetail,
                onShowDischargeDialog: _showDischargeDialog,
                onShowHistory: _showHistory,
                onShowTreatment: _showTreatment,
                onLoadPatientTreatments: _loadPatientTreatmentsInCalendar,
              ),

              // Calendario semanal
              Expanded(
                child: CalendarGanttWidget(
                  currentWeek: _currentWeek,
                  selectedTreatmentId: _selectedTreatmentId,
                  selectedPatientId: _selectedPatientId,
                  onTreatmentTap: (treatmentId) {
                    setState(() {
                      _selectedTreatmentId = treatmentId;
                      // Mantener _selectedPatientId para seguir mostrando tratamientos del paciente
                    });
                  },
                  onTreatmentEdit: _editTreatment,
                  onTreatmentComplete: _completeTreatment,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGanttView() {
    return Row(
      children: [
        // Panel izquierdo: Tratamientos
        Expanded(
          flex: 2,
          child: TreatmentsWidget(
            selectedPatientId: _selectedPatientId,
            selectedHospitalizationId: _selectedHospitalizationId,
            onTreatmentTap: (treatmentId) {
              setState(() {
                _selectedTreatmentId = treatmentId;
              });
            },
            onTreatmentEdit: _editTreatment,
            onTreatmentComplete: _completeTreatment,
          ),
        ),

        // Panel derecho: Detalles (solo se muestra si hay tratamientos seleccionados)
        if (_selectedTreatmentId.isNotEmpty)
          DetailPanelWidget(
            selectedTreatmentId: _selectedTreatmentId,
            selectedPatientId: _selectedPatientId,
            onClose: () => setState(() {
              _selectedTreatmentId = '';
              _selectedPatientId = null;
            }),
          ),
      ],
    );
  }

  Widget _buildCalendarView() {
    return Row(
      children: [
        // Panel izquierdo: Calendario
        Expanded(
          flex: 3,
          child: CalendarGanttWidget(
            currentWeek: _currentWeek,
            selectedTreatmentId: _selectedTreatmentId,
            selectedPatientId: _selectedPatientId,
            onTreatmentTap: (treatmentId) {
              setState(() {
                _selectedTreatmentId = treatmentId;
              });
            },
            onTreatmentEdit: _editTreatment,
            onTreatmentComplete: _completeTreatment,
          ),
        ),

        // Panel derecho: Detalles
        DetailPanelWidget(
          selectedTreatmentId: _selectedTreatmentId,
          selectedPatientId: _selectedPatientId,
          onClose: () => setState(() {
            _selectedTreatmentId = '';
            _selectedPatientId = null;
          }),
        ),
      ],
    );
  }

  Widget _buildReportsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.chart_2,
            size: 64,
            color: home.AppColors.neutral400,
          ),
          const SizedBox(height: 16),
          Text(
            'Reportes',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: home.AppColors.neutral900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Funcionalidad en desarrollo',
            style: TextStyle(
              fontSize: 16,
              color: home.AppColors.neutral600,
            ),
          ),
        ],
      ),
    );
  }

  void _showPatientSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => PatientSelectionDialog(
        onPatientSelected: (patient) => _addPatientToHospitalization(patient),
      ),
    );
  }

  void _showPatientDetail(HospitalizedPatient patient) {
    setState(() {
      _selectedPatientId = patient.id;
      _selectedTreatmentId = '';
    });
  }

  void _showDischargeDialog(HospitalizedPatient patient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Iconsax.logout,
              color: home.AppColors.success500,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text('Dar de Alta'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de que deseas dar de alta a este paciente?',
              style: TextStyle(
                fontSize: 16,
                color: home.AppColors.neutral700,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: home.AppColors.neutral50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: home.AppColors.neutral200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient.patientName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: home.AppColors.neutral900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'MRN: ${patient.mrn}',
                    style: TextStyle(
                      fontSize: 12,
                      color: home.AppColors.neutral600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: home.AppColors.neutral600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _dischargePatient(patient);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: home.AppColors.success500,
              foregroundColor: Colors.white,
            ),
            child: Text('Confirmar Alta'),
          ),
        ],
      ),
    );
  }

  // Función para navegar a la Historia Médica
  void _showHistory(HospitalizedPatient patient) {
    Navigator.pushNamed(
      context,
      '/historias',
      arguments: {'mrn': patient.mrn, 'patient_id': patient.id},
    );
  }

  // Función para cargar datos del paciente en calendario para ver tratamientos
  void _loadPatientTreatmentsInCalendar(HospitalizedPatient patient) {
    setState(() {
      _selectedPatientId = patient.id;
      _selectedHospitalizationId = patient.hospitalizationId;
      // No cambia a vista gantt automáticamente, deja que el usuario vea datos en calendario actual
    });
  }

  // Función para mostrar tratamientos del paciente - cambia a vista gantt/tratamientos
  void _showTreatment(HospitalizedPatient patient) {
    setState(() {
      _selectedPatientId = patient.id;
      _selectedHospitalizationId = patient.hospitalizationId;
      _currentView = HospitalizationView
          .gantt; // Navega a la vista gantt donde están los tratamientos
    });
  }

  void _editTreatment(String treatmentId) {
    // Implementar edición de tratamiento
    print('Editando tratamiento: $treatmentId');
  }

  void _completeTreatment(String treatmentId) {
    // Implementar completar tratamiento
    print('Completando tratamiento: $treatmentId');
  }

  Future<void> _addPatientToHospitalization(
      Map<String, dynamic> patient) async {
    final patientId = _getPatientId(patient);
    final patientMrn = _getPatientMrn(patient);

    print('🏥 Iniciando hospitalización para: ${patient['patient_name']}');
    print('🏥 ID del paciente: $patientId');
    print('🏥 MRN del paciente: $patientMrn');

    if (patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: No se pudo obtener el ID del paciente'),
          backgroundColor: home.AppColors.danger500,
        ),
      );
      return;
    }

    try {
      // Verificar si el paciente ya está hospitalizado
      print('🔍 Verificando si el paciente ya está hospitalizado...');
      final hospitalizationResponse = await _supa
          .from('hospitalization')
          .select('*')
          .eq('patient_id', patientId)
          .eq('status', 'active')
          .maybeSingle();

      print('🔍 Respuesta de verificación: $hospitalizationResponse');

      if (hospitalizationResponse != null) {
        print('⚠️ El paciente ya está hospitalizado');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('El paciente ya está hospitalizado'),
            backgroundColor: home.AppColors.warning500,
          ),
        );
      } else {
        print(
            '✅ Paciente no hospitalizado, procediendo con la hospitalización...');

        print('📝 Insertando en tabla hospitalization...');
        // Agregar el paciente a hospitalización
        try {
          final hospitalizationResult = await _supa
              .from('hospitalization')
              .insert({
                'clinic_id': '4c17fddf-24ab-4a8d-9343-4cc4f6a4a203',
                'patient_id': patientId,
                'admission_date': DateTime.now().toIso8601String(),
                'status': 'active',
                'priority': 'normal',
                'created_by': _supa.auth.currentUser?.id,
              })
              .select('id')
              .single();

          print('📝 Hospitalization insertado: $hospitalizationResult');
          final hospitalizationId = hospitalizationResult['id'];
          print('📝 ID de hospitalización obtenido: $hospitalizationId');

          // Crear nota de ingreso automática (sin column title)
          print('📝 Insertando nota de ingreso...');
          await _supa.from('notes').insert({
            'patient_id': patientId,
            'hospitalization_id': hospitalizationId,
            'content':
                'Ingreso a Hospitalización - Paciente ingresado el ${DateTime.now().toString().split(' ')[0]}',
            'note_type': 'admission',
            'created_by': _supa.auth.currentUser?.id,
          });
          print('📝 Nota de ingreso insertada');

          // Crear tarea inicial de evaluación
          print('📝 Insertando tarea de evaluación...');
          await _supa.from('tasks').insert({
            'patient_id': patientId,
            'hospitalization_id': hospitalizationId,
            'title': 'Evaluación Inicial',
            'description':
                'Realizar evaluación inicial del paciente hospitalizado',
            'task_type': 'evaluation',
            'priority': 'high',
            'due_date':
                DateTime.now().add(Duration(hours: 2)).toIso8601String(),
            'assigned_to': _supa.auth.currentUser?.id,
            'created_by': _supa.auth.currentUser?.id,
          });
          print('📝 Tarea de evaluación insertada');

          print(
              '✅ Hospitalización completada para: ${patient['patient_name']}');
          print('✅ ID de hospitalización: $hospitalizationId');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Paciente agregado a hospitalización'),
              backgroundColor: home.AppColors.success500,
            ),
          );
        } catch (e) {
          print('❌ Error en hospitalización: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error en hospitalización: $e'),
              backgroundColor: home.AppColors.danger500,
            ),
          );
          return;
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al agregar paciente: ${e.toString()}'),
          backgroundColor: home.AppColors.danger500,
        ),
      );
    }
  }

  Future<void> _dischargePatient(HospitalizedPatient patient) async {
    try {
      // Obtener el ID de hospitalización
      final hospitalizationResponse = await _supa
          .from('hospitalization')
          .select('id')
          .eq('patient_id', patient.id)
          .eq('status', 'active')
          .single();

      final hospitalizationId = hospitalizationResponse['id'];

      // Actualizar el estado de hospitalización a 'discharged'
      await _supa.from('hospitalization').update({
        'status': 'discharged',
        'discharge_date': DateTime.now().toIso8601String(),
        'updated_by': _supa.auth.currentUser?.id,
      }).eq('id', hospitalizationId);

      // Crear una nota de alta automática (sin title column)
      await _supa.from('notes').insert({
        'patient_id': patient.id,
        'hospitalization_id': hospitalizationId,
        'content':
            'Alta Médica - Paciente dado de alta el ${DateTime.now().toString().split(' ')[0]}',
        'note_type': 'discharge',
        'priority': 'normal',
        'created_by': _supa.auth.currentUser?.id,
      });

      // Crear una tarea de seguimiento post-alta
      await _supa.from('tasks').insert({
        'patient_id': patient.id,
        'hospitalization_id': hospitalizationId,
        'title': 'Seguimiento Post-Alta',
        'description': 'Contactar al dueño para seguimiento del paciente',
        'task_type': 'follow_up',
        'priority': 'normal',
        'due_date': DateTime.now().add(Duration(days: 3)).toIso8601String(),
        'assigned_to': _supa.auth.currentUser?.id,
        'created_by': _supa.auth.currentUser?.id,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Paciente dado de alta exitosamente'),
          backgroundColor: home.AppColors.success500,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al dar de alta: ${e.toString()}'),
          backgroundColor: home.AppColors.danger500,
        ),
      );
    }
  }
}

/// Diálogo para seleccionar pacientes no hospitalizados
class PatientSelectionDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onPatientSelected;

  const PatientSelectionDialog({
    super.key,
    required this.onPatientSelected,
  });

  @override
  State<PatientSelectionDialog> createState() => _PatientSelectionDialogState();
}

class _PatientSelectionDialogState extends State<PatientSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _patients = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadPatients();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Usar la misma lógica de búsqueda que funciona en buscador.dart
      final response = await _supa.from('v_app').select('*');

      setState(() {
        _patients = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar pacientes: ${e.toString()}'),
          backgroundColor: home.AppColors.danger500,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Funciones auxiliares estáticas para obtener campos con fallback
  static String? _getPatientMrn(Map<String, dynamic> patient) {
    return patient['history_number'] ??
        patient['mrn'] ??
        patient['patient_mrn'] ??
        patient['mrn_int']?.toString() ??
        patient['patient_id'];
  }

  @override
  Widget build(BuildContext context) {
    final filteredPatients = _patients.where((patient) {
      if (_searchQuery.isEmpty) return true;
      final mrn = _getPatientMrn(patient);
      return patient['patient_name']?.toLowerCase().contains(_searchQuery) ||
          (mrn?.toLowerCase().contains(_searchQuery) ?? false) ||
          patient['owner_name']?.toLowerCase().contains(_searchQuery);
    }).toList();

    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Iconsax.add_circle,
                  color: home.AppColors.primary500,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Seleccionar Paciente',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: home.AppColors.neutral900,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Iconsax.close_circle),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Búsqueda
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, MRN o dueño...',
                prefixIcon: Icon(Iconsax.search_normal, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: home.AppColors.neutral200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: home.AppColors.primary500, width: 2),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),

            const SizedBox(height: 16),

            // Lista de pacientes
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : filteredPatients.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Iconsax.document_text,
                                size: 48,
                                color: home.AppColors.neutral400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No se encontraron pacientes',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: home.AppColors.neutral600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredPatients.length,
                          itemBuilder: (context, index) {
                            final patient = filteredPatients[index];
                            return _buildPatientItem(patient);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientItem(Map<String, dynamic> patient) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: home.AppColors.neutral200,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          print('🔍 Paciente seleccionado: ${patient['patient_name']}');
          print('🔍 ID del paciente: ${patient['patient_id']}');
          Navigator.pop(context);
          widget.onPatientSelected(patient);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar del paciente
              CircleAvatar(
                radius: 24,
                backgroundColor: home.AppColors.primary100,
                child: Text(
                  patient['patient_name']?.substring(0, 1).toUpperCase() ?? '?',
                  style: TextStyle(
                    color: home.AppColors.primary500,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Información del paciente
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient['patient_name'] ?? 'Sin nombre',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: home.AppColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'MRN: ${_getPatientMrn(patient) ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: home.AppColors.neutral600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${patient['species_label'] ?? 'Sin especie'} / ${patient['breed_label'] ?? 'Sin raza'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: home.AppColors.neutral600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Dueño: ${patient['owner_name'] ?? 'Sin dueño'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: home.AppColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ),

              // Botón de seleccionar
              Icon(
                Iconsax.arrow_right_3,
                color: home.AppColors.primary500,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
