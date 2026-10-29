import 'package:flutter/material.dart';

/// Paleta de colores oficial inspirada en la identidad visual de EDUNEX
/// basada en el logotipo: birrete, figuras humanas (azul, naranja, verde) y libro abierto.
class AppColors {
  // Azul marino profundo (Texto "EDU", libro y birrete)
  static const Color navyDark = Color(0xFF0A1E42);
  static const Color navyPrimary = Color(0xFF0E2F6C);
  static const Color navyLight = Color(0xFF163E8A);

  // Azul eléctrico / cian (Texto "NEX", figura izquierda y página izquierda)
  static const Color electricBlue = Color(0xFF0088FF);
  static const Color cyanLight = Color(0xFF38B6FF);

  // Verde esmeralda / turquesa (Acento 'X', figura derecha)
  static const Color accentGreen = Color(0xFF00B784);
  static const Color tealLight = Color(0xFF1DD39B);

  // Naranja / Ámbar cálido (Figura central del logo)
  static const Color accentOrange = Color(0xFFFFA000);
  static const Color amberLight = Color(0xFFFFB74D);

  // Fondos y neutros
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color slateDark = Color(0xFF1E293B);
  static const Color slateGray = Color(0xFF64748B);
  static const Color slateLight = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFE2E8F0);

  // Paleta EdTech Pastel & Soft Tokens
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color subtleBackground = Color(0xFFF1F5F9);
  static const Color softIndigo = Color(0xFFEEF2FF);
  static const Color softEmerald = Color(0xFFECFDF5);
  static const Color softAmber = Color(0xFFFFFBEB);
  static const Color softRose = Color(0xFFFFF1F2);
  static const Color softCyan = Color(0xFFECFEFF);

  // Aliases semánticos para textos y acentos
  static const Color textPrimary = slateDark;
  static const Color textSecondary = slateGray;
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textLight = Color(0xFFE2E8F0);
  static const Color navySecondary = navyLight;
  static const Color amberAccent = accentOrange;
  static const Color crimsonAlert = Color(0xFFDC2626);
  static const Color borderSubtle = Color(0xFFE2E8F0);
  static const Color backgroundSecondary = Color(0xFFF8FAFC);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Degradados corporativos
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [navyPrimary, electricBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF071B3B), Color(0xFF0D2F6C), Color(0xFF0075DE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [navyPrimary, electricBlue],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient accentAccentGradient = LinearGradient(
    colors: [electricBlue, accentGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
