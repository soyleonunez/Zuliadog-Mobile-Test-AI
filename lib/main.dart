import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:zuliadog/core/theme.dart';
import 'package:zuliadog/features/home.dart';
import 'package:zuliadog/features/utilities/visor.dart';
import 'package:zuliadog/features/utilities/pacientes.dart';
import 'package:zuliadog/features/utilities/historias.dart';
import 'package:zuliadog/features/utilities/recetas.dart';
import 'package:zuliadog/features/utilities/laboratorio.dart';
import 'package:zuliadog/features/utilities/agenda.dart';
import 'package:zuliadog/features/utilities/hospitalizacion.dart';
import 'package:zuliadog/features/utilities/recursos.dart';
import 'package:zuliadog/features/utilities/tickets.dart';
import 'package:zuliadog/features/utilities/reportes.dart';
import 'package:zuliadog/auth/service.dart';
import 'package:zuliadog/auth/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar manejo de errores para evitar el error de teclado y PDFx
  FlutterError.onError = (FlutterErrorDetails details) {
    // Ignorar el error específico de teclado que es un bug conocido de Flutter
    if (details.exception.toString().contains('KeyDownEvent is dispatched') ||
        details.exception
            .toString()
            .contains('physical key is already pressed')) {
      return; // Ignorar este error específico
    }

    // Ignorar errores de PDFx que son comunes y no críticos
    if (details.exception.toString().contains('pdfx_exception') ||
        details.exception.toString().contains('Document failed to open')) {
      print('⚠️ Error de PDFx ignorado: ${details.exception}');
      return; // Ignorar este error específico
    }

    // Para otros errores, usar el handler por defecto
    FlutterError.presentError(details);
  };

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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'), // Español
        Locale('en', 'US'), // Inglés
      ],
      home: const WelcomeScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        VisorMedicoPage.route: (context) => const VisorMedicoPage(),
        '/pacientes': (context) => const PatientsDashboardPage(),
        HistoriasPage.route: (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          print('🔍 main.dart - args recibidos: $args');
          print('🔍 main.dart - patient_id: ${args?['patient_id']}');
          print('🔍 main.dart - mrn: ${args?['mrn']}');
          return HistoriasPage(
            patientId: args?['patient_id'],
            mrn: args?['mrn'],
          );
        },
        RecetasPage.route: (context) => const RecetasPage(),
        LaboratorioPage.route: (context) => const LaboratorioPage(),
        AgendaPage.route: (context) => const AgendaPage(),
        HospitalizacionPage.route: (context) => const HospitalizacionPage(),
        RecursosPage.route: (context) => const RecursosPage(),
        TicketsPage.route: (context) => const TicketsPage(),
        ReportesPage.route: (context) => const ReportesPage(),
      },
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            // Tamaño mínimo de ventana recomendado
            const minWidth = 1200.0;
            const minHeight = 800.0;

            // Si la ventana es muy pequeña, mostrar contenido con scroll
            if (constraints.maxWidth < minWidth ||
                constraints.maxHeight < minHeight) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: constraints.maxWidth < minWidth
                        ? minWidth
                        : constraints.maxWidth,
                    height: constraints.maxHeight < minHeight
                        ? minHeight
                        : constraints.maxHeight,
                    child: child,
                  ),
                ),
              );
            }

            return child!;
          },
        );
      },
    );
  }
}
