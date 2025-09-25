import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../menu.dart';
import '../home.dart' as home;
import '../../core/navigation.dart';
import 'historias.dart';
import 'recetas.dart';
import 'laboratorio.dart';
import 'agenda.dart';
import 'recursos.dart';
import 'tickets.dart';
import 'reportes.dart';

final _supa = Supabase.instance.client;

enum _Vista { gantt, calendario }

class HospitalizacionPage extends StatelessWidget {
  const HospitalizacionPage({super.key});

  static const route = '/hospitalizacion';

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        focusColor: home.AppColors.primary500.withOpacity(.12),
        hoverColor: home.AppColors.neutral50,
        splashColor: home.AppColors.primary500.withOpacity(.08),
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: home.AppColors.primary500,
              secondary: home.AppColors.primary600,
              surface: Colors.white,
              onSurface: home.AppColors.neutral900,
            ),
      ),
      child: Scaffold(
        backgroundColor: home.AppColors.neutral50,
        body: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSidebar(
                  activeRoute: 'frame_hospitalizacion',
                  onTap: (route) => _handleNavigation(context, route),
                  userRole: UserRole.doctor,
                ),
                Expanded(
                  child: Column(
                    children: [
                      _buildTopBar('Hospitalización'),
                      const Divider(
                          height: 1, color: home.AppColors.neutral200),
                      Expanded(
                        child: const HospitalizacionPanel(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
            bottom: BorderSide(color: home.AppColors.neutral200, width: 1)),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: home.AppColors.neutral900,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  void _handleNavigation(BuildContext context, String route) {
    if (route == 'frame_home') {
      NavigationHelper.navigateToRoute(context, '/home');
    } else if (route == 'frame_hospitalizacion') {
      // Ya estamos en hospitalización
    } else {
      // Navegar a la página correspondiente
      String routePath = '/home'; // fallback
      switch (route) {
        case 'frame_pacientes':
          routePath = '/pacientes';
          break;
        case 'frame_historias':
          routePath = HistoriasPage.route;
          break;
        case 'frame_recetas':
          routePath = RecetasPage.route;
          break;
        case 'frame_laboratorio':
          routePath = LaboratorioPage.route;
          break;
        case 'frame_agenda':
          routePath = AgendaPage.route;
          break;
        case 'frame_hospitalizacion':
          routePath = HospitalizacionPage.route;
          break;
        case 'frame_recursos':
          routePath = RecursosPage.route;
          break;
        case 'frame_tickets':
          routePath = TicketsPage.route;
          break;
        case 'frame_reportes':
          routePath = ReportesPage.route;
          break;
      }
      NavigationHelper.navigateToRoute(context, routePath);
    }
  }
}

/// ===============================
/// HOSPITALIZACIÓN – PANEL HÍBRIDO
/// Cards por paciente + Gantt/Calendario + Lateral de actualizaciones
/// ===============================

class HospitalizacionPanel extends StatefulWidget {
  const HospitalizacionPanel({super.key});

  @override
  State<HospitalizacionPanel> createState() => _HospitalizacionPanelState();
}

class _HospitalizacionPanelState extends State<HospitalizacionPanel> {
  // --- Estado UI ---
  bool showUpdates = true;
  _Vista vista = _Vista.gantt;
  String? selectedPatientMrn;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // --- Datos de Supabase ---
  String? _clinicId;

  // Streams para datos en tiempo real
  late Stream<List<PacienteResumen>> _patientsStream;
  late Stream<List<TareaHosp>> _tasksStream;
  late Stream<List<UpdateItem>> _updatesStream;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadClinicId();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  bool _isHospitalizedPatient(Map<String, dynamic> patient) {
    // Un paciente está hospitalizado si:
    // 1. Tiene un status explícito de hospitalizado
    // 2. Tiene registros médicos recientes (últimos 7 días)
    // 3. Tiene documentos adjuntos recientes
    final status = patient['status']?.toString().toLowerCase();
    if (status == 'hospitalized' || status == 'estable') {
      return true;
    }

    // Verificar si tiene registros médicos recientes
    final recordDate = patient['record_date'];
    if (recordDate != null) {
      try {
        final recordDateTime = DateTime.parse(recordDate);
        final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
        if (recordDateTime.isAfter(sevenDaysAgo)) {
          return true;
        }
      } catch (e) {
        // Si no se puede parsear la fecha, asumir que no está hospitalizado
      }
    }

    return false;
  }

  Future<void> _loadClinicId() async {
    try {
      // Obtener el clinic_id del usuario autenticado
      final user = _supa.auth.currentUser;
      if (user != null) {
        // Buscar el clinic_id en la tabla clinic_roles
        final response = await _supa
            .from('clinic_roles')
            .select('clinic_id')
            .eq('user_id', user.id)
            .eq('is_active', true)
            .single();

        _clinicId = response['clinic_id'];
        _initializeStreams();
      } else {
        // Fallback al clinic_id hardcodeado si no hay usuario autenticado
        _clinicId = '4c17fddf-24ab-4a8d-9343-4cc4f6a4a203';
        _initializeStreams();
      }
    } catch (e) {
      // Fallback al clinic_id hardcodeado en caso de error
      _clinicId = '4c17fddf-24ab-4a8d-9343-4cc4f6a4a203';
      _initializeStreams();
    }
  }

  void _initializeStreams() {
    if (_clinicId == null) return;

    // Stream de pacientes hospitalizados desde v_app
    _patientsStream = _supa
        .from('v_app')
        .stream(primaryKey: ['patient_id'])
        .eq('clinic_id', _clinicId!)
        .map((data) {
          // Agrupar por patient_id para evitar duplicados
          final Map<String, Map<String, dynamic>> uniquePatients = {};
          for (final record in data) {
            final patientId = record['patient_id'] ?? record['patient_uuid'];
            if (patientId != null && !uniquePatients.containsKey(patientId)) {
              uniquePatients[patientId] = record;
            }
          }

          return uniquePatients.values
              .where((p) => _isHospitalizedPatient(p))
              .map((p) => PacienteResumen.fromMap(p))
              .toList();
        });

    // Stream de tareas hospitalarias desde medical_records con department_code = 'HOSP'
    _tasksStream = _supa
        .from('medical_records')
        .stream(primaryKey: ['id'])
        .eq('clinic_id', _clinicId!)
        .map((data) => data
            .where((t) => t['department_code'] == 'HOSP')
            .map((t) => TareaHosp.fromMap(t))
            .toList());

    // Stream de actualizaciones desde medical_records recientes
    _updatesStream = _supa
        .from('medical_records')
        .stream(primaryKey: ['id'])
        .eq('clinic_id', _clinicId!)
        .map(
            (data) => data.take(10).map((u) => UpdateItem.fromMap(u)).toList());
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 1200;
    final rightPanelWidth = showUpdates && isWide ? 360.0 : 0.0;

    return Scaffold(
      backgroundColor:
          Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.15),
      appBar: AppBar(
        elevation: 0,
        title: const Text('Panel de Hospitalización',
            style: TextStyle(fontWeight: FontWeight.w700)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, MRN, dueño, especie...',
                prefixIcon: const Icon(Iconsax.search_normal),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ),
        actions: [
          _botonPrimario(
            context,
            icon: Icons.add,
            label: 'Añadir orden médica',
            onTap: () {
              _showAddTaskDialog(context);
            },
          ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Mostrar actualizaciones',
            onPressed: () => setState(() => showUpdates = !showUpdates),
            icon: Icon(showUpdates
                ? Icons.notifications_active
                : Icons.notifications_none),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<PacienteResumen>>(
        stream: _patientsStream,
        builder: (context, patientsSnapshot) {
          if (patientsSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (patientsSnapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error al cargar pacientes: ${patientsSnapshot.error}'),
                ],
              ),
            );
          }

          final patients = patientsSnapshot.data ?? [];
          if (patients.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_hospital,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No hay pacientes hospitalizados'),
                ],
              ),
            );
          }

          // Establecer paciente seleccionado por defecto
          if (selectedPatientMrn == null && patients.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() => selectedPatientMrn = patients.first.mrn);
            });
          }

          return Row(
            children: [
              // CONTENIDO PRINCIPAL
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _cardsPacientes(patients),
                      const SizedBox(height: 16),
                      _cabeceraVistas(context, patients),
                      const SizedBox(height: 8),
                      if (vista == _Vista.gantt)
                        _vistaGantt(context, patients)
                      else
                        _vistaCalendarioPorPaciente(context, patients),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              // PANEL LATERAL ACTUALIZACIONES
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: rightPanelWidth,
                child: showUpdates && isWide
                    ? _panelActualizaciones(context)
                    : const SizedBox.shrink(),
              ),
            ],
          );
        },
      ),
    );
  }

  // ----------------- UI SECTIONS -----------------

  Widget _cardsPacientes(List<PacienteResumen> patients) {
    // Filtrar pacientes según la búsqueda
    final filteredPatients = _searchQuery.isEmpty
        ? patients
        : patients.where((p) {
            return p.nombre.toLowerCase().contains(_searchQuery) ||
                p.mrn.toLowerCase().contains(_searchQuery) ||
                p.especie.toLowerCase().contains(_searchQuery) ||
                p.raza.toLowerCase().contains(_searchQuery) ||
                (p.ownerName?.toLowerCase().contains(_searchQuery) ?? false) ||
                (p.recordTitle?.toLowerCase().contains(_searchQuery) ?? false);
          }).toList();

    return LayoutBuilder(
      builder: (context, c) {
        final cols =
            MediaQuery.of(context).size.width ~/ 320; // ancho aprox por card
        final crossAxisCount = cols.clamp(1, 4);
        return GridView.builder(
          primary: false,
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisExtent: 160,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: filteredPatients.length,
          itemBuilder: (_, i) {
            final p = filteredPatients[i];
            final selected = p.mrn == selectedPatientMrn;
            return _cardPaciente(p, selected: selected, onSelect: () {
              setState(() => selectedPatientMrn = p.mrn);
            });
          },
        );
      },
    );
  }

  Widget _cabeceraVistas(BuildContext context, List<PacienteResumen> patients) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Row(
        children: [
          const Text('Calendario de Tareas',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const Spacer(),
          // Selector paciente (para vista Calendario)
          SizedBox(
            width: 260,
            child: DropdownButtonFormField<String>(
              value: selectedPatientMrn,
              decoration: InputDecoration(
                isDense: true,
                labelText: 'Paciente',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: patients
                  .map((p) => DropdownMenuItem<String>(
                        value: p.mrn,
                        child: Text('${p.nombre} — MRN ${p.mrn}'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => selectedPatientMrn = v),
            ),
          ),
          const SizedBox(width: 12),
          _Segmented(
            options: const ['Gantt', 'Calendario'],
            selectedIndex: vista.index,
            onChanged: (i) => setState(() => vista = _Vista.values[i]),
          ),
        ],
      ),
    );
  }

  /// Vista tipo Gantt: filas = pacientes, columnas = horas
  Widget _vistaGantt(BuildContext context, List<PacienteResumen> patients) {
    final horas = List.generate(13, (i) => 8 + i); // 08:00 -> 20:00
    final anchoCol = 96.0;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: StreamBuilder<List<TareaHosp>>(
        stream: _tasksStream,
        builder: (context, tasksSnapshot) {
          final tasks = tasksSnapshot.data ?? [];
          final tasksByPatient = <String, List<TareaHosp>>{};
          for (final task in tasks) {
            tasksByPatient.putIfAbsent(task.patientMrn, () => []).add(task);
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(minWidth: 160 + horas.length * anchoCol),
              child: Column(
                children: [
                  // cabecera horas
                  Row(
                    children: [
                      const SizedBox(width: 160),
                      for (final h in horas)
                        SizedBox(
                          width: anchoCol,
                          child: Center(
                            child: Text('${h.toString().padLeft(2, '0')}:00',
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color)),
                          ),
                        )
                    ],
                  ),
                  const Divider(height: 16),
                  // filas por paciente
                  for (final p in patients)
                    _filaGanttPaciente(context, p,
                        tasks: tasksByPatient[p.mrn] ?? [],
                        horas: horas,
                        colWidth: anchoCol),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _filaGanttPaciente(BuildContext context, PacienteResumen p,
      {required List<TareaHosp> tasks,
      required List<int> horas,
      required double colWidth}) {
    final rowHeight = 64.0;
    return Column(
      children: [
        SizedBox(
          height: rowHeight,
          child: Row(
            children: [
              SizedBox(
                width: 160,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(p.nombre,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              // grid horas con posición absoluta de bloques
              Expanded(
                child: Stack(
                  children: [
                    Row(
                      children: [
                        for (int i = 0; i < horas.length; i++)
                          _celdaHora(colWidth)
                      ],
                    ),
                    // bloques
                    for (final t in tasks)
                      _bloqueTareaGantt(
                        context,
                        t,
                        horas: horas,
                        colWidth: colWidth,
                        rowHeight: rowHeight,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: Colors.black.withOpacity(0.06)),
      ],
    );
  }

  Widget _celdaHora(double w) => Container(
        width: w,
        decoration: BoxDecoration(
          border:
              Border(right: BorderSide(color: Colors.black.withOpacity(0.05))),
        ),
      );

  Widget _bloqueTareaGantt(BuildContext context, TareaHosp t,
      {required List<int> horas,
      required double colWidth,
      required double rowHeight}) {
    // calcular posición
    double toDouble(TimeOfDay tod) => tod.hour + tod.minute / 60.0;
    final start = toDouble(t.inicio);
    final end = toDouble(t.fin);
    final base = horas.first.toDouble();
    final left = (start - base) * colWidth;
    final width = (end - start) * colWidth;

    final color = _colorTarea(context, t.tipo);
    final textColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
            ? Colors.white
            : Colors.black87;

    return Positioned(
      left: left.clamp(0.0, double.infinity),
      top: 8,
      width: width,
      height: rowHeight - 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_etiquetaTarea(t.tipo),
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: textColor)),
            Text(t.titulo,
                style:
                    TextStyle(fontSize: 11, color: textColor.withOpacity(0.9))),
          ],
        ),
      ),
    );
  }

  /// Vista Calendario: agenda diaria POR PACIENTE (selector arriba)
  Widget _vistaCalendarioPorPaciente(
      BuildContext context, List<PacienteResumen> patients) {
    final mrn = selectedPatientMrn;
    final patient =
        patients.firstWhere((p) => p.mrn == mrn, orElse: () => patients.first);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: StreamBuilder<List<TareaHosp>>(
        stream: _tasksStream,
        builder: (context, tasksSnapshot) {
          final allTasks = tasksSnapshot.data ?? [];
          final items = allTasks.where((t) => t.patientMrn == mrn).toList()
            ..sort((a, b) => a.inicio.hour.compareTo(b.inicio.hour));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Agenda diaria — ${patient.nombre}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              _listaAgenda(items),
            ],
          );
        },
      ),
    );
  }

  Widget _listaAgenda(List<TareaHosp> items) {
    String hhmm(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) =>
          Divider(color: Colors.black.withOpacity(0.06)),
      itemBuilder: (_, i) {
        final t = items[i];
        final color = _colorTarea(context, t.tipo);

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          leading: Container(
            width: 10,
            height: 44,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(8)),
          ),
          title: Text(t.titulo,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
              '${_etiquetaTarea(t.tipo)}  •  ${hhmm(t.inicio)} – ${hhmm(t.fin)}'),
          trailing: _botonSecundario(context, label: 'Registrar', onTap: () {
            // TODO: acción rápida para registrar ejecución (update en Supabase)
          }),
          onTap: () {
            // TODO: abrir detalle/adjuntos del bloque
          },
        );
      },
    );
  }

  Widget _panelActualizaciones(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        border: Border(left: BorderSide(color: Colors.black.withOpacity(0.06))),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
            child: Row(
              children: [
                const Text('Actualizaciones',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const Spacer(),
                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: () => setState(() => showUpdates = false),
                  icon: const Icon(Icons.close),
                )
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<UpdateItem>>(
              stream: _updatesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final updates = snapshot.data ?? [];

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: updates.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final u = updates[i];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceVariant
                            .withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(child: Text(u.usuario.characters.first)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(u.usuario,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(u.texto),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(u.hora,
                              style: TextStyle(
                                  color: Colors.black.withOpacity(0.5))),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ----------------- MÉTODOS DE NEGOCIO -----------------

  void _showAddTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Añadir Orden Médica'),
        content: const Text(
            'Funcionalidad en desarrollo. Se integrará con medical_records.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // ----------------- WIDGETS REUSABLES -----------------

  Widget _cardPaciente(PacienteResumen p,
      {required bool selected, required VoidCallback onSelect}) {
    final estadoChip = _chipEstado(p.estado);
    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 2))
          ],
          border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 2),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                    radius: 28,
                    backgroundImage:
                        p.avatarUrl != null ? NetworkImage(p.avatarUrl!) : null,
                    child: p.avatarUrl == null ? const Icon(Icons.pets) : null),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.nombre,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16)),
                        Text('MRN: ${p.mrn}',
                            style: TextStyle(
                                color: Colors.black.withOpacity(0.6))),
                        Text('${p.especie} / ${p.raza}',
                            style: TextStyle(
                                color: Colors.black.withOpacity(0.6))),
                        if (p.ownerName != null)
                          Text('Dueño: ${p.ownerName}',
                              style: TextStyle(
                                  color: Colors.black.withOpacity(0.5),
                                  fontSize: 12)),
                        if (p.recordTitle != null)
                          Text('Último: ${p.recordTitle}',
                              style: TextStyle(
                                  color: Colors.black.withOpacity(0.5),
                                  fontSize: 11)),
                      ]),
                ),
                estadoChip,
              ],
            ),
            const Spacer(),
            Row(
              children: [
                _botonPlano(
                    label: 'Historia Clínica',
                    onTap: () {
                      // TODO: navega a utilities/visor.dart con MRN
                    }),
                const SizedBox(width: 8),
                _botonPlano(
                    label: 'Signos Vitales',
                    onTap: () {
                      // TODO: abrir modal de signos (rangos por color)
                    }),
                const SizedBox(width: 8),
                _botonPlano(
                    label: 'Notas',
                    onTap: () {
                      // TODO: notas rápidas vinculadas a medical_records
                    }),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _chipEstado(EstadoPaciente e) {
    Color bg;
    Color fg;
    switch (e) {
      case EstadoPaciente.estable:
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF1B5E20);
        break;
      case EstadoPaciente.critico:
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFB71C1C);
        break;
      case EstadoPaciente.postqx:
        bg = const Color(0xFFFFF8E1);
        fg = const Color(0xFF7A5E00);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(_etiquetaEstado(e),
          style:
              TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }

  Widget _botonPlano({required String label, required VoidCallback onTap}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black87,
        backgroundColor: const Color(0xFFE5E7EB),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }

  Widget _botonSecundario(BuildContext context,
      {required String label, required VoidCallback onTap}) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label),
    );
  }

  Widget _botonPrimario(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ----------------- HELPERS -----------------

  Color _colorTarea(BuildContext context, TipoTarea tipo) {
    switch (tipo) {
      case TipoTarea.medicacion:
        return const Color(0xFFBFDBFE); // azul claro
      case TipoTarea.cirugia:
        return const Color(0xFFFECACA); // rojo claro
      case TipoTarea.laboratorio:
        return const Color(0xFFCDECCF); // verde claro
      case TipoTarea.cura:
        return const Color(0xFFE9D5FF); // lila claro
    }
  }

  String _etiquetaTarea(TipoTarea t) {
    switch (t) {
      case TipoTarea.medicacion:
        return 'Medicación';
      case TipoTarea.cirugia:
        return 'Cirugía';
      case TipoTarea.laboratorio:
        return 'Laboratorio';
      case TipoTarea.cura:
        return 'Cura';
    }
  }

  String _etiquetaEstado(EstadoPaciente e) {
    switch (e) {
      case EstadoPaciente.estable:
        return 'Estable';
      case EstadoPaciente.critico:
        return 'Crítico';
      case EstadoPaciente.postqx:
        return 'Post-Qx';
    }
  }
}

