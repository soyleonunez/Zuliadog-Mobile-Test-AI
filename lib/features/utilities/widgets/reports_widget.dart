import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../home.dart' as home;

final _supa = Supabase.instance.client;

class ReportsWidget extends StatefulWidget {
  const ReportsWidget({super.key});

  @override
  State<ReportsWidget> createState() => _ReportsWidgetState();
}

class _ReportsWidgetState extends State<ReportsWidget> {
  List<Map<String, dynamic>> _patients = [];
  Map<String, List<Map<String, dynamic>>> _tasksByPatient = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Cargar pacientes
      final patientsResponse = await _supa
          .from('patients')
          .select('id, name, species, breed, status')
          .eq('status', 'active')
          .limit(10);

      _patients = List<Map<String, dynamic>>.from(patientsResponse);

      // Cargar tareas por paciente
      for (var patient in _patients) {
        final tasksResponse = await _supa
            .from('treatments')
            .select('*')
            .eq('patient_id', patient['id'])
            .order('scheduled_time', ascending: true);

        _tasksByPatient[patient['id']] =
            List<Map<String, dynamic>>.from(tasksResponse);
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error cargando datos de reportes: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),

          const SizedBox(height: 24),

          // Tablero Kanban
          Expanded(
            child: _buildKanbanBoard(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: home.AppColors.primary500,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Iconsax.chart_2,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tablero de Reportes',
                style: TextStyle(
                  color: home.AppColors.neutral900,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Gestión visual de tareas por paciente',
                style: TextStyle(
                  color: home.AppColors.neutral600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        // Botón de actualizar
        GestureDetector(
          onTap: _loadData,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: home.AppColors.neutral100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: home.AppColors.neutral200,
                width: 1,
              ),
            ),
            child: const Icon(
              Iconsax.refresh,
              color: home.AppColors.neutral600,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKanbanBoard() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _patients.map((patient) {
          return Container(
            width: 300,
            margin: const EdgeInsets.only(right: 16),
            child: _buildPatientColumn(patient),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPatientColumn(Map<String, dynamic> patient) {
    final patientId = patient['id'];
    final tasks = _tasksByPatient[patientId] ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: home.AppColors.neutral200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la columna
          _buildColumnHeader(patient, tasks.length),

          // Lista de tareas
          Expanded(
            child: _buildTasksList(tasks, patientId),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeader(Map<String, dynamic> patient, int taskCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: home.AppColors.primary500,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Iconsax.user,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient['name'] ?? 'Sin nombre',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${patient['species'] ?? ''} - ${patient['breed'] ?? ''}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$taskCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTasksList(List<Map<String, dynamic>> tasks, String patientId) {
    if (tasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Iconsax.task_square,
              color: home.AppColors.neutral400,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Sin tareas',
              style: TextStyle(
                color: home.AppColors.neutral500,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'No hay tareas asignadas',
              style: TextStyle(
                color: home.AppColors.neutral400,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: tasks.map((task) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: _buildTaskCard(task, patientId),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task, String patientId) {
    final priority = task['priority'] ?? 'normal';

    return Draggable<Map<String, dynamic>>(
      data: task,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: _buildTaskCardContent(task, priority, true),
      ),
      childWhenDragging: Container(
        height: 80,
        decoration: BoxDecoration(
          color: home.AppColors.neutral100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: home.AppColors.neutral200,
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
      ),
      child: DragTarget<Map<String, dynamic>>(
        onAccept: (draggedTask) {
          _moveTask(draggedTask, patientId);
        },
        builder: (context, candidateData, rejectedData) {
          return _buildTaskCardContent(task, priority, false);
        },
      ),
    );
  }

  Widget _buildTaskCardContent(
      Map<String, dynamic> task, String priority, bool isDragging) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getPriorityColor(priority),
          width: 2,
        ),
        boxShadow: isDragging
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la tarea
          Row(
            children: [
              Icon(
                _getTaskIcon(task['task_type']),
                color: _getPriorityColor(priority),
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task['title'] ?? 'Tarea sin título',
                  style: TextStyle(
                    color: home.AppColors.neutral900,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getPriorityColor(priority),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getPriorityLabel(priority),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Descripción
          if (task['description'] != null)
            Text(
              task['description'],
              style: TextStyle(
                color: home.AppColors.neutral600,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

          const SizedBox(height: 8),

          // Footer con fecha y estado
          Row(
            children: [
              Icon(
                Iconsax.clock,
                color: home.AppColors.neutral400,
                size: 12,
              ),
              const SizedBox(width: 4),
              Text(
                _formatTaskTime(task['scheduled_time']),
                style: TextStyle(
                  color: home.AppColors.neutral500,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(task['status']),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getStatusLabel(task['status']),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return home.AppColors.danger500;
      case 'high':
        return home.AppColors.warning500;
      case 'normal':
        return home.AppColors.primary500;
      case 'low':
        return home.AppColors.success500;
      default:
        return home.AppColors.neutral500;
    }
  }

  String _getPriorityLabel(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return 'Urgente';
      case 'high':
        return 'Alta';
      case 'normal':
        return 'Normal';
      case 'low':
        return 'Baja';
      default:
        return 'Normal';
    }
  }

  IconData _getTaskIcon(String? taskType) {
    switch (taskType?.toLowerCase()) {
      case 'medication':
        return Iconsax.health;
      case 'feeding':
        return Iconsax.cup;
      case 'exercise':
        return Iconsax.activity;
      case 'monitoring':
        return Iconsax.eye;
      case 'treatment':
        return Iconsax.health;
      case 'examination':
        return Iconsax.document_text;
      case 'vaccination':
        return Iconsax.shield_tick;
      case 'surgery':
        return Iconsax.scissor;
      case 'consultation':
        return Iconsax.message_question;
      case 'follow_up':
        return Iconsax.refresh;
      case 'lab_test':
        return Iconsax.health;
      case 'imaging':
        return Iconsax.camera;
      case 'therapy':
        return Iconsax.heart;
      case 'grooming':
        return Iconsax.scissor_1;
      case 'boarding':
        return Iconsax.home;
      default:
        return Iconsax.task_square;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
      case 'scheduled':
        return home.AppColors.warning500;
      case 'completed':
      case 'done':
        return home.AppColors.success500;
      case 'cancelled':
        return home.AppColors.danger500;
      case 'in_progress':
        return home.AppColors.primary500;
      default:
        return home.AppColors.neutral500;
    }
  }

  String _getStatusLabel(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
      case 'scheduled':
        return 'Pendiente';
      case 'completed':
      case 'done':
        return 'Completado';
      case 'cancelled':
        return 'Cancelado';
      case 'in_progress':
        return 'En Progreso';
      default:
        return 'Desconocido';
    }
  }

  String _formatTaskTime(dynamic scheduledTime) {
    if (scheduledTime == null) return 'Sin fecha';

    try {
      final dateTime = DateTime.parse(scheduledTime.toString());
      final now = DateTime.now();
      final difference = dateTime.difference(now);

      if (difference.inDays > 0) {
        return 'En ${difference.inDays} días';
      } else if (difference.inHours > 0) {
        return 'En ${difference.inHours} horas';
      } else if (difference.inMinutes > 0) {
        return 'En ${difference.inMinutes} minutos';
      } else {
        return 'Ahora';
      }
    } catch (e) {
      return 'Fecha inválida';
    }
  }

  Future<void> _moveTask(Map<String, dynamic> task, String newPatientId) async {
    try {
      await _supa
          .from('treatments')
          .update({'patient_id': newPatientId}).eq('id', task['id']);

      // Recargar datos
      await _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tarea movida exitosamente'),
          backgroundColor: home.AppColors.success500,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error moviendo tarea: $e'),
          backgroundColor: home.AppColors.danger500,
        ),
      );
    }
  }
}
