import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../home.dart' as home;
import 'treatment_form_widget.dart';
import 'treatment_card_widget.dart';

final _supa = Supabase.instance.client;

class TreatmentsWidget extends StatefulWidget {
  final String? selectedPatientId;
  final String? selectedHospitalizationId;
  final Function(String) onTreatmentTap;
  final Function(String) onTreatmentEdit;
  final Function(String) onTreatmentComplete;

  const TreatmentsWidget({
    super.key,
    this.selectedPatientId,
    this.selectedHospitalizationId,
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
            'Tratamientos y Medicamentos',
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

        return LayoutBuilder(
          builder: (context, constraints) {
            // Calcular número de columnas basado en el ancho disponible
            int crossAxisCount;
            double childAspectRatio;

            if (constraints.maxWidth > 1200) {
              crossAxisCount = 4; // Pantallas grandes: 4 columnas
              childAspectRatio =
                  1.3; // Más rectangular para evitar desbordamiento
            } else if (constraints.maxWidth > 900) {
              crossAxisCount = 3; // Pantallas medianas: 3 columnas
              childAspectRatio =
                  1.25; // Más rectangular para evitar desbordamiento
            } else if (constraints.maxWidth > 600) {
              crossAxisCount = 2; // Pantallas pequeñas: 2 columnas
              childAspectRatio = 1.2; // Rectangular
            } else {
              crossAxisCount = 1; // Móviles: 1 columna
              childAspectRatio = 1.5; // Más vertical para móviles
            }

            return GridView.builder(
              padding: EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: childAspectRatio,
                crossAxisSpacing: 12, // Reducido de 16 a 12
                mainAxisSpacing: 12, // Reducido de 16 a 12
              ),
              itemCount: filteredTreatments.length,
              itemBuilder: (context, index) {
                final treatment = filteredTreatments[index];
                return TreatmentCardWidget(
                  treatment: treatment,
                  onEdit: () => widget.onTreatmentEdit(treatment['id'] ?? ''),
                  onComplete: () =>
                      widget.onTreatmentComplete(treatment['id'] ?? ''),
                );
              },
            );
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
            hospitalizationId: widget.selectedHospitalizationId ?? '',
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
      // Separar los datos principales de los recordatorios
      final reminders =
          treatmentData.remove('reminders') as List<Map<String, dynamic>>? ??
              [];

      // Asegurar que no incluye id null para auto-generation principal
      final cleanTreatmentData = Map<String, dynamic>.from(treatmentData);
      cleanTreatmentData.remove('id');

      // Insertar el tratamiento principal
      await _supa.from('follows').insert(cleanTreatmentData);

      // Generar entradas automáticas basadas en frecuencia
      final frequency = treatmentData['frequency'] as String?;
      final duration = treatmentData['duration_days'] as int? ?? 1;
      final medicationName = treatmentData['medication_name'] as String? ?? '';
      final dosage = treatmentData['dosage'] as String? ?? '';
      final route = treatmentData['route'] as String? ?? '';

      if (frequency != null && frequency.isNotEmpty) {
        final frequencyEntries = await _generateFrequencyEntries(
          frequency,
          duration,
          medicationName,
          dosage,
          route,
          treatmentData,
        );

        if (frequencyEntries.isNotEmpty) {
          await _supa.from('follows').insert(frequencyEntries);
        }
      }

      // Insertar los recordatorios automáticos si existen
      if (reminders.isNotEmpty) {
        final remindersData = reminders.map((reminder) {
          // Crear una copia limpia sin id nulo
          final cleanReminder = Map<String, dynamic>.from(reminder);
          // Remover id nulo si existe
          cleanReminder.remove('id');

          // Agregar campos requeridos para recordatorios
          cleanReminder['clinic_id'] = treatmentData['clinic_id'];
          cleanReminder['patient_id'] = treatmentData['patient_id'];
          cleanReminder['hospitalization_id'] =
              treatmentData['hospitalization_id'];
          cleanReminder['completion_type'] = 'medication_administered';
          cleanReminder['completion_status'] = 'scheduled';
          cleanReminder['created_at'] =
              DateTime.now().toUtc().toIso8601String();
          return cleanReminder;
        }).toList();

        await _supa.from('follows').insert(remindersData);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Tratamiento agregado exitosamente${reminders.isNotEmpty ? ' con ${reminders.length} recordatorios' : ''}'),
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

  // Función para generar entradas automáticas basadas en frecuencia
  Future<List<Map<String, dynamic>>> _generateFrequencyEntries(
    String frequency,
    int durationDays,
    String medicationName,
    String dosage,
    String route,
    Map<String, dynamic> baseTreatmentData,
  ) async {
    final entries = <Map<String, dynamic>>[];
    final now = DateTime.now();

    // Calcular el número de entradas basado en la frecuencia
    int intervalHours;
    int entriesPerDay;

    switch (frequency.toLowerCase()) {
      case 'cada 6 horas':
        intervalHours = 6;
        entriesPerDay = 4;
        break;
      case 'cada 8 horas':
        intervalHours = 8;
        entriesPerDay = 3;
        break;
      case 'cada 12 horas':
        intervalHours = 12;
        entriesPerDay = 2;
        break;
      case 'diario':
        intervalHours = 24;
        entriesPerDay = 1;
        break;
      case 'cada 4 horas':
        intervalHours = 4;
        entriesPerDay = 6;
        break;
      default:
        return entries; // No generar entradas para frecuencias no reconocidas
    }

    // Generar entradas para cada día
    for (int day = 0; day < durationDays; day++) {
      final currentDay = now.add(Duration(days: day));

      for (int entry = 0; entry < entriesPerDay; entry++) {
        final scheduledTime =
            currentDay.add(Duration(hours: entry * intervalHours));

        // Crear entrada de calendario
        final entryData = Map<String, dynamic>.from(baseTreatmentData);
        entryData['id'] = null; // Auto-generar ID
        entryData['scheduled_time'] = scheduledTime.toUtc().toIso8601String();
        entryData['medication_name'] = medicationName;
        entryData['dosage'] = dosage;
        entryData['route'] = route;
        entryData['frequency'] = frequency;
        entryData['status'] = 'scheduled';
        entryData['created_at'] = now.toUtc().toIso8601String();
        entryData['updated_at'] = now.toUtc().toIso8601String();

        entries.add(entryData);
      }
    }

    return entries;
  }
}