// ----------------- MODELOS SIMPLES -----------------

enum EstadoPaciente { estable, critico, postqx }

class PacienteResumen {
  final String mrn;
  final String nombre;
  final String especie;
  final String raza;
  final EstadoPaciente estado;
  final String? avatarUrl;
  final String? ownerName;
  final String? ownerPhone;
  final String? recordTitle;
  final String? recordDate;

  PacienteResumen({
    required this.mrn,
    required this.nombre,
    required this.especie,
    required this.raza,
    required this.estado,
    this.avatarUrl,
    this.ownerName,
    this.ownerPhone,
    this.recordTitle,
    this.recordDate,
  });

  factory PacienteResumen.fromMap(Map<String, dynamic> data) {
    return PacienteResumen(
      mrn: data['patient_mrn'] ?? data['history_number_snapshot'] ?? '',
      nombre: data['patient_name'] ?? data['paciente_name_snapshot'] ?? '',
      especie: _getSpeciesLabel(data['patient_species_code']),
      raza: data['breed_label'] ?? data['breed'] ?? 'Sin especificar',
      estado: _parseEstado(data['status'] ?? 'estable'),
      avatarUrl: data['avatar_url'] ?? data['patient_avatar'],
      ownerName: data['owner_name'] ?? data['owner_name_snapshot'],
      ownerPhone: data['owner_phone'],
      recordTitle: data['record_title'],
      recordDate: data['record_date'],
    );
  }

