import 'package:flutter/material.dart';
import '../models/store_item.dart';

/// Repositorio en memoria y sincronizado para la Tienda Escolar EDUNEX
class StoreRepository {
  final bool useDemoFallback;
  final List<StoreProduct> _products;
  final List<StoreOrder> _orders;

  StoreRepository({this.useDemoFallback = false})
      : _products = useDemoFallback ? List<StoreProduct>.from(_defaultProducts) : [],
        _orders = useDemoFallback ? List<StoreOrder>.from(_defaultOrders) : [];

  void clearAllData() {
    _products.clear();
    _orders.clear();
  }

  static final List<StoreProduct> _defaultProducts = [
    const StoreProduct(
      id: 'prod-001',
      colegioId: 'school-001',
      name: 'Polo Oficial Institucional EDUNEX',
      category: 'Uniformes',
      price: 850.0,
      description: 'Piqué de algodón peinado con logo institucional bordado de alta durabilidad.',
      sizes: ['Talla 6', 'Talla 8', 'Talla 10', 'Talla 12', 'Talla 14', 'Talla S', 'Talla M', 'Talla L'],
      stock: 45,
      icon: Icons.checkroom_rounded,
    ),
    const StoreProduct(
      id: 'prod-002',
      colegioId: 'school-001',
      name: 'Pantalón Escolar Caqui Reforzado',
      category: 'Uniformes',
      price: 1150.0,
      description: 'Tela gabardina reforzada resistente a lavados continuos, corte reglamentario.',
      sizes: ['Talla 6', 'Talla 8', 'Talla 10', 'Talla 12', 'Talla 14', 'Talla 16'],
      stock: 32,
      icon: Icons.dry_cleaning_rounded,
    ),
    const StoreProduct(
      id: 'prod-003',
      colegioId: 'school-001',
      name: 'Polo Deportivo Educación Física',
      category: 'Uniformes',
      price: 750.0,
      description: 'Microfibra transpirable con tecnología dry-fit y franjas deportivas institucionales.',
      sizes: ['Talla 6', 'Talla 8', 'Talla 10', 'Talla 12', 'Talla S', 'Talla M'],
      stock: 58,
      icon: Icons.sports_soccer_rounded,
    ),
    const StoreProduct(
      id: 'prod-004',
      colegioId: 'school-001',
      name: 'Chaqueta Térmica Azul Marino EDUNEX',
      category: 'Uniformes',
      price: 1600.0,
      description: 'Chaqueta abrigada con forro polar interior, cremallera metálica y escudo bordado.',
      sizes: ['Talla 8', 'Talla 10', 'Talla 12', 'Talla 14', 'Talla S', 'Talla M'],
      stock: 14,
      icon: Icons.accessibility_new_rounded,
    ),
    const StoreProduct(
      id: 'prod-005',
      colegioId: 'school-001',
      name: 'Paquete de Libros de Texto Primaria',
      category: 'Libros & Textos',
      price: 4800.0,
      description: 'Lote completo autorizado MINERD: Matemáticas, Lengua Española, Ciencias y Sociales.',
      sizes: ['1er Grado', '2do Grado', '3er Grado', '4to Grado', '5to Grado', '6to Grado'],
      stock: 28,
      icon: Icons.menu_book_rounded,
    ),
    const StoreProduct(
      id: 'prod-006',
      colegioId: 'school-001',
      name: 'Libro de Inglés Cambridge Primary Stage 3',
      category: 'Libros & Textos',
      price: 1950.0,
      description: 'Learner’s Book & Activity Workbook para el currículo bilingüe internacional.',
      sizes: ['Edición 2026'],
      stock: 22,
      icon: Icons.translate_rounded,
    ),
    const StoreProduct(
      id: 'prod-007',
      colegioId: 'school-001',
      name: 'Mochila Ergonómica Escolar EDUNEX',
      category: 'Útiles Escolares',
      price: 1450.0,
      description: 'Compartimento acolchado para dispositivo, tela impermeable y correas anatómicas.',
      sizes: ['Azul Marino', 'Gris Grafito'],
      stock: 19,
      icon: Icons.backpack_rounded,
    ),
    const StoreProduct(
      id: 'prod-008',
      colegioId: 'school-001',
      name: 'Kit Completo de Útiles & Cartuchera',
      category: 'Útiles Escolares',
      price: 950.0,
      description: 'Set con lápices HB, sacapuntas con depósito, tijera escolar y colores triangulares.',
      sizes: ['Pack Estándar'],
      stock: 65,
      icon: Icons.draw_rounded,
    ),
    const StoreProduct(
      id: 'prod-009',
      colegioId: 'school-001',
      name: 'Cuadernos Cosidos Cuadriculados (Pack x6)',
      category: 'Útiles Escolares',
      price: 550.0,
      description: 'Pack de 6 cuadernos cosidos de 100 páginas con portada plástica lavable.',
      sizes: ['Pack x6'],
      stock: 8, // Bajo stock para probar alerta visual
      icon: Icons.auto_stories_rounded,
    ),
  ];

