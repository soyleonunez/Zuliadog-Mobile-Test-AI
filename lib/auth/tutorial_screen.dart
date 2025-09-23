import 'package:flutter/material.dart';

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
      appBar: AppBar(
        title: const Text('Tutorial'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _skipTutorial,
            child: const Text('Omitir'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Contenido del tutorial
            Expanded(
              child: Center(
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
                          // Icono más pequeño
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: page.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              page.icon,
                              size: 40,
                              color: page.color,
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
                          const SizedBox(height: 32),

                          // Indicadores de página
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              tutorialPages.length,
                              (index) => Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
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
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),

            // Botones de navegación
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Botón anterior
                  if (_currentPage > 0)
                    OutlinedButton.icon(
                      onPressed: _previousPage,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Anterior'),
                    )
                  else
                    const SizedBox(width: 100),

                  // Botón siguiente/finalizar
                  FilledButton.icon(
                    onPressed: _nextPage,
                    icon: Icon(
                      _currentPage == tutorialPages.length - 1
                          ? Icons.check
                          : Icons.arrow_forward,
                    ),
                    label: Text(
                      _currentPage == tutorialPages.length - 1
                          ? 'Finalizar'
                          : 'Siguiente',
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
