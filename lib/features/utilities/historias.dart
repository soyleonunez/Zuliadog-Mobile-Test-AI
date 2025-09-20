import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:iconsax/iconsax.dart';
import 'package:zuliadog/features/widgets/optimizedhist.dart';
import '../menu.dart';
import '../../core/navigation.dart';
import '../../core/responsive_wrapper.dart';

/// =========================
/// WIDGETS PRINCIPALES
/// =========================

class HistoriasPage extends StatefulWidget {
  static const String route = '/historias';

  final String? patientId;
  final String authorName;

  const HistoriasPage({
    super.key,
    this.patientId,
    this.authorName = 'Veterinaria',
  });

  @override
  State<HistoriasPage> createState() => _HistoriasPageState();
}

class _HistoriasPageState extends State<HistoriasPage> {
  // Estado de la UI
  String? _selectedPatientId;

  @override
  void initState() {
    super.initState();
    _initializeDateFormatting();
    _selectedPatientId = widget.patientId;
  }

  Future<void> _initializeDateFormatting() async {
    await initializeDateFormatting('es_VE', null);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF4F46E5),
            ),
      ),
      child: MinSizePage(
        minWidth: 1200.0, // Mismo tamaño que el resto de la app
        minHeight: 800.0,
        child: Scaffold(
          backgroundColor: Colors.grey[50],
          body: Stack(
            children: [
              Row(
                children: [
                  // Sidebar
                  AppSidebar(
                    activeRoute: 'frame_historias',
                    onTap: (route) {
                      if (route != 'frame_historias') {
                        NavigationHelper.navigateToRoute(context, '/home');
                      }
                    },
                    userRole: UserRole.doctor,
                  ),
                  // Contenido principal - Usar OptimizedHistoriasPage
                  Expanded(
                    child: _buildHistoriaMedica(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoriaMedica(BuildContext context) {
    return OptimizedHistoriasPage(
      clinicId:
          '4c17fddf-24ab-4a8d-9343-4cc4f6a4a203', // TODO: Obtener del contexto
      mrn:
          _selectedPatientId, // Puede ser null, OptimizedHistoriasPage lo maneja
    );
  }
}