  static final List<StoreOrder> _defaultOrders = [
    StoreOrder(
      id: 'ord-001',
      colegioId: 'a0000000-0000-0000-0000-000000000001',
      familiaId: 'e0000000-0000-0000-0000-000000000001',
      familiaNombre: 'Familia Pérez Gómez',
      estudianteNombre: 'Mateo Pérez',
      fecha: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
      items: const [
        StoreOrderItem(
          productId: 'prod-001',
          productName: 'Polo Oficial Institucional EDUNEX',
          size: 'Talla 8',
          quantity: 2,
          unitPrice: 850.0,
        ),
        StoreOrderItem(
          productId: 'prod-007',
          productName: 'Mochila Ergonómica Escolar EDUNEX',
          size: 'Azul Marino',
          quantity: 1,
          unitPrice: 1450.0,
        ),
      ],
      total: 3150.0,
      metodoPago: 'Tarjeta de Crédito / CardNET',
      ncf: 'B0200000018',
      status: StoreOrderStatus.listo,
      notas: 'Empacado en mostrador principal para retiro matutino.',
    ),
    StoreOrder(
      id: 'ord-002',
      colegioId: 'a0000000-0000-0000-0000-000000000001',
      familiaId: 'e0000000-0000-0000-0000-000000000002',
      familiaNombre: 'Familia Ramírez Rodríguez',
      estudianteNombre: 'Camila Ramírez',
      fecha: DateTime.now().subtract(const Duration(hours: 5)),
      items: const [
        StoreOrderItem(
          productId: 'prod-005',
          productName: 'Paquete de Libros de Texto Primaria',
          size: '3er Grado',
          quantity: 1,
          unitPrice: 4800.0,
        ),
      ],
      total: 4800.0,
      metodoPago: 'Caja Escolar / Efectivo',
      ncf: 'B0200000019',
      status: StoreOrderStatus.pendiente,
      notas: 'En preparación en biblioteca central.',
    ),
  ];

  /// Obtener todos los productos del catálogo
  Future<List<StoreProduct>> getProducts({String? colegioId}) async {
    await Future.delayed(const Duration(milliseconds: 40));
    if (colegioId == null) return List.unmodifiable(_products);
    return List.unmodifiable(_products.where((p) =>
        p.colegioId == colegioId ||
        ((colegioId == 'a0000000-0000-0000-0000-000000000001' || colegioId == 'col-1') && p.colegioId == 'school-001')));
  }

  /// Añadir un nuevo producto al catálogo
  Future<void> addProduct(StoreProduct product) async {
    _products.add(product);
  }

  /// Actualizar los datos de un producto
  Future<void> updateProduct(StoreProduct product) async {
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index] = product;
    }
  }

  /// Ajustar stock de un producto (+ o - unidades)
  Future<void> adjustStock({required String productId, required int delta}) async {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final current = _products[index];
      final newStock = (current.stock + delta).clamp(0, 9999);
      _products[index] = current.copyWith(stock: newStock);
    }
  }

  /// Obtener lista de pedidos
  Future<List<StoreOrder>> getOrders({String? colegioId, String? familiaId}) async {
    var list = _orders;
    if (colegioId != null) {
      list = list.where((o) =>
          o.colegioId == colegioId ||
          ((colegioId == 'school-001' || colegioId == 'col-1') && o.colegioId == 'a0000000-0000-0000-0000-000000000001')).toList();
    }
    if (familiaId != null) {
      list = list.where((o) => o.familiaId == familiaId).toList();
    }
    // Orden descendente por fecha
    return List.unmodifiable(list..sort((a, b) => b.fecha.compareTo(a.fecha)));
  }

  /// Crear y registrar un pedido de la familia
  Future<StoreOrder> createOrder({
    required String colegioId,
    required String familiaId,
    required String familiaNombre,
    required String estudianteNombre,
    required List<StoreOrderItem> items,
    required String metodoPago,
    String? ncf,
  }) async {
    double total = 0.0;
    for (final item in items) {
      total += item.subtotal;
      // Descontar stock del producto
      final productIdx = _products.indexWhere((p) => p.id == item.productId);
      if (productIdx != -1) {
        final p = _products[productIdx];
        final newStock = (p.stock - item.quantity).clamp(0, 9999);
        _products[productIdx] = p.copyWith(stock: newStock);
      }
    }

    final newOrder = StoreOrder(
      id: 'ord-${DateTime.now().millisecondsSinceEpoch}',
      colegioId: colegioId,
      familiaId: familiaId,
      familiaNombre: familiaNombre,
      estudianteNombre: estudianteNombre,
      fecha: DateTime.now(),
      items: items,
      total: total,
      metodoPago: metodoPago,
      ncf: ncf,
      status: StoreOrderStatus.pendiente,
      notas: 'Pedido registrado en línea por la familia.',
    );

    _orders.insert(0, newOrder);
    return newOrder;
  }

  /// Actualizar el estado de entrega del pedido
  Future<void> updateOrderStatus({
    required String orderId,
    required StoreOrderStatus newStatus,
    String? notas,
  }) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final current = _orders[index];
      _orders[index] = current.copyWith(
        status: newStatus,
        notas: notas ?? current.notas,
        fechaEntrega: newStatus == StoreOrderStatus.entregado ? DateTime.now() : current.fechaEntrega,
      );
    }
  }
}
