import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<TutorialPage> tutorialPages = [
    TutorialPage(
      title: 'Bienvenido a Zuliadog',
      description:
          'Sistema completo de gestión veterinaria para administrar pacientes, citas y recetas de manera eficiente.',
      icon: Icons.pets,
      color: Colors.blue,
    ),
    TutorialPage(
      title: 'Gestión de Pacientes',
      description:
          'Registra y administra la información de tus pacientes animales, incluyendo historias clínicas y datos de contacto.',
      icon: Icons.pets,
      color: Colors.green,
    ),
    TutorialPage(
      title: 'Sistema de Citas',
      description:
          'Programa y gestiona las citas de tus pacientes con un calendario intuitivo y notificaciones automáticas.',
      icon: Icons.calendar_today,
      color: Colors.orange,
    ),
    TutorialPage(
      title: 'Recetas Médicas',
      description:
          'Crea y gestiona recetas médicas digitales para tus pacientes con seguimiento de tratamientos.',
      icon: Icons.medication,
      color: Colors.purple,
    ),
    TutorialPage(
      title: 'Laboratorio',
      description:
          'Administra resultados de laboratorio y análisis clínicos de manera organizada y accesible.',
      icon: Icons.science,
      color: Colors.teal,
    ),
    TutorialPage(
      title: 'Reportes y Estadísticas',
      description:
          'Genera reportes detallados y visualiza estadísticas de tu clínica veterinaria.',
      icon: Icons.analytics,
      color: Colors.indigo,
    ),
  ];

  void _nextPage() {
    if (_currentPage < tutorialPages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipTutorial() {
    Navigator.of(context).pop();
  }

  String _getTutorialImage(int index) {
    switch (index) {
      case 0:
        return 'Assets/Images/tutorial_welcome.png'; // Bienvenido a Zuliadog
      case 1:
        return 'Assets/Images/tutorial_patients.png'; // Gestión de Pacientes
      case 2:
        return 'Assets/Images/tutorial_appointments.png'; // Sistema de Citas
      case 3:
        return 'Assets/Images/tutorial_prescriptions.png'; // Recetas Médicas
      case 4:
        return 'Assets/Images/tutorial_laboratory.png'; // Laboratorio
      case 5:
        return 'Assets/Images/tutorial_reports.png'; // Reportes y Estadísticas
      default:
        return 'Assets/Icon/appicon.svg'; // Fallback al logo
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                padding: const EdgeInsets.all(32),
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: tutorialPages.length,
                  itemBuilder: (context, index) {
                    final page = tutorialPages[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Imagen circular para cada página del tutorial
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              _getTutorialImage(index),
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback al SVG si no existe la imagen
                                return Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: SvgPicture.asset(
                                    'Assets/Icon/appicon.svg',
                                    width: 80,
                                    height: 80,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Título
                        Text(
                          page.title,
                          style: t.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),

                        // Descripción
                        Text(
                          page.description,
                          style: t.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // Indicadores de página
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            tutorialPages.length,
                            (index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: _currentPage == index ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _currentPage == index
                                    ? page.color
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Botones de navegación alineados
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Botón anterior (solo si no es la primera página)
                            if (_currentPage > 0)
                              Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: _previousPage,
                                    child: const Icon(
                                      Icons.arrow_back,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),

                            if (_currentPage > 0) const SizedBox(width: 16),

                            // Botón siguiente/finalizar
                            Container(
                              height: 40,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: _nextPage,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _currentPage == tutorialPages.length - 1
                                            ? 'Finalizar'
                                            : 'Siguiente',
                                        style: t.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        _currentPage == tutorialPages.length - 1
                                            ? Icons.check
                                            : Icons.arrow_forward,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            // Botón de atrás flotante (solo desde la segunda página)
            if (_currentPage > 0)
              Positioned(
                top: 16,
                left: 16,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _previousPage,
                    child: Container(
                      width: 48,
                      height: 48,
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            // Botón de omitir flotante
            Positioned(
              top: 24,
              right: 48,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _skipTutorial,
                  child: Container(
                    width: 48,
                    height: 48,
                    child: const Icon(
                      Icons.close,
                      color: Colors.black,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TutorialPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  TutorialPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
