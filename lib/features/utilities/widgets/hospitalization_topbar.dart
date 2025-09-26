import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../home.dart' as home;

enum HospitalizationView { patients, gantt, calendar, reports }

class HospitalizationTopBar extends StatelessWidget {
  final HospitalizationView currentView;
  final Function(HospitalizationView) onViewChanged;

  const HospitalizationTopBar({
    super.key,
    required this.currentView,
    required this.onViewChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: home.AppColors.neutral200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Logo/Icono
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: home.AppColors.primary500,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Iconsax.hospital,
              color: Colors.white,
              size: 20,
            ),
          ),

          const SizedBox(width: 16),

          // Título
          Text(
            'Hospitalización',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: home.AppColors.neutral900,
            ),
          ),

          const Spacer(),

          // Botones de vista
          Row(
            children: [
              _buildViewButton(
                icon: Iconsax.people,
                label: 'Pacientes',
                view: HospitalizationView.patients,
                isSelected: currentView == HospitalizationView.patients,
              ),
              const SizedBox(width: 8),
              _buildViewButton(
                icon: Iconsax.task_square,
                label:
                    'Tratamientos', // Cambiado de 'Gantt' a 'Tratamientos' para que sea más claro
                view: HospitalizationView.gantt,
                isSelected: currentView == HospitalizationView.gantt,
              ),
              const SizedBox(width: 8),
              _buildViewButton(
                icon: Iconsax.calendar_2,
                label: 'Calendario',
                view: HospitalizationView.calendar,
                isSelected: currentView == HospitalizationView.calendar,
              ),
              const SizedBox(width: 8),
              _buildViewButton(
                icon: Iconsax.chart_2,
                label: 'Reportes',
                view: HospitalizationView.reports,
                isSelected: currentView == HospitalizationView.reports,
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
    required HospitalizationView view,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => onViewChanged(view),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? home.AppColors.primary500 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
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
}
