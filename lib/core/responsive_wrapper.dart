import 'package:flutter/material.dart';

/// Widget wrapper que maneja el tamaño mínimo de ventana y evita overflows
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double minWidth;
  final double minHeight;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.minWidth = 1200.0,
    this.minHeight = 800.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Si la ventana es muy pequeña, usar scroll sin advertencia
        if (constraints.maxWidth < minWidth ||
            constraints.maxHeight < minHeight) {
          return _buildScrollableContent(constraints);
        }

        return child;
      },
    );
  }

  Widget _buildScrollableContent(BoxConstraints constraints) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: SizedBox(
          width:
              constraints.maxWidth < minWidth ? minWidth : constraints.maxWidth,
          height: constraints.maxHeight < minHeight
              ? minHeight
              : constraints.maxHeight,
          child: child,
        ),
      ),
    );
  }
}

/// Widget para páginas que necesitan un tamaño mínimo específico
class MinSizePage extends StatelessWidget {
  final Widget child;
  final double minWidth;
  final double minHeight;

  const MinSizePage({
    super.key,
    required this.child,
    this.minWidth = 1200.0,
    this.minHeight = 800.0,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveWrapper(
      minWidth: minWidth,
      minHeight: minHeight,
      child: child,
    );
  }
}