  static String _getSpeciesLabel(String? speciesCode) {
    switch (speciesCode?.toUpperCase()) {
      case 'CAN':
        return 'Canino';
      case 'FEL':
        return 'Felino';
      case 'AVE':
        return 'Ave';
      case 'EQU':
        return 'Equino';
      case 'BOV':
        return 'Bovino';
      case 'POR':
        return 'Porcino';
      case 'CAP':
        return 'Caprino';
      case 'OVI':
        return 'Ovino';
      default:
        return speciesCode ?? 'Sin especificar';
    }
  }

  static EstadoPaciente _parseEstado(String status) {
    switch (status.toLowerCase()) {
      case 'critico':
      case 'critical':
        return EstadoPaciente.critico;
      case 'postqx':
      case 'post_operative':
        return EstadoPaciente.postqx;
      case 'estable':
      case 'stable':
      case 'hospitalized':
      default:
        return EstadoPaciente.estable;
    }
  }
}

enum TipoTarea { medicacion, cirugia, laboratorio, cura }

class TareaHosp {
  final TipoTarea tipo;
  final String titulo;
  final TimeOfDay inicio;
  final TimeOfDay fin;
  final String patientMrn;

  TareaHosp({
    required this.tipo,
    required this.titulo,
    required this.inicio,
    required this.fin,
    required this.patientMrn,
  });

