import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../home.dart' as home;
// DataService import removido para evitar problemas de carga
import '../hospitalizacion.dart';

class HospitalizedPatientsWidget extends StatelessWidget {
  final Stream<List<HospitalizedPatient>> patientsStream;
  final Function() onShowPatientSelection;
  final Function(HospitalizedPatient) onShowPatientDetail;
  final Function(HospitalizedPatient) onShowDischargeDialog;
  final Function(HospitalizedPatient) onShowHistory;
  final Function(HospitalizedPatient) onShowTreatment;
  final Function(HospitalizedPatient) onLoadPatientTreatments;

  const HospitalizedPatientsWidget({
    super.key,
    required this.patientsStream,
    required this.onShowPatientSelection,
    required this.onShowPatientDetail,
    required this.onShowDischargeDialog,
    required this.onShowHistory,
    required this.onShowTreatment,
    required this.onLoadPatientTreatments,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Text(
            'Pacientes Hospitalizados',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: home.AppColors.neutral900,
            ),
          ),
          const SizedBox(height: 8),

          // Stream de pacientes - Scroll horizontal
          Expanded(
            child: StreamBuilder<List<HospitalizedPatient>>(
              stream: patientsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }

                if (snapshot.hasError) {
                  return _buildErrorState();
                }

                final patients = snapshot.data ?? [];

                // Si no hay pacientes hospitalizados, mostrar mensaje
                if (patients.isEmpty) {
                  return Container(
                    height: 100,
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.empty_wallet,
                            size: 32,
                            color: home.AppColors.neutral400,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No hay pacientes hospitalizados',
                            style: TextStyle(
                              fontSize: 14,
                              color: home.AppColors.neutral500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: patients.length + 1,
                  itemBuilder: (context, index) {
                    if (index == patients.length) {
                      return Container(
                        width: 120,
                        margin: EdgeInsets.only(right: 8),
                        child: _buildAddPatientCard(),
                      );
                    }

                    // Card de paciente
                    return Container(
                      width:
                          250, // Aumentado para evitar overflow de los botones
                      margin: EdgeInsets.only(right: 12),
                      child: _buildPatientCard(patients[index]),
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

  Widget _buildLoadingState() {
    return ListView(
      scrollDirection: Axis.horizontal,
      children: [
        _buildAddPatientCard(),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.warning_2,
            size: 48,
            color: home.AppColors.danger500,
          ),
          const SizedBox(height: 16),
          Text(
            'Error al cargar pacientes',
            style: TextStyle(
              fontSize: 14,
              color: home.AppColors.neutral600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPatientCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: home.AppColors.primary200,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onShowPatientSelection,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.add_circle,
                  size: 24,
                  color: home.AppColors.primary500,
                ),
                const SizedBox(height: 4),
                Text(
                  'Agregar',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: home.AppColors.neutral900,
                  ),
                ),
                Text(
                  'Paciente',
                  style: TextStyle(
                    fontSize: 10,
                    color: home.AppColors.neutral600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientCard(HospitalizedPatient patient) {
    return Container(
      height: 135, // Altura reducida optimizada
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: home.AppColors.neutral200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: home.AppColors.neutral200.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          print('🔍 Card taped para paciente: ${patient.patientName}');
          // Cargar equipo datos en Calendario/Gantt
          onLoadPatientTreatments(patient);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical:
                    12), // Padding ligeramente reducido para evitar overflow en botones
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment
                    .center, // Centrar el contenido en el espacio disponible
                children: [
                  // Sección principal del paciente - Sin Expanded, contenido natural centrado
                  Row(
                    crossAxisAlignment: CrossAxisAlignment
                        .start, // Alinear en la parte superior para que avatar y texto estén alineados
                    children: [
                      // Avatar del paciente (circular)
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: home.AppColors.primary100,
                            ),
                            child: Center(
                              child: Text(
                                patient.patientName.isNotEmpty
                                    ? patient.patientName
                                        .substring(0, 1)
                                        .toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: home.AppColors.primary500,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                          width:
                              14), // Aumentado de 10 a 14 para más respiro entre avatar y texto

                      // Información del paciente
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment
                              .start, // Cambiado de center a start para permitir control manual del spacing
                          children: [
                            // Nombre del paciente
                            Text(
                              patient.patientName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: home.AppColors.neutral900,
                              ),
                              maxLines:
                                  2, // Permite 2 líneas para nombres largos
                              overflow: TextOverflow.ellipsis,
                            ),

                            const SizedBox(
                                height:
                                    3), // Aumentado para más espaciado entre nombre y MRN

                            // MRN
                            Text(
                              'MRN: ${patient.mrn}',
                              style: TextStyle(
                                fontSize: 12,
                                color: home.AppColors.neutral600,
                              ),
                            ),

                            const SizedBox(
                                height:
                                    3), // Aumentado para más espaciado entre MRN y especie/raza

                            // Especie y raza
                            Text(
                              '${patient.speciesLabel} / ${patient.breedLabel}',
                              style: TextStyle(
                                fontSize: 11,
                                color: home.AppColors.neutral500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                            const SizedBox(
                                height: 3), // Espacio hacia temperamento

                            // Temperamento con badge pegado directo al final del texto
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Temperamento del paciente
                                Text(
                                  patient.temperament ?? 'Suave',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: home.AppColors.neutral600,
                                  ),
                                ),
                                const SizedBox(
                                    width:
                                        6), // Espacio mínimo entre texto y badge
                                // Badge directamente pegado al temperamento
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: home.AppColors.success500
                                        .withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    patient.hospitalizationStatus == 'active'
                                        ? 'Estable'
                                        : _getPriorityLabel(
                                            patient.hospitalizationPriority),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: home.AppColors.success500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                      height:
                          8), // Aumentado de 4 a 8 para mejor espaciado entre info y botones

                  // Botones de acción: Historia, Tratamiento y Alta médica - Aumentados ligeramente
                  SizedBox(
                    height: 28, // Aumentado de 24 a 28 para mejor usabilidad
                    child: Row(
                      children: [
                        // Historia - botón más compacto
                        Flexible(
                          child: _buildPillButton(
                            label: 'Historia',
                            icon: Iconsax.document_text,
                            onTap: () => onShowHistory(patient),
                          ),
                        ),
                        const SizedBox(
                            width:
                                6), // Aumentado de 4 a 6 para mejor separación
                        // Tratamiento - botón más compacto
                        Flexible(
                          child: _buildPillButton(
                            label: 'Tratamiento',
                            icon: Iconsax.health,
                            onTap: () => onShowTreatment(patient),
                          ),
                        ),
                        const SizedBox(
                            width:
                                6), // Aumentado de 3 a 6 para mejor separación
                        // Botón de Alta médica con icono circular - fijo
                        _buildDischargeButton(patient),
                      ],
                    ),
                  ),
                ],
              ),
            )), // Cierre del IntrinsicHeight
      ),
    );
  }

  Widget _buildPillButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: home.AppColors.neutral100,
        borderRadius: BorderRadius.circular(16), // Más redondeado y compacto
        border: Border.all(
          color: home.AppColors.neutral200,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 6), // Aumentado ligeramente para mejor usabilidad
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 11, // Ligeramente aumentado para mejor proporción
                color: home.AppColors.neutral600,
              ),
              const SizedBox(width: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10, // Aumentado ligeramente de 9 a 10
                  color: home.AppColors.neutral700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDischargeButton(HospitalizedPatient patient) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: home.AppColors.neutral100,
        shape: BoxShape.circle,
        border: Border.all(
          color: home.AppColors.neutral200,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => onShowDischargeDialog(patient),
        borderRadius: BorderRadius.circular(16),
        child: Icon(
          Iconsax.logout,
          size: 14,
          color: home.AppColors.success500,
        ),
      ),
    );
  }

// _buildStatChip y _getPriorityColor métodos no utilizados removidos

  String _getPriorityLabel(String? priority) {
    switch (priority) {
      case 'low':
        return 'Baja';
      case 'normal':
        return 'Normal';
      case 'high':
        return 'Alta';
      case 'critical':
        return 'Crítica';
      default:
        return 'Normal';
    }
  }

// _formatDate y _calculateAge métodos no utilizados removidos
}
