// =====================================================
// FORMULARIO DE PACIENTES - ESTRUCTURA CORREGIDA
// Compatible con el esquema de base de datos actual
// =====================================================

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/config.dart';
import '../../core/theme.dart';

final _supa = Supabase.instance.client;

class ModernPatientForm extends StatefulWidget {
  final VoidCallback? onPatientCreated;
  final VoidCallback? onCancel;

  const ModernPatientForm({
    super.key,
    this.onPatientCreated,
    this.onCancel,
  });

  @override
  State<ModernPatientForm> createState() => _ModernPatientFormState();
}

class _ModernPatientFormState extends State<ModernPatientForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _historyNumberController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  final _weightController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _pulseController = TextEditingController();
  final _respirationController = TextEditingController();
  final _hydrationController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedSpeciesCode = 'DOG';
  String? _selectedBreedId;
  String _selectedSex = 'M';
  String _selectedTemperament = 'Normal';
  DateTime? _selectedBirthDate;
  bool _isLoading = false;

  List<Map<String, dynamic>> _speciesOptions = [];
  List<Map<String, dynamic>> _breedOptions = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _historyNumberController.dispose();
    _ownerNameController.dispose();
    _ownerPhoneController.dispose();
    _ownerEmailController.dispose();
    _weightController.dispose();
    _temperatureController.dispose();
    _pulseController.dispose();
    _respirationController.dispose();
    _hydrationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadSpecies(),
      _loadBreeds(),
    ]);
  }

  Future<void> _loadSpecies() async {
    try {
      // Las especies están hardcodeadas según el esquema
      setState(() {
        _speciesOptions = [
          {'code': 'DOG', 'label': 'Canino'},
          {'code': 'CAT', 'label': 'Felino'},
          {'code': 'OTHER', 'label': 'Otros'},
        ];
      });
    } catch (e) {
      _showError('Error al cargar especies: $e');
    }
  }

  Future<void> _loadBreeds() async {
    try {
      final response = await _supa
          .from('breeds')
          .select('id, species_code, label, species_label')
          .eq('species_code', _selectedSpeciesCode)
          .order('label');

      setState(() {
        _breedOptions = List<Map<String, dynamic>>.from(response);
        _selectedBreedId = null; // Reset breed selection
      });
    } catch (e) {
      _showError('Error al cargar razas: $e');
    }
  }

  void _onSpeciesChanged(String? speciesCode) {
    if (speciesCode != null && speciesCode != _selectedSpeciesCode) {
      setState(() {
        _selectedSpeciesCode = speciesCode;
        _selectedBreedId = null; // Reset breed selection
      });
      _loadBreeds();
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final clinicId = AppConfig.clinicId;

      // 1. Crear o buscar el propietario
      String ownerId;
      if (_ownerNameController.text.trim().isNotEmpty) {
        ownerId = await _createOrFindOwner();
      } else {
        throw Exception('El nombre del propietario es requerido');
      }

      // 2. Crear el paciente
      final patientData = {
        'mrn': _historyNumberController.text.trim(),
        'name': _nameController.text.trim(),
        'species_code': _selectedSpeciesCode,
        'breed_id': _selectedBreedId,
        'breed': _breedOptions.firstWhere(
          (b) => b['id'] == _selectedBreedId,
          orElse: () => {'label': ''},
        )['label'],
        'sex': _selectedSex,
        'birth_date': _selectedBirthDate?.toIso8601String().split('T')[0],
        'weight_kg': double.tryParse(_weightController.text.trim()),
        'notes': _notesController.text.trim(),
        'owner_id': ownerId,
        'clinic_id': clinicId,
        'history_number': _historyNumberController.text.trim(),
        'temper': _selectedTemperament,
        'temperature': double.tryParse(_temperatureController.text.trim()),
        'respiration': int.tryParse(_respirationController.text.trim()),
        'pulse': int.tryParse(_pulseController.text.trim()),
        'hydration': _hydrationController.text.trim(),
        'weight': _weightController.text.trim().isNotEmpty
            ? '${_weightController.text.trim()} kg'
            : null,
        'admission_date': DateTime.now().toIso8601String().split('T')[0],
      };

      // Creando paciente
      final patientResponse =
          await _supa.from('patients').insert(patientData).select().single();

      // Paciente creado exitosamente
      _showSuccess('Paciente creado exitosamente');

      // Navegar directamente a las historias médicas del paciente recién creado
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/historias',
          arguments: {
            'patient_id': patientResponse['id'],
            'historyNumber': patientResponse['history_number'],
          },
        );
      }

      if (widget.onPatientCreated != null) {
        widget.onPatientCreated!();
      }

      // Limpiar formulario
      _clearForm();
    } catch (e) {
      _showError('Error al crear paciente: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _createOrFindOwner() async {
    final ownerName = _ownerNameController.text.trim();
    final ownerPhone = _ownerPhoneController.text.trim();
    final ownerEmail = _ownerEmailController.text.trim();

    // Buscar propietario existente
    try {
      final existing = await _supa
          .from('owners')
          .select('id')
          .eq('name', ownerName)
          .maybeSingle();

      if (existing != null) {
        return existing['id'];
      }
    } catch (e) {}

    // Crear nuevo propietario
    final ownerData = {
      'name': ownerName,
      'phone': ownerPhone.isNotEmpty ? ownerPhone : null,
      'email': ownerEmail.isNotEmpty ? ownerEmail : null,
      'clinic_id': AppConfig.clinicId,
    };

    final response =
        await _supa.from('owners').insert(ownerData).select().single();

    return response['id'];
  }

  void _clearForm() {
    _nameController.clear();
    _historyNumberController.clear();
    _ownerNameController.clear();
    _ownerPhoneController.clear();
    _ownerEmailController.clear();
    _weightController.clear();
    _temperatureController.clear();
    _pulseController.clear();
    _respirationController.clear();
    _hydrationController.clear();
    _notesController.clear();

    setState(() {
      _selectedSpeciesCode = 'DOG';
      _selectedBreedId = null;
      _selectedSex = 'M';
      _selectedTemperament = 'Normal';
      _selectedBirthDate = null;
    });
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: AppColors.primary500.withOpacity(.08),
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary500,
              secondary: AppColors.primary600,
              surface: Colors.white,
              onSurface: AppColors.neutral900,
            ),
      ),
      child: Scaffold(
        backgroundColor: AppColors.neutral50,
        appBar: AppBar(
          title: const Text('Crear Nuevo Paciente'),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            TextButton(
              onPressed: widget.onCancel,
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMainForm(),
                  const SizedBox(height: 24),
                  _buildAssistantPanel(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainForm() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.neutral200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información del Paciente
              Text(
                'Información del Paciente',
                style: AppText.heading3.copyWith(
                  color: AppColors.neutral900,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Campos en columnas simples para mejor rendimiento
              Column(
                children: [
                  // Primera fila
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _nameController,
                          label: 'Nombre de la Mascota',
                          icon: Iconsax.pet,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Campo requerido';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _historyNumberController,
                          label: 'Número de Historia',
                          icon: Iconsax.document_text,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Campo requerido';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Segunda fila
                  Row(
                    children: [
                      Expanded(child: _buildSpeciesDropdown()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildBreedDropdown()),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tercera fila
                  Row(
                    children: [
                      Expanded(child: _buildDateField()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildSexDropdown()),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Cuarta fila
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _weightController,
                          label: 'Peso (kg)',
                          icon: Iconsax.weight,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTemperamentDropdown()),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Signos Vitales
              Text(
                'Signos Vitales',
                style: AppText.heading3.copyWith(
                  color: AppColors.neutral900,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Signos vitales en filas simples
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _temperatureController,
                          label: 'Temperatura (°C)',
                          icon: Iconsax.cpu,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _pulseController,
                          label: 'Pulso (ppm)',
                          icon: Iconsax.heart,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _respirationController,
                          label: 'Respiración (rpm)',
                          icon: Iconsax.wind,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _hydrationController,
                          label: 'Hidratación',
                          icon: Iconsax.drop,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Información del propietario
              Text(
                'Información del Propietario',
                style: AppText.heading3.copyWith(
                  color: AppColors.neutral900,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Información del propietario en filas simples
              Column(
                children: [
                  _buildTextField(
                    controller: _ownerNameController,
                    label: 'Nombre del Propietario',
                    icon: Iconsax.user,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo requerido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _ownerPhoneController,
                          label: 'Teléfono',
                          icon: Iconsax.call,
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _ownerEmailController,
                          label: 'Email',
                          icon: Iconsax.sms,
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Notas
              Text(
                'Notas Adicionales',
                style: AppText.heading3.copyWith(
                  color: AppColors.neutral900,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText:
                      'Cualquier otra información relevante sobre el paciente...',
                  prefixIcon:
                      Icon(Iconsax.note_text, color: AppColors.neutral400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.neutral300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.neutral300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: AppColors.primary500, width: 2),
                  ),
                  filled: true,
                  fillColor: AppColors.neutral50,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),

              const SizedBox(height: 24),

              // Botón de crear
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _savePatient,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary500,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Crear Paciente',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.neutral400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.neutral300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.neutral300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary500, width: 2),
        ),
        filled: true,
        fillColor: enabled ? AppColors.neutral50 : AppColors.neutral100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      validator: validator,
    );
  }

  Widget _buildSpeciesDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedSpeciesCode,
      decoration: InputDecoration(
        labelText: 'Especie',
        prefixIcon: Icon(Iconsax.pet, color: AppColors.neutral400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.neutral300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.neutral300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary500, width: 2),
        ),
        filled: true,
        fillColor: AppColors.neutral50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: _speciesOptions.map((species) {
        return DropdownMenuItem<String>(
          value: species['code'],
          child: Text(species['label']),
        );
      }).toList(),
      onChanged: _onSpeciesChanged,
    );
  }

  Widget _buildBreedDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedBreedId,
      decoration: InputDecoration(
        labelText: 'Raza',
        prefixIcon: Icon(Iconsax.crown, color: AppColors.neutral400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.neutral300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.neutral300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary500, width: 2),
        ),
        filled: true,
        fillColor: AppColors.neutral50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: _breedOptions.map((breed) {
        return DropdownMenuItem<String>(
          value: breed['id'],
          child: Text(breed['label']),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedBreedId = value;
        });
      },
    );
  }

  Widget _buildSexDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedSex,
      decoration: InputDecoration(
        labelText: 'Sexo',
        prefixIcon: Icon(Iconsax.user, color: AppColors.neutral400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.neutral300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.neutral300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary500, width: 2),
        ),
        filled: true,
        fillColor: AppColors.neutral50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: const [
        DropdownMenuItem(value: 'M', child: Text('Macho')),
        DropdownMenuItem(value: 'F', child: Text('Hembra')),
      ],
      onChanged: (value) {
        setState(() {
          _selectedSex = value ?? 'M';
        });
      },
    );
  }

  Widget _buildTemperamentDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedTemperament,
      decoration: InputDecoration(
        labelText: 'Temperamento',
        prefixIcon: Icon(Iconsax.emoji_happy, color: AppColors.neutral400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.neutral300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.neutral300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary500, width: 2),
        ),
        filled: true,
        fillColor: AppColors.neutral50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: const [
        DropdownMenuItem(value: 'Normal', child: Text('Normal')),
        DropdownMenuItem(value: 'Agresivo', child: Text('Agresivo')),
        DropdownMenuItem(value: 'Tímido', child: Text('Tímido')),
        DropdownMenuItem(value: 'Muy dócil', child: Text('Muy dócil')),
        DropdownMenuItem(value: 'Nervioso', child: Text('Nervioso')),
      ],
      onChanged: (value) {
        setState(() {
          _selectedTemperament = value ?? 'Normal';
        });
      },
    );
  }

  Widget _buildDateField() {
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: 'Fecha de Nacimiento',
        prefixIcon: Icon(Iconsax.calendar, color: AppColors.neutral400),
        suffixIcon: IconButton(
          icon: Icon(Iconsax.calendar_1, color: AppColors.neutral400),
          onPressed: () => _selectDate(context),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.neutral300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.neutral300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary500, width: 2),
        ),
        filled: true,
        fillColor: AppColors.neutral50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      controller: TextEditingController(
        text: _selectedBirthDate != null
            ? DateFormat('dd/MM/yyyy').format(_selectedBirthDate!)
            : '',
      ),
    );
  }

  Widget _buildAssistantPanel() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.neutral200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Asistente de Creación',
              style: AppText.heading3.copyWith(
                color: AppColors.neutral900,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Consejo rápido
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Iconsax.lamp_charge,
                          color: AppColors.primary600, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Consejo Rápido',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Asegúrese de que el número de historia sea único para cada paciente para evitar duplicados.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.neutral700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Pasos a seguir
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.neutral50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.neutral200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Iconsax.task_square,
                          color: AppColors.neutral600, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Pasos a seguir',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.neutral700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildStep('1. Rellene los datos del paciente.'),
                  _buildStep('2. Complete la información del propietario.'),
                  _buildStep('3. Describa el motivo de la visita.'),
                  _buildStep(
                      '4. Haga clic en "Crear Paciente" para continuar.'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Paciente existente
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Iconsax.info_circle, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '¿Paciente Existente?',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Si el paciente ya tiene una historia, búsquelo en la pantalla principal en lugar de crear una nueva.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.neutral700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 8),
            decoration: BoxDecoration(
              color: AppColors.neutral400,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.neutral600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
