import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

/// Enumeración de roles del sistema EDUNEX según la propuesta estratégica
enum UserRole {
  superadmin,
  adminColegio,
  cajaFinanzas,
  admisiones,
  coordinadorAcademico,
  docente,
  responsableCuido,
  responsableTransporte,
  tiendaInventario,
  tutorFamiliar,
  estudiante;

  /// Conversión desde string de base de datos Supabase
  static UserRole fromString(String? roleStr) {
    switch (roleStr?.toLowerCase()) {
      case 'superadmin':
        return UserRole.superadmin;
      case 'admin_colegio':
        return UserRole.adminColegio;
      case 'caja_finanzas':
        return UserRole.cajaFinanzas;
      case 'admisiones':
        return UserRole.admisiones;
      case 'coordinador_academico':
        return UserRole.coordinadorAcademico;
      case 'docente':
        return UserRole.docente;
      case 'responsable_cuido':
        return UserRole.responsableCuido;
      case 'responsable_transporte':
        return UserRole.responsableTransporte;
      case 'tienda_inventario':
        return UserRole.tiendaInventario;
      case 'estudiante':
        return UserRole.estudiante;
      case 'tutor_familiar':
      default:
        return UserRole.tutorFamiliar;
    }
  }

  /// Conversión hacia string de base de datos Postgres / Supabase
  String toDbString() {
    switch (this) {
      case UserRole.superadmin:
        return 'superadmin';
      case UserRole.adminColegio:
        return 'admin_colegio';
      case UserRole.cajaFinanzas:
        return 'caja_finanzas';
      case UserRole.admisiones:
        return 'admisiones';
      case UserRole.coordinadorAcademico:
        return 'coordinador_academico';
      case UserRole.docente:
        return 'docente';
      case UserRole.responsableCuido:
        return 'responsable_cuido';
      case UserRole.responsableTransporte:
        return 'responsable_transporte';
      case UserRole.tiendaInventario:
        return 'tienda_inventario';
      case UserRole.tutorFamiliar:
        return 'tutor_familiar';
      case UserRole.estudiante:
        return 'estudiante';
    }
  }

  /// Nombre amigable y profesional para mostrar en la interfaz de usuario
  String get displayName {
    switch (this) {
      case UserRole.superadmin:
        return 'Super Administrador SaaS';
      case UserRole.adminColegio:
        return 'Director / Administrador';
      case UserRole.cajaFinanzas:
        return 'Caja y Finanzas';
      case UserRole.admisiones:
        return 'Admisiones y Registro';
      case UserRole.coordinadorAcademico:
        return 'Coordinación Académica';
      case UserRole.docente:
        return 'Docente';
      case UserRole.responsableCuido:
        return 'Encargado de Cuido';
      case UserRole.responsableTransporte:
        return 'Transporte Escolar';
      case UserRole.tiendaInventario:
        return 'Tienda y Uniformes';
      case UserRole.tutorFamiliar:
        return 'Tutor o Familia';
      case UserRole.estudiante:
        return 'Estudiante';
    }
  }

  /// Ícono representativo del rol
  IconData get icon {
    switch (this) {
      case UserRole.superadmin:
      case UserRole.adminColegio:
        return Icons.admin_panel_settings_rounded;
      case UserRole.cajaFinanzas:
        return Icons.point_of_sale_rounded;
      case UserRole.admisiones:
        return Icons.app_registration_rounded;
      case UserRole.coordinadorAcademico:
        return Icons.school_rounded;
      case UserRole.docente:
        return Icons.menu_book_rounded;
      case UserRole.responsableCuido:
        return Icons.child_care_rounded;
      case UserRole.responsableTransporte:
        return Icons.directions_bus_rounded;
      case UserRole.tiendaInventario:
        return Icons.storefront_rounded;
      case UserRole.tutorFamiliar:
        return Icons.family_restroom_rounded;
      case UserRole.estudiante:
        return Icons.backpack_rounded;
    }
  }

