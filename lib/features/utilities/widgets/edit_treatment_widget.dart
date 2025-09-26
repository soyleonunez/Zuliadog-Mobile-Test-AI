import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../home.dart' as home;

class EditTreatmentWidget extends StatefulWidget {
  final Map<String, dynamic> treatment;
  final Function(Map<String, dynamic>) onSubmit;
  final VoidCallback onCancel;

  const EditTreatmentWidget({
    super.key,
    required this.treatment,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  State<EditTreatmentWidget> createState() => _EditTreatmentWidgetState();
}

class _EditTreatmentWidgetState extends State<EditTreatmentWidget> {
  late TextEditingController _medicationNameController;
  late TextEditingController _presentationController;
  late TextEditingController _dosageController;
  late TextEditingController _routeController;
  late TextEditingController _doctorController;
  late TextEditingController _notesController;

  late DateTime _scheduledDate;
  late TimeOfDay _scheduledTime;
  late String _status;
  late String _priority;

  @override
  void initState() {
    super.initState();

    // Inicializar controladores con datos existentes
    _medicationNameController = TextEditingController(
      text: widget.treatment['medication_name'] ?? '',
    );
    _presentationController = TextEditingController(
      text: widget.treatment['presentation'] ?? '',
    );
    _dosageController = TextEditingController(
      text: widget.treatment['dosage'] ?? '',
    );
    _routeController = TextEditingController(
      text: widget.treatment['administration_route'] ?? '',
    );
    _doctorController = TextEditingController(
      text: widget.treatment['responsible_doctor'] ?? '',
    );
    _notesController = TextEditingController(
      text: widget.treatment['observations'] ?? '',
    );

    // Inicializar fechas y estados
    _scheduledDate = widget.treatment['scheduled_date'] != null
        ? DateTime.parse(widget.treatment['scheduled_date'].toString())
        : DateTime.now();
    _scheduledTime = widget.treatment['scheduled_time'] != null
        ? TimeOfDay.fromDateTime(
            DateTime.parse(widget.treatment['scheduled_time'].toString()))
        : TimeOfDay.now();
    _status = widget.treatment['status'] ?? 'scheduled';
    _priority = widget.treatment['priority'] ?? 'normal';
  }

  @override
  void dispose() {
    _medicationNameController.dispose();
    _presentationController.dispose();
    _dosageController.dispose();
    _routeController.dispose();
    _doctorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 600,
      height: 500,
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Iconsax.health,
                size: 24,
                color: home.AppColors.primary600,
              ),
              const SizedBox(width: 12),
              Text(
                'Editar Tratamiento',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: home.AppColors.neutral900,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: widget.onCancel,
                icon: Icon(Iconsax.close_circle),
                iconSize: 24,
                color: home.AppColors.neutral500,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Formulario
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Fila 1: Nombre del medicamento y Presentación
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _medicationNameController,
                          label: 'Nombre del Medicamento',
                          icon: Iconsax.health,
                          isRequired: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _presentationController,
                          label: 'Presentación',
                          icon: Iconsax.health,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Fila 2: Dosificación y Vía de administración
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _dosageController,
                          label: 'Dosificación',
                          icon: Iconsax.weight,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _routeController,
                          label: 'Vía de Administración',
                          icon: Iconsax.direct,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Fila 3: Fecha y Hora programada
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

                  // Fila 4: Estado y Prioridad
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusDropdown(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildPriorityDropdown(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Médico responsable
                  _buildTextField(
                    controller: _doctorController,
                    label: 'Médico Responsable',
                    icon: Iconsax.user,
                  ),

                  const SizedBox(height: 16),

                  // Notas
                  _buildTextField(
                    controller: _notesController,
                    label: 'Notas y Observaciones',
                    icon: Iconsax.document_text,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Botones de acción
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onCancel,
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: home.AppColors.neutral600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _submitTreatment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: home.AppColors.primary500,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Guardar Cambios',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: home.AppColors.neutral600,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: home.AppColors.neutral700,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  fontSize: 14,
                  color: home.AppColors.danger500,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: 'Ingrese ${label.toLowerCase()}',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: home.AppColors.neutral200,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: home.AppColors.neutral200,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: home.AppColors.primary500,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Iconsax.calendar_1,
              size: 16,
              color: home.AppColors.neutral600,
            ),
            const SizedBox(width: 8),
            Text(
              'Fecha Programada',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: home.AppColors.neutral700,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(
                fontSize: 14,
                color: home.AppColors.danger500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: home.AppColors.neutral200,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(
                  DateFormat('dd/MM/yyyy').format(_scheduledDate),
                  style: TextStyle(
                    fontSize: 14,
                    color: home.AppColors.neutral900,
                  ),
                ),
                const Spacer(),
                Icon(
                  Iconsax.calendar_1,
                  size: 16,
                  color: home.AppColors.neutral500,
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
        Row(
          children: [
            Icon(
              Iconsax.clock,
              size: 16,
              color: home.AppColors.neutral600,
            ),
            const SizedBox(width: 8),
            Text(
              'Hora Programada',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: home.AppColors.neutral700,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(
                fontSize: 14,
                color: home.AppColors.danger500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectTime,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: home.AppColors.neutral200,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(
                  _scheduledTime.format(context),
                  style: TextStyle(
                    fontSize: 14,
                    color: home.AppColors.neutral900,
                  ),
                ),
                const Spacer(),
                Icon(
                  Iconsax.clock,
                  size: 16,
                  color: home.AppColors.neutral500,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Iconsax.status_up,
              size: 16,
              color: home.AppColors.neutral600,
            ),
            const SizedBox(width: 8),
            Text(
              'Estado',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: home.AppColors.neutral700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _status,
          onChanged: (value) => setState(() => _status = value!),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: home.AppColors.neutral200,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: home.AppColors.neutral200,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: home.AppColors.primary500,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          items: [
            DropdownMenuItem(
              value: 'scheduled',
              child: Text('Programado'),
            ),
            DropdownMenuItem(
              value: 'in_progress',
              child: Text('En Progreso'),
            ),
            DropdownMenuItem(
              value: 'completed',
              child: Text('Completado'),
            ),
            DropdownMenuItem(
              value: 'cancelled',
              child: Text('Cancelado'),
            ),
            DropdownMenuItem(
              value: 'overdue',
              child: Text('Vencido'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriorityDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Iconsax.flag,
              size: 16,
              color: home.AppColors.neutral600,
            ),
            const SizedBox(width: 8),
            Text(
              'Prioridad',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: home.AppColors.neutral700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _priority,
          onChanged: (value) => setState(() => _priority = value!),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: home.AppColors.neutral200,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: home.AppColors.neutral200,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: home.AppColors.primary500,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          items: [
            DropdownMenuItem(
              value: 'low',
              child: Text('Baja'),
            ),
            DropdownMenuItem(
              value: 'normal',
              child: Text('Normal'),
            ),
            DropdownMenuItem(
              value: 'high',
              child: Text('Alta'),
            ),
            DropdownMenuItem(
              value: 'urgent',
              child: Text('Urgente'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now().subtract(Duration(days: 30)),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (date != null) {
      setState(() => _scheduledDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _scheduledTime,
    );

    if (time != null) {
      setState(() => _scheduledTime = time);
    }
  }

  void _submitTreatment() {
    if (_medicationNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('El nombre del medicamento es requerido'),
          backgroundColor: home.AppColors.danger500,
        ),
      );
      return;
    }

    final treatmentData = {
      'medication_name': _medicationNameController.text.trim(),
      'presentation': _presentationController.text.trim(),
      'dosage': _dosageController.text.trim(),
      'administration_route': _routeController.text.trim(),
      'scheduled_date': _scheduledDate.toIso8601String().split('T')[0],
      'scheduled_time':
          '${_scheduledTime.hour.toString().padLeft(2, '0')}:${_scheduledTime.minute.toString().padLeft(2, '0')}:00',
      'status': _status,
      'priority': _priority,
      'responsible_doctor': _doctorController.text.trim(),
      'observations': _notesController.text.trim(),
    };

    widget.onSubmit(treatmentData);
  }
}
