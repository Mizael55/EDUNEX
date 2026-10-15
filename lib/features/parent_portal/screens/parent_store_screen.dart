import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../auth/models/user_profile.dart';
import '../../families/models/family.dart';
import '../../families/repositories/family_repository.dart';
import '../../store/models/store_item.dart';
import '../../store/repositories/store_repository.dart';
import '../widgets/receipt_details_dialog.dart';

/// Pantalla de la Tienda Escolar EDUNEX para Compra de Uniformes, Libros y Útiles Escolares
class ParentStoreScreen extends StatefulWidget {
  final UserProfile userProfile;
  final FamilyRepository familyRepository;
  final StoreRepository? storeRepository;

  const ParentStoreScreen({
    super.key,
    required this.userProfile,
    required this.familyRepository,
    this.storeRepository,
  });

  @override
  State<ParentStoreScreen> createState() => _ParentStoreScreenState();
}

class _ParentStoreScreenState extends State<ParentStoreScreen> {
  late final StoreRepository _storeRepo;
  Family? _family;
  bool _isLoading = true;
  String _selectedCategory = 'Todos';
  final Map<String, _CartItem> _cart = {};
  List<StoreProduct> _products = [];
  List<StoreOrder> _familyOrders = [];

  @override
  void initState() {
    super.initState();
    _storeRepo = widget.storeRepository ?? StoreRepository();
    _loadData(showLoading: true);
  }

  Future<void> _loadData({bool showLoading = false}) async {
    if (showLoading || _family == null) {
      setState(() => _isLoading = true);
    }
    try {
      final family = await widget.familyRepository.getFamilyForCurrentUser(
        email: widget.userProfile.email,
        colegioId: widget.userProfile.colegioId,
      );
      final products = await _storeRepo.getProducts(colegioId: widget.userProfile.colegioId);
      final orders = family != null
          ? await _storeRepo.getOrders(colegioId: widget.userProfile.colegioId, familiaId: family.id)
          : <StoreOrder>[];

      if (mounted) {
        setState(() {
          _family = family;
          _products = products;
          _familyOrders = orders;
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
            // Cabecera Principal con Carrito y Mis Pedidos
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showMyOrdersModal(context, family),
                      icon: const Icon(Icons.receipt_long_rounded, size: 18),
                      label: Text('Mis Pedidos (${_familyOrders.length})'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navyPrimary,
                        side: const BorderSide(color: AppColors.navyPrimary),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
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
                  _buildCategoryChip('Útiles Escolares'),
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
                    childAspectRatio: isWide ? 0.74 : (isMedium ? 0.76 : 0.88),
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

  Widget _buildProductCard(StoreProduct product) {
    String selectedSize = product.sizes.isNotEmpty ? product.sizes.first : 'Única';

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.electricBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      product.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.electricBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                if (product.isOutOfStock)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.crimsonAlert.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Agotado', style: TextStyle(color: AppColors.crimsonAlert, fontSize: 9, fontWeight: FontWeight.bold)),
                  )
                else
                  Flexible(
                    child: Text(
                      '${product.stock} disp.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.8), fontSize: 9),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              product.name,
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
                  onPressed: product.isOutOfStock
                      ? null
                      : () {
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
                              content: Text('Agregado: ${product.name} ($selectedSize) al carrito'),
                              duration: const Duration(seconds: 1),
                              backgroundColor: AppColors.navyPrimary,
                            ),
                          );
                        },
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 15),
                  label: Text(product.isOutOfStock ? 'Agotado' : 'Agregar'),
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
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.shopping_cart_rounded, color: AppColors.navyPrimary),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'Carrito de Compras ($_cartItemCount artículos)',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
                          ),
                        ),
                      ],
                    ),
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
                                    item.product.name,
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

  void _showMyOrdersModal(BuildContext context, Family family) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
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
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_rounded, color: AppColors.navyPrimary),
                      const SizedBox(width: 10),
                      const Flexible(
                        child: Text(
                          'Mis Pedidos de Tienda',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const Divider(height: 20),
            if (_familyOrders.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'No tienes pedidos registrados recientemente.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _familyOrders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final order = _familyOrders[index];
                    Color statusColor = AppColors.accentGreen;
                    if (order.status == StoreOrderStatus.pendiente) {
                      statusColor = const Color(0xFFD97706);
                    } else if (order.status == StoreOrderStatus.listo) {
                      statusColor = AppColors.electricBlue;
                    }

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Pedido #${order.id}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyPrimary),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  order.status.label,
                                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ...order.items.map((i) => Text(
                                '• ${i.quantity}x ${i.productName} (${i.size})',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              )),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total: RD\$ ${order.total.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyPrimary),
                              ),
                              if (order.ncf != null)
                                Text('NCF: ${order.ncf}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                          if (order.notas != null) ...[
                            const SizedBox(height: 4),
                            Text('Nota: ${order.notas}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _processCheckout(BuildContext modalContext, Family family) async {
    final total = _cartTotal;
    final itemsSummary = _cart.values.map((i) => '${i.quantity}x ${i.product.name} (${i.size})').join(', ');
    final orderItems = _cart.values
        .map((i) => StoreOrderItem(
              productId: i.product.id,
              productName: i.product.name,
              size: i.size,
              quantity: i.quantity,
              unitPrice: i.product.price,
            ))
        .toList();

    Navigator.of(modalContext).pop();

    // 1. Registrar pago oficial con emisión de recibo fiscal NCF
    final receipt = await widget.familyRepository.recordPayment(
      familiaId: family.id,
      monto: total,
      concepto: 'Compra Tienda Escolar: $itemsSummary',
      metodo: 'Tarjeta de Crédito / CardNET',
    );

    // 2. Registrar el pedido en el repositorio de la tienda
    final studentName = family.estudiantes.isNotEmpty ? family.estudiantes.first.nombreCompleto : 'Alumno';
    await _storeRepo.createOrder(
      colegioId: family.colegioId,
      familiaId: family.id,
      familiaNombre: family.nombreFamilia,
      estudianteNombre: studentName,
      items: orderItems,
      metodoPago: 'Tarjeta de Crédito / CardNET',
      ncf: receipt.ncf,
    );

    setState(() {
      _cart.clear();
    });

    await _loadData(showLoading: false);

    if (mounted) {
      ReceiptDetailsDialog.show(context, receipt);
    }
  }
}

class _CartItem {
  final StoreProduct product;
  final String size;
  int quantity;

  _CartItem({
    required this.product,
    required this.size,
    required this.quantity,
  });
}
