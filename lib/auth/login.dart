import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:zuliadog/features/home.dart';
import 'department_login.dart';
import 'tutorial_screen.dart';

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

  void _goToLogin(BuildContext context) async {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const DepartmentLoginScreen(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
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
            // CONTENIDO PRINCIPAL - POSICIONAMIENTO DESDE ABAJO
            Positioned(
              bottom:
                  138, // PADDING INFERIOR: Cambia este valor para subir/bajar el contenido
              left: 0,
              right: 0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // TÍTULO PRINCIPAL
                  Text(
                    'Bienvenido a la App',
                    style: t.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 24, // TAMAÑO DE TÍTULO: Ajusta según necesites
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // ESPACIADO ENTRE TÍTULO Y SUBTÍTULO
                  const SizedBox(
                      height:
                          1), // ESPACIADO TÍTULO-SUBTÍTULO: Cambia este valor

                  // SUBTÍTULO
                  Text(
                    'de gestión veterinaria.',
                    style: t.bodyLarge?.copyWith(
                      color: Colors.black,
                      fontSize:
                          14, // TAMAÑO DE SUBTÍTULO: Ajusta según necesites
                      fontWeight: FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // ESPACIADO ENTRE SUBTÍTULO Y BOTÓN
                  const SizedBox(
                      height:
                          10), // ESPACIADO SUBTÍTULO-BOTÓN: Cambia este valor

                  // BOTÓN PRINCIPAL "INGRESAR" - FONDO NEGRO CON ICONO OUTLINE Y ANIMACIÓN
                  AnimatedBuilder(
                    animation: _buttonScale,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _buttonScale.value,
                        child: Container(
                          height: 40, // ALTURA DEL BOTÓN: Cambia este valor
                          padding: const EdgeInsets.symmetric(
                              horizontal:
                                  24), // PADDING HORIZONTAL DEL BOTÓN: Cambia este valor
                          decoration: BoxDecoration(
                            color: Colors.black, // FONDO NEGRO
                            borderRadius: BorderRadius.circular(
                                20), // BORDES REDONDOS DEL BOTÓN: Cambia este valor
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => _goToLogin(context),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Ingresar',
                                    style: t.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white, // TEXTO BLANCO
                                      fontSize:
                                          12, // TAMAÑO DEL TEXTO DEL BOTÓN: Cambia este valor
                                    ),
                                  ),
                                  const SizedBox(
                                      width:
                                          6), // ESPACIADO TEXTO-ICONO: Cambia este valor
                                  const Icon(
                                    Iconsax.login,
                                    color: Colors.white, // ICONO BLANCO OUTLINE
                                    size:
                                        16, // TAMAÑO DEL ICONO: Cambia este valor
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

            // BOTÓN DE TUTORIAL - POSICIONAMIENTO DESDE ABAJO Y DERECHA CON ANIMACIÓN
            Positioned(
              bottom:
                  145, // PADDING INFERIOR: Mismo valor que el contenido principal
              right:
                  35, // PADDING DERECHO: Cambia este valor para alejar/acercar del borde
              child: GestureDetector(
                onTap: () => _goToTutorial(context),
                child: AnimatedBuilder(
                  animation: _tutorialScale,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _tutorialScale.value,
                      child: Container(
                        width:
                            40, // ANCHO DEL BOTÓN DE TUTORIAL: Cambia este valor
                        height:
                            40, // ALTO DEL BOTÓN DE TUTORIAL: Cambia este valor
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.8),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius:
                                  8, // DESENFOQUE DE LA SOMBRA: Cambia este valor
                              offset: const Offset(0,
                                  4), // DESPLAZAMIENTO DE LA SOMBRA: Cambia este valor
                            ),
                          ],
                        ),
                        child: const Icon(
                          Iconsax.info_circle,
                          color: Colors.white,
                          size:
                              20, // TAMAÑO DEL ICONO DE TUTORIAL: Cambia este valor
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
