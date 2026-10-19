import 'student.dart';
import 'tutor.dart';

/// Modelo de Cuenta Familiar Única en EDUNEX
/// Centraliza a los tutores, los estudiantes (hermanos) y el balance contable
class Family {
  final String id;
  final String colegioId;
  final String codigoFamilia;
  final String nombreFamilia;
  final double balancePendiente;
  final String? telefonoPrincipal;
  final String? emailPrincipal;
  final String? direccion;
  final bool activo;
  final List<Tutor> tutores;
  final List<Student> estudiantes;
  final String modalidadPago; // 'mensual', 'trimestral', 'semestral', 'anual', 'acuerdo_especial'
  final double descuentoAcordadoPct;
  final String? notaAcuerdoPago;
  final List<String> criteriosCentroAdicionales;

  const Family({
    required this.id,
    required this.colegioId,
    required this.codigoFamilia,
    required this.nombreFamilia,
    required this.balancePendiente,
    this.telefonoPrincipal,
    this.emailPrincipal,
    this.direccion,
    this.activo = true,
    this.tutores = const [],
    this.estudiantes = const [],
    this.modalidadPago = 'mensual',
    this.descuentoAcordadoPct = 0.0,
    this.notaAcuerdoPago,
    this.criteriosCentroAdicionales = const [],
  });

  /// Indica si la familia está al día con sus pagos
  bool get estaAlDia => balancePendiente <= 0.01;

  /// Retorna el tutor principal o el primer tutor registrado
  Tutor? get tutorPrincipal {
    if (tutores.isEmpty) return null;
    return tutores.firstWhere(
      (t) => t.esContactoPrincipal,
      orElse: () => tutores.first,
    );
  }

  /// Conteo de estudiantes (hijos) pertenecientes a la cuenta familiar
  int get cantidadHijos => estudiantes.length;

  Family copyWith({
    String? id,
    String? colegioId,
    String? codigoFamilia,
    String? nombreFamilia,
    double? balancePendiente,
    String? telefonoPrincipal,
    String? emailPrincipal,
    String? direccion,
    bool? activo,
    List<Tutor>? tutores,
    List<Student>? estudiantes,
    String? modalidadPago,
    double? descuentoAcordadoPct,
    String? notaAcuerdoPago,
    List<String>? criteriosCentroAdicionales,
  }) {
    return Family(
      id: id ?? this.id,
      colegioId: colegioId ?? this.colegioId,
      codigoFamilia: codigoFamilia ?? this.codigoFamilia,
      nombreFamilia: nombreFamilia ?? this.nombreFamilia,
      balancePendiente: balancePendiente ?? this.balancePendiente,
      telefonoPrincipal: telefonoPrincipal ?? this.telefonoPrincipal,
      emailPrincipal: emailPrincipal ?? this.emailPrincipal,
      direccion: direccion ?? this.direccion,
      activo: activo ?? this.activo,
      tutores: tutores ?? this.tutores,
      estudiantes: estudiantes ?? this.estudiantes,
      modalidadPago: modalidadPago ?? this.modalidadPago,
      descuentoAcordadoPct: descuentoAcordadoPct ?? this.descuentoAcordadoPct,
      notaAcuerdoPago: notaAcuerdoPago ?? this.notaAcuerdoPago,
      criteriosCentroAdicionales: criteriosCentroAdicionales ?? this.criteriosCentroAdicionales,
    );
  }

  factory Family.fromJson(Map<String, dynamic> json) {
    List<Tutor> parsedTutores = [];
    if (json['tutores'] is List) {
      parsedTutores = (json['tutores'] as List)
          .map((t) => Tutor.fromJson(t as Map<String, dynamic>))
          .toList();
    }

    List<Student> parsedEstudiantes = [];
    if (json['estudiantes'] is List) {
      parsedEstudiantes = (json['estudiantes'] as List)
          .map((e) => Student.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final rawBalance = json['balance_pendiente'];
    final double balance = (rawBalance is num)
        ? rawBalance.toDouble()
        : double.tryParse(rawBalance?.toString() ?? '0') ?? 0.0;

    List<String> criterios = [];
    if (json['criterios_centro_adicionales'] is List) {
      criterios = (json['criterios_centro_adicionales'] as List).map((e) => e.toString()).toList();
    }

    final rawDesc = json['descuento_acordado_pct'];
    final double descPct = (rawDesc is num)
        ? rawDesc.toDouble()
        : double.tryParse(rawDesc?.toString() ?? '0') ?? 0.0;

    return Family(
      id: json['id'] as String? ?? '',
      colegioId: json['colegio_id'] as String? ?? '',
      codigoFamilia: json['codigo_familia'] as String? ?? '',
      nombreFamilia: json['nombre_familia'] as String? ?? '',
      balancePendiente: balance,
      telefonoPrincipal: json['telefono_principal'] as String?,
      emailPrincipal: json['email_principal'] as String?,
      direccion: json['direccion'] as String?,
      activo: json['activo'] as bool? ?? true,
      tutores: parsedTutores,
      estudiantes: parsedEstudiantes,
      modalidadPago: json['modalidad_pago'] as String? ?? 'mensual',
      descuentoAcordadoPct: descPct,
      notaAcuerdoPago: json['nota_acuerdo_pago'] as String?,
      criteriosCentroAdicionales: criterios,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'colegioId': colegioId,
      'codigo_familia': codigoFamilia,
      'nombre_familia': nombreFamilia,
      'balance_pendiente': balancePendiente,
      'telefono_principal': telefonoPrincipal,
      'email_principal': emailPrincipal,
      'direccion': direccion,
      'activo': activo,
      'tutores': tutores.map((t) => t.toJson()).toList(),
      'estudiantes': estudiantes.map((e) => e.toJson()).toList(),
      'modalidad_pago': modalidadPago,
      'descuento_acordado_pct': descuentoAcordadoPct,
      'nota_acuerdo_pago': notaAcuerdoPago,
      'criterios_centro_adicionales': criteriosCentroAdicionales,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Family && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
