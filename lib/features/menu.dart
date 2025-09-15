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
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    route: '/dashboard',
  ),
  AppMenuItem(
    label: 'Pacientes',
    icon: Icons.pets_outlined,
    selectedIcon: Icons.pets,
    route: '/patients',
  ),
  AppMenuItem(
    label: 'Citas',
    icon: Icons.event_note_outlined,
    selectedIcon: Icons.event_note,
    route: '/appointments',
  ),
  AppMenuItem(
    label: 'Recetas',
    icon: Icons.medication_outlined,
    selectedIcon: Icons.medication,
    route: '/prescriptions',
  ),
  AppMenuItem(
    label: 'Documentos',
    icon: Icons.description_outlined,
    selectedIcon: Icons.description,
    route: '/documents',
    badgeBuilder: () => 3,
  ),
  AppMenuItem(
    label: 'Recursos',
    icon: Icons.menu_book_outlined,
    selectedIcon: Icons.menu_book,
    route: '/resources',
  ),
  AppMenuItem(
    label: 'Servicios',
    icon: Icons.pie_chart_outline,
    selectedIcon: Icons.pie_chart,
    route: '/services',
    visibleFor: {UserRole.admin},
  ),
  AppMenuItem(
    label: 'KPIs',
    icon: Icons.query_stats_outlined,
    selectedIcon: Icons.query_stats,
    route: '/kpi',
    visibleFor: {UserRole.admin},
  ),
  AppMenuItem(
    label: 'Ajustes',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    route: '/settings',
  ),
];

List<AppMenuItem> visibleMenu(UserRole role) =>
    _allMenuItems.where((m) => m.visibleFor.contains(role)).toList();

int indexForRoute(List<AppMenuItem> items, String route, {int fallback = 0}) {
  final i = items.indexWhere((m) => m.route == route);
  return i >= 0 ? i : fallback;
}
