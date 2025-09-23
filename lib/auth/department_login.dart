import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:zuliadog/features/home.dart';

class DepartmentLoginScreen extends StatefulWidget {
  const DepartmentLoginScreen({super.key});

  @override
  State<DepartmentLoginScreen> createState() => _DepartmentLoginScreenState();
}

class _DepartmentLoginScreenState extends State<DepartmentLoginScreen> {
  String? selectedRole;
  String? selectedUser;
  bool isLoading = false;

  // Datos de roles y usuarios predefinidos (sin owner)
  final List<Map<String, dynamic>> clinicRoles = [
    {
      "idx": 1,
      "clinic_id": "4c17fddf-24ab-4a8d-9343-4cc4f6a4a203",
      "user_id": "1e2d3c4b-5a6f-7e8d-9c0b-1a2b3c4d5e6f",
      "email": "zuliadogvet@gmail.com",
      "display_name": "Zuliadog",
      "role": "assistant",
      "is_active": true,
      "created_at": "2025-09-23 13:38:26+00",
      "updated_at": "2025-09-23 13:42:52.663417+00"
    },
    {
      "idx": 2,
      "clinic_id": "4c17fddf-24ab-4a8d-9343-4cc4f6a4a203",
      "user_id": "7b6a5c4d-2e1f-3a8b-9c0d-1e2f3a4b5c6d",
      "email": "zuliadogvet@gmail.com",
      "display_name": "Zuliadog",
      "role": "doctor",
      "is_active": true,
      "created_at": "2025-09-23 13:38:26+00",
      "updated_at": "2025-09-23 13:38:59+00"
    },
    {
      "idx": 3,
      "clinic_id": "4c17fddf-24ab-4a8d-9343-4cc4f6a4a203",
      "user_id": "c8d7e6f5-4a3b-2c1d-0e9f-8a7b6c5d4e3f",
      "email": "zuliadogvet@gmail.com",
      "display_name": "Zuliadog",
      "role": "lab",
      "is_active": true,
      "created_at": "2025-09-23 13:38:26+00",
      "updated_at": "2025-09-23 13:43:29.784216+00"
    },
    {
      "idx": 4,
      "clinic_id": "4c17fddf-24ab-4a8d-9343-4cc4f6a4a203",
      "user_id": "f0e9d8c7-b6a5-4f3e-2d1c-0b9a8c7d6e5f",
      "email": "zuliadogvet@gmail.com",
      "display_name": "Zuliadog",
      "role": "admin",
      "is_active": true,
      "created_at": "2025-09-23 13:38:26+00",
      "updated_at": "2025-09-23 13:44:26.766862+00"
    }
  ];

  // Mapeo de roles a nombres más amigables
  final Map<String, String> roleNames = {
    'admin': 'Administrador',
    'doctor': 'Veterinario',
    'assistant': 'Asistente',
    'lab': 'Laboratorio',
  };

  // Mapeo de roles a iconos Iconsax
  final Map<String, IconData> roleIcons = {
    'admin': Iconsax.shield_tick,
    'doctor': Iconsax.health,
    'assistant': Iconsax.user_add,
    'lab': Iconsax.cpu,
  };

  // Mapeo de roles a colores modernos
  final Map<String, Color> roleColors = {
    'admin': const Color(0xFF6366F1), // Indigo
    'doctor': const Color(0xFF10B981), // Emerald
    'assistant': const Color(0xFFF59E0B), // Amber
    'lab': const Color(0xFF06B6D4), // Cyan
  };

  void _login() async {
    if (selectedRole == null || selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un departamento'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    // Simular proceso de login
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      isLoading = false;
    });

    // Navegar a la pantalla principal
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Iniciar Sesión'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Título
                Text(
                  'Selecciona tu Departamento',
                  style: t.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Elige el rol con el que deseas ingresar',
                  style: t.bodyLarge?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Cards de departamentos
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: clinicRoles
                      .map((user) => user['role'])
                      .toSet()
                      .map((role) => _buildDepartmentCard(role))
                      .toList(),
                ),

                const SizedBox(height: 48),

                // Botón de login moderno
                if (selectedRole != null) ...[
                  _buildLoginButton(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: 200,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: isLoading ? null : _login,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Iconsax.arrow_right_3),
        label: Text(isLoading ? 'Ingresando...' : 'Ingresar'),
      ),
    );
  }

  Widget _buildDepartmentCard(String role) {
    final isSelected = selectedRole == role;
    final color = roleColors[role]!;
    final icon = roleIcons[role]!;
    final name = roleNames[role]!;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRole = role;
          selectedUser =
              clinicRoles.firstWhere((user) => user['role'] == role)['user_id'];
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 160,
        height: 120,
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? color.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? color : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? color : Colors.grey[700],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Zuliadog',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
