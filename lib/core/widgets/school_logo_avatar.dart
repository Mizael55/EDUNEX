import 'dart:convert';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Componente visual reutilizable para mostrar el logotipo de un colegio cliente.
/// Soporta data URLs en base64, URLs remotas (HTTP/HTTPS) y assets locales,
/// con respaldo visual elegante de iniciales ante cualquier fallo.
class SchoolLogoAvatar extends StatelessWidget {
  final String? logoUrl;
  final String fallbackText;
  final double radius;
  final VoidCallback? onTap;

  const SchoolLogoAvatar({
    super.key,
    required this.logoUrl,
    required this.fallbackText,
    this.radius = 36,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    Widget content;

    final trimmed = logoUrl?.trim() ?? '';
    if (trimmed.startsWith('data:image')) {
      try {
        final commaIdx = trimmed.indexOf(',');
        final base64Str = commaIdx != -1 ? trimmed.substring(commaIdx + 1) : trimmed;
        final bytes = base64Decode(base64Str);
        content = Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallback(),
        );
      } catch (_) {
        content = _buildFallback();
      }
    } else if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      content = Image.network(
        trimmed,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallback(),
      );
    } else if (trimmed.startsWith('assets/')) {
      content = Image.asset(
        trimmed,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallback(),
      );
    } else {
      content = _buildFallback();
    }

    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.navyPrimary.withValues(alpha: 0.08),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: ClipOval(child: content),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: avatar,
      );
    }
    return avatar;
  }

  Widget _buildFallback() {
    final text = fallbackText.trim();
    final initials = text.isNotEmpty
        ? (text.length <= 4 ? text : text.substring(0, 2)).toUpperCase()
        : 'ED';
    return Container(
      alignment: Alignment.center,
      color: AppColors.navyPrimary.withValues(alpha: 0.1),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: radius * 0.65,
          fontWeight: FontWeight.bold,
          color: AppColors.navyPrimary,
        ),
      ),
    );
  }
}
