import 'package:flutter/material.dart';
import 'package:zuliadog/features/home.dart';

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
                  'Assets/Images/App.png',
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
