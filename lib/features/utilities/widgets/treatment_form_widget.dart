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

  String _selectedPresentation = 'Tableta';
  String _selectedRoute = 'Oral';
  String _selectedPriority = 'normal';
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

  @override
  void dispose() {
    _medicationNameController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    _durationController.dispose();
    super.dispose();
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

        // Frecuencia y duración
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _frequencyController,
                label: 'Frecuencia',
                hint: 'Ej: Cada 8 horas, Diario',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La frecuencia es requerida';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
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
        _buildDropdown(
          label: 'Nivel de Prioridad',
          value: _selectedPriority,
          items: _priorities.map((p) => _getPriorityLabel(p)).toList(),
          onChanged: (value) {
            final index = _priorities.indexOf(value!);
            setState(() => _selectedPriority = _priorities[index]);
          },
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
      final treatmentData = {
        'clinic_id': widget.clinicId,
        'patient_id': widget.patientId,
        'hospitalization_id': widget.hospitalizationId,
        'medication_name': _medicationNameController.text,
        'presentation': _selectedPresentation,
        'dosage': _dosageController.text,
        'administration_route': _selectedRoute,
        'scheduled_date': _selectedDate.toIso8601String().split('T')[0],
        'scheduled_time':
            '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}:00',
        'frequency': _frequencyController.text,
        'duration_days': int.parse(_durationController.text),
        'priority': _selectedPriority,
        'status': 'scheduled',
      };

      widget.onSubmit?.call(treatmentData);
    }
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
