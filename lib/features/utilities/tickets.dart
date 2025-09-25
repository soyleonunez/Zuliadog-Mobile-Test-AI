import 'package:flutter/material.dart';
import '../menu.dart';
import '../home.dart' as home;
import '../../core/navigation.dart';
import 'hospitalizacion.dart';

class TicketsPage extends StatelessWidget {
  const TicketsPage({super.key});

  static const route = '/tickets';

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        focusColor: home.AppColors.primary500.withOpacity(.12),
        hoverColor: home.AppColors.neutral50,
        splashColor: home.AppColors.primary500.withOpacity(.08),
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: home.AppColors.primary500,
              secondary: home.AppColors.primary600,
              surface: Colors.white,
              onSurface: home.AppColors.neutral900,
            ),
      ),
      child: Scaffold(
        backgroundColor: home.AppColors.neutral50,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSidebar(
              activeRoute: 'frame_tickets',
              onTap: (route) => _handleNavigation(context, route),
              userRole: UserRole.doctor,
            ),
            Expanded(
              child: Column(
                children: [
                  _TopBar(title: 'Tickets'),
                  const Divider(height: 1, color: home.AppColors.neutral200),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt,
                            size: 64,
                            color: home.AppColors.neutral400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Sistema de Tickets',
                            style: home.AppText.titleL.copyWith(
                              color: home.AppColors.neutral700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Gestiona tickets y soporte técnico',
                            style: home.AppText.bodyM.copyWith(
                              color: home.AppColors.neutral500,
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
    } else if (route == 'frame_tickets') {
      // Ya estamos en tickets
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
        case 'frame_hospitalizacion':
          routePath = HospitalizacionPage.route;
          break;
        case 'frame_recursos':
          routePath = '/recursos';
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
            bottom: BorderSide(color: home.AppColors.neutral200, width: 1),
          ),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: home.AppText.titleM.copyWith(
                color: home.AppColors.neutral900,
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
