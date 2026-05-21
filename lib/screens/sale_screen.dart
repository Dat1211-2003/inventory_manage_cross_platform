import 'dart:io';

import 'package:flutter/material.dart';
import 'package:inventory_manage/screens/home_screen.dart';
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

class DesktopSaleScreen extends StatelessWidget {
  const DesktopSaleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Text('Is Desktop Screen'));
  }
}
