// Imports necesarios
import '../features/home.dart';
import '../features/utilities/pacientes.dart';
import '../features/utilities/historias.dart';
import '../features/utilities/recetas.dart';
import '../features/utilities/laboratorio.dart';
import '../features/utilities/agenda.dart';
import '../features/utilities/visor.dart';
import '../features/utilities/recursos.dart';
import '../features/utilities/tickets.dart';
import '../features/utilities/reportes.dart';

import 'package:flutter/material.dart';

class NavigationHelper {
  /// Navega a una ruta sin animación
  static void navigateToRoute(BuildContext context, String route) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          // Obtener la página correspondiente a la ruta
          Widget page;
          switch (route) {
            case '/home':
              page = const HomeScreen();
              break;
            case '/pacientes':
              page = const PacientesPage();
              break;
            case '/historias':
              page = const HistoriasPage();
              break;
            case '/recetas':
              page = const RecetasPage();
              break;
            case '/laboratorio':
              page = const LaboratorioPage();
              break;
            case '/agenda':
              page = const AgendaPage();
              break;
            case '/visor-medico':
              page = const VisorMedicoPage();
              break;
            case '/recursos':
              page = const RecursosPage();
              break;
            case '/tickets':
              page = const TicketsPage();
              break;
            case '/reportes':
              page = const ReportesPage();
              break;
            default:
              page = const HomeScreen();
          }
          return page;
        },
        transitionDuration: Duration.zero, // Sin animación
        reverseTransitionDuration: Duration.zero, // Sin animación de regreso
      ),
    );
  }
}
