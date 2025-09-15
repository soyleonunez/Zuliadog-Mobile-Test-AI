import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData light() {
    final seed = const Color(0xFF5E81F4); // parecido a la referencia
    final base = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: seed,
      brightness: Brightness.light,
    );

    return base.copyWith(
      textTheme:
          GoogleFonts.interTextTheme(base.textTheme), // tipografía moderna
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        surfaceTintColor: Colors.transparent,
      ),
      appBarTheme: base.appBarTheme.copyWith(
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: base.colorScheme.onSurface,
        ),
      ),
      listTileTheme: const ListTileThemeData(
        dense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12),
      ),
      dividerTheme: const DividerThemeData(thickness: 1, space: 1),
    );
  }
}

/// ======================================================
/// BLOQUES BASE REUTILIZABLES (premium)
/// ======================================================

/// Card premium con hover/sombra sutil
class SectionCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool enableHover;

  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.enableHover = true,
  });

  @override
  State<SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<SectionCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) {
        if (widget.enableHover) setState(() => _hover = true);
      },
      onExit: (_) {
        if (widget.enableHover) setState(() => _hover = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        transform: _hover
            ? (Matrix4.identity()..translate(0.0, -2.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hover
                ? scheme.primary.withValues(alpha: .12)
                : Colors.black.withValues(alpha: .08),
          ),
          boxShadow: _hover
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .06),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
          color: Theme.of(context).cardColor,
        ),
        child: Padding(
          padding: widget.padding,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Header estándar con título, descripción y acciones
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.padding = const EdgeInsets.only(bottom: 12),
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final sub = subtitle;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: t.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
              if (sub != null) ...[
                const SizedBox(height: 4),
                Text(sub,
                    style: t.bodyMedium?.copyWith(color: Colors.grey[700])),
              ],
            ]),
          ),
          if (actions != null && actions!.isNotEmpty)
            Wrap(spacing: 8, runSpacing: 8, children: actions!),
        ],
      ),
    );
  }
}

/// Chip/Badge estadístico
class StatChip extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color? color;

  const StatChip({super.key, this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = color ?? scheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withValues(alpha: .25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: c),
          const SizedBox(width: 6),
        ],
        Text(label, style: TextStyle(color: c, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

/// Estado vacío elegante
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
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(title, style: t.titleMedium),
          if (message != null) ...[
            const SizedBox(height: 4),
            Text(message!,
                style: t.bodyMedium?.copyWith(color: Colors.grey[600])),
          ],
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    );
  }
}
