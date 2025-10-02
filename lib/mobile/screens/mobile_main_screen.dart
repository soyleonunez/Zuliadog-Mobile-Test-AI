import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:zuliadog/mobile/core/mobile_theme.dart';
import 'package:zuliadog/mobile/screens/mobile_dashboard_screen.dart';
import 'package:zuliadog/mobile/screens/mobile_pets_screen.dart';
import 'package:zuliadog/mobile/screens/mobile_files_screen.dart';
import 'package:zuliadog/mobile/screens/mobile_profile_screen.dart';

class MobileMainScreen extends StatefulWidget {
  const MobileMainScreen({super.key});

  @override
  State<MobileMainScreen> createState() => _MobileMainScreenState();
}

class _MobileMainScreenState extends State<MobileMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    MobileDashboardScreen(),
    MobilePetsScreen(),
    MobileFilesScreen(),
    MobileProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: MobileTheme.surfaceColor,
          boxShadow: [
            BoxShadow(
              color: MobileTheme.textPrimary.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Iconsax.home_2, 'Inicio'),
                _buildNavItem(1, Iconsax.heart, 'Mascotas'),
                _buildNavItem(2, Iconsax.folder_2, 'Archivos'),
                _buildNavItem(3, Iconsax.user, 'Perfil'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? MobileTheme.primaryColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? MobileTheme.primaryColor
                    : MobileTheme.textTertiary,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? MobileTheme.primaryColor
                      : MobileTheme.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
