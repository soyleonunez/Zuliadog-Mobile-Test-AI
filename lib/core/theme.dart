import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Design System Tokens
  static const Color primary500 = Color(0xFF5E81F4);
  static const Color primary600 = Color(0xFF4B6BE0);
  static const Color neutral900 = Color(0xFF0E1116);
  static const Color neutral700 = Color(0xFF2C333A);
  static const Color neutral500 = Color(0xFF667085);
  static const Color neutral200 = Color(0xFFE5E7EB);
  static const Color neutral50 = Color(0xFFF8FAFC);
  static const Color success500 = Color(0xFF22C55E);
  static const Color warning500 = Color(0xFFF59E0B);
  static const Color danger500 = Color(0xFFEF4444);

  // Spacing tokens (8pt scale)
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: primary500,
      brightness: Brightness.light,
    );

    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: primary500,
        secondary: primary600,
        surface: neutral50,
        onSurface: neutral900,
        onSurfaceVariant: neutral500,
        outline: neutral200,
        error: danger500,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        // Title/L (28–32, 700)
        headlineLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: neutral900,
        ),
        // Title/M (24, 600)
        headlineMedium: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: neutral900,
        ),
        // Title/S (20, 600)
        headlineSmall: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: neutral900,
        ),
        // Body/M (16, 400–500)
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: neutral900,
        ),
        // Body/S (14, 400–500)
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: neutral500,
        ),
        // Label (12–14, 500)
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: neutral500,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        surfaceTintColor: Colors.transparent,
        color: Colors.white,
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: neutral900,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: neutral900,
        ),
      ),
      listTileTheme: ListTileThemeData(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: space12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      dividerTheme: const DividerThemeData(
        thickness: 1,
        space: 1,
        color: neutral200,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary500,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: space24,
            vertical: space12,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary500,
          side: const BorderSide(color: primary500),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: space24,
            vertical: space12,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: neutral50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: neutral200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: neutral200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary500, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: danger500),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: space16,
          vertical: space12,
        ),
      ),
    );
  }
}

// Componentes reutilizables del Design System

class KpiCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? delta;
  final bool isPositive;
  final Color? iconColor;

  const KpiCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.delta,
    this.isPositive = true,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppTheme.primary500;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.space12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                if (delta != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space8,
                      vertical: AppTheme.space4,
                    ),
                    decoration: BoxDecoration(
                      color: isPositive
                          ? AppTheme.success500
                          : AppTheme.warning500,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      delta!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.space16),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: AppTheme.neutral900,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppTheme.space4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.neutral500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatusTag extends StatelessWidget {
  final String text;
  final StatusType type;

  const StatusTag({
    super.key,
    required this.text,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor = Colors.white;

    switch (type) {
      case StatusType.success:
        backgroundColor = AppTheme.success500;
        break;
      case StatusType.warning:
        backgroundColor = AppTheme.warning500;
        break;
      case StatusType.danger:
        backgroundColor = AppTheme.danger500;
        break;
      case StatusType.neutral:
        backgroundColor = AppTheme.neutral500;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space8,
        vertical: AppTheme.space4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

enum StatusType { success, warning, danger, neutral }

class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final String? title;
  final List<Widget>? actions;

  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTheme.space24),
    this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null || actions != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.space16),
                child: Row(
                  children: [
                    if (title != null)
                      Expanded(
                        child: Text(
                          title!,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                    if (actions != null) ...actions!,
                  ],
                ),
              ),
            child,
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppTheme.neutral500,
            ),
            const SizedBox(height: AppTheme.space16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (message != null) ...[
              const SizedBox(height: AppTheme.space8),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppTheme.space24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

// =====================================================
// CLASES DE ESTILOS PARA COMPATIBILIDAD
// =====================================================

class AppColors {
  // Colores primarios
  static const primary500 = Color(0xFF5E81F4);
  static const primary600 = Color(0xFF4B6BE0);
  static const primary700 = Color(0xFF3B5BD6);
  static const primary200 = Color(0xFFB8C8FF);
  static const primary100 = Color(0xFFD6E2FF);
  static const primary50 = Color(0xFFF0F4FF);

  // Colores neutros
  static const neutral900 = Color(0xFF0E1116);
  static const neutral700 = Color(0xFF2C333A);
  static const neutral600 = Color(0xFF475467);
  static const neutral500 = Color(0xFF667085);
  static const neutral400 = Color(0xFF98A2B3);
  static const neutral300 = Color(0xFFD1D5DB);
  static const neutral200 = Color(0xFFE5E7EB);
  static const neutral100 = Color(0xFFF1F3F4);
  static const neutral50 = Color(0xFFF8FAFC);

  // Colores de estado
  static const success500 = Color(0xFF22C55E);
  static const success50 = Color(0xFFF0FDF4);
  static const success200 = Color(0xFFBBF7D0);
  static const success700 = Color(0xFF15803D);

  static const warning500 = Color(0xFFF59E0B);
  static const warning50 = Color(0xFFFEFBF3);
  static const warning200 = Color(0xFFFDE68A);
  static const warning700 = Color(0xFFB45309);

  static const danger500 = Color(0xFFEF4444);
  static const danger50 = Color(0xFFFEF2F2);
  static const danger200 = Color(0xFFFECACA);
  static const danger700 = Color(0xFFB91C1C);

  // Colores rojos (para errores)
  static const red50 = Color(0xFFFEF2F2);
  static const red200 = Color(0xFFFECACA);
  static const red500 = Color(0xFFEF4444);
  static const red700 = Color(0xFFB91C1C);
}

class AppText {
  // Títulos
  static const heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.neutral900,
  );

  static const heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.neutral900,
  );

  static const heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.neutral900,
  );

  // Texto del cuerpo
  static const bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.neutral900,
  );

  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.neutral900,
  );

  static const bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.neutral900,
  );

  // Texto de etiquetas
  static const label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.neutral900,
  );

  // Estilos heredados (para compatibilidad)
  static const titleL = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    color: AppColors.neutral900,
  );

  static const titleM = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.neutral900,
  );

  static const titleS = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.neutral900,
  );

  static const bodyM = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.neutral900,
  );

  static const bodyS = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.neutral900,
  );
}
