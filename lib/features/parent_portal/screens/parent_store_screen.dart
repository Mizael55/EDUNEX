import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../auth/models/user_profile.dart';
import '../../families/models/family.dart';
import '../../families/repositories/family_repository.dart';
import '../widgets/receipt_details_dialog.dart';

/// Pantalla de la Tienda Escolar EDUNEX para Compra de Uniformes, Libros y Útiles Escolares
class ParentStoreScreen extends StatefulWidget {
  final UserProfile userProfile;
  final FamilyRepository familyRepository;

  const ParentStoreScreen({
    super.key,
    required this.userProfile,
    required this.familyRepository,
  });

  @override
  State<ParentStoreScreen> createState() => _ParentStoreScreenState();
}

class _ParentStoreScreenState extends State<ParentStoreScreen> {
  Family? _family;
  bool _isLoading = true;
  String _selectedCategory = 'Todos';
  final Map<String, _CartItem> _cart = {};

  final List<_ProductItem> _products = [
    const _ProductItem(
      id: 'prod-001',
      title: 'Polo Oficial Institucional EDUNEX',
      category: 'Uniformes',
      price: 850.0,
      description: 'Piqué de algodón con logo bordado institucional de alta durabilidad.',
      sizes: ['Talla 6', 'Talla 8', 'Talla 10', 'Talla 12', 'Talla 14', 'Talla S', 'Talla M'],
      icon: Icons.checkroom_rounded,
    ),
    const _ProductItem(
      id: 'prod-002',
      title: 'Pantalón Escolar Caqui Reforzado',
      category: 'Uniformes',
      price: 1150.0,
      description: 'Tela resistente a lavados diarios, corte formal reglamentario.',
      sizes: ['Talla 6', 'Talla 8', 'Talla 10', 'Talla 12', 'Talla 14', 'Talla 16'],
      icon: Icons.dry_cleaning_rounded,
    ),
    const _ProductItem(
      id: 'prod-003',
      title: 'Polo Deportivo Educación Física',
      category: 'Uniformes',
      price: 750.0,
      description: 'Tejido transpirable para deportes con franjas institucionales.',
      sizes: ['Talla 6', 'Talla 8', 'Talla 10', 'Talla 12', 'Talla S', 'Talla M'],
      icon: Icons.sports_soccer_rounded,
    ),
    const _ProductItem(
      id: 'prod-004',
      title: 'Chaqueta / Abrigo Institucional',
      category: 'Uniformes',
      price: 1600.0,
      description: 'Chaqueta térmica azul marino con cremallera y escudo bordado.',
      sizes: ['Talla 8', 'Talla 10', 'Talla 12', 'Talla 14', 'Talla S'],
      icon: Icons.accessibility_new_rounded,
    ),
    const _ProductItem(
      id: 'prod-005',
      title: 'Paquete de Libros de Texto Primaria',
      category: 'Libros & Textos',
      price: 4800.0,
      description: 'Incluye Matemáticas, Ciencias, Lengua Española y Ciencias Sociales.',
      sizes: ['1er Grado', '2do Grado', '3er Grado', '4to Grado', '5to Grado', '6to Grado'],
      icon: Icons.menu_book_rounded,
    ),
    const _ProductItem(
      id: 'prod-006',
      title: 'Libro de Inglés Cambridge Primary Stage 3',
      category: 'Libros & Textos',
      price: 1950.0,
      description: 'Learner’s Book & Workbook para programa de bilingüismo.',
      sizes: ['Edición 2026'],
      icon: Icons.translate_rounded,
    ),
    const _ProductItem(
      id: 'prod-007',
      title: 'Mochila Ergonómica Escolar EDUNEX',
      category: 'Útiles',
      price: 1450.0,
      description: 'Resistente al agua, compartimento para tablet y soporte lumbar.',
      sizes: ['Azul Marino'],
      icon: Icons.backpack_rounded,
    ),
    const _ProductItem(
      id: 'prod-008',
      title: 'Kit Completo de Útiles y Cartuchera',
      category: 'Útiles',
      price: 950.0,
      description: 'Lápices, sacapuntas, colores triangulares, reglas y tijeras punta roma.',
      sizes: ['Set Estándar'],
      icon: Icons.draw_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadFamily();
  }

  Future<void> _loadFamily() async {
    setState(() => _isLoading = true);
    try {
      final family = await widget.familyRepository.getFamilyForCurrentUser(
        email: widget.userProfile.email,
        colegioId: widget.userProfile.colegioId,
      );
      if (mounted) {
        setState(() {
          _family = family;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _cartTotal {
    double total = 0.0;
    for (final item in _cart.values) {
      total += item.product.price * item.quantity;
    }
    return total;
  }

  int get _cartItemCount {
    int count = 0;
    for (final item in _cart.values) {
      count += item.quantity;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Center(child: CircularProgressIndicator(color: AppColors.navyPrimary)),
      );
    }

    final family = _family;
    if (family == null) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Center(child: Text('No se encontró expediente familiar.')),
      );
    }

    final filteredProducts = _selectedCategory == 'Todos'
        ? _products
        : _products.where((p) => p.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera Principal con Carrito
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tienda Escolar EDUNEX',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navyPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Uniformes reglamentarios, libros y útiles para tus hijos • ${family.nombreFamilia}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showCartModal(context, family),
                  icon: Badge(
                    label: Text('$_cartItemCount'),
                    isLabelVisible: _cartItemCount > 0,
                    backgroundColor: AppColors.amberAccent,
                    textColor: AppColors.navyPrimary,
                    child: const Icon(Icons.shopping_cart_rounded, size: 20),
                  ),
                  label: Text('Carrito (RD\$ ${_cartTotal.toStringAsFixed(2)})'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyPrimary,
                    foregroundColor: AppColors.surfaceWhite,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Selector de Categorías
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip('Todos'),
                  const SizedBox(width: 8),
                  _buildCategoryChip('Uniformes'),
                  const SizedBox(width: 8),
                  _buildCategoryChip('Libros & Textos'),
                  const SizedBox(width: 8),
                  _buildCategoryChip('Útiles'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Catálogo de Productos en Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 950;
                final isMedium = constraints.maxWidth >= 650;
                final crossAxisCount = isWide ? 3 : (isMedium ? 2 : 1);

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: isWide ? 0.76 : (isMedium ? 0.78 : 0.90),
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return _buildProductCard(product);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label) {
    final isSelected = _selectedCategory == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedCategory = label),
      selectedColor: AppColors.navyPrimary,
      backgroundColor: AppColors.surfaceWhite,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.surfaceWhite : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? AppColors.navyPrimary : const Color(0xFFCBD5E1),
        ),
      ),
    );
  }

  Widget _buildProductCard(_ProductItem product) {
    String selectedSize = product.sizes.first;

    return StatefulBuilder(
      builder: (context, setCardState) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.navyPrimary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(product.icon, size: 54, color: AppColors.navyPrimary),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.electricBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                product.category,
                style: const TextStyle(
                  color: AppColors.electricBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              product.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              product.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            if (product.sizes.length > 1) ...[
              DropdownButtonFormField<String>(
                value: selectedSize,
                isExpanded: true,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: product.sizes
                    .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12))))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setCardState(() => selectedSize = val);
                },
              ),
              const SizedBox(height: 8),
            ],
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Text(
                  'RD\$ ${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: AppColors.navyPrimary,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    final key = '${product.id}_$selectedSize';
                    setState(() {
                      if (_cart.containsKey(key)) {
                        _cart[key]!.quantity++;
                      } else {
                        _cart[key] = _CartItem(
                          product: product,
                          size: selectedSize,
                          quantity: 1,
                        );
                      }
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Agregado: ${product.title} ($selectedSize) al carrito'),
                        duration: const Duration(seconds: 1),
                        backgroundColor: AppColors.navyPrimary,
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 15),
                  label: const Text('Agregar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyPrimary,
                    foregroundColor: AppColors.surfaceWhite,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCartModal(BuildContext context, Family family) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shopping_cart_rounded, color: AppColors.navyPrimary),
                      const SizedBox(width: 10),
                      Text(
                        'Carrito de Compras ($_cartItemCount artículos)',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const Divider(height: 20),
              if (_cart.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'Tu carrito está vacío.\nAgrega uniformes o libros escolares para proceder.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              else ...[
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _cart.values.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _cart.values.elementAt(index);
                      final key = '${item.product.id}_${item.size}';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.navyPrimary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(item.product.icon, color: AppColors.navyPrimary, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    '${item.size} • RD\$ ${item.product.price.toStringAsFixed(2)} c/u',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                                  onPressed: () {
                                    setModalState(() {
                                      if (item.quantity > 1) {
                                        item.quantity--;
                                      } else {
                                        _cart.remove(key);
                                      }
                                    });
                                    setState(() {});
                                  },
                                ),
                                Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                                  onPressed: () {
                                    setModalState(() {
                                      item.quantity++;
                                    });
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                            Text(
                              'RD\$ ${(item.product.price * item.quantity).toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total a Pagar:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navyPrimary),
                      ),
                      Text(
                        'RD\$ ${_cartTotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.navyPrimary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _processCheckout(ctx, family),
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text('Completar Pedido & Pagar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navyPrimary,
                      foregroundColor: AppColors.surfaceWhite,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processCheckout(BuildContext modalContext, Family family) async {
    final total = _cartTotal;
    final itemsSummary = _cart.values.map((i) => '${i.quantity}x ${i.product.title} (${i.size})').join(', ');

    Navigator.of(modalContext).pop();

    final receipt = await widget.familyRepository.recordPayment(
      familiaId: family.id,
      monto: total,
      concepto: 'Compra Tienda Escolar: $itemsSummary',
      metodo: 'Tarjeta de Crédito / CardNET',
    );

    setState(() {
      _cart.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Pedido completado con éxito! Comprobante emitido con NCF ${receipt.ncf}'),
          backgroundColor: AppColors.accentGreen,
        ),
      );
      ReceiptDetailsDialog.show(context, receipt);
    }
  }
}

class _ProductItem {
  final String id;
  final String title;
  final String category;
  final double price;
  final String description;
  final List<String> sizes;
  final IconData icon;

  const _ProductItem({
    required this.id,
    required this.title,
    required this.category,
    required this.price,
    required this.description,
    required this.sizes,
    required this.icon,
  });
}

class _CartItem {
  final _ProductItem product;
  final String size;
  int quantity;

  _CartItem({
    required this.product,
    required this.size,
    required this.quantity,
  });
}
