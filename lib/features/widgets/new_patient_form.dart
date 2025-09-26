import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zuliadog/core/notifications.dart';

final _supa = Supabase.instance.client;

/// Formulario para crear un nuevo paciente
class NewPatientForm extends StatefulWidget {
  final String clinicId;
  final VoidCallback? onPatientCreated;
  final VoidCallback? onCancel;

  const NewPatientForm({
    super.key,
    required this.clinicId,
    this.onPatientCreated,
    this.onCancel,
  });

  @override
  State<NewPatientForm> createState() => _NewPatientFormState();
}

class _NewPatientFormState extends State<NewPatientForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mrnController = TextEditingController();
  final _ageController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _ownerEmailController = TextEditingController();

  String _selectedSpecies = 'Canino';
  String _selectedSex = 'Macho';
  String _selectedBreed = '';
  String _selectedTemperament = 'Suave';
  List<Map<String, dynamic>> _availableBreeds = [];
  bool _breedsLoaded = false;
  bool _isLoading = false;

  // Opciones de temperamento
  final List<String> _temperamentOptions = [
    'Suave',
    'Activo',
    'Nervioso',
    'Agresivo',
    'Tranquilo',
  ];

  @override
  void initState() {
    super.initState();
    _loadBreeds();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mrnController.dispose();
    _ageController.dispose();
    _ownerNameController.dispose();
    _ownerPhoneController.dispose();
    _ownerEmailController.dispose();
    super.dispose();
  }

  Future<void> _loadBreeds() async {
    try {
      // Determinar el código de especie para filtrar las razas
      String speciesCode = '';
      switch (_selectedSpecies.toLowerCase()) {
        case 'canino':
          speciesCode = 'dog';
          break;
        case 'felino':
          speciesCode = 'cat';
          break;
        default:
          speciesCode = 'dog'; // Default to dog if species not found
      }

      final breeds = await _supa
          .from('breeds')
          .select('id, name, species_code')
          .eq('species_code', speciesCode)
          .order('name');

      if (mounted) {
        setState(() {
          _availableBreeds = List<Map<String, dynamic>>.from(breeds);
          _breedsLoaded = true;
          if (_selectedBreed.isNotEmpty &&
              !_availableBreeds
                  .any((breed) => breed['name'] == _selectedBreed)) {
            _selectedBreed =
                ''; // Clear selection if current breed is not available for new species
          }
        });
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError('Error al cargar razas: $e');
      }
    }
  }

  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Usar MRN manual o generar uno automático
      String mrn = _mrnController.text.trim();
      if (mrn.isEmpty) {
        mrn = await _generateUniqueMRN();
      } else {
        // Validar que el MRN no exista
        final existingPatient = await _supa
            .from('patients')
            .select('id')
            .eq('clinic_id', widget.clinicId)
            .eq('mrn', mrn)
            .maybeSingle();

        if (existingPatient != null) {
          if (mounted) {
            NotificationService.showError(
                'El MRN ya existe. Por favor, use otro número.');
          }
          return;
        }
      }

      // Crear paciente
      final patientData = {
        'clinic_id': widget.clinicId,
        'name': _nameController.text.trim(),
        'species': _selectedSpecies,
        'breed': _selectedBreed,
        'sex': _selectedSex,
        'temper': _selectedTemperament,
        'birth_date': _ageController.text.trim().isNotEmpty
            ? DateTime.parse(_ageController.text.trim())
            : null,
        'mrn': mrn,
        'created_at': DateTime.now().toIso8601String(),
      };

      final patientResponse = await _supa
          .from('patients')
          .insert(patientData)
          .select('id')
          .single();

      // Crear propietario si se proporcionó información
      if (_ownerNameController.text.trim().isNotEmpty) {
        final ownerData = {
          'clinic_id': widget.clinicId,
          'patient_id': patientResponse['id'],
          'name': _ownerNameController.text.trim(),
          'phone': _ownerPhoneController.text.trim(),
          'email': _ownerEmailController.text.trim(),
          'created_at': DateTime.now().toIso8601String(),
        };

        await _supa.from('owners').insert(ownerData);
      }

      if (mounted) {
        widget.onPatientCreated?.call();
        NotificationService.showSuccess('Paciente creado exitosamente');
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError('Error al crear paciente: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String> _generateUniqueMRN() async {
    // Obtener el último MRN de la clínica
    final lastPatient = await _supa
        .from('patients')
        .select('mrn')
        .eq('clinic_id', widget.clinicId)
        .order('mrn', ascending: false)
        .limit(1)
        .maybeSingle();

    int nextNumber = 1;
    if (lastPatient != null && lastPatient['mrn'] != null) {
      final lastMRN = lastPatient['mrn'].toString();
      if (lastMRN.length >= 6) {
        nextNumber =
            int.parse(lastMRN.substring(2)) + 1; // Asumiendo formato 00XXXX
      }
    }

    return nextNumber.toString().padLeft(6, '0');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Paciente'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _savePatient,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Iconsax.save_2),
            label: const Text('Guardar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información del Paciente
              const Text(
                'Información del Paciente',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Paciente *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El nombre es requerido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _mrnController,
                      decoration: const InputDecoration(
                        labelText: 'MRN (6 dígitos)',
                        border: OutlineInputBorder(),
                        helperText: 'Dejar vacío para generar automáticamente',
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          if (value.trim().length != 6) {
                            return 'El MRN debe tener 6 dígitos';
                          }
                          if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
                            return 'El MRN debe contener solo números';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedSpecies,
                      decoration: const InputDecoration(
                        labelText: 'Especie *',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Canino', 'Felino']
                          .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSpecies = value!;
                          _selectedBreed =
                              ''; // Reset breed when species changes
                        });
                        _loadBreeds(); // Reload breeds for the new species
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(), // Espacio vacío para mantener el layout
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _breedsLoaded
                        ? DropdownButtonFormField<String>(
                            value:
                                _selectedBreed.isEmpty ? null : _selectedBreed,
                            decoration: const InputDecoration(
                              labelText: 'Raza',
                              border: OutlineInputBorder(),
                            ),
                            items: _availableBreeds
                                .map((breed) => DropdownMenuItem<String>(
                                      value: breed['name'] as String,
                                      child: Text(breed['name'] as String),
                                    ))
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _selectedBreed = value ?? ''),
                            hint: const Text('Seleccione una raza'),
                          )
                        : const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Raza'),
                              SizedBox(height: 8),
                              SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedSex,
                      decoration: const InputDecoration(
                        labelText: 'Sexo *',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Macho', 'Hembra']
                          .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedSex = value!),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Agregar selección de temperamento
              DropdownButtonFormField<String>(
                value: _selectedTemperament,
                decoration: const InputDecoration(
                  labelText: 'Temperamento *',
                  border: OutlineInputBorder(),
                ),
                items: _temperamentOptions
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        ))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedTemperament = value!),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: 'Fecha de Nacimiento (YYYY-MM-DD)',
                  border: OutlineInputBorder(),
                  helperText: 'Formato: 2020-01-15',
                ),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    try {
                      DateTime.parse(value.trim());
                    } catch (e) {
                      return 'Formato de fecha inválido';
                    }
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Información del Propietario
              const Text(
                'Información del Propietario',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _ownerNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Propietario',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ownerPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _ownerEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
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
}
