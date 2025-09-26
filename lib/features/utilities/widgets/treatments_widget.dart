import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../home.dart' as home;
import 'treatment_form_widget.dart';

final _supa = Supabase.instance.client;

class TreatmentsWidget extends StatefulWidget {
  final String? selectedPatientId;
  final Function(String) onTreatmentTap;
  final Function(String) onTreatmentEdit;
  final Function(String) onTreatmentComplete;

  const TreatmentsWidget({
    super.key,
    this.selectedPatientId,
    required this.onTreatmentTap,
    required this.onTreatmentEdit,
    required this.onTreatmentComplete,
  });

  @override
  State<TreatmentsWidget> createState() => _TreatmentsWidgetState();
}

class _TreatmentsWidgetState extends State<TreatmentsWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: home.AppColors.neutral200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header con botón de agregar
          _buildHeader(),

          // Lista de tratamientos
          Expanded(
            child: _buildTreatmentsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: home.AppColors.neutral50,
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
            Iconsax.health,
            size: 20,
            color: home.AppColors.primary600,
          ),
          const SizedBox(width: 8),
          Text(
            'Tratamientos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: home.AppColors.neutral900,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _showAddTreatmentDialog,
            icon: Icon(Iconsax.add, size: 16),
            label: Text('Agregar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: home.AppColors.primary500,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supa.from('follows').stream(primaryKey: ['id']).map((data) =>
          data.where((item) => item['follow_type'] == 'treatment').toList()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final treatments = snapshot.data ?? [];

        // Filtrar por paciente si está seleccionado
        final filteredTreatments = widget.selectedPatientId != null
            ? treatments
                .where((treatment) =>
                    treatment['patient_id'] == widget.selectedPatientId)
                .toList()
            : treatments;

        if (filteredTreatments.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: filteredTreatments.length,
          itemBuilder: (context, index) {
            final treatment = filteredTreatments[index];
            return _buildTreatmentItem(treatment);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.health,
            size: 48,
            color: home.AppColors.neutral400,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay tratamientos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: home.AppColors.neutral700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega un tratamiento para comenzar',
            style: TextStyle(
              fontSize: 14,
              color: home.AppColors.neutral500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentItem(Map<String, dynamic> treatment) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getTreatmentColor(treatment).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getTreatmentColor(treatment),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getTreatmentIcon(treatment),
                size: 16,
                color: _getTreatmentColor(treatment),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  treatment['medication_name'] ?? 'Tratamiento',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: home.AppColors.neutral900,
                  ),
                ),
              ),
              _buildStatusChip(treatment['status']),
            ],
          ),

          const SizedBox(height: 8),

          // Información del tratamiento
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Dosis',
                  treatment['dosage'] ?? 'No especificada',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  'Vía',
                  treatment['administration_route'] ?? 'No especificada',
                ),
              ),
            ],
          ),

          if (treatment['scheduled_date'] != null) ...[
            const SizedBox(height: 4),
            _buildInfoItem(
              'Fecha',
              DateFormat('dd/MM/yyyy HH:mm').format(
                  DateTime.parse(treatment['scheduled_date'].toString())),
            ),
          ],

          const SizedBox(height: 8),

          // Botones de acción
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => widget.onTreatmentEdit(treatment['id']),
                  icon: Icon(Iconsax.edit, size: 14),
                  label: Text('Editar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: home.AppColors.primary500,
                    side: BorderSide(color: home.AppColors.primary500),
                    padding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => widget.onTreatmentComplete(treatment['id']),
                  icon: Icon(Iconsax.tick_circle, size: 14),
                  label: Text('Completar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: home.AppColors.success500,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: home.AppColors.neutral500,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: home.AppColors.neutral900,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String? status) {
    Color color;
    String label;

    switch (status) {
      case 'completed':
        color = home.AppColors.success500;
        label = 'Completado';
        break;
      case 'in_progress':
        color = home.AppColors.warning500;
        label = 'En Progreso';
        break;
      case 'pending':
        color = home.AppColors.neutral500;
        label = 'Pendiente';
        break;
      default:
        color = home.AppColors.neutral500;
        label = 'Pendiente';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getTreatmentColor(Map<String, dynamic> treatment) {
    switch (treatment['follow_type']) {
      case 'treatment':
        return home.AppColors.primary500;
      case 'medication':
        return home.AppColors.success500;
      case 'vital_signs':
        return home.AppColors.warning500;
      case 'evolution':
        return home.AppColors.danger500;
      default:
        return home.AppColors.neutral500;
    }
  }

  IconData _getTreatmentIcon(Map<String, dynamic> treatment) {
    switch (treatment['follow_type']) {
      case 'treatment':
        return Iconsax.health;
      case 'medication':
        return Iconsax.health;
      case 'vital_signs':
        return Iconsax.heart;
      case 'evolution':
        return Iconsax.document_text;
      default:
        return Iconsax.health;
    }
  }

  void _showAddTreatmentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Agregar Tratamiento'),
        content: SizedBox(
          width: 600,
          height: 500,
          child: TreatmentFormWidget(
            patientId: widget.selectedPatientId ?? '',
            hospitalizationId: widget.selectedPatientId ?? '',
            clinicId: '4c17fddf-24ab-4a8d-9343-4cc4f6a4a203',
            onSubmit: (treatmentData) {
              _addTreatment(treatmentData);
              Navigator.of(context).pop();
            },
            onCancel: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  Future<void> _addTreatment(Map<String, dynamic> treatmentData) async {
    try {
      // Agregar follow_type para identificar como tratamiento
      treatmentData['follow_type'] = 'treatment';

      await _supa.from('follows').insert(treatmentData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tratamiento agregado exitosamente'),
          backgroundColor: home.AppColors.success500,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al agregar tratamiento: $e'),
          backgroundColor: home.AppColors.danger500,
        ),
      );
    }
  }
}
