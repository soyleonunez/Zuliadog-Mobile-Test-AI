// lib/features/utilities/patients.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _supa = Supabase.instance.client;

/// Pantalla principal de Pacientes
class PatientsPage extends StatefulWidget {
  final String clinicId;
  const PatientsPage({super.key, required this.clinicId});

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  final _searchCtrl = TextEditingController();
  String? _speciesFilter; // 'CAN'/'FEL' si luego lo conectas a species_code
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<List<Map<String, dynamic>>> _fetch() async {
    var q =
        _supa.from('patients_search').select().eq('clinic_id', widget.clinicId);

    final text = _searchCtrl.text.trim();
    if (text.isNotEmpty) {
      q = q.ilike('patient_name', '%$text%');
    }
    if (_speciesFilter != null && _speciesFilter!.isNotEmpty) {
      q = q.eq('species_code', _speciesFilter!);
    }

    final resp = await q.order('patient_name');
    return List<Map<String, dynamic>>.from(resp);
  }

  void _reload() {
    setState(() {
      _future = _fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pacientes'),
        actions: [
          // Buscar
          SizedBox(
            width: 280,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => _reload(),
                decoration: InputDecoration(
                  hintText: 'Buscar paciente…',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filtros superiores
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                DropdownButtonFormField<String>(
                  value: _speciesFilter,
                  isDense: true,
                  decoration: const InputDecoration(
                    labelText: 'Especie',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Todas')),
                    DropdownMenuItem(value: 'CAN', child: Text('Canino')),
                    DropdownMenuItem(value: 'FEL', child: Text('Felino')),
                  ],
                  onChanged: (v) {
                    setState(() => _speciesFilter = v);
                    _reload();
                  },
                ),
                // Ejemplo de fecha/estado (opcional)
                // SizedBox(
                //   width: 180,
                //   child: TextField(
                //     readOnly: true,
                //     decoration: const InputDecoration(
                //       labelText: 'Fecha',
                //       border: OutlineInputBorder(),
                //       suffixIcon: Icon(Icons.today),
                //     ),
                //     onTap: () async {
                //       final d = await showDatePicker(
                //         context: context,
                //         firstDate: DateTime(2018),
                //         lastDate: DateTime(2100),
                //         initialDate: DateTime.now(),
                //       );
                //       setState(() => _dateFilter = d);
                //       _reload();
                //     },
                //   ),
                // ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                final rows = snap.data ?? [];
                if (rows.isEmpty) {
                  return const Center(child: Text('Sin pacientes'));
                }
                return _PatientsTable(
                  rows: rows,
                  onOpen: (id) => _openDrawerFor(id),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDrawerFor(null),
        icon: const Icon(Icons.add),
        label: const Text('Añadir Paciente'),
      ),
    );
  }

  Future<void> _openDrawerFor(String? patientId) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
                maxWidth: 520, minWidth: 480, maxHeight: 760),
            child: _PatientDrawer(
              clinicId: widget.clinicId,
              patientId: patientId,
            ),
          ),
        ),
      ),
    );
    if (saved == true) _reload();
  }
}

