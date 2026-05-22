import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_manage/models/sale.dart';
import 'package:inventory_manage/repository/sale_repository.dart';
import 'package:inventory_manage/screens/pay_screen.dart';
import 'package:inventory_manage/models/product.dart';
import 'package:inventory_manage/screens/product_screen.dart';
import 'package:inventory_manage/repository/product_repository.dart';

class SaleScreen extends StatelessWidget {
  const SaleScreen({super.key});

  bool get isDesktop => Platform.isWindows;

  @override
  Widget build(BuildContext context) {
    return isDesktop ? const DesktopSaleScreen() : MobileSaleScreen();
  }
}

class MobileSaleScreen extends StatefulWidget {
  const MobileSaleScreen({super.key});

  @override
  State<MobileSaleScreen> createState() => _MobileSaleScreenState();
}

class _MobileSaleScreenState extends State<MobileSaleScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final List<_CartItem> _cart = [];
  final repo = ProductRepository();
  List<Product> products = [];
  List<Product> filteredProducts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim();
      _applyFilter();
    });
  }

  void _applyFilter() {
    final q = _searchQuery.toLowerCase();
    if (q.isEmpty) {
      filteredProducts = List.from(products);
    } else {
      filteredProducts = products.where((product) {
        return product.name.toLowerCase().contains(q) ||
            product.barcode.toLowerCase().contains(q);
      }).toList();
    }
  }

  Future<void> _loadProducts() async {
    final loaded = await repo.getAll();
    if (!mounted) return;
    setState(() {
      products = loaded;
      isLoading = false;
      _applyFilter();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.red,
        elevation: 0,
        titleSpacing: 8,
        title: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 40,
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    hintText: 'Tìm tên hoặc mã vạch...',
                    hintStyle: TextStyle(
                      // color: Colors.white.withOpacity(0.6),
                      color: Colors.white,
                      fontSize: 15,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Colors.white,
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: Colors.white70,
                              size: 18,
                            ),
                            onPressed: () => _searchController.clear(),
                            padding: EdgeInsets.zero,
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.3),
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(
                        color: Colors.white54,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                if (Platform.isWindows) {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Tính năng không khả dụng'),
                      content: const Text(
                        'Bạn không thể sử dụng tính năng này trên Windows.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PayScreen()),
                ).then((result) {
                  if (result == true) setState(() {});
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shopping_cart, color: Colors.white, size: 16),
                    SizedBox(width: 5),
                    Text(
                      'Giỏ hàng',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Product add via per-item '+' buttons; removed top Add button
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Tìm thấy ${filteredProducts.length} sản phẩm',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  ),
                Expanded(
                  child: filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _searchQuery.isNotEmpty
                                    ? Icons.search_off
                                    : Icons.inbox,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'Không tìm thấy sản phẩm'
                                    : 'Không có sản phẩm',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'Thử tìm với từ khóa khác'
                                    : 'Thêm sản phẩm trong màn hình sản phẩm',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 8,
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                leading:
                                    product.image.isNotEmpty &&
                                        File(product.image).existsSync()
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          File(product.image),
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(Icons.image),
                                      ),
                                title: Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      'Công ty: ${product.companyName}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      'Quy cách: ${product.specifications ?? 'Chưa có'}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      'HSD: ${product.expiryDate}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                      ),
                                      onPressed: () {
                                        final existing = _cart.indexWhere(
                                          (c) => c.product.id == product.id,
                                        );
                                        setState(() {
                                          if (existing >= 0) {
                                            _cart[existing].quantity += 1;
                                          } else {
                                            _cart.add(
                                              _CartItem(
                                                product: product,
                                                quantity: 1,
                                              ),
                                            );
                                          }
                                        });
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Đã thêm ${product.name} vào giỏ hàng',
                                            ),
                                            duration: const Duration(
                                              milliseconds: 800,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  // view product details
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProductScreen(),
                                    ),
                                  ).then((_) => _loadProducts());
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _CartItem {
  final Product product;
  int quantity;
  _CartItem({required this.product, this.quantity = 1});
}

class DesktopSaleScreen extends StatefulWidget {
  const DesktopSaleScreen({super.key});

  @override
  State<DesktopSaleScreen> createState() => _DesktopSaleScreenState();
}

class _DesktopSaleScreenState extends State<DesktopSaleScreen> {
  final ProductRepository _productRepo = ProductRepository();
  final SaleRepository _saleRepo = SaleRepository();
  final TextEditingController _searchController = TextEditingController();
  final NumberFormat _moneyFormat = NumberFormat.decimalPattern('vi_VN');

  final List<_CartItem> _cart = [];
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final loaded = await _productRepo.getAll();
    if (!mounted) return;
    setState(() {
      _products = loaded;
      _filteredProducts = List.from(loaded);
      _isLoading = false;
    });
  }

  void _onSearchChanged() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredProducts = List.from(_products);
      } else {
        _filteredProducts = _products.where((product) {
          return product.name.toLowerCase().contains(q) ||
              product.barcode.toLowerCase().contains(q) ||
              product.companyName.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  void _addToCart(Product product) {
    final idx = _cart.indexWhere((item) => item.product.id == product.id);
    setState(() {
      if (idx >= 0) {
        _cart[idx].quantity += 1;
      } else {
        _cart.add(_CartItem(product: product, quantity: 1));
      }
    });
  }

  void _changeQuantity(_CartItem item, int delta) {
    final index = _cart.indexOf(item);
    if (index < 0) return;

    setState(() {
      final next = _cart[index].quantity + delta;
      if (next <= 0) {
        _cart.removeAt(index);
      } else {
        _cart[index].quantity = next;
      }
    });
  }

  int get _totalQuantity {
    return _cart.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  double get _totalAmount {
    return _cart.fold<double>(
      0,
      (sum, item) => sum + ((item.product.sellPrice ?? 0) * item.quantity),
    );
  }

  String _money(double value) => '${_moneyFormat.format(value.round())} đ';

  Future<void> _checkout() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Giỏ hàng đang trống')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận thanh toán'),
        content: Text(
          'Tạo ${_cart.length} giao dịch bán với tổng tiền ${_money(_totalAmount)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);

    try {
      for (final item in _cart) {
        final sellPrice = item.product.sellPrice ?? 0;
        final importPrice =
            item.product.importPrice ?? item.product.costPrice ?? 0;
        final profit = (sellPrice - importPrice) * item.quantity;

        final sale = Sale(
          productId: item.product.id ?? 0,
          quantity: item.quantity,
          sellPrice: sellPrice,
          profit: profit,
          date: DateTime.now(),
        );
        await _saleRepo.insert(sale);
      }

      if (!mounted) return;
      setState(() {
        _cart.clear();
      });
      await _loadProducts();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu lịch sử bán hàng thành công')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể thanh toán: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bán hàng (Windows)'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _isSaving ? null : _loadProducts,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                Expanded(
                  flex: 7,
                  child: Container(
                    color: const Color(0xFFF6F8FB),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Tìm theo tên, mã vạch, công ty...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      onPressed: () {
                                        _searchController.clear();
                                      },
                                      icon: const Icon(Icons.clear),
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: _filteredProducts.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Không tìm thấy sản phẩm phù hợp',
                                  ),
                                )
                              : GridView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    8,
                                    16,
                                    16,
                                  ),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                        childAspectRatio: 1.8,
                                      ),
                                  itemCount: _filteredProducts.length,
                                  itemBuilder: (context, index) {
                                    final product = _filteredProducts[index];
                                    return Card(
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: const BorderSide(
                                          color: Color(0x14000000),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              product.companyName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Color(0xFF616161),
                                                fontSize: 12,
                                              ),
                                            ),
                                            const Spacer(),
                                            Text('Tồn: ${product.quantity}'),
                                            Text(
                                              'Giá: ${_money(product.sellPrice ?? 0)}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: FilledButton.icon(
                                                onPressed: product.quantity <= 0
                                                    ? null
                                                    : () => _addToCart(product),
                                                icon: const Icon(
                                                  Icons.add_shopping_cart,
                                                ),
                                                label: const Text('Thêm'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(width: 1, color: const Color(0x16000000)),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Giỏ hàng',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$_totalQuantity sản phẩm',
                          style: const TextStyle(color: Color(0xFF616161)),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: _cart.isEmpty
                              ? const Center(
                                  child: Text('Chưa có sản phẩm nào'),
                                )
                              : ListView.separated(
                                  itemBuilder: (context, index) {
                                    final item = _cart[index];
                                    return Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: const Color(0x17000000),
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.product.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              IconButton(
                                                onPressed: _isSaving
                                                    ? null
                                                    : () => _changeQuantity(
                                                        item,
                                                        -1,
                                                      ),
                                                icon: const Icon(
                                                  Icons.remove_circle_outline,
                                                ),
                                              ),
                                              Text('${item.quantity}'),
                                              IconButton(
                                                onPressed: _isSaving
                                                    ? null
                                                    : () => _changeQuantity(
                                                        item,
                                                        1,
                                                      ),
                                                icon: const Icon(
                                                  Icons.add_circle_outline,
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                _money(
                                                  (item.product.sellPrice ??
                                                          0) *
                                                      item.quantity,
                                                ),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 8),
                                  itemCount: _cart.length,
                                ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              const Text(
                                'Tổng tiền:',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              Text(
                                _money(_totalAmount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _isSaving ? null : _checkout,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.payments_outlined),
                            label: Text(
                              _isSaving ? 'Đang xử lý...' : 'Thanh toán',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
