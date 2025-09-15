import 'package:flutter/material.dart';

enum StyleKit { material, expressive }

class AppTokens {
  // Paleta base (ajusta a tu marca)
  static const seed = Color(0xFF2E7D32); // verde clínico
  static const surface = Color(0xFFF7F9F7);

  // Espacios
  static const gapXs = 6.0;
  static const gapSm = 12.0;
  static const gapMd = 16.0;
  static const gapLg = 20.0;

  // Radios
  static const rSm = 12.0;
  static const rMd = 16.0;
  static const rLg = 20.0;

  // Sombras
  static const shadowSm = [
    BoxShadow(blurRadius: 8, color: Colors.black12, offset: Offset(0, 2)),
  ];

  // Tipografías base (Inter o la que uses)
  static const fontFamily = 'Inter';
}
