import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../services/history_service.dart';

/// Widget para la barra de búsqueda de pacientes
class PatientSearchField extends StatefulWidget {
  final TextEditingController searchController;
  final List<PatientSearchRow> searchResults;
  final bool isSearching;
  final Function(String) onSearchChanged;
  final Function(PatientSearchRow) onPatientSelected;

  const PatientSearchField({
    super.key,
    required this.searchController,
    required this.searchResults,
    required this.isSearching,
    required this.onSearchChanged,
    required this.onPatientSelected,
  });

  @override
  State<PatientSearchField> createState() => _PatientSearchFieldState();
}

class _PatientSearchFieldState extends State<PatientSearchField> {
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    // Cancelar el timer anterior si existe
    _debounceTimer?.cancel();

    // Crear un nuevo timer con debounce de 300ms
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        widget.onSearchChanged(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      child: Column(
        children: [
          // Campo de búsqueda
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: widget.searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Buscar por MRN o nombre de mascota...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon:
                    Icon(Iconsax.search_normal, color: Colors.grey[500]),
                suffixIcon: widget.isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Resultados de búsqueda
          if (widget.searchResults.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.searchResults.length,
                itemBuilder: (context, index) {
                  final patient = widget.searchResults[index];
                  return _PatientSearchResultItem(
                    patient: patient,
                    onTap: () => widget.onPatientSelected(patient),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget para un resultado individual de búsqueda
class _PatientSearchResultItem extends StatelessWidget {
  final PatientSearchRow patient;
  final VoidCallback onTap;

  const _PatientSearchResultItem({
    required this.patient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Avatar con especie
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getSpeciesColor(patient.species ?? '').withOpacity(0.1),
                    _getSpeciesColor(patient.species ?? '').withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  patient.patientName.isNotEmpty
                      ? patient.patientName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: _getSpeciesColor(patient.species ?? ''),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Información del paciente
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient.patientName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (patient.ownerName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Dueño: ${patient.ownerName}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (patient.historyNumber != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'MRN: ${patient.historyNumber}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Badge de especie
            if (patient.species != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getSpeciesColor(patient.species!).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  patient.species!,
                  style: TextStyle(
                    color: _getSpeciesColor(patient.species!),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getSpeciesColor(String species) {
    switch (species.toLowerCase()) {
      case 'canino':
      case 'perro':
        return const Color(0xFF8B5CF6);
      case 'felino':
      case 'gato':
        return const Color(0xFFF59E0B);
      case 'ave':
      case 'pájaro':
        return const Color(0xFF10B981);
      case 'roedor':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF4F46E5);
    }
  }
}
