import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../home.dart' as home;

class TreatmentDetailWidget extends StatelessWidget {
  final Map<String, dynamic> treatment;
  final VoidCallback? onEdit;
  final VoidCallback? onComplete;
  final VoidCallback? onClose;

  const TreatmentDetailWidget({
    super.key,
    required this.treatment,
    this.onEdit,
    this.onComplete,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header con título y botón de cerrar
          _buildHeader(),

          // Contenido principal
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información básica del medicamento
                  _buildMedicationInfo(),

                  const SizedBox(height: 24),

                  // Información de dosificación
                  _buildDosageInfo(),

                  const SizedBox(height: 24),

                  // Información de horarios
                  _buildScheduleInfo(),

                  const SizedBox(height: 24),

                  // Información adicional
                  _buildAdditionalInfo(),

                  const SizedBox(height: 32),

                  // Botones de acción
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: home.AppColors.primary500,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Iconsax.health,
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
                  treatment['medication_name'] ?? 'Tratamiento',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusLabel(treatment['status'] ?? 'pending'),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (onClose != null)
            GestureDetector(
              onTap: onClose,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Iconsax.close_circle,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMedicationInfo() {
    return _buildInfoSection(
      title: 'Información del Medicamento',
      icon: Iconsax.health,
      children: [
        _buildInfoRow(
            'Medicamento', treatment['medication_name'] ?? 'No especificado'),
        _buildInfoRow('Dosis', treatment['dosage'] ?? 'No especificada'),
        _buildInfoRow(
            'Vía de administración', treatment['route'] ?? 'No especificada'),
        _buildInfoRow(
            'Frecuencia', treatment['frequency'] ?? 'No especificada'),
      ],
    );
  }

  Widget _buildDosageInfo() {
    return _buildInfoSection(
      title: 'Información de Dosificación',
      icon: Iconsax.calendar_1,
      children: [
        _buildInfoRow('Duración', '${treatment['duration_days'] ?? 1} días'),
        _buildInfoRow(
            'Estado', _getStatusLabel(treatment['status'] ?? 'pending')),
        if (treatment['special_instructions'] != null)
          _buildInfoRow(
              'Instrucciones especiales', treatment['special_instructions']),
      ],
    );
  }

  Widget _buildScheduleInfo() {
    final scheduledTime = treatment['scheduled_time'];
    final scheduledDate = treatment['scheduled_date'];

    return _buildInfoSection(
      title: 'Horarios Programados',
      icon: Iconsax.clock,
      children: [
        if (scheduledTime != null)
          _buildInfoRow('Hora programada', _formatDateTime(scheduledTime)),
        if (scheduledDate != null)
          _buildInfoRow('Fecha programada', _formatDate(scheduledDate)),
        _buildInfoRow('Creado', _formatDateTime(treatment['created_at'])),
        if (treatment['updated_at'] != null)
          _buildInfoRow(
              'Última actualización', _formatDateTime(treatment['updated_at'])),
      ],
    );
  }

  Widget _buildAdditionalInfo() {
    return _buildInfoSection(
      title: 'Información Adicional',
      icon: Iconsax.document_text,
      children: [
        _buildInfoRow('ID del tratamiento', treatment['id'] ?? 'N/A'),
        if (treatment['patient_id'] != null)
          _buildInfoRow('ID del paciente', treatment['patient_id']),
        if (treatment['hospitalization_id'] != null)
          _buildInfoRow(
              'ID de hospitalización', treatment['hospitalization_id']),
        if (treatment['clinic_id'] != null)
          _buildInfoRow('ID de clínica', treatment['clinic_id']),
      ],
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: home.AppColors.neutral50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: home.AppColors.neutral200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: home.AppColors.primary500,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: home.AppColors.neutral900,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: home.AppColors.neutral600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: home.AppColors.neutral900,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (onEdit != null)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Iconsax.edit, size: 18),
              label: const Text('Editar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: home.AppColors.primary500,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        if (onEdit != null && onComplete != null) const SizedBox(width: 12),
        if (onComplete != null)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onComplete,
              icon: const Icon(Iconsax.tick_circle, size: 18),
              label: const Text('Completar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: home.AppColors.success500,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'scheduled':
        return 'Programado';
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

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return 'No especificado';

    try {
      final parsed = DateTime.parse(dateTime.toString());
      return DateFormat('dd/MM/yyyy HH:mm').format(parsed);
    } catch (e) {
      return 'Formato inválido';
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'No especificado';

    try {
      final parsed = DateTime.parse(date.toString());
      return DateFormat('dd/MM/yyyy').format(parsed);
    } catch (e) {
      return 'Formato inválido';
    }
  }
}
