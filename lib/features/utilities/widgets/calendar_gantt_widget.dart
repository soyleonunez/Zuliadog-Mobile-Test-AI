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
  final Function(String) onTreatmentTap;
  final Function(String) onTreatmentEdit;
  final Function(String) onTreatmentComplete;

  const CalendarGanttWidget({
    super.key,
    required this.currentWeek,
    this.selectedTreatmentId,
    required this.onTreatmentTap,
    required this.onTreatmentEdit,
    required this.onTreatmentComplete,
  });

  @override
  State<CalendarGanttWidget> createState() => _CalendarGanttWidgetState();
}

class _CalendarGanttWidgetState extends State<CalendarGanttWidget> {
  CalendarView _currentView = CalendarView.week;

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
                  // Implementar navegación anterior
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
                  // Implementar navegación siguiente
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
    final weekDays = _getWeekDays(widget.currentWeek);

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
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supa.from('follows').stream(primaryKey: ['id']).map((data) =>
          data.where((item) => item['follow_type'] == 'treatment').toList()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final treatments = snapshot.data ?? [];

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: treatments.length,
          itemBuilder: (context, index) {
            final treatment = treatments[index];
            return _buildGanttItem(treatment);
          },
        );
      },
    );
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
                  '${treatment['dosage'] ?? ''} - ${treatment['administration_route'] ?? ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: home.AppColors.neutral600,
                  ),
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
      stream: _supa.from('follows').stream(primaryKey: ['id']).map((data) =>
          data.where((item) => item['follow_type'] == 'treatment').toList()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container();
        }

        final treatments = snapshot.data ?? [];
        final dayTreatments = treatments.where((treatment) {
          if (treatment['scheduled_date'] == null ||
              treatment['scheduled_time'] == null) return false;
          final treatmentDate =
              DateTime.parse(treatment['scheduled_date'].toString());
          final treatmentTime = treatment['scheduled_time'].toString();
          return _isSameDay(treatmentDate, day) &&
              _isSameHour(treatmentTime, hour);
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
                  margin: EdgeInsets.only(bottom: 1),
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getTreatmentColor(treatment).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: _getTreatmentColor(treatment),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    treatment['medication_name'] ?? 'Tratamiento',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w500,
                      color: _getTreatmentColor(treatment),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
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
    return time1.startsWith(time2);
  }

  bool _isCurrentHour(String hour) {
    final now = DateTime.now();
    final currentHour = '${now.hour.toString().padLeft(2, '0')}:00';
    return hour == currentHour;
  }

  Color _getTreatmentColor(Map<String, dynamic> treatment) {
    switch (treatment['follow_type']) {
      case 'treatment':
        return home.AppColors.primary500;
      case 'medication':
        return home.AppColors.success500;
      case 'vital_signs':
        return home.AppColors.warning500;
      case 'evolution':
        return home.AppColors.danger500;
      default:
        return home.AppColors.neutral500;
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
    final start = _getWeekStart(widget.currentWeek);
    final end = start.add(Duration(days: 6));
    return '${DateFormat('dd MMM', 'es').format(start)} - ${DateFormat('dd MMM yyyy', 'es').format(end)}';
  }
}
