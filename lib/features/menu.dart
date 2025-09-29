import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zuliadog/features/auth/welcome_screen.dart';
import 'package:zuliadog/features/home.dart';

enum UserRole { doctor, admin }

class AppMenuItem {
  final String label;
  final IconData icon;
  final String route;
  final Set<UserRole> visibleFor;
  final int Function()? badgeBuilder;

  const AppMenuItem({
    required this.label,
    required this.icon,
    required this.route,
    this.visibleFor = const {UserRole.doctor, UserRole.admin},
    this.badgeBuilder,
  });
}

// ==== COLORS ====

// ==== TEXT STYLES ====
class AppText {
  static const titleL = TextStyle(
      fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.neutral900);
  static const titleM = TextStyle(
      fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.neutral900);
  static const titleS = TextStyle(
      fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.neutral900);
  static const bodyM = TextStyle(
      fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.neutral900);
  static const bodyS = TextStyle(
      fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.neutral900);
  static const label = TextStyle(
      fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.neutral900);
}

List<AppMenuItem> _allMenuItems = [
  AppMenuItem(
    label: 'Home',
    icon: Iconsax.home_2,
    route: 'frame_home',
  ),
  AppMenuItem(
    label: 'Pacientes',
    icon: Iconsax.pet,
    route: 'frame_pacientes',
  ),
  AppMenuItem(
    label: 'Historias médicas',
    icon: Iconsax.health,
    route: 'frame_historias',
  ),
  AppMenuItem(
    label: 'Recetas',
    icon: Iconsax.note_text,
    route: 'frame_recetas',
  ),
  AppMenuItem(
    label: 'Laboratorio',
    icon: Iconsax.bill,
    route: 'frame_laboratorio',
  ),
  AppMenuItem(
    label: 'Agenda & Calendario',
    icon: Iconsax.calendar_1,
    route: 'frame_agenda',
  ),
  AppMenuItem(
    label: 'Hospitalización',
    icon: Iconsax.hospital,
    route: 'frame_hospitalizacion',
    badgeBuilder: () => 3,
  ),
  AppMenuItem(
    label: 'Recursos',
    icon: Iconsax.book_1,
    route: 'frame_recursos',
  ),
  AppMenuItem(
    label: 'Tickets',
    icon: Iconsax.receipt_2,
    route: 'frame_tickets',
  ),
  AppMenuItem(
    label: 'Reportes',
    icon: Iconsax.chart_2,
    route: 'frame_reportes',
    visibleFor: {UserRole.admin},
  ),
];

List<AppMenuItem> visibleMenu(UserRole role) =>
    _allMenuItems.where((m) => m.visibleFor.contains(role)).toList();

int indexForRoute(List<AppMenuItem> items, String route, {int fallback = 0}) {
  final i = items.indexWhere((m) => m.route == route);
  return i >= 0 ? i : fallback;
}

// ==== WIDGET DE MENÚ REUTILIZABLE ====
class AppSidebar extends StatelessWidget {
  final String activeRoute;
  final void Function(String route) onTap;
  final UserRole userRole;

  const AppSidebar({
    super.key,
    required this.activeRoute,
    required this.onTap,
    this.userRole = UserRole.doctor,
  });

  // Función para mostrar diálogo de actualización
  void _showRefreshDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [AppColors.primary500, AppColors.primary600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child:
                    const Icon(Iconsax.refresh, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Text('Actualizando datos...'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary500),
              ),
              const SizedBox(height: 16),
              Text(
                'Sincronizando información con el servidor...',
                style: AppText.bodyS.copyWith(color: AppColors.neutral500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );

    // Simular actualización de base de datos
    _refreshDatabase(context);
  }

  // Función para actualizar la base de datos
  Future<void> _refreshDatabase(BuildContext context) async {
    try {
      // Simular tiempo de actualización
      await Future.delayed(const Duration(seconds: 2));

      // Aquí puedes agregar la lógica real de actualización
      // Por ejemplo: await DatabaseService.refreshAllData();

      // Cerrar el diálogo
      if (context.mounted) {
        Navigator.of(context).pop();

        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Iconsax.tick_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('Datos actualizados correctamente'),
              ],
            ),
            backgroundColor: AppColors.success500,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      // Cerrar el diálogo en caso de error
      if (context.mounted) {
        Navigator.of(context).pop();

        // Mostrar mensaje de error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Iconsax.close_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('Error al actualizar los datos'),
              ],
            ),
            backgroundColor: AppColors.danger500,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  // Función para mostrar diálogo de confirmación de cierre de sesión
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.danger500.withOpacity(0.1),
                ),
                child: const Icon(
                  Iconsax.logout,
                  size: 16,
                  color: AppColors.danger500,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Cerrar sesión'),
            ],
          ),
          content: const Text(
            '¿Estás seguro de que deseas cerrar sesión?',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(color: AppColors.neutral500),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performLogout(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger500,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );
  }

  // Función para volver a la pantalla de bienvenida
  void _performLogout(BuildContext context) {
    // Navegar a la pantalla de bienvenida
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const WelcomeScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = visibleMenu(userRole);

    return Container(
      width: 260,
      height: 700, // Altura fija como en home.dart
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: AppColors.neutral200, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header con logo
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // Navegar al home y actualizar base de datos
                      onTap('frame_home');
                      _showRefreshDialog(context);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SvgPicture.asset(
                          'Assets/Icon/appicon.svg',
                          width: 40,
                          height: 40,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Zuliadog', style: AppText.titleS),
                      Text('Veterinaria',
                          style: AppText.bodyS
                              .copyWith(color: AppColors.neutral500)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Menú principal
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemBuilder: (_, i) {
                final item = items[i];
                final active = item.route == activeRoute;
                return _SidebarItem(
                  label: item.label,
                  icon: item.icon,
                  active: active,
                  badge: item.badgeBuilder?.call(),
                  onTap: () => onTap(item.route),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemCount: items.length,
            ),
          ),

          // Divider y ajustes
          const Divider(height: 1, color: AppColors.neutral200),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: _SidebarItem(
              label: 'Ajustes',
              icon: Iconsax.setting_2,
              active: activeRoute == 'frame_ajustes',
              onTap: () => onTap('frame_ajustes'),
            ),
          ),

          // Usuario en la parte inferior
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            decoration: BoxDecoration(
              color: AppColors.neutral50,
              border: const Border(
                top: BorderSide(color: AppColors.neutral200, width: 1),
              ),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundImage: AssetImage('Assets/Images/ProfileImage.png'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Doctor/a', style: AppText.bodyM),
                      Text('doctor@zuliadog.com',
                          style: AppText.bodyS
                              .copyWith(color: AppColors.neutral500)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Iconsax.more_2, size: 18),
                  tooltip: 'Menú de usuario',
                  onSelected: (value) {
                    if (value == 'logout') {
                      _showLogoutDialog(context);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Iconsax.logout,
                              size: 16, color: AppColors.danger500),
                          SizedBox(width: 8),
                          Text('Cerrar sesión'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final int? badge;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary500.withOpacity(.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: active
                ? Border.all(
                    color: AppColors.primary500.withOpacity(.2), width: 1)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: active ? AppColors.primary600 : AppColors.neutral600,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppText.bodyM.copyWith(
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    color: active ? AppColors.neutral900 : AppColors.neutral700,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: const BoxDecoration(
                    color: AppColors.danger500,
                    shape: BoxShape.circle,
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    badge.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (active)
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.primary600,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
