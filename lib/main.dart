import 'package:flutter/material.dart';
import 'package:zuliadog/core/theme.dart';
import 'package:zuliadog/features/home.dart';
import 'package:zuliadog/features/utilities/visor.dart';
import 'package:zuliadog/features/utilities/pacientes.dart';
import 'package:zuliadog/features/utilities/historias.dart';
import 'package:zuliadog/features/utilities/recetas.dart';
import 'package:zuliadog/features/utilities/laboratorio.dart';
import 'package:zuliadog/features/utilities/agenda.dart';
import 'package:zuliadog/features/utilities/recursos.dart';
import 'package:zuliadog/features/utilities/tickets.dart';
import 'package:zuliadog/features/utilities/reportes.dart';
import 'package:zuliadog/auth/service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseService.init();
  runApp(const ZuliadogApp());
}

class ZuliadogApp extends StatelessWidget {
  const ZuliadogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const HomeScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        VisorMedicoPage.route: (context) => const VisorMedicoPage(),
        PacientesPage.route: (context) => const PacientesPage(),
        HistoriasPage.route: (context) => const HistoriasPage(),
        RecetasPage.route: (context) => const RecetasPage(),
        LaboratorioPage.route: (context) => const LaboratorioPage(),
        AgendaPage.route: (context) => const AgendaPage(),
        RecursosPage.route: (context) => const RecursosPage(),
        TicketsPage.route: (context) => const TicketsPage(),
        ReportesPage.route: (context) => const ReportesPage(),
      },
    );
  }
}
