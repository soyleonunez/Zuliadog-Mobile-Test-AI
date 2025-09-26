import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../home.dart' as home;

final _supa = Supabase.instance.client;

enum CalendarView { week, gantt }

class CalendarGanttWidget extends StatefulWidget {
  final DateTime currentWeek;
  final String? selectedTreatmentId;
  final String? selectedPatientId;
  final Function(String) onTreatmentTap;
  final Function(String) onTreatmentEdit;
  final Function(String) onTreatmentComplete;

  const CalendarGanttWidget({
    super.key,
    required this.currentWeek,
    this.selectedTreatmentId,
    this.selectedPatientId,
    required this.onTreatmentTap,
    required this.onTreatmentEdit,
    required this.onTreatmentComplete,
  });

  @override
  State<CalendarGanttWidget> createState() => _CalendarGanttWidgetState();
}

class _CalendarGanttWidgetState extends State<CalendarGanttWidget> {
  CalendarView _currentView = CalendarView.week;
  Stream<List<Map<String, dynamic>>>? _treatmentsStream;
  late DateTime _currentWeek;

  @override
  void initState() {
    super.initState();
    _currentWeek = widget.currentWeek;
    _initializeTreatmentsStream();
  }

  @override
  void didUpdateWidget(CalendarGanttWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPatientId != widget.selectedPatientId) {
      print(
          '🔍 Patient changed from ${oldWidget.selectedPatientId} to ${widget.selectedPatientId}');
      _initializeTreatmentsStream();
    }
  }

  static Stream<List<Map<String, dynamic>>>? _globalTreatmentsStream;
  static String? _lastGlobalPatientId;

  void _initializeTreatmentsStream() {
    try {
      // Reutilizar stream global para evitar too many channels
      if (_globalTreatmentsStream != null &&
          _lastGlobalPatientId == widget.selectedPatientId) {
        _treatmentsStream = _globalTreatmentsStream;
        print(
            '🔍 Reusing global stream for patient ${widget.selectedPatientId}');
        return;
      }

      print(
          '🔍 Creating new data fetch for CalendarGanttWidget with selectedPatientId: ${widget.selectedPatientId}');

      // Usar Future direct para cargar datos en real time
      _globalTreatmentsStream = _initializeTreatmentsData();

      _treatmentsStream = _globalTreatmentsStream;
      _lastGlobalPatientId = widget.selectedPatientId;
    } catch (e) {
      print('Error inicializando stream de tratamientos: $e');
      _treatmentsStream = Stream.value([]);
    }
  }

  Stream<List<Map<String, dynamic>>> _initializeTreatmentsData() async* {
    try {
      print('🔍 Fetching follows data from database...');
      final followsData = await _supa
          .from('follows')
          .select('*')
          .eq('follow_type', 'treatment');

      print('🔍 Found ${followsData.length} treatments in database');

      // Procesar treats y obtener nombres de patient completos
      List<Map<String, dynamic>> enrichedData = [];

      for (var item in followsData) {
        try {
          final patientData = await _supa
              .from('patients')
              .select('name')
              .eq('id', item['patient_id'])
              .single();

          var enrichedItem = Map<String, dynamic>.from(item);
          enrichedItem['patient_name'] = patientData['name'] ?? 'Paciente';
          enrichedData.add(enrichedItem);
        } catch (e) {
          // Patient not found: use fallback
          var enrichedItem = Map<String, dynamic>.from(item);
          enrichedItem['patient_name'] = 'Paciente';
          enrichedData.add(enrichedItem);
        }
      }

      // Filtrar según selectedPatientId
      if (widget.selectedPatientId != null) {
        print('🔍 Filtering for specific patient: ${widget.selectedPatientId}');
        enrichedData = enrichedData
            .where((treat) => treat['patient_id'] == widget.selectedPatientId)
            .toList();
        print(
            '🔍 Filtered to ${enrichedData.length} treatments for selected patient');
      } else {
        print(
            '🔍 No specific patient selected - showing ALL treatments (${enrichedData.length} total)');
      }

      yield enrichedData;

      // For informational passage updates else
      while (true) {
        await Future.delayed(Duration(seconds: 30));

        // Refetch refresh  datif patient changes
        final refreshFollows = await _supa
            .from('follows')
            .select('*')
            .eq('follow_type', 'treatment');

        List<Map<String, dynamic>> refreshedEnriched = [];
        for (var item in refreshFollows) {
          try {
            final patientData = await _supa
                .from('patients')
                .select('name')
                .eq('id', item['patient_id'])
                .single();

            var enrichedItem = Map<String, dynamic>.from(item);
            enrichedItem['patient_name'] = patientData['name'] ?? 'Paciente';
            refreshedEnriched.add(enrichedItem);
          } catch (e) {
            // Patient not found, skip: fallback
            var enrichedItem = Map<String, dynamic>.from(item);
            enrichedItem['patient_name'] = 'Paciente';
            refreshedEnriched.add(enrichedItem);
          }
        }

        // Asegurorse based on `widget.selectedPatientId`
        if (widget.selectedPatientId != null) {
          refreshedEnriched = refreshedEnriched
              .where((treat) => treat['patient_id'] == widget.selectedPatientId)
              .toList();
        }

        yield refreshedEnriched;
      }
    } catch (e) {
      print('Error _initializeTreatmentsData: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _filterTreatmentsByPatient(
      List<Map<String, dynamic>> data) async {
    // Filtros aplicados con posterior menerium okay
    final treatments =
        data.where((item) => item['follow_type'] == 'treatment').toList();

    print('🔍 Filtering treatments: ${treatments.length} total treatments');
    print('🔍 Widget selectedPatientId: ${widget.selectedPatientId}');

    // Necesitamos cargar los nombres de pacientes para cada tratamiento
    List<Map<String, dynamic>> enrichedTreatments = [];

    for (var treatment in treatments) {
      try {
        if (treatment['patient_id'] != null) {
          try {
            // Fetch patient data to get patient_name
            final patientData = await _supa
                .from('patients')
                .select('name')
                .eq('id', treatment['patient_id'])
                .single();

            var enrichedTreatment = Map<String, dynamic>.from(treatment);
            enrichedTreatment['patient_name'] =
                patientData['name'] ?? 'Paciente';
            enrichedTreatments.add(enrichedTreatment);

            print('🔍 Treatment: ${treatment['medication_name'] ?? 'No name'}');
            print('🔍 Patient ID: ${treatment['patient_id'] ?? 'NULL'}');
            print('🔍 Patient Name: ${enrichedTreatment['patient_name']}');
            print(
                '🔍 Scheduled Date: ${treatment['scheduled_date'] ?? 'No date'}');
            print('🔍 Follow Type: ${treatment['follow_type'] ?? 'No type'}');
          } catch (e) {
            print('Error fetching patient info for treatment: $e');
            // Add fallback treatment record without patient name
            var enrichedTreatment = Map<String, dynamic>.from(treatment);
            enrichedTreatment['patient_name'] = 'Paciente';
            enrichedTreatments.add(enrichedTreatment);
          }
        }
      } catch (e) {
        print('Error fetching patient info for treatment: $e');
        // Fallback sin nombre
        var fallbackTreatment = Map<String, dynamic>.from(treatment);
        fallbackTreatment['patient_name'] = 'Paciente';
        enrichedTreatments.add(fallbackTreatment);
      }
    }

    if (widget.selectedPatientId != null) {
      final filteredTreatments = enrichedTreatments
          .where((treatment) =>
              treatment['patient_id'] == widget.selectedPatientId)
          .toList();

      print(
          '🔍 Filtered to ${filteredTreatments.length} treatments for patient ${widget.selectedPatientId}');
      return filteredTreatments;
    }

    print('🔍 No patient selected, returning all treatments');
    return enrichedTreatments;
  }

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
          // Header con selector de vista
          _buildHeader(),

          // Contenido según la vista seleccionada
          Expanded(
            child: _currentView == CalendarView.week
                ? _buildWeekView()
                : _buildGanttView(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          // Selector de vista
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: home.AppColors.neutral200),
            ),
            child: Row(
              children: [
                _buildViewButton(
                  icon: Iconsax.calendar_2,
                  label: 'Semana',
                  view: CalendarView.week,
                ),
                _buildViewButton(
                  icon: Iconsax.task_square,
                  label: 'Gantt',
                  view: CalendarView.gantt,
                ),
              ],
            ),
          ),

          const Spacer(),

          // Navegación de tiempo
          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _currentWeek = _currentWeek.subtract(Duration(days: 7));
                  });
                },
                icon: Icon(Iconsax.arrow_left_2, size: 16),
                color: home.AppColors.neutral600,
              ),
              Text(
                _getCurrentWeekRange(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: home.AppColors.neutral900,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _currentWeek = _currentWeek.add(Duration(days: 7));
                  });
                },
                icon: Icon(Iconsax.arrow_right_2, size: 16),
                color: home.AppColors.neutral600,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewButton({
    required IconData icon,
    required String label,
    required CalendarView view,
  }) {
    final isSelected = _currentView == view;
    return InkWell(
      onTap: () => setState(() => _currentView = view),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? home.AppColors.primary500 : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : home.AppColors.neutral600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : home.AppColors.neutral600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekView() {
    final weekDays = _getWeekDays(_currentWeek);

    return Column(
      children: [
        // Header de días
        _buildWeekHeader(weekDays),

        // Grid del calendario
        Expanded(
          child: _buildWeekGrid(weekDays),
        ),
      ],
    );
  }

  Widget _buildWeekHeader(List<DateTime> weekDays) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
          // Columna de horas
          Container(
            width: 50,
            child: Text(
              'Hora',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: home.AppColors.neutral600,
              ),
            ),
          ),

          // Días de la semana
          ...weekDays.map((day) {
            final isToday = _isSameDay(day, DateTime.now());
            return Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color:
                      isToday ? home.AppColors.primary100 : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  children: [
                    Text(
                      DateFormat('E', 'es').format(day),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isToday
                            ? home.AppColors.primary700
                            : home.AppColors.neutral600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      day.day.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isToday
                            ? home.AppColors.primary700
                            : home.AppColors.neutral900,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildWeekGrid(List<DateTime> weekDays) {
    final hours = _generateHours();

    return SingleChildScrollView(
      child: Column(
        children: hours.map((hour) {
          final isCurrentHour = _isCurrentHour(hour);
          return Container(
            height: 50,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isCurrentHour
                      ? home.AppColors.primary500
                      : home.AppColors.neutral100,
                  width: isCurrentHour ? 2 : 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Columna de hora
                Container(
                  width: 50,
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCurrentHour
                        ? home.AppColors.primary50
                        : Colors.transparent,
                  ),
                  child: Text(
                    hour,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          isCurrentHour ? FontWeight.w700 : FontWeight.w500,
                      color: isCurrentHour
                          ? home.AppColors.primary700
                          : home.AppColors.neutral600,
                    ),
                  ),
                ),

                // Celdas de días
                ...weekDays.map((day) {
                  return Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: home.AppColors.neutral100,
                            width: 1,
                          ),
                        ),
                      ),
                      child: _buildTimeSlot(day, hour),
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGanttView() {
    final weekDays = _getWeekDays(_currentWeek);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _treatmentsStream ?? Stream.value([]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final treatments = snapshot.data ?? [];
        print(
            '📊 Gantt cargando ${treatments.length} tratamientos para paciente ${widget.selectedPatientId}');

        // Debug: Mostrar si selectedPatientId es null y qué estamos filtrando
        if (widget.selectedPatientId == null) {
          print(
              '❌ selectedPatientId is NULL - no patient selected, trying to show all treatments');
        }

        if (treatments.isEmpty && widget.selectedPatientId != null) {
          print(
              '⚠️ No treatments found for selected patient ${widget.selectedPatientId}');
        }

        if (treatments.isEmpty && widget.selectedPatientId == null) {
          print('⚠️ No treatments in database found to display in Gantt');
        }

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: home.AppColors.neutral200),
          ),
          child: Column(
            children: [
              // Debug info panel cuando no hay paciente
              if (widget.selectedPatientId == null)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  margin: EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: home.AppColors.warning500.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: home.AppColors.warning500.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Selecciona un paciente de la lista para ver sus tratamientos',
                    style: TextStyle(
                      color: home.AppColors.warning500,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              // Header con días de la semana
              _buildHTMLStyleWeekHeader(weekDays),
              const SizedBox(height: 8),
              // Grid del timeline como en HTML
              Expanded(
                child: treatments.isEmpty
                    ? Center(
                        child: Text(
                          widget.selectedPatientId == null
                              ? 'No hay paciente seleccionado'
                              : 'No hay tratamientos programados',
                          style: TextStyle(color: home.AppColors.neutral500),
                        ),
                      )
                    : _buildHTMLLikeGantt(treatments, weekDays),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHTMLStyleWeekHeader(List<DateTime> weekDays) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: home.AppColors.neutral200, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Columna fija para "Paciente"
          Container(
            width: 120,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: home.AppColors.neutral50,
              border: Border(
                right: BorderSide(color: home.AppColors.neutral200, width: 1),
              ),
            ),
            child: Center(
              child: Text(
                'Paciente',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: home.AppColors.neutral700,
                ),
              ),
            ),
          ),
          // Columnas de días de la semana - estilo compacto como en la imagen
          ...weekDays.map((day) {
            final isToday = _isSameDay(day, DateTime.now());
            return Expanded(
              child: Container(
                height: 45,
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    right:
                        BorderSide(color: home.AppColors.neutral200, width: 1),
                    bottom:
                        BorderSide(color: home.AppColors.neutral200, width: 1),
                  ),
                  color: isToday
                      ? home.AppColors.primary100
                      : home.AppColors.neutral50,
                ),
                child: Center(
                  child: Text(
                    '${_getDayAbbreviation(day)} ${day.day}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isToday
                          ? home.AppColors.primary700
                          : home.AppColors.neutral700,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildHTMLLikeGantt(
      List<Map<String, dynamic>> treatments, List<DateTime> weekDays) {
    // Agrupar tratamientos por paciente como en el ejemplo HTML
    Map<String, List<Map<String, dynamic>>> treatmentsByPatient = {};

    for (var treatment in treatments) {
      String patientName = treatment['patient_name'] ?? 'Paciente';
      if (!treatmentsByPatient.containsKey(patientName)) {
        treatmentsByPatient[patientName] = [];
      }
      treatmentsByPatient[patientName]!.add(treatment);
    }

    print(
        '🔍 Gantt treatments by patient: ${treatmentsByPatient.keys.toList()}');

    if (treatmentsByPatient.isEmpty) {
      return Container(
        height: 200,
        child: Center(
          child: Text(
            'No hay tratamientos programados\npara mostrar en el Gantt',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: home.AppColors.neutral500,
            ),
          ),
        ),
      );
    }

    return Container(
      height: treatmentsByPatient.length * 60.0 + 20,
      child: Column(
        children: treatmentsByPatient.entries.map((entry) {
          String patientName = entry.key;
          List<Map<String, dynamic>> patientTreatments = entry.value;

          return Container(
            height: 60,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: home.AppColors.neutral200, width: 1),
              ),
            ),
            child: Row(
              children: [
                // Nombre del paciente - columna fija
                Container(
                  width: 120,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      right: BorderSide(
                          color: home.AppColors.neutral200, width: 1),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      patientName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: home.AppColors.neutral900,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
                // Grid de días - estilo matriz simple
                Expanded(
                  child: _buildSimpleGanttGrid(patientTreatments, weekDays),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSimpleGanttGrid(
      List<Map<String, dynamic>> treatments, List<DateTime> weekDays) {
    return Row(
      children: weekDays.map((day) {
        final dayTreatments = treatments.where((treatment) {
          if (treatment['scheduled_date'] == null) return false;
          try {
            final targetDate =
                DateTime.parse(treatment['scheduled_date'].toString());
            return _isSameDay(targetDate, day);
          } catch (e) {
            return false;
          }
        }).toList();

        return Expanded(
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: home.AppColors.neutral200, width: 1),
              ),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: dayTreatments.isEmpty
                  ? Container() // Celda vacía como en la imagen
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: dayTreatments.map((treatment) {
                        return GestureDetector(
                          onTap: () => widget.onTreatmentTap(treatment['id']),
                          child: Container(
                            width: double.infinity,
                            margin: EdgeInsets.only(bottom: 2),
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getTreatmentColor(treatment),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 3,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              treatment['medication_name'] ?? 'Tratamiento',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.25),
                                    offset: Offset(0, 1),
                                    blurRadius: 1,
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPatientTimelineGrid(
      List<Map<String, dynamic>> treatments, List<DateTime> weekDays) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 80,
          child: Stack(
            children: [
              // Grid de fondo como en HTML
              Row(
                children: weekDays.map((day) {
                  return Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: home.AppColors.neutral200, width: 1),
                      ),
                      height: 80,
                    ),
                  );
                }).toList(),
              ),
              // Tratamientos superpuestos
              ...treatments
                  .map((treatment) => _buildTreatmentBar(
                      treatment, weekDays, constraints.maxWidth))
                  .toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTreatmentBar(Map<String, dynamic> treatment,
      List<DateTime> weekDays, double availableWidth) {
    if (treatment['scheduled_date'] == null) return Container();

    try {
      DateTime startDate =
          DateTime.parse(treatment['scheduled_date'].toString());

      // Obtener duración desde la base de datos - mejor manejo
      int durationDays = 1;
      if (treatment['duration_days'] != null) {
        durationDays = int.tryParse(treatment['duration_days'].toString()) ?? 1;
      } else if (treatment['duration_hours'] != null) {
        // Convertir horas a días si solo tenemos horas
        int hours = int.tryParse(treatment['duration_hours'].toString()) ?? 24;
        durationDays = (hours / 24).ceil().clamp(1, 365);
      }

      // Debug info
      print('📅 Tratamiento: ${treatment['medication_name']}');
      print('📅 Inicio: $startDate');
      print('📅 Duración BD: $durationDays días');

      // Calcular fecha final basada en duration_days de la base de datos
      DateTime endDate = startDate.add(Duration(days: durationDays - 1));

      print('📅 Fin calculado: $endDate');
      print('📅 Días totales: $durationDays');

      // Encontrar días de la semana donde se muestra el tratamiento
      List<bool> treatmentDays = weekDays.map((day) {
        final dayOnly = DateTime(day.year, day.month, day.day);
        final startDayOnly =
            DateTime(startDate.year, startDate.month, startDate.day);
        final endDayOnly = DateTime(endDate.year, endDate.month, endDate.day);

        // El día está en el rango del tratamiento (inclusivo)
        return (dayOnly.isAtSameMomentAs(startDayOnly) ||
                dayOnly.isAfter(startDayOnly)) &&
            (dayOnly.isAtSameMomentAs(endDayOnly) ||
                dayOnly.isBefore(endDayOnly.add(Duration(days: 1))));
      }).toList();

      if (!treatmentDays.any((hasTreatment) => hasTreatment)) {
        print(
            '❌ Tratamiento ${treatment['medication_name']} no se muestra en ninguna columna de la semana');
        return Container();
      }

      // Encontrar primera y última columna activas
      int firstColumn = treatmentDays.indexOf(true);
      int lastColumn = treatmentDays.lastIndexOf(true);

      if (firstColumn == -1) return Container();

      // Calcular posiciones más precisas usando el ancho disponible
      final cellWidth = availableWidth / weekDays.length;
      final leftPosition = firstColumn * cellWidth;
      final numberOfCells = (lastColumn - firstColumn + 1);
      final width = (numberOfCells * cellWidth - 4)
          .clamp(60.0, availableWidth); // Clamp width

      print(
          '📊 Posición: izquierda=$leftPosition, ancho=$width, columnas=$firstColumn-$lastColumn');

      return Positioned(
        left: leftPosition.clamp(0.0, availableWidth - width),
        top: 12,
        bottom: 12,
        width: width,
        child: GestureDetector(
          onTap: () {
            print('🔍 Tap en tratamiento: ${treatment['medication_name']}');
            widget.onTreatmentTap(treatment['id'].toString());
          },
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: _getTreatmentColor(treatment).withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Nombre del medicamento
                  Text(
                    treatment['medication_name'] ?? 'Tratamiento',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: Offset(0, 1),
                          blurRadius: 1,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 3),
                  // Hora de tratamiento
                  if (treatment['scheduled_time'] != null)
                    Text(
                      _formatTimeToString(treatment['scheduled_time']),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      return Container();
    }
  }

  Widget _buildGanttWeekHeader(List<DateTime> weekDays) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: home.AppColors.neutral50,
        border: Border(
          bottom: BorderSide(color: home.AppColors.neutral200),
        ),
      ),
      child: Row(
        children: [
          // Columna del medicamento
          Container(
            width: 200,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: home.AppColors.neutral200),
              ),
            ),
            child: Text(
              'Medicamento',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: home.AppColors.neutral700,
              ),
            ),
          ),
          // Columnas de días de la semana
          ...weekDays.map((day) {
            final isToday = _isSameDay(day, DateTime.now());
            return Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: isToday ? home.AppColors.primary100 : Colors.white,
                  border: Border.all(
                    color: home.AppColors.neutral200,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('E', 'es').format(day),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isToday
                            ? home.AppColors.primary700
                            : home.AppColors.neutral600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      day.day.toString(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isToday
                            ? home.AppColors.primary700
                            : home.AppColors.neutral900,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildGanttTreatmentRow(
      Map<String, dynamic> treatment, List<DateTime> weekDays) {
    final startDate = treatment['scheduled_date'] != null
        ? DateTime.parse(treatment['scheduled_date'].toString())
        : null;

    if (startDate == null) return Container();

    final durationDays = treatment['duration_days'] != null
        ? int.tryParse(treatment['duration_days'].toString()) ?? 1
        : 1;

    return Container(
      height: 60,
      margin: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Nombre del medicamento
          Container(
            width: 200,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: home.AppColors.neutral200),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  treatment['medication_name'] ?? 'Tratamiento',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: home.AppColors.neutral900,
                  ),
                ),
                if (treatment['medication_dosage'] != null)
                  Text(
                    treatment['medication_dosage'],
                    style: TextStyle(
                      fontSize: 11,
                      color: home.AppColors.neutral600,
                    ),
                  ),
              ],
            ),
          ),
          // Barras de duración por días
          ...weekDays.map((day) {
            final isInRange = _isTreatmentOnDay(startDate, day, durationDays);
            final startDayOnly =
                DateTime(startDate.year, startDate.month, startDate.day);
            final endDate = startDate.add(Duration(days: durationDays - 1));
            final endDayOnly =
                DateTime(endDate.year, endDate.month, endDate.day);
            final compareDayOnly = DateTime(day.year, day.month, day.day);

            final isStartDay = compareDayOnly.isAtSameMomentAs(startDayOnly);
            final isEndDay = _isTreatmentOnDay(startDate, day, durationDays) &&
                compareDayOnly.isAtSameMomentAs(endDayOnly);

            return Expanded(
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: home.AppColors.neutral200,
                    width: 1,
                  ),
                ),
                child: isInRange
                    ? Container(
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: _getTreatmentColor(treatment).withOpacity(0.8),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isStartDay)
                                Text(
                                  'Inicio',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                )
                              else if (isEndDay)
                                Text(
                                  treatment['frequency'] ?? '',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.white,
                                  ),
                                )
                              else
                                Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: Colors.white,
                                ),
                            ],
                          ),
                        ),
                      )
                    : Container(),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  bool _isTreatmentOnDay(
      DateTime startDate, DateTime checkDay, int durationDays) {
    // Comparar solo las fechas (año, mes, día) sin horas
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(
        startDate.year, startDate.month, startDate.day + (durationDays - 1));
    final check = DateTime(checkDay.year, checkDay.month, checkDay.day);

    return check.isAtSameMomentAs(start) ||
        (check.isAfter(start) && check.isBefore(end.add(Duration(days: 1))));
  }

  Widget _buildHorizontalGanttContent(
      List<Map<String, dynamic>> treatments, List<String> hours) {
    // Agrupar tratamientos por paciente para las filas
    final treatmentsByPatient = <String, List<Map<String, dynamic>>>{};

    for (final treatment in treatments) {
      final patientName = treatment['patient_name'] ?? 'Paciente';
      if (!treatmentsByPatient.containsKey(patientName)) {
        treatmentsByPatient[patientName] = [];
      }
      treatmentsByPatient[patientName]!.add(treatment);
    }

    return Column(
      children: treatmentsByPatient.entries.map((entry) {
        final patientName = entry.key;
        final patientTreatments = entry.value;

        return Container(
          height: 80,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: home.AppColors.neutral200, width: 1),
            ),
          ),
          child: Row(
            children: [
              // Nombre del paciente
              Container(
                width: 120,
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    right:
                        BorderSide(color: home.AppColors.neutral200, width: 1),
                  ),
                ),
                child: Center(
                  child: Text(
                    patientName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: home.AppColors.neutral900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              // Área de tratamientos sobre el grid horizontal
              Expanded(
                child: _buildPatientTreatmentsRow(patientTreatments, hours),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPatientTreatmentsRow(
      List<Map<String, dynamic>> treatments, List<String> hours) {
    return Stack(
      children: [
        // Grid de fondo con líneas como el HTML
        Row(
          children: hours.map((hour) {
            return Expanded(
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                        color: home.AppColors.neutral200, width: 0.5),
                  ),
                ),
                child: Container(),
              ),
            );
          }).toList(),
        ),
        // Tratamientos superpuestos exact like HTML
        ...treatments.map((treatment) {
          return _buildTreatmentPosition(treatment, hours);
        }).toList(),
      ],
    );
  }

  Widget _buildTreatmentPosition(
      Map<String, dynamic> treatment, List<String> hours) {
    if (treatment['scheduled_time'] == null) {
      return Container();
    }

    try {
      final scheduledTime = treatment['scheduled_time'].toString();
      final startHour = scheduledTime.split(':')[0];
      final startIndex =
          hours.indexWhere((hour) => hour.startsWith(startHour + ':'));

      if (startIndex == -1) return Container();

      final cellWidth = 100.0 / hours.length;
      final durationHours = 1; // Duración por defecto
      final leftPosition = startIndex * cellWidth;
      final width = durationHours * cellWidth;

      return Positioned(
        left: leftPosition,
        top: 16,
        bottom: 16,
        width: width,
        child: GestureDetector(
          onTap: () => widget.onTreatmentTap(treatment['id']),
          child: Container(
            margin: EdgeInsets.all(1),
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: _getTreatmentColor(treatment).withOpacity(0.8),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  treatment['medication_name'] ?? 'Tratamiento',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (treatment['medication_dosage'] != null)
                  Text(
                    treatment['medication_dosage'],
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      print('❌ Error calculando posición del tratamiento: $e');
      return Container();
    }
  }

  Widget _buildGanttTimelineItem(
      Map<String, dynamic> treatment, List<DateTime> weekDays) {
    final startDate = treatment['scheduled_date'] != null
        ? DateTime.parse(treatment['scheduled_date'].toString())
        : null;
    final durationDays = treatment['duration_days'] != null
        ? int.tryParse(treatment['duration_days'].toString()) ?? 1
        : 1;

    if (startDate == null) return Container();

    final endDate = startDate.add(Duration(days: durationDays - 1));

    return Container(
      margin: EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          // Columna del nombre del medicamento
          Container(
            width: 200,
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  treatment['medication_name'] ?? 'Tratamiento',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: home.AppColors.neutral900,
                  ),
                ),
                if (treatment['medication_dosage'] != null)
                  Text(
                    treatment['medication_dosage'],
                    style: TextStyle(
                      fontSize: 11,
                      color: home.AppColors.neutral600,
                    ),
                  ),
              ],
            ),
          ),

          // Barras de duración por días
          ...weekDays.map((day) {
            final isInRange =
                (day.isAtSameMomentAs(startDate) || day.isAfter(startDate)) &&
                    day.isBefore(endDate.add(Duration(days: 1)));
            final isStartDay = day.isAtSameMomentAs(startDate);
            final isEndDay = day.isAtSameMomentAs(endDate);

            return Expanded(
              child: Container(
                height: 40,
                padding: EdgeInsets.all(2),
                child: isInRange
                    ? Container(
                        decoration: BoxDecoration(
                          color: _getTreatmentColor(treatment).withOpacity(0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: _buildTimelineDayContent(
                              isStartDay, isEndDay, treatment),
                        ),
                      )
                    : Container(),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTimelineDayContent(
      bool isStartDay, bool isEndDay, Map<String, dynamic> treatment) {
    if (isStartDay) {
      return Text(
        'Inicio',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      );
    } else if (isEndDay) {
      return Text(
        '${treatment['frequency'] ?? ''}',
        style: TextStyle(
          fontSize: 9,
          color: Colors.white,
        ),
      );
    } else {
      return Icon(
        Icons.circle,
        size: 8,
        color: Colors.white,
      );
    }
  }

  Widget _buildGanttItem(Map<String, dynamic> treatment) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getTreatmentColor(treatment).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getTreatmentColor(treatment),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Iconsax.health,
            size: 16,
            color: _getTreatmentColor(treatment),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  treatment['medication_name'] ?? 'Tratamiento',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: home.AppColors.neutral900,
                  ),
                ),
                Text(
                  '${treatment['medication_dosage'] ?? ''} - ${treatment['administration_route'] ?? ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: home.AppColors.neutral600,
                  ),
                ),
                // Duración del tratamiento en días
                if (treatment['duration_days'] != null)
                  Container(
                    margin: EdgeInsets.only(top: 4),
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: home.AppColors.primary500.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Duración: ${treatment['duration_days']} días',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: home.AppColors.primary600,
                      ),
                    ),
                  ),
                // Agregar información adicional útil
                if (treatment['frequency'] != null ||
                    treatment['scheduled_time'] != null)
                  Row(
                    children: [
                      if (treatment['frequency'] != null)
                        Container(
                          margin: EdgeInsets.only(top: 2),
                          padding:
                              EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: home.AppColors.primary500.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            treatment['frequency'],
                            style: TextStyle(
                              fontSize: 10,
                              color: home.AppColors.primary600,
                            ),
                          ),
                        ),
                      if (treatment['scheduled_time'] != null)
                        Container(
                          margin: EdgeInsets.only(top: 2, left: 4),
                          padding:
                              EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: home.AppColors.success500.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            treatment['scheduled_time'],
                            style: TextStyle(
                              fontSize: 10,
                              color: home.AppColors.success500,
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => widget.onTreatmentEdit(treatment['id']),
                icon: Icon(Iconsax.edit, size: 16),
                color: home.AppColors.primary500,
              ),
              IconButton(
                onPressed: () => widget.onTreatmentComplete(treatment['id']),
                icon: Icon(Iconsax.tick_circle, size: 16),
                color: home.AppColors.success500,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlot(DateTime day, String hour) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _treatmentsStream ?? Stream.value([]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final treatments = snapshot.data ?? [];
        print(
            '🕒 Calendario revisando ${treatments.length} tratamientos para día: ${DateFormat('yyyy-MM-dd').format(day)}, hora: $hour');

        final dayTreatments = treatments.where((treatment) {
          if (treatment['scheduled_date'] == null ||
              treatment['scheduled_time'] == null) {
            print(
                '⚠️ Tratamiento sin fecha/hora: ${treatment['medication_name']}');
            return false;
          }
          try {
            final treatmentDate =
                DateTime.parse(treatment['scheduled_date'].toString());
            final treatmentTime = treatment['scheduled_time'].toString();

            final isThisDay = _isSameDay(treatmentDate, day);
            final isThisHour = _isSameHour(treatmentTime, hour);

            print(
                '🔍 Check: ${treatment['medication_name']} - Date: ${treatment['scheduled_date']} Time: ${treatment['scheduled_time']} vs Day: ${DateFormat('yyyy-MM-dd').format(day)} Hour: $hour');
            print(
                '🔍 Debug day: ${treatmentDate.toIso8601String()} vs ${day.toIso8601String()}');
            print('🔍 Debug time: $treatmentTime vs $hour format comparison');
            print('🔍 Matches: day=$isThisDay hour=$isThisHour');

            if (isThisDay && isThisHour) {
              print(
                  '✅ Chip SHOWN: ${treatment['medication_name']} - Día: ${DateFormat('yyyy-MM-dd').format(day)} Hora: $hour');
            }

            return isThisDay && isThisHour;
          } catch (e) {
            print(
                '❌ Error parsing datos: ${treatment['scheduled_date']}, ${treatment['scheduled_time']} - $e');
            return false;
          }
        }).toList();

        if (dayTreatments.isEmpty) {
          return Container();
        }

        return Container(
          padding: EdgeInsets.all(2),
          child: Column(
            children: dayTreatments.map((treatment) {
              return GestureDetector(
                onTap: () => widget.onTreatmentTap(treatment['id']),
                child: Container(
                  margin: EdgeInsets.only(bottom: 2),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getTreatmentColor(treatment),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        treatment['medication_name'] ?? 'Tratamiento',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (treatment['scheduled_time'] != null) ...[
                        SizedBox(height: 1),
                        Text(
                          _formatTimeToString(treatment['scheduled_time']),
                          style: TextStyle(
                            fontSize: 7,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  String _formatTimeToString(dynamic scheduledTime) {
    try {
      String timeStr = scheduledTime.toString();
      if (timeStr.contains(':')) {
        List<String> parts = timeStr.split(':');
        if (parts.length >= 2) {
          return '${parts[0]}:${parts[1]}';
        }
      }
      return timeStr;
    } catch (e) {
      return scheduledTime.toString();
    }
  }

  String _getDayAbbreviation(DateTime date) {
    final dayNames = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
    return dayNames[date.weekday - 1];
  }

  List<String> _generateHours() {
    final hours = <String>[];
    for (int i = 6; i <= 22; i++) {
      hours.add('${i.toString().padLeft(2, '0')}:00');
    }
    return hours;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  bool _isSameHour(String time1, String time2) {
    try {
      // Convert to compare in proper hour format (e.g., "13:00" vs "13:45:00")
      if (time2.endsWith(':00')) {
        final h2 = time2.replaceAll(':00', '');
        return time1.startsWith('${h2}:');
      }
      return time1.startsWith(time2);
    } catch (e) {
      return false;
    }
  }

  bool _isCurrentHour(String hour) {
    final now = DateTime.now();
    final currentHour = '${now.hour.toString().padLeft(2, '0')}:00';
    return hour == currentHour;
  }

  Color _getTreatmentColor(Map<String, dynamic> treatment) {
    // Basado en el tipo de medicación o prioridad
    String medicationName = (treatment['medication_name'] ?? '').toLowerCase();
    String priority = treatment['priority'] ?? 'normal';

    // Medicamentos antibióticos - azul
    if (medicationName.contains('antibiotico') ||
        medicationName.contains('amoxicilina') ||
        medicationName.contains('penicilina') ||
        medicationName.contains('cefalosporina')) {
      return home.AppColors.primary500;
    }

    // Medicamentos analgésicos/antiinflamatorios - verde
    if (medicationName.contains('analgesico') ||
        medicationName.contains('ibuprofeno') ||
        medicationName.contains('paracetamol') ||
        medicationName.contains('morfina')) {
      return home.AppColors.success500;
    }

    // Medicamentos de soporte - púrpura
    if (medicationName.contains('soporte') ||
        medicationName.contains('fluidoterapia') ||
        medicationName.contains('nutricional') ||
        medicationName.contains('vitamina')) {
      return Colors.purple;
    }

    // Tratamientos de alta prioridad - rojo
    if (priority == 'urgent' ||
        priority == 'critical' ||
        medicationName.contains('critico')) {
      return home.AppColors.danger500;
    }

    // Tratamientos normales - azul medio
    if (priority == 'normal' || priority == 'routine') {
      return home.AppColors.primary500;
    }

    // Cirugías y procedimientos - naranja
    if (medicationName.contains('cirugia') ||
        medicationName.contains('procedimiento') ||
        medicationName.contains('operacion')) {
      return home.AppColors.warning500;
    }

    // Por defecto según tipo de seguimiento
    switch (treatment['follow_type']) {
      case 'treatment':
        return home.AppColors.primary500;
      case 'medication':
        return Colors.blue[600]!;
      case 'medication_reminder':
        return Colors.teal[600]!;
      default:
        return home.AppColors.primary500;
    }
  }

  List<DateTime> _getWeekDays(DateTime date) {
    final start = _getWeekStart(date);
    return List.generate(7, (index) => start.add(Duration(days: index)));
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  String _getCurrentWeekRange() {
    final start = _getWeekStart(_currentWeek);
    final end = start.add(Duration(days: 6));
    return '${DateFormat('dd MMM', 'es').format(start)} - ${DateFormat('dd MMM yyyy', 'es').format(end)}';
  }
}
