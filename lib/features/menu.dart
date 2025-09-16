import 'package:flutter/material.dart';

enum UserRole { doctor, admin }

class AppMenuItem {
  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final String route;
  final Set<UserRole> visibleFor;
  final int Function()? badgeBuilder;

  const AppMenuItem({
    required this.label,
    required this.icon,
    this.selectedIcon,
    required this.route,
    this.visibleFor = const {UserRole.doctor, UserRole.admin},
    this.badgeBuilder,
  });
}

List<AppMenuItem> _allMenuItems = [
  AppMenuItem(
    label: 'Home',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    route: '/home',
  ),
  AppMenuItem(
    label: 'Pacientes',
    icon: Icons.pets_outlined,
    selectedIcon: Icons.pets,
    route: '/pacientes',
  ),
  AppMenuItem(
    label: 'Historias médicas',
    icon: Icons.medical_services_outlined,
    selectedIcon: Icons.medical_services,
    route: '/historias',
  ),
  AppMenuItem(
    label: 'Recetas',
    icon: Icons.medication_outlined,
    selectedIcon: Icons.medication,
    route: '/recetas',
  ),
  AppMenuItem(
    label: 'Agenda & Calendario',
    icon: Icons.event_note_outlined,
    selectedIcon: Icons.event_note,
    route: '/agenda',
  ),
  AppMenuItem(
    label: 'Documentos',
    icon: Icons.description_outlined,
    selectedIcon: Icons.description,
    route: '/documentos',
    badgeBuilder: () => 3,
  ),
  AppMenuItem(
    label: 'Recursos',
    icon: Icons.menu_book_outlined,
    selectedIcon: Icons.menu_book,
    route: '/recursos',
  ),
  AppMenuItem(
    label: 'Tickets',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long,
    route: '/tickets',
  ),
  AppMenuItem(
    label: 'Reportes',
    icon: Icons.query_stats_outlined,
    selectedIcon: Icons.query_stats,
    route: '/reportes',
    visibleFor: {UserRole.admin},
  ),
  AppMenuItem(
    label: 'Ajustes',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    route: '/ajustes',
  ),
];

List<AppMenuItem> visibleMenu(UserRole role) =>
    _allMenuItems.where((m) => m.visibleFor.contains(role)).toList();

int indexForRoute(List<AppMenuItem> items, String route, {int fallback = 0}) {
  final i = items.indexWhere((m) => m.route == route);
  return i >= 0 ? i : fallback;
}
