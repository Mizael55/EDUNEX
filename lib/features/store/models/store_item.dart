import 'package:flutter/material.dart';

/// Categorías oficiales de la Tienda Escolar
enum StoreCategory {
  uniformes('Uniformes'),
  libros('Libros & Textos'),
  utiles('Útiles Escolares'),
  cafeteria('Cafetería & Snacks');

  final String label;
  const StoreCategory(this.label);
}

/// Estado de un pedido de tienda escolar
enum StoreOrderStatus {
  pendiente('Pendiente de Preparación'),
  listo('Listo para Retiro'),
  entregado('Entregado al Alumno'),
  cancelado('Cancelado');

  final String label;
  const StoreOrderStatus(this.label);
}

/// Modelo de Producto de la Tienda Escolar
class StoreProduct {
  final String id;
  final String colegioId;
  final String name;
  final String category;
  final double price;
  final String description;
  final List<String> sizes;
  final int stock;
  final IconData icon;
  final bool isActive;

  const StoreProduct({
    required this.id,
    required this.colegioId,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    required this.sizes,
    required this.stock,
    required this.icon,
    this.isActive = true,
  });

  bool get isOutOfStock => stock <= 0;
  bool get isLowStock => stock > 0 && stock <= 10;

  StoreProduct copyWith({
    String? id,
    String? colegioId,
    String? name,
    String? category,
    double? price,
    String? description,
    List<String>? sizes,
    int? stock,
    IconData? icon,
    bool? isActive,
  }) {
    return StoreProduct(
      id: id ?? this.id,
      colegioId: colegioId ?? this.colegioId,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      description: description ?? this.description,
      sizes: sizes ?? this.sizes,
      stock: stock ?? this.stock,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Artículo dentro de un pedido
class StoreOrderItem {
  final String productId;
  final String productName;
  final String size;
  final int quantity;
  final double unitPrice;

  const StoreOrderItem({
    required this.productId,
    required this.productName,
    required this.size,
    required this.quantity,
    required this.unitPrice,
  });

  double get subtotal => unitPrice * quantity;
}

/// Pedido formal registrado por una familia en la Tienda Escolar
class StoreOrder {
  final String id;
  final String colegioId;
  final String familiaId;
  final String familiaNombre;
  final String estudianteNombre;
  final DateTime fecha;
  final List<StoreOrderItem> items;
  final double total;
  final String metodoPago;
  final String? ncf;
  final StoreOrderStatus status;
  final DateTime? fechaEntrega;
  final String? notas;

  const StoreOrder({
    required this.id,
    required this.colegioId,
    required this.familiaId,
    required this.familiaNombre,
    required this.estudianteNombre,
    required this.fecha,
    required this.items,
    required this.total,
    required this.metodoPago,
    this.ncf,
    required this.status,
    this.fechaEntrega,
    this.notas,
  });

  StoreOrder copyWith({
    String? id,
    String? colegioId,
    String? familiaId,
    String? familiaNombre,
    String? estudianteNombre,
    DateTime? fecha,
    List<StoreOrderItem>? items,
    double? total,
    String? metodoPago,
    String? ncf,
    StoreOrderStatus? status,
    DateTime? fechaEntrega,
    String? notas,
  }) {
    return StoreOrder(
      id: id ?? this.id,
      colegioId: colegioId ?? this.colegioId,
      familiaId: familiaId ?? this.familiaId,
      familiaNombre: familiaNombre ?? this.familiaNombre,
      estudianteNombre: estudianteNombre ?? this.estudianteNombre,
      fecha: fecha ?? this.fecha,
      items: items ?? this.items,
      total: total ?? this.total,
      metodoPago: metodoPago ?? this.metodoPago,
      ncf: ncf ?? this.ncf,
      status: status ?? this.status,
      fechaEntrega: fechaEntrega ?? this.fechaEntrega,
      notas: notas ?? this.notas,
    );
  }
}
