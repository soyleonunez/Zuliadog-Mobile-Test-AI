import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../home.dart' as home;

class TreatmentCardWidget extends StatelessWidget {
  final Map<String, dynamic> treatment;
  final VoidCallback? onEdit;
  final VoidCallback? onComplete;

  const TreatmentCardWidget({
    Key? key,
    required this.treatment,
    this.onEdit,
    this.onComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final medicationName = treatment['medication_name'] ?? 'Medicamento';
    final dosage = treatment['medication_dosage'] ?? 'No especificada';
    final status = treatment['status'] ?? 'pending';
    final route = treatment['administration_route'] ?? 'Oral';
    final frequency = treatment['frequency'] ?? 'No especificada';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(8), // Reducido para minimizar espacio interno
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header con título y botones de acción
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicationName,
                        style: TextStyle(
                          fontSize: 16, // Reducido de 18 a 16
                          fontWeight: FontWeight.w700,
                          color: home.AppColors.neutral900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 1),
                      Text(
                        _getMedicationType(medicationName),
                        style: TextStyle(
                          fontSize: 12, // Reducido de 14 a 12
                          fontWeight: FontWeight.w400,
                          color: home.AppColors.neutral500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Botones de acción directos
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Botón editar
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: home.AppColors.neutral100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: onEdit,
                        icon: Icon(
                          Iconsax.edit_2,
                          size: 14,
                          color: home.AppColors.neutral600,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ),
                    SizedBox(width: 4),
                    // Botón completar
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: status == 'completed'
                            ? home.AppColors.success500.withOpacity(0.1)
                            : home.AppColors.primary500.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: onComplete,
                        icon: Icon(
                          status == 'completed'
                              ? Iconsax.tick_circle
                              : Iconsax.play_circle,
                          size: 14,
                          color: status == 'completed'
                              ? home.AppColors.success500
                              : home.AppColors.primary500,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 8), // Reducido para minimizar espacio

            // Información detallada
            Column(
              children: [
                // Dosis
                _buildInfoRow(
                  Iconsax.health,
                  'Dosis',
                  dosage,
                ),

                SizedBox(height: 4), // Reducido para minimizar espacio

                // Frecuencia
                _buildInfoRow(
                  Iconsax.clock,
                  'Frecuencia',
                  frequency,
                ),

                SizedBox(height: 4), // Reducido para minimizar espacio

                // Vía de administración
                _buildInfoRow(
                  Iconsax.route_square,
                  'Vía',
                  route,
                ),
              ],
            ),

            SizedBox(height: 8), // Reducido para minimizar espacio

            // Footer con estado
            Container(
              padding:
                  EdgeInsets.only(top: 4), // Reducido para minimizar espacio
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: home.AppColors.neutral200,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Estado del tratamiento
                  _buildStatusButton(status),

                  // Botón de notificaciones
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: status == 'completed'
                          ? home.AppColors.primary500.withOpacity(0.1)
                          : home.AppColors.neutral100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: IconButton(
                      onPressed: () {
                        // Toggle notificaciones
                      },
                      icon: Icon(
                        status == 'completed'
                            ? Iconsax.notification_bing
                            : Iconsax.notification,
                        size: 14,
                        color: status == 'completed'
                            ? home.AppColors.primary500
                            : home.AppColors.neutral400,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 16, // Reducido de 20 a 16
          height: 16,
          child: Icon(
            icon,
            size: 12, // Reducido de 16 a 12
            color: home.AppColors.primary500,
          ),
        ),
        SizedBox(width: 6), // Reducido para minimizar espacio
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 12, // Reducido de 14 a 12
                color: home.AppColors.neutral600,
              ),
              children: [
                TextSpan(text: '$label: '),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: home.AppColors.neutral900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusButton(String status) {
    final isCompleted = status == 'completed';

    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: 10, vertical: 4), // Reducido padding
      decoration: BoxDecoration(
        color: isCompleted
            ? home.AppColors.success500.withOpacity(0.1)
            : home.AppColors.primary500.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16), // Más redondeado
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCompleted ? Iconsax.tick_circle : Iconsax.clock,
            size: 12, // Reducido de 14 a 12
            color: isCompleted
                ? home.AppColors.success500
                : home.AppColors.primary500,
          ),
          SizedBox(width: 4), // Reducido de 6 a 4
          Text(
            _getStatusLabel(status),
            style: TextStyle(
              fontSize: 11, // Reducido de 12 a 11
              fontWeight: FontWeight.w600,
              color: isCompleted
                  ? home.AppColors.success500
                  : home.AppColors.primary500,
            ),
          ),
        ],
      ),
    );
  }

  String _getMedicationType(String medicationName) {
    final name = medicationName.toLowerCase();
    if (name.contains('amoxicilina') ||
        name.contains('penicilina') ||
        name.contains('cefalexina')) {
      return 'Antibiótico';
    } else if (name.contains('meloxicam') ||
        name.contains('carprofeno') ||
        name.contains('ketoprofeno')) {
      return 'Analgésico (AINE)';
    } else if (name.contains('omeprazol') || name.contains('ranitidina')) {
      return 'Protector Gástrico';
    } else if (name.contains('desloratadina') || name.contains('cetirizina')) {
      return 'Antihistamínico';
    } else if (name.contains('fluido') || name.contains('ringer')) {
      return 'Soporte';
    } else if (name.contains('cura') || name.contains('herida')) {
      return 'Procedimiento';
    } else {
      return 'Medicamento';
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pendiente';
      case 'scheduled':
        return 'Programado';
      case 'completed':
      case 'done':
        return 'Administrado';
      case 'cancelled':
        return 'Cancelado';
      case 'in_progress':
        return 'En Progreso';
      default:
        return 'Pendiente';
    }
  }
}
