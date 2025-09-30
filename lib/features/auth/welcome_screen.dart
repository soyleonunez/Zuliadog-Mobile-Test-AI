import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:zuliadog/features/home.dart';
import 'package:zuliadog/features/auth/tutorial_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _buttonController;
  late AnimationController _tutorialController;
  late Animation<double> _buttonScale;
  late Animation<double> _tutorialScale;

  @override
  void initState() {
    super.initState();
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _tutorialController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _buttonScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
    _tutorialScale = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _tutorialController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _buttonController.dispose();
    _tutorialController.dispose();
    super.dispose();
  }

  void _goToHome(BuildContext context) async {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );
    }
  }

  void _goToTutorial(BuildContext context) async {
    if (mounted) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const TutorialScreen(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final screenSize = MediaQuery.of(context).size;
    final isMaximized = screenSize.width > 1200; // Detectar si está maximizado
    final isSmallScreen = screenSize.width < 800; // Detectar pantallas pequeñas

    return Scaffold(
      body: Container(
        // VENTANA RESPONSIVE QUE SE ADAPTA AL TAMAÑO DISPONIBLE
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('Assets/Images/App.jpg'),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter, // Cortar desde arriba
          ),
        ),
        child: Stack(
          children: [
            // CONTENIDO PRINCIPAL - POSICIONAMIENTO RESPONSIVE MEJORADO
            Positioned(
              bottom: isMaximized
                  ? 220 // Vista maximizada: más espacio desde abajo
                  : isSmallScreen
                      ? 120 // Vista pequeña: menos espacio
                      : 150, // Vista normal: espacio intermedio
              left: isMaximized ? 80 : 40, // Padding horizontal responsivo
              right: isMaximized ? 80 : 40,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // TÍTULO PRINCIPAL
                  Text(
                    'Bienvenido a la App',
                    style: t.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: isMaximized
                          ? 32 // Vista maximizada: texto más grande
                          : isSmallScreen
                              ? 20 // Vista pequeña: texto más pequeño
                              : 24, // Vista normal
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // ESPACIADO ENTRE TÍTULO Y SUBTÍTULO
                  SizedBox(height: isMaximized ? 8 : 4),

                  // SUBTÍTULO
                  Text(
                    'de gestión veterinaria.',
                    style: t.bodyLarge?.copyWith(
                      color: Colors.black,
                      fontSize: isMaximized
                          ? 18 // Vista maximizada: texto más grande
                          : isSmallScreen
                              ? 12 // Vista pequeña: texto más pequeño
                              : 14, // Vista normal
                      fontWeight: FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // ESPACIADO ENTRE SUBTÍTULO Y BOTÓN
                  SizedBox(height: isMaximized ? 20 : 16),

                  // BOTÓN PRINCIPAL "INGRESAR" - FONDO NEGRO CON ICONO OUTLINE Y ANIMACIÓN
                  AnimatedBuilder(
                    animation: _buttonScale,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _buttonScale.value,
                        child: Container(
                          height: isMaximized
                              ? 50 // Vista maximizada: botón más alto
                              : isSmallScreen
                                  ? 36 // Vista pequeña: botón más pequeño
                                  : 42, // Vista normal
                          padding: EdgeInsets.symmetric(
                            horizontal: isMaximized
                                ? 32 // Vista maximizada: más padding horizontal
                                : isSmallScreen
                                    ? 20 // Vista pequeña: menos padding
                                    : 26, // Vista normal
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black, // FONDO NEGRO
                            borderRadius: BorderRadius.circular(
                                isMaximized ? 25 : 20 // Radio responsivo
                                ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: isMaximized ? 12 : 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius:
                                  BorderRadius.circular(isMaximized ? 25 : 20),
                              onTap: () => _goToHome(context),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Entrar',
                                    style: t.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white, // TEXTO BLANCO
                                      fontSize: isMaximized
                                          ? 16 // Vista maximizada: texto más grande
                                          : isSmallScreen
                                              ? 12 // Vista pequeña: texto más pequeño
                                              : 14, // Vista normal
                                    ),
                                  ),
                                  SizedBox(width: isMaximized ? 8 : 6),
                                  Icon(
                                    Iconsax.login,
                                    color: Colors.white, // ICONO BLANCO OUTLINE
                                    size: isMaximized
                                        ? 20 // Vista maximizada: icono más grande
                                        : isSmallScreen
                                            ? 14 // Vista pequeña: icono más pequeño
                                            : 16, // Vista normal
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // BOTÓN DE TUTORIAL - POSICIONAMIENTO RESPONSIVE MEJORADO
            Positioned(
              bottom: isMaximized
                  ? 230 // Vista maximizada: más espacio desde abajo
                  : isSmallScreen
                      ? 130 // Vista pequeña: menos espacio
                      : 160, // Vista normal
              right: isMaximized
                  ? 100 // Vista maximizada: más espacio del borde
                  : isSmallScreen
                      ? 20 // Vista pequeña: menos espacio
                      : 50, // Vista normal
              child: GestureDetector(
                onTap: () => _goToTutorial(context),
                child: AnimatedBuilder(
                  animation: _tutorialScale,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _tutorialScale.value,
                      child: Container(
                        width: isMaximized
                            ? 50 // Vista maximizada: botón más grande
                            : isSmallScreen
                                ? 35 // Vista pequeña: botón más pequeño
                                : 42, // Vista normal
                        height: isMaximized
                            ? 50 // Vista maximizada: botón más grande
                            : isSmallScreen
                                ? 35 // Vista pequeña: botón más pequeño
                                : 42, // Vista normal
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.8),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: isMaximized ? 10 : 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Iconsax.info_circle,
                          color: Colors.white,
                          size: isMaximized
                              ? 24 // Vista maximizada: icono más grande
                              : isSmallScreen
                                  ? 18 // Vista pequeña: icono más pequeño
                                  : 20, // Vista normal
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Mantener la clase original para compatibilidad
class LoginView extends StatelessWidget {
  const LoginView({super.key});

  void _enterApp(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              const Spacer(),
              // Imagen de bienvenida
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Image.asset(
                  'Assets/Images/App.jpg',
                  height: 220,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 32),

              // Texto de bienvenida
              Text(
                '¡Bienvenido a Zuliadog!',
                style: t.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Gestiona tus pacientes, recetas y citas en un solo lugar.',
                style: t.bodyMedium?.copyWith(color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const Spacer(),

              // Botón principal
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _enterApp(context),
                  icon: const Icon(Icons.pets),
                  label: const Text('Entrar'),
                ),
              ),
              const SizedBox(height: 20),
              const SizedBox(width: 24),
            ],
          ),
        ),
      ),
    );
  }
}
