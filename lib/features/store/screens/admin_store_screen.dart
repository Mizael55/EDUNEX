import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../models/store_item.dart';
import '../repositories/store_repository.dart';

/// Pantalla Administrativa de Gestión de Tienda Escolar, Inventario y Despacho
class AdminStoreScreen extends StatefulWidget {
  final StoreRepository storeRepository;
  final String? colegioId;

  const AdminStoreScreen({
    super.key,
    required this.storeRepository,
    this.colegioId,
  });

  @override
  State<AdminStoreScreen> createState() => _AdminStoreScreenState();
}

class _AdminStoreScreenState extends State<AdminStoreScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<StoreProduct> _products = [];
  List<StoreOrder> _orders = [];

  String _selectedCategory = 'Todos';
  String _productSearchQuery = '';
  String _orderStatusFilter = 'Todos';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData(showLoading: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool showLoading = false}) async {
    if (showLoading || _products.isEmpty) {
      setState(() => _isLoading = true);
    }
    final products = await widget.storeRepository.getProducts(colegioId: widget.colegioId);
    final orders = await widget.storeRepository.getOrders(colegioId: widget.colegioId);
    if (mounted) {
      setState(() {
        _products = products;
        _orders = orders;
        _isLoading = false;
      });
    }
  }

  int get _totalStockUnits => _products.fold<int>(0, (sum, p) => sum + p.stock);
  int get _pendingOrdersCount => _orders.where((o) => o.status != StoreOrderStatus.entregado && o.status != StoreOrderStatus.cancelado).length;
  double get _totalRevenue => _orders.fold<double>(0.0, (sum, o) => sum + o.total);

  List<StoreProduct> get _filteredProducts {
    return _products.where((p) {
      final matchesCat = _selectedCategory == 'Todos' || p.category == _selectedCategory;
      final matchesSearch = p.name.toLowerCase().contains(_productSearchQuery.toLowerCase()) ||
          p.description.toLowerCase().contains(_productSearchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();
  }

  List<StoreOrder> get _filteredOrders {
    return _orders.where((o) {
      if (_orderStatusFilter == 'Todos') return true;
      if (_orderStatusFilter == 'Pendientes') return o.status == StoreOrderStatus.pendiente;
      if (_orderStatusFilter == 'Listos para Retiro') return o.status == StoreOrderStatus.listo;
      if (_orderStatusFilter == 'Entregados') return o.status == StoreOrderStatus.entregado;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Center(child: CircularProgressIndicator(color: AppColors.navyPrimary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tienda & Uniformes Oficiales',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Control central de inventario físico, catálogo de prendas, libros y despacho a familias.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary.withValues(alpha: 0.9)),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddProductDialog(context),
                  icon: const Icon(Icons.add_box_rounded, size: 18),
                  label: const Text('Nuevo Producto'),
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

            // 4 KPIs
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 850;
                if (isWide) {
                  return Row(
                    children: [
                      Expanded(child: _buildKpiCard('Artículos Catálogo', '${_products.length}', 'Prendas y textos', Icons.inventory_2_rounded, AppColors.electricBlue)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildKpiCard('Stock Físico', '$_totalStockUnits', 'Unidades en almacén', Icons.warehouse_rounded, AppColors.accentGreen)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildKpiCard('Por Despachar', '$_pendingOrdersCount', 'Listos y en proceso', Icons.local_shipping_rounded, const Color(0xFFD97706))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildKpiCard('Ventas Tienda', 'RD\$ ${_totalRevenue.toStringAsFixed(0)}', 'Cobrado formalmente', Icons.payments_rounded, AppColors.navyPrimary)),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildKpiCard('Artículos', '${_products.length}', 'Catálogo', Icons.inventory_2_rounded, AppColors.electricBlue)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildKpiCard('Stock Físico', '$_totalStockUnits', 'Unidades', Icons.warehouse_rounded, AppColors.accentGreen)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _buildKpiCard('Por Despachar', '$_pendingOrdersCount', 'Pendientes', Icons.local_shipping_rounded, const Color(0xFFD97706))),
                          const SizedBox(width: 10),
                          Expanded(child: _buildKpiCard('Ventas', 'RD\$ ${_totalRevenue.toStringAsFixed(0)}', 'Total', Icons.payments_rounded, AppColors.navyPrimary)),
                        ],
                      ),
                    ],
                  );
                }
              },
            ),

            const SizedBox(height: 20),

            // Tabs Selector
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.navyPrimary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.navyPrimary,
                indicatorWeight: 3,
                tabs: [
                  Tab(
                    icon: const Icon(Icons.shelves),
                    text: 'Catálogo & Control de Stock (${_products.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.assignment_turned_in_rounded),
                    text: 'Pedidos & Despacho a Familias (${_orders.length})',
                  ),
                ],
                onTap: (_) => setState(() {}),
              ),
            ),

            const SizedBox(height: 16),

            // Tabs View Body
            IndexedStack(
              index: _tabController.index,
              children: [
                _buildInventoryTab(),
                _buildOrdersTab(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: INVENTARIO & CATÁLOGO
  // ==========================================
  Widget _buildInventoryTab() {
    final filtered = _filteredProducts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filtros y Búsqueda
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar por producto o descripción...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: AppColors.surfaceWhite,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                  isDense: true,
                ),
                onChanged: (val) => setState(() => _productSearchQuery = val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
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
        const SizedBox(height: 16),

        // Grid o Lista de Productos
        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Text('No se encontraron artículos con los criterios seleccionados.', style: TextStyle(color: AppColors.textSecondary)),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final product = filtered[index];
              return _buildProductListItem(product);
            },
          ),
      ],
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
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: isSelected ? AppColors.navyPrimary : const Color(0xFFCBD5E1)),
      ),
    );
  }

  Widget _buildProductListItem(StoreProduct product) {
    Color stockBadgeColor = AppColors.accentGreen;
    String stockLabel = '${product.stock} un. en stock';

    if (product.isOutOfStock) {
      stockBadgeColor = AppColors.crimsonAlert;
      stockLabel = 'Agotado (0 un.)';
    } else if (product.isLowStock) {
      stockBadgeColor = const Color(0xFFD97706);
      stockLabel = 'Bajo Stock (${product.stock} un.)';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.navyPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(product.icon, color: AppColors.navyPrimary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: stockBadgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        stockLabel,
                        style: TextStyle(color: stockBadgeColor, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${product.category} • Tallas/Variantes: ${product.sizes.join(", ")}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  product.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'RD\$ ${product.price.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.navyPrimary),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(
                    onPressed: product.stock > 0
                        ? () async {
                            await widget.storeRepository.adjustStock(productId: product.id, delta: -1);
                            await _loadData();
                          }
                        : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('-1', style: TextStyle(fontSize: 11)),
                  ),
                  const SizedBox(width: 4),
                  OutlinedButton(
                    onPressed: () async {
                      await widget.storeRepository.adjustStock(productId: product.id, delta: 5);
                      await _loadData();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('+5', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: PEDIDOS & DESPACHO
  // ==========================================
  Widget _buildOrdersTab() {
    final filtered = _filteredOrders;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selector de Estado
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildOrderStatusChip('Todos'),
              const SizedBox(width: 8),
              _buildOrderStatusChip('Pendientes'),
              const SizedBox(width: 8),
              _buildOrderStatusChip('Listos para Retiro'),
              const SizedBox(width: 8),
              _buildOrderStatusChip('Entregados'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Text('No hay pedidos registrados en este estado.', style: TextStyle(color: AppColors.textSecondary)),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final order = filtered[index];
              return _buildOrderCard(order);
            },
          ),
      ],
    );
  }

  Widget _buildOrderStatusChip(String label) {
    final isSelected = _orderStatusFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _orderStatusFilter = label),
      selectedColor: AppColors.navyPrimary,
      backgroundColor: AppColors.surfaceWhite,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.surfaceWhite : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: isSelected ? AppColors.navyPrimary : const Color(0xFFCBD5E1)),
      ),
    );
  }

  Widget _buildOrderCard(StoreOrder order) {
    Color statusColor;
    IconData statusIcon;
    switch (order.status) {
      case StoreOrderStatus.pendiente:
        statusColor = const Color(0xFFD97706);
        statusIcon = Icons.hourglass_top_rounded;
        break;
      case StoreOrderStatus.listo:
        statusColor = AppColors.electricBlue;
        statusIcon = Icons.storefront_rounded;
        break;
      case StoreOrderStatus.entregado:
        statusColor = AppColors.accentGreen;
        statusIcon = Icons.check_circle_rounded;
        break;
      case StoreOrderStatus.cancelado:
        statusColor = AppColors.crimsonAlert;
        statusIcon = Icons.cancel_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado del pedido
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pedido #${order.id}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navyPrimary),
                      ),
                      Text(
                        '${order.familiaNombre} • Alumno: ${order.estudianteNombre}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.status.label,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),

          const Divider(height: 20),

          // Desglose de Artículos
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  children: [
                    Text('• ${item.quantity}x ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.navyPrimary)),
                    Expanded(
                      child: Text(
                        '${item.productName} (${item.size})',
                        style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                      ),
                    ),
                    Text(
                      'RD\$ ${item.subtotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              )),

          const SizedBox(height: 12),

          // Pie con total, NCF y acciones
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Pagado: RD\$ ${order.total.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navyPrimary),
                  ),
                  Text(
                    'Método: ${order.metodoPago}${order.ncf != null ? " • NCF: ${order.ncf}" : ""}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
              Row(
                children: [
                  if (order.status == StoreOrderStatus.pendiente)
                    ElevatedButton.icon(
                      onPressed: () async {
                        await widget.storeRepository.updateOrderStatus(
                          orderId: order.id,
                          newStatus: StoreOrderStatus.listo,
                          notas: 'Empacado y listo para retiro en recepción escolar.',
                        );
                        await _loadData();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Pedido marcado como "Listo para Retiro". Familia notificada.'),
                              backgroundColor: AppColors.electricBlue,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check, size: 15),
                      label: const Text('Listo para Retiro'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.electricBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  if (order.status == StoreOrderStatus.listo)
                    ElevatedButton.icon(
                      onPressed: () async {
                        await widget.storeRepository.updateOrderStatus(
                          orderId: order.id,
                          newStatus: StoreOrderStatus.entregado,
                          notas: 'Entregado al tutor en ventanilla de uniformes.',
                        );
                        await _loadData();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('¡Pedido formalmente entregado al tutor/alumno!'),
                              backgroundColor: AppColors.accentGreen,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.done_all, size: 15),
                      label: const Text('Confirmar Entrega'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // DIÁLOGO: CREAR NUEVO PRODUCTO
  // ==========================================
  void _showAddProductDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '20');
    final descCtrl = TextEditingController();
    final sizesCtrl = TextEditingController(text: 'Talla 6, Talla 8, Talla 10, Talla 12, Talla S, Talla M');
    String category = 'Uniformes';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.add_shopping_cart_rounded, color: AppColors.navyPrimary),
              SizedBox(width: 10),
              Text('Nuevo Producto en Tienda', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nombre del Producto / Artículo:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Ej. Suéter Escolar Bordado',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Categoría:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: category,
                              decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                              items: const [
                                DropdownMenuItem(value: 'Uniformes', child: Text('Uniformes')),
                                DropdownMenuItem(value: 'Libros & Textos', child: Text('Libros & Textos')),
                                DropdownMenuItem(value: 'Útiles Escolares', child: Text('Útiles Escolares')),
                                DropdownMenuItem(value: 'Cafetería & Snacks', child: Text('Cafetería & Snacks')),
                              ],
                              onChanged: (val) {
                                if (val != null) setDialogState(() => category = val);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Precio (RD\$):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: priceCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: 'Ej. 1200.00',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Stock Inicial:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: stockCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: 'Ej. 25',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Tallas / Variantes (separadas por coma):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: sizesCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Talla 6, Talla 8, Talla 10...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Descripción detallada:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Material, corte, especificaciones técnicas...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                final stock = int.tryParse(stockCtrl.text.trim()) ?? 0;
                final desc = descCtrl.text.trim().isEmpty ? 'Prenda oficial reglamentaria.' : descCtrl.text.trim();
                final sizes = sizesCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

                if (name.isEmpty || price <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor ingresa un nombre y precio válido.')),
                  );
                  return;
                }

                Navigator.of(ctx).pop();

                final newProd = StoreProduct(
                  id: 'prod-${DateTime.now().millisecondsSinceEpoch}',
                  colegioId: widget.colegioId ?? 'school-001',
                  name: name,
                  category: category,
                  price: price,
                  description: desc,
                  sizes: sizes.isEmpty ? ['Única'] : sizes,
                  stock: stock,
                  icon: category == 'Uniformes'
                      ? Icons.checkroom_rounded
                      : (category == 'Libros & Textos' ? Icons.menu_book_rounded : Icons.backpack_rounded),
                );

                await widget.storeRepository.addProduct(newProd);
                await _loadData();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Producto "$name" agregado al catálogo con éxito.'),
                      backgroundColor: AppColors.accentGreen,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyPrimary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Guardar Producto'),
            ),
          ],
        ),
      ),
    );
  }
}
