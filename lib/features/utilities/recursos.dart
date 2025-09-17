import 'package:flutter/material.dart';
import '../menu.dart';
import '../../core/navigation.dart';

class RecursosPage extends StatelessWidget {
  const RecursosPage({super.key});

  static const route = '/recursos';

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        focusColor: AppColors.primary500.withOpacity(.12),
        hoverColor: AppColors.neutral50,
        splashColor: AppColors.primary500.withOpacity(.08),
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary500,
              secondary: AppColors.primary600,
              surface: Colors.white,
              onSurface: AppColors.neutral900,
            ),
      ),
      child: Scaffold(
        backgroundColor: AppColors.neutral50,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSidebar(
              activeRoute: 'frame_recursos',
              onTap: (route) => _handleNavigation(context, route),
              userRole: UserRole.doctor,
            ),
            Expanded(
              child: Column(
                children: [
                  _TopBar(title: 'Recursos'),
                  const Divider(height: 1, color: AppColors.neutral200),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.library_books,
                            size: 64,
                            color: AppColors.neutral400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Recursos',
                            style: AppText.titleL.copyWith(
                              color: AppColors.neutral700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Accede a recursos y documentación médica',
                            style: AppText.bodyM.copyWith(
                              color: AppColors.neutral500,
                            ),
                          ),
                        ],
                      ),
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

  void _handleNavigation(BuildContext context, String route) {
    if (route == 'frame_home') {
      NavigationHelper.navigateToRoute(context, '/home');
    } else if (route == 'frame_recursos') {
      // Ya estamos en recursos
    } else {
      // Navegar a la página correspondiente
      String routePath = '/home'; // fallback
      switch (route) {
        case 'frame_pacientes':
          routePath = '/pacientes';
          break;
        case 'frame_historias':
          routePath = '/historias';
          break;
        case 'frame_recetas':
          routePath = '/recetas';
          break;
        case 'frame_laboratorio':
          routePath = '/laboratorio';
          break;
        case 'frame_agenda':
          routePath = '/agenda';
          break;
        case 'frame_visor_medico':
          routePath = '/visor-medico';
          break;
        case 'frame_tickets':
          routePath = '/tickets';
          break;
        case 'frame_reportes':
          routePath = '/reportes';
          break;
      }
      NavigationHelper.navigateToRoute(context, routePath);
    }
  }
}

class _TopBar extends StatelessWidget {
  final String title;

  const _TopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: AppColors.neutral200, width: 1),
          ),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: AppText.titleM.copyWith(
                color: AppColors.neutral900,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            const CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage('Assets/Images/ProfileImage.png'),
            ),
          ],
        ),
      ),
    );
  }
}
