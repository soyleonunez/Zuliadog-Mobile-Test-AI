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
  late DateTime _currentWeek;
  List<Map<String, dynamic>> _cachedTreatments = [];
  bool _isLoading = false;

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

// Variables estáticas removidas para optimizar código

  void _initializeTreatmentsStream() async {
    try {
      // ⚡ SOLO INICIALIZAR SI HAY PACIENTE SELECCIONADO
      if (widget.selectedPatientId == null) {
        print('🔍 No patient selected, stream not initialized yet');
        setState(() {
          _cachedTreatments = [];
          _isLoading = false;
        });
        return;
      }

      print(
          '🔍 Initializing treatments caching for patient: ${widget.selectedPatientId}');
      setState(() => _isLoading = true);

      // Cargar datos en caché en lugar de usar streams (EVITAR MÚLTIPLES STREAMBUILDERS)
      final treatments = await _loadTreatmentsAsync();
      setState(() {
        _cachedTreatments = treatments;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error inicializando treatments: $e');
      setState(() {
        _cachedTreatments = [];
        _isLoading = false;
      });
    }
  }

// _createOptimizedTreatmentsStream removido - ya no se usa para evitar stream conflicts

  Future<List<Map<String, dynamic>>> _loadTreatmentsAsync() async {
    try {
      print('🔄 Starting non-blocking treatment loading...');

      // ⚡ CARGAR SOLO SI HAY PACIENTE SELECCIONADO (evitar bloques)
      final selectedPatientId = widget.selectedPatientId;
      if (selectedPatientId == null) {
        print('🔍 No patient selected, returning empty treatment list');
        return [];
      }

      // ⚡ BÚSQUEDA OPTIMIZADA CON FILTRO PRE-VIEW
      final followsData = await _supa
          .from('follows')
          .select(
              'id, follow_type, medication_name, scheduled_date, scheduled_time, patient_id')
          .eq('follow_type', 'treatment')
          .eq('patient_id', selectedPatientId);

      print(
          '🔍 Found ${followsData.length} treatments for patient: $selectedPatientId');

      // ⚡ SIMPLIFICAR PROCESAMIENTO - NO MÚLTIPLES QUERIES
      return followsData.map((item) {
        Map<String, dynamic> enrichedItem = Map<String, dynamic>.from(item);
        enrichedItem['patient_name'] = 'Paciente'; // Fallback simple
        return enrichedItem;
      }).toList();
    } catch (e) {
      print('❌ Error loading treatments: $e');
      return [];
    }
  }

// Método obsoleto removido - reemplazado por _loadTreatmentsAsync para evitar bucles infinitos

// Método _filterTreatmentsByPatient removido - método obsoleto no utilizado

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

    // ⚡ USAR DATOS EN CACHÉ EN LUGAR DE STREAM PARA EVITAR "SAME STREAM LISTENED" ERROR
    if (_isLoading) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: home.AppColors.neutral200),
        ),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final treatments = _cachedTreatments;
    print(
        '📊 Gantt cargando ${treatments.length} tratamientos desde caché para paciente ${widget.selectedPatientId}');

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

// _buildPatientTimelineGrid método no utilizado removido

// _buildTreatmentBar método no utilizado removido

// _buildGanttWeekHeader método no utilizado removido

// _buildGanttTreatmentRow método no utilizado removido

// _isTreatmentOnDay método no utilizado removido

// _buildHorizontalGanttContent método no utilizado removido

// _buildPatientTreatmentsRow y _buildTreatmentPosition métodos no utilizados removidos

// _buildGanttTimelineItem, _buildTimelineDayContent y _buildGanttItem métodos no utilizados removidos

  Widget _buildTimeSlot(DateTime day, String hour) {
    // ⚡ USAR DATOS EN CACHÉ EN LUGAR DE STREAM PARA EVITAR "SAME STREAM ERROR"
    if (_isLoading) {
      return Container(); // Vacío mientras carga
    }

    final treatments = _cachedTreatments;

    // ⚡ SIMPLIFICAR PROCESAMIENTO - MENOS PRINTS/LÓGICAS PESADAS
    final dayTreatments = treatments.where((treatment) {
      if (treatment['scheduled_date'] == null ||
          treatment['scheduled_time'] == null) {
        return false;
      }
      try {
        final treatmentDate =
            DateTime.parse(treatment['scheduled_date'].toString());
        final treatmentTime = treatment['scheduled_time'].toString();
        return _isSameDay(treatmentDate, day) &&
            _isSameHour(treatmentTime, hour);
      } catch (e) {
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
