import 'package:flutter/material.dart';
import 'package:inventory_manage/models/product.dart';
import 'package:inventory_manage/repository/sale_repository.dart';
import 'package:inventory_manage/models/sale.dart';
import 'package:inventory_manage/repository/product_repository.dart';
import 'package:inventory_manage/screens/pay_screen.dart';

class SaleScreen extends StatefulWidget {
  const SaleScreen({super.key});

  @override
  State<SaleScreen> createState() => _SaleScreenState();
}

class _SaleScreenState extends State<SaleScreen> {
  final productRepo = ProductRepository();
  final saleRepo = SaleRepository();
  final TextEditingController _searchCtrl = TextEditingController();

  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];

  // Cart: productId -> {product, qty}
  final Map<int, Map<String, dynamic>> _cart = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final data = await productRepo.getAll();
    setState(() {
      _allProducts = data.where((p) => p.quantity > 0).toList();
      _filteredProducts = _allProducts;
      _isLoading = false;
    });
  }

  void _filterProducts(String q) {
    final query = q.toLowerCase();
    setState(() {
      _filteredProducts = _allProducts
          .where((p) =>
              p.name.toLowerCase().contains(query) ||
              (p.companyName?.toLowerCase().contains(query) ?? false))
          .toList();
    });
  }

  void _addToCart(Product product) {
    final id = product.id!;
    final currentQty = _cart[id]?['qty'] as int? ?? 0;
    if (currentQty >= product.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không đủ hàng trong kho (còn ${product.quantity})'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      _cart[id] = {'product': product, 'qty': currentQty + 1};
    });
  }

  void _removeFromCart(int productId) {
    setState(() {
      final cur = _cart[productId]?['qty'] as int? ?? 0;
      if (cur <= 1) {
        _cart.remove(productId);
      } else {
        _cart[productId]!['qty'] = cur - 1;
      }
    });
  }

  void _deleteFromCart(int productId) {
    setState(() => _cart.remove(productId));
  }

  int get _totalItems =>
      _cart.values.fold(0, (sum, e) => sum + (e['qty'] as int));

  double get _totalAmount => _cart.values.fold(0.0, (sum, e) {
        final p = e['product'] as Product;
        final q = e['qty'] as int;
        return sum + (p.sellPrice ?? 0.0) * q;
      });

  double get _totalProfit => _cart.values.fold(0.0, (sum, e) {
        final p = e['product'] as Product;
        final q = e['qty'] as int;
        final cost = p.costPrice ?? 0.0;
        final sell = p.sellPrice ?? 0.0;
        return sum + (sell - cost) * q;
      });

  Future<void> _checkout() async {
    if (_cart.isEmpty) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PayScreen(
          cart: _cart,
          totalAmount: _totalAmount,
          totalProfit: _totalProfit,
        ),
      ),
    );

    if (result == true) {
      setState(() => _cart.clear());
      await _loadProducts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Thanh toán thành công!'),
            ]),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatCurrency(double amount) {
    final s = amount.toStringAsFixed(0);
    final buffer = StringBuffer();
    final chars = s.split('').reversed.toList();
    for (int i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) buffer.write('.');
      buffer.write(chars[i]);
    }
    return '${buffer.toString().split('').reversed.join()}₫';
  }

  void _showCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx2, setS) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (_, scrollCtrl) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Giỏ hàng ($_totalItems)',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _cart.clear());
                      setS(() {});
                      Navigator.pop(ctx2);
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text('Xóa tất cả',
                        style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: _cart.isEmpty
                    ? const Center(
                        child: Text('Giỏ hàng trống',
                            style: TextStyle(color: Colors.grey)))
                    : ListView(
                        controller: scrollCtrl,
                        children: _cart.entries.map((entry) {
                          final p = entry.value['product'] as Product;
                          final qty = entry.value['qty'] as int;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(p.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(
                                _formatCurrency((p.sellPrice ?? 0) * qty)),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline,
                                    color: Colors.orange),
                                onPressed: () {
                                  _removeFromCart(entry.key);
                                  setS(() {});
                                },
                              ),
                              Text('$qty',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline,
                                    color: Colors.green),
                                onPressed: () {
                                  _addToCart(p);
                                  setS(() {});
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.red, size: 20),
                                onPressed: () {
                                  _deleteFromCart(entry.key);
                                  setS(() {});
                                },
                              ),
                            ]),
                          );
                        }).toList(),
                      ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Tổng cộng',
                          style: TextStyle(color: Colors.grey)),
                      Text(_formatCurrency(_totalAmount),
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE53935))),
                    ]),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      const Text('Lợi nhuận',
                          style: TextStyle(color: Colors.grey)),
                      Text(_formatCurrency(_totalProfit),
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green)),
                    ]),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.payment),
                  label: const Text('Thanh toán ngay',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.pop(ctx2);
                    _checkout();
                  },
                ),
              ),
            ]),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Bán hàng',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, size: 28),
                onPressed: _showCart,
              ),
              if (_totalItems > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child: Text(
                      '$_totalItems',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE53935)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(children: [
        // Header tổng tiền
        Container(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          color: const Color(0xFFE53935),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _filterProducts,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Tìm sản phẩm...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    prefixIcon: Icon(Icons.search,
                        color: Colors.white.withOpacity(0.8)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Summary bar
        if (_cart.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  const Icon(Icons.shopping_bag, color: Color(0xFFE53935), size: 20),
                  const SizedBox(width: 8),
                  Text('$_totalItems sản phẩm',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ]),
                Text(_formatCurrency(_totalAmount),
                    style: const TextStyle(
                        color: Color(0xFFE53935),
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ],
            ),
          ),

        const SizedBox(height: 8),

        // Products
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFE53935)))
              : _filteredProducts.isEmpty
                  ? const Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('Không tìm thấy sản phẩm',
                              style: TextStyle(color: Colors.grey)),
                        ]))
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 0.85),
                      itemCount: _filteredProducts.length,
                      itemBuilder: (_, i) {
                        final p = _filteredProducts[i];
                        final inCart = _cart[p.id]?['qty'] as int? ?? 0;
                        return _ProductCard(
                          product: p,
                          inCart: inCart,
                          formatCurrency: _formatCurrency,
                          onAdd: () => _addToCart(p),
                          onRemove: inCart > 0 ? () => _removeFromCart(p.id!) : null,
                        );
                      },
                    ),
        ),
      ]),
      floatingActionButton: _cart.isNotEmpty
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.payment),
              label: Text('Thanh toán • ${_formatCurrency(_totalAmount)}'),
              onPressed: _checkout,
            )
          : null,
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final int inCart;
  final String Function(double) formatCurrency;
  final VoidCallback onAdd;
  final VoidCallback? onRemove;

  const _ProductCard({
    required this.product,
    required this.inCart,
    required this.formatCurrency,
    required this.onAdd,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isLowStock = product.quantity <= 5;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: inCart > 0
            ? Border.all(color: const Color(0xFFE53935), width: 2)
            : null,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Container(
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3F3),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Stack(children: [
              const Center(
                  child: Icon(Icons.inventory_2_outlined,
                      size: 40, color: Color(0xFFE53935))),
              if (inCart > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: const Color(0xFFE53935),
                        borderRadius: BorderRadius.circular(12)),
                    child: Text('x$inCart',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  formatCurrency(product.sellPrice ?? 0),
                  style: const TextStyle(
                      color: Color(0xFFE53935),
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Còn: ${product.quantity}',
                      style: TextStyle(
                          color: isLowStock ? Colors.orange : Colors.grey,
                          fontSize: 11),
                    ),
                    Row(children: [
                      if (onRemove != null)
                        GestureDetector(
                          onTap: onRemove,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                shape: BoxShape.circle),
                            child: const Icon(Icons.remove,
                                size: 14, color: Colors.orange),
                          ),
                        ),
                      if (onRemove != null) const SizedBox(width: 4),
                      GestureDetector(
                        onTap: onAdd,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                              color: Color(0xFFE53935),
                              shape: BoxShape.circle),
                          child: const Icon(Icons.add,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ]),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
