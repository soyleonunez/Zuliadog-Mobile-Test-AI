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
  final _durationController = TextEditingController();
  final _observationsController = TextEditingController();
  final _medicalResponsibleController = TextEditingController();

  // Variables de estado
  String _selectedRoute = 'Oral';
  String _selectedPriority = 'normal';
  String _selectedFrequency = 'Cada 12 horas';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  // Listas de opciones simplificadas
  final List<String> _routes = [
    'Oral',
    'Intravenosa (IV)',
    'Intramuscular (IM)',
    'Subcutánea',
    'Tópica',
    'Rectal',
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
    'Mañana y noche',
    'Personalizado'
  ];

  @override
  void dispose() {
    _medicationNameController.dispose();
    _dosageController.dispose();
    _durationController.dispose();
    _observationsController.dispose();
    _medicalResponsibleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header simplificado
            _buildHeader(),
            const SizedBox(height: 20),

            // Formulario principal
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sección del medicamento
                    _buildMedicationSection(),
                    const SizedBox(height: 20),

                    // Sección de programación
                    _buildScheduleSection(),
                    const SizedBox(height: 20),

                    // Sección del responsable médico
                    _buildMedicalResponsibleSection(),
                    const SizedBox(height: 20),

                    // Sección de prioridad
                    _buildPrioritySection(),
                  ],
                ),
              ),
            ),

            // Botones de acción
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
          'Nuevo Tratamiento',
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: home.AppColors.neutral50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: home.AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Medicamento',
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
            icon: Iconsax.health,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'El nombre del medicamento es requerido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Dosis y vía de administración
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildTextField(
                  controller: _dosageController,
                  label: 'Dosis',
                  hint: 'Ej: 500mg, 2ml',
                  icon: Iconsax.weight,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La dosis es requerida';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _buildDropdown(
                  label: 'Vía',
                  value: _selectedRoute,
                  items: _routes,
                  onChanged: (value) => setState(() => _selectedRoute = value!),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: home.AppColors.neutral50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: home.AppColors.neutral200),
      ),
      child: Column(
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
                flex: 3,
                child: _buildDropdown(
                  label: 'Frecuencia',
                  value: _selectedFrequency,
                  items: _frequencyOptions,
                  onChanged: (value) =>
                      setState(() => _selectedFrequency = value!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _buildTextField(
                  controller: _durationController,
                  label: 'Duración (días)',
                  hint: '7',
                  icon: Iconsax.calendar,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La duración es requerida';
                    }
                    final days = int.tryParse(value);
                    if (days == null || days <= 0) {
                      return 'Ingrese un número válido';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalResponsibleSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: home.AppColors.neutral50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: home.AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Responsable Médico',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: home.AppColors.neutral900,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _medicalResponsibleController,
            label: 'Médico Responsable',
            hint: 'Nombre del médico',
            icon: Iconsax.user,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'El médico responsable es requerido';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrioritySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: home.AppColors.neutral50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: home.AppColors.neutral200),
      ),
      child: Column(
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
            items: _priorities,
            onChanged: (value) => setState(() => _selectedPriority = value!),
          ),
          const SizedBox(height: 16),

          // Campo opcional de observaciones
          _buildTextField(
            controller: _observationsController,
            label: 'Observaciones (opcional)',
            hint: 'Notas adicionales sobre el tratamiento',
            icon: Iconsax.document_text,
            validator: null,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
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
            prefixIcon: Icon(icon, size: 18, color: home.AppColors.neutral500),
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
              borderSide:
                  BorderSide(color: home.AppColors.primary500, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: home.AppColors.danger500),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: true,
            fillColor: Colors.white,
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
              borderSide:
                  BorderSide(color: home.AppColors.primary500, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: true,
            fillColor: Colors.white,
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
          'Fecha de Inicio',
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
              color: Colors.white,
            ),
            child: Row(
              children: [
                Icon(
                  Iconsax.calendar_1,
                  size: 18,
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
              color: Colors.white,
            ),
            child: Row(
              children: [
                Icon(
                  Iconsax.clock,
                  size: 18,
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
              padding: const EdgeInsets.symmetric(vertical: 14),
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
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Crear Tratamiento',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
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
      locale: const Locale('es', 'ES'),
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Crear el objeto de tratamiento con todos los campos requeridos
      final treatmentData = {
        // Campos requeridos para evitar el error de constraint
        'clinic_id': widget.clinicId,
        'patient_id': widget.patientId,
        'hospitalization_id': widget.hospitalizationId.isNotEmpty
            ? widget.hospitalizationId
            : null,

        // Campos requeridos que estaban causando el error
        'completion_type': 'treatment_scheduled', // Tipo de completación
        'completion_status': 'pending', // Estado inicial del tratamiento
        'follow_type': 'treatment', // Tipo de seguimiento

        // Información del medicamento
        'medication_name': _medicationNameController.text,
        'medication_dosage': _dosageController.text,
        'administration_route': _selectedRoute,

        // Programación
        'scheduled_date': _selectedDate.toIso8601String().split('T')[0],
        'scheduled_time':
            '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}:00',
        'frequency': _selectedFrequency,
        'duration_days': int.parse(_durationController.text),
        'priority': _selectedPriority,
        'status': 'scheduled',

        // Campos adicionales
        'observations': _observationsController.text.isNotEmpty
            ? _observationsController.text
            : null,

        // Información del responsable médico
        'completed_by':
            null, // Se puede obtener del usuario actual si está disponible
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };

      // Llamar al callback con los datos del tratamiento
      widget.onSubmit?.call(treatmentData);

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tratamiento creado exitosamente'),
          backgroundColor: home.AppColors.success500,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