/// Tabla simple (responsive) inspirada en tu mock
class _PatientsTable extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final void Function(String id) onOpen;
  const _PatientsTable({required this.rows, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final th = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.all(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            alignment: Alignment.centerLeft,
            child: Text('Listado', style: th.titleMedium),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: rows.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final p = rows[i];
                final speciesBreed =
                    '${p['species_label'] ?? ''}${(p['breed_label'] ?? '') != null && (p['breed_label'] ?? '').toString().isNotEmpty ? ' / ${p['breed_label']}' : ''}';
                final age = p['age_label'] ?? '—';
                final owner = p['owner_name'] ?? '—';
                final phone = p['owner_phone'] ?? '—';
                final photo = p['photo_path'] ?? '';

                return ListTile(
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundImage:
                        photo.isNotEmpty ? NetworkImage(photo) : null,
                    child: photo.isNotEmpty ? null : const Text('🐾'),
                  ),
                  title: Text(p['patient_name'] ?? '—',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(speciesBreed),
                      const SizedBox(height: 2),
                      Text('Edad: $age   •   Dueño: $owner   •   Tel: $phone',
                          style: th.bodySmall),
                    ],
                  ),
                  trailing: TextButton(
                    onPressed: () => onOpen(p['patient_id']),
                    child: const Text('Ver'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Drawer de detalle + edición
class _PatientDrawer extends StatefulWidget {
  final String clinicId;
  final String? patientId; // null => nuevo
  const _PatientDrawer({required this.clinicId, required this.patientId});

  @override
  State<_PatientDrawer> createState() => _PatientDrawerState();
}

class _PatientDrawerState extends State<_PatientDrawer> {
  final _form = GlobalKey<FormState>();
  // Patient
  final _name = TextEditingController();
  final _mrn = TextEditingController();
  final _birth = TextEditingController();

  // Dropdown values
  String _selectedSpecies = 'CAN';
  String? _selectedBreed;
  String _selectedSex = 'Macho';

  // Data for dropdowns
  List<Map<String, dynamic>> _breeds = [];
  List<Map<String, dynamic>> _filteredBreeds = [];
  // Owner
  final _ownerName = TextEditingController();
  final _ownerPhone = TextEditingController();
  final _ownerEmail = TextEditingController();

  String? _patientRowId;
  String? _ownerId;

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Cargar razas desde la tabla breeds
      await _loadBreeds();

      if (widget.patientId == null) {
        // nuevo
        _loading = false;
        setState(() {});
        return;
      }
      final response = await _supa
          .from('patients')
          .select('*')
          .eq('id', widget.patientId!)
          .single();

      final p = response;

      _patientRowId = p['id'] as String?;
      _ownerId = p['owner_id'] as String?;

      _name.text = (p['name'] ?? '') as String;
      _mrn.text = (p['mrn'] ?? '') as String;
      _selectedSpecies = (p['species_code'] ?? 'CAN') as String;
      _selectedBreed = (p['breed_id'] ?? '') as String?;
      _birth.text =
          ((p['birth_date'] ?? '') as String).toString().substring(0, 10);
      _selectedSex = (p['sex'] ?? 'Macho') as String;

      // Filtrar razas según la especie seleccionada
      _filterBreedsBySpecies(_selectedSpecies);

      if (_ownerId != null) {
        final ownerResponse =
            await _supa.from('owners').select('*').eq('id', _ownerId!).single();

        final o = ownerResponse;
        _ownerName.text = (o['name'] ?? '') as String;
        _ownerPhone.text = (o['phone'] ?? '') as String;
        _ownerEmail.text = (o['email'] ?? '') as String;
      }
      _loading = false;
      setState(() {});
    } catch (e) {
      _error = e.toString();
      _loading = false;
      setState(() {});
    }
  }

  Future<void> _loadBreeds() async {
    try {
      final breeds = await _supa
          .from('breeds')
          .select('id, species_code, label')
          .order('label');

      _breeds = List<Map<String, dynamic>>.from(breeds);
      _filteredBreeds = List.from(_breeds);
    } catch (e) {
      print('Error cargando razas: $e');
      _breeds = [];
      _filteredBreeds = [];
    }
  }

  void _filterBreedsBySpecies(String speciesCode) {
    setState(() {
      _filteredBreeds = _breeds
          .where((breed) => breed['species_code'] == speciesCode)
          .toList();
      // Si la raza actual no es de la especie seleccionada, limpiar selección
      if (_selectedBreed != null &&
          !_filteredBreeds.any((breed) => breed['id'] == _selectedBreed)) {
        _selectedBreed = null;
      }
    });
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;

    final patientPayload = {
      'clinic_id': widget.clinicId,
      'name': _name.text.trim(),
      'mrn': _mrn.text.trim(),
      'species_code': _selectedSpecies,
      'breed_id': _selectedBreed,
      'birth_date': _birth.text.isEmpty ? null : _birth.text,
      'sex': _selectedSex,
    };

    try {
      if (_patientRowId == null) {
        final ins = await _supa
            .from('patients')
            .insert(patientPayload)
            .select('id')
            .single();
        _patientRowId = ins['id'] as String?;
      } else {
        await _supa
            .from('patients')
            .update(patientPayload)
            .eq('id', _patientRowId!);
      }

      // Dueño (si existe fila de owners)
      if (_ownerId != null) {
        await _supa.from('owners').update({
          'name':
              _ownerName.text.trim().isEmpty ? null : _ownerName.text.trim(),
          'phone':
              _ownerPhone.text.trim().isEmpty ? null : _ownerPhone.text.trim(),
          'email':
              _ownerEmail.text.trim().isEmpty ? null : _ownerEmail.text.trim(),
        }).eq('id', _ownerId!);
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final th = Theme.of(context).textTheme;
    return Material(
      elevation: 8,
      borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                      widget.patientId == null
                          ? 'Nuevo Paciente'
                          : 'Detalle del Paciente',
                      style: th.titleLarge),
                  const Spacer(),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(child: Text(_error!))
                        : Form(
                            key: _form,
                            child: ListView(
                              children: [
                                Text('Información del Paciente',
                                    style: th.titleMedium),
                                const SizedBox(height: 8),
                                GridView.count(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  children: [
                                    _field('Nombre', _name, required: true),
                                    _field('MRN', _mrn, required: true),
                                    _speciesDropdown(),
                                    _breedDropdown(),
                                    _dateField('Nacimiento', _birth),
                                    _sexDropdown(),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text('Información del Dueño',
                                    style: th.titleMedium),
                                const SizedBox(height: 8),
                                GridView.count(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  children: [
                                    _field('Nombre', _ownerName),
                                    _field('Teléfono', _ownerPhone),
                                    _field('Email', _ownerEmail, span2: true),
                                  ],
                                ),
                              ],
                            ),
                          ),
              ),
              const Divider(),
              Row(
                children: [
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c,
      {bool required = false, bool span2 = false}) {
    final input = TextFormField(
      controller: c,
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null
          : null,
      decoration:
          InputDecoration(labelText: label, border: const OutlineInputBorder()),
    );
    return span2
        ? GridTileBar(title: const SizedBox.shrink(), subtitle: input)
        : input;
  }

  Widget _dateField(String label, TextEditingController c) {
    return TextFormField(
      controller: c,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.event),
        border: const OutlineInputBorder(),
      ),
      onTap: () async {
        final initial = c.text.isNotEmpty
            ? DateTime.tryParse(c.text) ?? DateTime.now()
            : DateTime.now();
        final d = await showDatePicker(
          context: context,
          firstDate: DateTime(1995),
          lastDate: DateTime(2100),
          initialDate: initial,
        );
        if (d != null) c.text = DateFormat('yyyy-MM-dd').format(d);
      },
    );
  }

  Widget _speciesDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedSpecies,
      decoration: const InputDecoration(
        labelText: 'Especie',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'CAN', child: Text('Canino')),
        DropdownMenuItem(value: 'FEL', child: Text('Felino')),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedSpecies = value;
            _filterBreedsBySpecies(value);
          });
        }
      },
    );
  }

  Widget _breedDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedBreed,
      decoration: const InputDecoration(
        labelText: 'Raza',
        border: OutlineInputBorder(),
      ),
      items: _filteredBreeds.map((breed) {
        return DropdownMenuItem<String>(
          value: breed['id'] as String,
          child: Text(breed['label'] as String),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedBreed = value;
        });
      },
    );
  }

  Widget _sexDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedSex,
      decoration: const InputDecoration(
        labelText: 'Sexo',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'Macho', child: Text('Macho')),
        DropdownMenuItem(value: 'Hembra', child: Text('Hembra')),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedSex = value;
          });
        }
      },
    );
  }
}