  factory TareaHosp.fromMap(Map<String, dynamic> data) {
    return TareaHosp(
      tipo: _parseTipoTarea(data['type'] ?? data['title'] ?? 'medicacion'),
      titulo: data['title'] ?? data['record_title'] ?? '',
      inicio: _parseTimeOfDay(data['start_time'] ?? data['date'] ?? '08:00'),
      fin: _parseTimeOfDay(data['end_time'] ?? data['date'] ?? '09:00'),
      patientMrn: data['patient_id'] ?? data['patient_mrn'] ?? '',
    );
  }

  static TipoTarea _parseTipoTarea(String type) {
    switch (type.toLowerCase()) {
      case 'cirugia':
      case 'surgery':
        return TipoTarea.cirugia;
      case 'laboratorio':
      case 'lab':
        return TipoTarea.laboratorio;
      case 'cura':
      case 'dressing':
        return TipoTarea.cura;
      case 'medicacion':
      case 'medication':
      default:
        return TipoTarea.medicacion;
    }
  }

  static TimeOfDay _parseTimeOfDay(String timeStr) {
    try {
      if (timeStr.contains('T')) {
        // Formato ISO datetime
        final dateTime = DateTime.parse(timeStr);
        return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
      } else if (timeStr.contains(':')) {
        // Formato HH:MM
        final parts = timeStr.split(':');
        return TimeOfDay(
            hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    } catch (e) {}
    return const TimeOfDay(hour: 8, minute: 0); // Default
  }
}

class UpdateItem {
  final String usuario;
  final String hora;
  final String texto;

  UpdateItem({required this.usuario, required this.hora, required this.texto});

  factory UpdateItem.fromMap(Map<String, dynamic> data) {
    final createdAt =
        DateTime.tryParse(data['created_at'] ?? '') ?? DateTime.now();
    final doctor = data['doctor'] ?? data['created_by'] ?? 'Sistema';

    return UpdateItem(
      usuario: doctor,
      hora: DateFormat('HH:mm').format(createdAt),
      texto: data['summary'] ?? data['title'] ?? 'Actualización del paciente',
    );
  }
}

// ----------------- CONTROLES UI -----------------

class _Segmented extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  const _Segmented(
      {required this.options,
      required this.selectedIndex,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(options.length, (i) {
          final selected = i == selectedIndex;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onChanged(i),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? Theme.of(context).colorScheme.background
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 8)
                        ]
                      : null,
                ),
                child: Text(
                  options[i],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
