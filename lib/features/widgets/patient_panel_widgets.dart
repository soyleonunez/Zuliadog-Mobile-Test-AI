import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../services/history_service.dart';

/// Widget para el panel de información del paciente
class PatientInfoPanel extends StatefulWidget {
  final PatientSummary? patient;
  final Function(Map<String, dynamic>) onSavePatientInfo;

  const PatientInfoPanel({
    super.key,
    required this.patient,
    required this.onSavePatientInfo,
  });

  @override
  State<PatientInfoPanel> createState() => _PatientInfoPanelState();
}

class _PatientInfoPanelState extends State<PatientInfoPanel> {
  late TextEditingController _speciesController;
  late TextEditingController _breedController;
  late TextEditingController _sexController;
  late TextEditingController _ageController;
  late TextEditingController _temperatureController;
  late TextEditingController _respirationController;
  late TextEditingController _pulseController;
  late TextEditingController _hydrationController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _updateControllersFromPatient();
  }

  void _initializeControllers() {
    _speciesController = TextEditingController();
    _breedController = TextEditingController();
    _sexController = TextEditingController();
    _ageController = TextEditingController();
    _temperatureController = TextEditingController();
    _respirationController = TextEditingController();
    _pulseController = TextEditingController();
    _hydrationController = TextEditingController();
  }

  void _updateControllersFromPatient() {
    if (widget.patient != null) {
      _speciesController.text = widget.patient!.species ?? '';
      _breedController.text = widget.patient!.breed ?? '';
      _sexController.text = widget.patient!.sex ?? '';
      _ageController.text = widget.patient!.ageLabel ?? '';
      _temperatureController.text =
          widget.patient!.temperature?.toString() ?? '';
      _respirationController.text =
          widget.patient!.respiration?.toString() ?? '';
      _pulseController.text = widget.patient!.pulse?.toString() ?? '';
      _hydrationController.text = widget.patient!.hydration ?? '';
    } else {
      _clearControllers();
    }
  }

  void _clearControllers() {
    _speciesController.clear();
    _breedController.clear();
    _sexController.clear();
    _ageController.clear();
    _temperatureController.clear();
    _respirationController.clear();
    _pulseController.clear();
    _hydrationController.clear();
  }

  @override
  void didUpdateWidget(PatientInfoPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.patient != widget.patient) {
      _updateControllersFromPatient();
    }
  }

  @override
  void dispose() {
    _speciesController.dispose();
    _breedController.dispose();
    _sexController.dispose();
    _ageController.dispose();
    _temperatureController.dispose();
    _respirationController.dispose();
    _pulseController.dispose();
    _hydrationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Ficha del Paciente
          Card(
            margin: const EdgeInsets.all(16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar y nombre
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor:
                            const Color(0xFF4F46E5).withOpacity(0.1),
                        child: const Icon(
                          Iconsax.pet,
                          size: 40,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.patient?.name ?? 'Sin nombre',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'N° de historia: ${widget.patient?.id ?? 'N/A'}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Información del paciente - Campos editables
                  _buildEditableInfoRow(
                      'Especie', _speciesController, 'Especie'),
                  _buildEditableInfoRow('Raza', _breedController, 'Raza'),
                  _buildEditableInfoRow('Sexo', _sexController, 'Sexo'),
                  _buildEditableInfoRow('Edad', _ageController, 'Edad'),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Signos vitales - Campos editables
                  Text(
                    'Signos Vitales',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildEditableVitalSign(
                      'Temperatura', _temperatureController, '°C'),
                  _buildEditableVitalSign(
                      'Respiración', _respirationController, 'rpm'),
                  _buildEditableVitalSign('Pulso', _pulseController, 'ppm'),
                  _buildEditableVitalSign(
                      'Hidratación', _hydrationController, ''),

                  const SizedBox(height: 16),

                  // Botón para guardar cambios
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _savePatientInfo,
                      icon: const Icon(Iconsax.save_2),
                      label: const Text('Guardar Cambios'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableInfoRow(
      String label, TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableVitalSign(
      String label, TextEditingController controller, String unit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                isDense: true,
              ),
            ),
          ),
          if (unit.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              unit,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _savePatientInfo() async {
    if (widget.patient == null) return;

    try {
      final patientData = {
        'species': _speciesController.text.trim(),
        'breed': _breedController.text.trim(),
        'sex': _sexController.text.trim(),
        'age_label': _ageController.text.trim(),
        'temperature': double.tryParse(_temperatureController.text.trim()),
        'respiration': int.tryParse(_respirationController.text.trim()),
        'pulse': int.tryParse(_pulseController.text.trim()),
        'hydration': _hydrationController.text.trim(),
      };

      widget.onSavePatientInfo(patientData);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar paciente: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Widget para el timeline de cambios del paciente
class PatientTimelinePanel extends StatelessWidget {
  final List<TimelineEvent> timeline;

  const PatientTimelinePanel({super.key, required this.timeline});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historial de Cambios',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: timeline.isEmpty
                  ? Center(
                      child: Text(
                        'No hay cambios registrados',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: timeline.length,
                      itemBuilder: (context, index) {
                        final event = timeline[index];
                        return _TimelineItem(event: event);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget para un elemento individual del timeline
class _TimelineItem extends StatelessWidget {
  final TimelineEvent event;

  const _TimelineItem({required this.event});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Punto del timeline
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: event.dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),

          // Contenido del evento
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (event.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    event.subtitle!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(event.at),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Hoy ${_formatTime(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Ayer ${_formatTime(dateTime)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} días atrás';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
