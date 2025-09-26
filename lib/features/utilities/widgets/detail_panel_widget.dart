import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../home.dart' as home;

final _supa = Supabase.instance.client;

class DetailPanelWidget extends StatelessWidget {
  final String? selectedTreatmentId;
  final String? selectedPatientId;
  final VoidCallback onClose;

  const DetailPanelWidget({
    super.key,
    this.selectedTreatmentId,
    this.selectedPatientId,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(
            color: home.AppColors.neutral200,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header del panel
          _buildHeader(),

          // Contenido del panel
          Expanded(
            child: selectedTreatmentId != null
                ? _buildTreatmentDetails()
                : selectedPatientId != null
                    ? _buildPatientDetails()
                    : _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: home.AppColors.neutral200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            selectedTreatmentId != null ? Iconsax.health : Iconsax.user,
            size: 20,
            color: home.AppColors.primary600,
          ),
          const SizedBox(width: 8),
          Text(
            selectedTreatmentId != null
                ? 'Detalles del Tratamiento'
                : 'Detalles del Paciente',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: home.AppColors.neutral900,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onClose,
            icon: Icon(Iconsax.close_circle),
            iconSize: 20,
            color: home.AppColors.neutral500,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
            'Selecciona un elemento',
            style: TextStyle(
              fontSize: 16,
              color: home.AppColors.neutral600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Haz clic en un tratamiento o paciente para ver los detalles',
            style: TextStyle(
              fontSize: 14,
              color: home.AppColors.neutral500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentDetails() {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _supa
          .from('follows')
          .stream(primaryKey: ['id'])
          .map((data) => data.firstWhere(
                (item) => item['id'] == selectedTreatmentId,
                orElse: () => <String, dynamic>{},
              ))
          .map((data) => data.isNotEmpty ? data : null),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Center(child: Text('Error al cargar tratamiento'));
        }

        final treatment = snapshot.data!;
        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información básica
              Text(
                'Información del Tratamiento',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: home.AppColors.neutral900,
                ),
              ),
              const SizedBox(height: 16),

              // Detalles del tratamiento
              _buildDetailRow('Medicamento',
                  treatment['medication_name'] ?? 'No especificado'),
              _buildDetailRow('Dosificación',
                  treatment['medication_dosage'] ?? 'No especificada'),
              _buildDetailRow('Vía',
                  treatment['administration_route'] ?? 'No especificada'),
              _buildDetailRow(
                  'Frecuencia', treatment['frequency'] ?? 'No especificada'),
              _buildDetailRow(
                  'Duración', '${treatment['duration_days'] ?? 0} días'),

              if (treatment['scheduled_date'] != null &&
                  treatment['scheduled_time'] != null)
                _buildDetailRow(
                  'Fecha Programada',
                  DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(
                      '${treatment['scheduled_date']} ${treatment['scheduled_time']}')),
                )
              else if (treatment['scheduled_date'] != null)
                _buildDetailRow(
                  'Fecha',
                  DateFormat('dd/MM/yyyy')
                      .format(DateTime.parse(treatment['scheduled_date'])),
                ),

              _buildDetailRow(
                  'Tipo', treatment['follow_type'] ?? 'Sin especificar'),
              _buildDetailRow('Estado', _getStatusLabel(treatment['status'])),
              _buildDetailRow(
                  'Completado',
                  treatment['completion_status']?.toString() ??
                      'No especificado'),
              _buildDetailRow(
                  'Prioridad', _getPriorityLabel(treatment['priority'])),

              if (treatment['observations'] != null)
                _buildDetailRow('Observaciones', treatment['observations']),

              if (treatment['recommendations'] != null)
                _buildDetailRow(
                    'Recomendaciones', treatment['recommendations']),

              if (treatment['effectiveness_rating'] != null)
                _buildDetailRow('Calificación de Efectividad',
                    '${treatment['effectiveness_rating']}/5'),

              if (treatment['side_effects'] != null)
                _buildDetailRow(
                    'Efectos Secundarios', treatment['side_effects']),

              if (treatment['next_evaluation_date'] != null)
                _buildDetailRow(
                  'Próxima Evaluación',
                  DateFormat('dd/MM/yyyy').format(
                      DateTime.parse(treatment['next_evaluation_date'])),
                ),

              const SizedBox(height: 24),

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Implementar edición
                      },
                      icon: Icon(Iconsax.edit, size: 16),
                      label: Text('Editar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: home.AppColors.primary500,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Implementar completar
                      },
                      icon: Icon(Iconsax.tick_circle, size: 16),
                      label: Text('Completar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: home.AppColors.success500,
                        side: BorderSide(color: home.AppColors.success500),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPatientDetails() {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _supa
          .from('v_hosp')
          .stream(primaryKey: ['patient_id'])
          .map((data) => data.firstWhere(
                (item) => item['patient_id'] == selectedPatientId,
                orElse: () => <String, dynamic>{},
              ))
          .map((data) => data.isNotEmpty ? data : null),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Center(child: Text('Error al cargar paciente'));
        }

        final patient = snapshot.data!;
        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información del paciente
              _buildInfoSection(
                'Información del Paciente',
                Iconsax.user,
                [
                  _buildInfoRow(
                      'Nombre', patient['patient_name'] ?? 'No especificado'),
                  _buildInfoRow('MRN', patient['mrn'] ?? 'No especificado'),
                  _buildInfoRow('Sexo', patient['sex'] ?? 'No especificado'),
                  _buildInfoRow(
                      'Especie', patient['species_label'] ?? 'No especificada'),
                  _buildInfoRow(
                      'Raza', patient['breed_label'] ?? 'No especificada'),
                ],
              ),

              const SizedBox(height: 16),

              // Información de hospitalización
              _buildInfoSection(
                'Hospitalización',
                Iconsax.hospital,
                [
                  _buildInfoRow('Estado',
                      patient['hospitalization_status'] ?? 'No especificado'),
                  _buildInfoRow('Prioridad',
                      patient['hospitalization_priority'] ?? 'No especificada'),
                  _buildInfoRow(
                      'Habitación', patient['room_number'] ?? 'No asignada'),
                  _buildInfoRow('Cama', patient['bed_number'] ?? 'No asignada'),
                ],
              ),

              const SizedBox(height: 16),

              // Estadísticas
              _buildInfoSection(
                'Estadísticas',
                Iconsax.chart_2,
                [
                  _buildInfoRow(
                      'Tareas Pendientes', '${patient['pending_tasks'] ?? 0}'),
                  _buildInfoRow('Tareas Completadas',
                      '${patient['completed_tasks'] ?? 0}'),
                  _buildInfoRow('Notas Importantes',
                      '${patient['important_notes'] ?? 0}'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoSection(String title, IconData icon, List<Widget> children) {
    return Container(
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
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: home.AppColors.primary600,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: home.AppColors.neutral900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: home.AppColors.neutral600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: home.AppColors.neutral900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: home.AppColors.neutral600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: home.AppColors.neutral900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'completed':
        return 'Completado';
      case 'in_progress':
        return 'En Progreso';
      case 'pending':
        return 'Pendiente';
      default:
        return 'Pendiente';
    }
  }

  String _getPriorityLabel(String? priority) {
    switch (priority) {
      case 'low':
        return 'Baja';
      case 'normal':
        return 'Normal';
      case 'high':
        return 'Alta';
      case 'critical':
        return 'Crítica';
      default:
        return 'Normal';
    }
  }
}
