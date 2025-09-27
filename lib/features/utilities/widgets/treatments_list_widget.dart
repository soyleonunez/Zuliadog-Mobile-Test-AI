import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../home.dart' as home;
import 'treatment_card_widget.dart';

class TreatmentsListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> treatments;
  final Function(String)? onEditTreatment;
  final Function(String)? onCompleteTreatment;
  final VoidCallback? onAddTreatment;

  const TreatmentsListWidget({
    Key? key,
    required this.treatments,
    this.onEditTreatment,
    this.onCompleteTreatment,
    this.onAddTreatment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: home.AppColors.neutral50,
      child: Column(
        children: [
          // Header mejorado
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Título principal
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            home.AppColors.primary500,
                            home.AppColors.primary600,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: home.AppColors.primary500.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Iconsax.health,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tratamientos y Medicamentos',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: home.AppColors.neutral900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${treatments.length} tratamiento${treatments.length != 1 ? 's' : ''} activo${treatments.length != 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: home.AppColors.neutral600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Botón de agregar mejorado
                    if (onAddTreatment != null)
                      Container(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: onAddTreatment,
                          icon: Icon(
                            Iconsax.add,
                            size: 18,
                          ),
                          label: Text(
                            'Agregar',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: home.AppColors.primary500,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            shadowColor:
                                home.AppColors.primary500.withOpacity(0.3),
                          ),
                        ),
                      ),
                  ],
                ),

                // Filtros y estadísticas rápidas
                if (treatments.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: home.AppColors.neutral50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: home.AppColors.neutral200),
                    ),
                    child: Row(
                      children: [
                        // Estadística de pendientes
                        Expanded(
                          child: _buildStatCard(
                            'Pendientes',
                            treatments
                                .where((t) => t['status'] == 'pending')
                                .length,
                            home.AppColors.warning500,
                            Iconsax.clock,
                          ),
                        ),
                        SizedBox(width: 12),
                        // Estadística de completados
                        Expanded(
                          child: _buildStatCard(
                            'Completados',
                            treatments
                                .where((t) => t['status'] == 'completed')
                                .length,
                            home.AppColors.success500,
                            Iconsax.tick_circle,
                          ),
                        ),
                        SizedBox(width: 12),
                        // Estadística de en progreso
                        Expanded(
                          child: _buildStatCard(
                            'En Progreso',
                            treatments
                                .where((t) => t['status'] == 'in_progress')
                                .length,
                            home.AppColors.primary500,
                            Iconsax.activity,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Lista de tratamientos
          Expanded(
            child: treatments.isEmpty
                ? _buildEmptyState()
                : Container(
                    padding: EdgeInsets.all(16),
                    child: ListView.builder(
                      itemCount: treatments.length,
                      itemBuilder: (context, index) {
                        final treatment = treatments[index];
                        return TreatmentCardWidget(
                          treatment: treatment,
                          onEdit: onEditTreatment != null
                              ? () => onEditTreatment!(treatment['id'] ?? '')
                              : null,
                          onComplete: onCompleteTreatment != null
                              ? () =>
                                  onCompleteTreatment!(treatment['id'] ?? '')
                              : null,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: color,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: home.AppColors.neutral900,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: home.AppColors.neutral600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: home.AppColors.neutral100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.health,
              size: 48,
              color: home.AppColors.neutral400,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No hay tratamientos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: home.AppColors.neutral700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Agrega el primer tratamiento para comenzar',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: home.AppColors.neutral500,
            ),
          ),
          SizedBox(height: 24),
          if (onAddTreatment != null)
            ElevatedButton.icon(
              onPressed: onAddTreatment,
              icon: Icon(
                Iconsax.add,
                size: 18,
              ),
              label: Text(
                'Agregar Tratamiento',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: home.AppColors.primary500,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                shadowColor: home.AppColors.primary500.withOpacity(0.3),
              ),
            ),
        ],
      ),
    );
  }
}
