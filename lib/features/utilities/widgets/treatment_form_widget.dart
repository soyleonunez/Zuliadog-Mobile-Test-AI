import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../home.dart' as home;

class TreatmentFormWidget extends StatefulWidget {
  final String patientId;
  final String hospitalizationId;
  final String clinicId;
  final Function(Map<String, dynamic>)? onSubmit;
  final Function()? onCancel;

  const TreatmentFormWidget({
    Key? key,
    required this.patientId,
    required this.hospitalizationId,
    required this.clinicId,
    this.onSubmit,
    this.onCancel,
  }) : super(key: key);

  @override
  State<TreatmentFormWidget> createState() => _TreatmentFormWidgetState();
}

class _TreatmentFormWidgetState extends State<TreatmentFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _medicationNameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _frequencyController = TextEditingController();
  final _durationController = TextEditingController();
  final _observationsController = TextEditingController();
  final _recommendationsController = TextEditingController();

  String _selectedPresentation = 'Tableta';
  String _selectedRoute = 'Oral';
  String _selectedPriority = 'normal';
  List<String> _selectedFrequencies = [];
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  final List<String> _presentations = [
    'Tableta',
    'Cápsula',
    'Inyección',
    'Pomada',
    'Gotas',
    'Jarabe',
    'Supositorio',
    'Parche',
    'Inhalador',
    'Otro'
  ];

  final List<String> _routes = [
    'Oral',
    'Intravenosa (IV)',
    'Intramuscular (IM)',
    'Subcutánea',
    'Tópica',
    'Rectal',
    'Vaginal',
    'Nasal',
    'Oftálmica',
    'Ótica'
  ];

  final List<String> _priorities = ['low', 'normal', 'high', 'urgent'];

  final List<String> _frequencyOptions = [
    'Cada 6 horas',
    'Cada 8 horas',
    'Cada 12 horas',
    'Cada 24 horas',
    'Mañana',
    'Noche',
    'Mañana y noche',
    'Personalizado'
  ];

  @override
  void dispose() {
    _medicationNameController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    _durationController.dispose();
    _observationsController.dispose();
    _recommendationsController.dispose();
    super.dispose();
  }

  /// Genera múltiples entradas de treatment basadas en frecuencias para recordatorios automáticos
  List<Map<String, dynamic>> _generateTreatmentReminders({
    required Map<String, dynamic> baseTreatment,
    required List<String> frequencies,
  }) {
    List<Map<String, dynamic>> reminders = [];
    final baseDate = DateTime.parse(baseTreatment['scheduled_date']);
    final durationDays = baseTreatment['duration_days'] ?? 7;

    for (final frequency in frequencies) {
      List<DateTime> scheduledDates = _generateScheduledDates(
        baseDate: baseDate,
        frequency: frequency,
        durationDays: durationDays,
      );

      for (final scheduledDate in scheduledDates) {
        final reminderData = Map<String, dynamic>.from(baseTreatment);
        // Remove id field completely to allow auto-generation
        reminderData.remove('id');
        reminderData['scheduled_date'] =
            scheduledDate.toIso8601String().split('T')[0];
        reminderData['follow_type'] = 'medication_reminder';
        reminderData['frequency'] = frequency;
        reminders.add(reminderData);
      }
    }

    return reminders;
  }

  /// Calcula las fechas propuestas según la frecuencia
  List<DateTime> _generateScheduledDates({
    required DateTime baseDate,
    required String frequency,
    required int durationDays,
  }) {
    List<DateTime> scheduledDates = [];
    final endDate = baseDate.add(Duration(days: durationDays));

    switch (frequency) {
      case 'Cada 6 horas':
        DateTime current = baseDate;
        while (current.isBefore(endDate)) {
          scheduledDates.add(current);
          current = current.add(Duration(hours: 6));
        }
        break;
      case 'Cada 8 horas':
        DateTime current = baseDate;
        while (current.isBefore(endDate)) {
          scheduledDates.add(current);
          current = current.add(Duration(hours: 8));
        }
        break;
      case 'Cada 12 horas':
        DateTime current = baseDate;
        while (current.isBefore(endDate)) {
          scheduledDates.add(current);
          current = current.add(Duration(hours: 12));
        }
        break;
      case 'Cada 24 horas':
        DateTime current = baseDate;
        while (current.isBefore(endDate)) {
          scheduledDates.add(current);
          current = current.add(Duration(days: 1));
        }
        break;
      case 'Mañana':
        DateTime current = baseDate;
        while (current.isBefore(endDate)) {
          scheduledDates
              .add(DateTime(current.year, current.month, current.day, 8, 0));
          current = current.add(Duration(days: 1));
        }
        break;
      case 'Noche':
        DateTime current = baseDate;
        while (current.isBefore(endDate)) {
          scheduledDates
              .add(DateTime(current.year, current.month, current.day, 20, 0));
          current = current.add(Duration(days: 1));
        }
        break;
      case 'Mañana y noche':
        DateTime current = baseDate;
        while (current.isBefore(endDate)) {
          scheduledDates
              .add(DateTime(current.year, current.month, current.day, 8, 0));
          scheduledDates
              .add(DateTime(current.year, current.month, current.day, 20, 0));
          current = current.add(Duration(days: 1));
        }
        break;
      default:
        // Personalizado - usar solo la fecha original
        scheduledDates.add(baseDate);
        break;
    }

    return scheduledDates;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 24),

            // Formulario
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información del medicamento
                    _buildMedicationSection(),
                    const SizedBox(height: 24),

                    // Programación
                    _buildScheduleSection(),
                    const SizedBox(height: 24),

                    // Responsable
                    _buildResponsibleSection(),
                    const SizedBox(height: 24),

                    // Prioridad
                    _buildPrioritySection(),
                  ],
                ),
              ),
            ),

            // Botones
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Iconsax.health,
          size: 24,
          color: home.AppColors.primary500,
        ),
        const SizedBox(width: 12),
        Text(
          'Agregar Tratamiento',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: home.AppColors.neutral900,
          ),
        ),
      ],
    );
  }

  Widget _buildMedicationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información del Medicamento',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: home.AppColors.neutral900,
          ),
        ),
        const SizedBox(height: 16),

        // Nombre del medicamento
        _buildTextField(
          controller: _medicationNameController,
          label: 'Nombre del Medicamento',
          hint: 'Ej: Amoxicilina, Ibuprofeno',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'El nombre del medicamento es requerido';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Presentación y dosis
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildDropdown(
                label: 'Presentación',
                value: _selectedPresentation,
                items: _presentations,
                onChanged: (value) =>
                    setState(() => _selectedPresentation = value!),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: _buildTextField(
                controller: _dosageController,
                label: 'Dosis',
                hint: 'Ej: 500mg, 2ml, 1 tableta',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La dosis es requerida';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Vía de administración
        _buildDropdown(
          label: 'Vía de Administración',
          value: _selectedRoute,
          items: _routes,
          onChanged: (value) => setState(() => _selectedRoute = value!),
        ),
      ],
    );
  }

  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Programación',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: home.AppColors.neutral900,
          ),
        ),
        const SizedBox(height: 16),

        // Fecha y hora
        Row(
          children: [
            Expanded(
              child: _buildDateField(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTimeField(),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Frecuencia múltiple
        _buildFrequencySection(),
        const SizedBox(height: 16),

        // Duración e información adicional
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _durationController,
                label: 'Duración (días)',
                hint: 'Ej: 7, 10, 14',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La duración es requerida';
                  }
                  final days = int.tryParse(value);
                  if (days == null || days <= 0) {
                    return 'Ingrese un número válido de días';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _frequencyController,
                label: 'Frecuencia personalizada',
                hint: 'Ej: Dos veces al día',
                validator: (value) {
                  // Validación opcional ya que hay opciones múltiples
                  return null;
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Observaciones y Recomendaciones
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _observationsController,
                label: 'Observaciones',
                hint: 'Notas adicionales sobre el tratamiento',
                validator: null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _recommendationsController,
                label: 'Recomendaciones',
                hint: 'Recomendaciones para el seguimiento',
                validator: null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResponsibleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Responsable',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: home.AppColors.neutral900,
          ),
        ),
        const SizedBox(height: 16),

        // Doctor responsable
        _buildTextField(
          controller: TextEditingController(),
          label: 'Médico Responsable',
          hint: 'Nombre del médico que administrará el tratamiento',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'El médico responsable es requerido';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPrioritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prioridad',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: home.AppColors.neutral900,
          ),
        ),
        const SizedBox(height: 16),

        // Etiqueta para el dropdown de prioridad
        Text(
          'Nivel de Prioridad',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: home.AppColors.neutral900,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedPriority,
          items: _priorities
              .map((priority) => DropdownMenuItem<String>(
                    value: priority,
                    child: Text(_getPriorityLabel(priority)),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedPriority = value);
            }
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: home.AppColors.neutral200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: home.AppColors.neutral200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: home.AppColors.primary500),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: home.AppColors.neutral900,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: home.AppColors.neutral200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: home.AppColors.neutral200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: home.AppColors.primary500),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: home.AppColors.neutral900,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  ))
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: home.AppColors.neutral200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: home.AppColors.neutral200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: home.AppColors.primary500),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fecha',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: home.AppColors.neutral900,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: home.AppColors.neutral200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Iconsax.calendar_1,
                  size: 16,
                  color: home.AppColors.neutral500,
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd/MM/yyyy').format(_selectedDate),
                  style: TextStyle(
                    fontSize: 14,
                    color: home.AppColors.neutral900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hora',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: home.AppColors.neutral900,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectTime,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: home.AppColors.neutral200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Iconsax.clock,
                  size: 16,
                  color: home.AppColors.neutral500,
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedTime.format(context),
                  style: TextStyle(
                    fontSize: 14,
                    color: home.AppColors.neutral900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: widget.onCancel,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: home.AppColors.neutral200),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: home.AppColors.neutral700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: home.AppColors.primary500,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Agregar Tratamiento',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Validación adicional para frecuencias
      if (_selectedFrequencies.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selecciona al menos una frecuencia de aplicación'),
            backgroundColor: home.AppColors.danger500,
          ),
        );
        return;
      }

      final treatmentData = {
        'clinic_id': widget.clinicId,
        'patient_id': widget.patientId,
        'hospitalization_id': widget.hospitalizationId.isNotEmpty
            ? widget.hospitalizationId
            : null,
        // Campos específicos de la tabla follows
        'completion_type': 'treatment_given',
        'completion_status':
            'completed', // El tratamiento se ha programado con éxito
        'follow_type': 'treatment',

        // Información del medicamento
        'medication_name': _medicationNameController.text,
        'medication_dosage': _dosageController.text,
        'administration_route': _selectedRoute,

        // Programación
        'scheduled_date': _selectedDate.toIso8601String().split('T')[0],
        'scheduled_time':
            '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}:00',
        'frequency': _selectedFrequencies
            .join(', '), // Múltiples frecuencias separadas por coma
        'duration_days': int.parse(_durationController.text),
        'priority': _selectedPriority,
        'status': 'scheduled',

        // Campos adicionales
        'observations': _observationsController.text.isNotEmpty
            ? _observationsController.text
            : null,
        'recommendations': _recommendationsController.text.isNotEmpty
            ? _recommendationsController.text
            : null,

        // Información del responsable (si existe)
        'completed_by': null, // Se podría obtener del usuario actual
        'created_at': DateTime.now().toUtc().toIso8601String(),

        // Datos de recordatorios automáticos generados
        'reminders': _generateTreatmentReminders(
          baseTreatment: {
            'clinic_id': widget.clinicId,
            'patient_id': widget.patientId,
            'hospitalization_id': widget.hospitalizationId,
            'medication_name': _medicationNameController.text,
            'medication_dosage': _dosageController.text,
            'administration_route': _selectedRoute,
            'duration_days': int.parse(_durationController.text),
            'priority': _selectedPriority,
            'scheduled_date': _selectedDate.toIso8601String().split('T')[0],
            'scheduled_time':
                '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}:00',
            'observations': _observationsController.text.isNotEmpty
                ? _observationsController.text
                : null,
            'recommendations': _recommendationsController.text.isNotEmpty
                ? _recommendationsController.text
                : null,
          },
          frequencies: _selectedFrequencies,
        ),
      };

      widget.onSubmit?.call(treatmentData);
    }
  }

  Widget _buildFrequencySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frecuencia de Aplicación',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: home.AppColors.neutral900,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _frequencyOptions.map((frequency) {
            return FilterChip(
              label: Text(frequency),
              selected: _selectedFrequencies.contains(frequency),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedFrequencies.add(frequency);
                  } else {
                    _selectedFrequencies.remove(frequency);
                  }
                });
              },
              checkmarkColor: Colors.white,
              selectedColor: home.AppColors.primary500,
              labelStyle: TextStyle(
                color: _selectedFrequencies.contains(frequency)
                    ? Colors.white
                    : home.AppColors.neutral700,
              ),
            );
          }).toList(),
        ),
        if (_selectedFrequencies.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Selecciona al menos una frecuencia',
              style: TextStyle(
                fontSize: 12,
                color: home.AppColors.danger500,
              ),
            ),
          ),
      ],
    );
  }

  String _getPriorityLabel(String priority) {
    switch (priority) {
      case 'low':
        return 'Baja';
      case 'normal':
        return 'Normal';
      case 'high':
        return 'Alta';
      case 'urgent':
        return 'Urgente';
      default:
        return priority;
    }
  }
}