  /// Color institucional único y diferenciador asociado al rol
  Color get color {
    switch (this) {
      case UserRole.superadmin:
        return const Color(0xFF6366F1); // SaaS Violet
      case UserRole.adminColegio:
        return const Color(0xFF1E3A8A); // Deep Executive Navy
      case UserRole.cajaFinanzas:
        return const Color(0xFF0D9488); // Finance Teal / Esmeralda
      case UserRole.admisiones:
        return const Color(0xFF7C3AED); // Admissions Purple
      case UserRole.coordinadorAcademico:
        return const Color(0xFF0284C7); // Academic Sky Blue
      case UserRole.docente:
        return const Color(0xFF2563EB); // Royal Blue Docente
      case UserRole.responsableCuido:
        return const Color(0xFFDB2777); // Care Rose / Rosa
      case UserRole.responsableTransporte:
        return const Color(0xFFD97706); // Transport Amber
      case UserRole.tiendaInventario:
        return const Color(0xFF78350F); // Warm Terracotta Store
      case UserRole.tutorFamiliar:
        return const Color(0xFFEA580C); // Family Warm Sunset Orange
      case UserRole.estudiante:
        return const Color(0xFF16A34A); // Student Emerald Mint Green
    }
  }

  /// Gradiente institucional de navegación y layout específico del rol
  LinearGradient get layoutGradient {
    switch (this) {
      case UserRole.superadmin:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B0F19), Color(0xFF1E1B4B)],
        );
      case UserRole.adminColegio:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A192F), Color(0xFF1E3A8A)],
        );
      case UserRole.docente:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B2545), Color(0xFF1E40AF)],
        );
      case UserRole.tutorFamiliar:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C1307), Color(0xFF7C2D12)],
        );
      case UserRole.estudiante:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF022C22), Color(0xFF065F46)],
        );
      case UserRole.cajaFinanzas:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF042F2E), Color(0xFF115E59)],
        );
      case UserRole.admisiones:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E1065), Color(0xFF5B21B6)],
        );
      case UserRole.coordinadorAcademico:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF082F49), Color(0xFF0369A1)],
        );
      case UserRole.responsableCuido:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4C0519), Color(0xFF9F1239)],
        );
      case UserRole.responsableTransporte:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF451A03), Color(0xFF92400E)],
        );
      case UserRole.tiendaInventario:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E293B), Color(0xFF334155)],
        );
    }
  }

  /// Color de realce activo para menú y pestañas
  Color get activeItemColor {
    switch (this) {
      case UserRole.superadmin:
        return const Color(0xFF818CF8);
      case UserRole.adminColegio:
        return const Color(0xFF3B82F6);
      case UserRole.docente:
        return const Color(0xFF60A5FA);
      case UserRole.tutorFamiliar:
        return const Color(0xFFFB923C);
      case UserRole.estudiante:
        return const Color(0xFF4ADE80);
      case UserRole.cajaFinanzas:
        return const Color(0xFF2DD4BF);
      case UserRole.admisiones:
        return const Color(0xFFA78BFA);
      case UserRole.coordinadorAcademico:
        return const Color(0xFF38BDF8);
      case UserRole.responsableCuido:
        return const Color(0xFFF472B6);
      case UserRole.responsableTransporte:
        return const Color(0xFFFBBF24);
      case UserRole.tiendaInventario:
        return const Color(0xFFF59E0B);
    }
  }

  /// Etiqueta visible del rol para badges de cabecera
  String get tagLabel {
    switch (this) {
      case UserRole.superadmin:
        return 'SUPERADMINISTRADOR SAAS';
      case UserRole.adminColegio:
        return 'DIRECCIÓN & ADMINISTRACIÓN';
      case UserRole.docente:
        return 'PORTAL DOCENTE / AULA';
      case UserRole.tutorFamiliar:
        return 'PORTAL FAMILIAR / TUTOR';
      case UserRole.estudiante:
        return 'PORTAL ESTUDIANTIL';
      case UserRole.cajaFinanzas:
        return 'CAJA & FINANZAS';
      case UserRole.admisiones:
        return 'ADMISIONES & REGISTRO';
      case UserRole.coordinadorAcademico:
        return 'COORDINACIÓN ACADÉMICA';
      case UserRole.responsableCuido:
        return 'CUIDO & GUARDERÍA';
      case UserRole.responsableTransporte:
        return 'TRANSPORTE ESCOLAR';
      case UserRole.tiendaInventario:
        return 'TIENDA & UNIFORMES';
    }
  }

  /// Determina si el rol pertenece al equipo administrativo del colegio
  bool get isAdminOrStaff {
    return this != UserRole.tutorFamiliar && this != UserRole.estudiante;
  }
}
