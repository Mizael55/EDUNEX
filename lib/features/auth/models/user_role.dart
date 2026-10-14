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

  /// Color institucional asociado al rol
  Color get color {
    switch (this) {
      case UserRole.superadmin:
      case UserRole.adminColegio:
        return AppColors.navyPrimary;
      case UserRole.cajaFinanzas:
        return AppColors.accentOrange;
      case UserRole.admisiones:
      case UserRole.coordinadorAcademico:
      case UserRole.docente:
        return AppColors.electricBlue;
      case UserRole.responsableCuido:
      case UserRole.responsableTransporte:
      case UserRole.tiendaInventario:
        return AppColors.cyanLight;
      case UserRole.tutorFamiliar:
        return AppColors.accentOrange;
      case UserRole.estudiante:
        return AppColors.accentGreen;
    }
  }

  /// Determina si el rol pertenece al equipo administrativo del colegio
  bool get isAdminOrStaff {
    return this != UserRole.tutorFamiliar && this != UserRole.estudiante;
  }
}
