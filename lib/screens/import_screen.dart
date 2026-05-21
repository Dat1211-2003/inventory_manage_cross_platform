import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Thêm import này để định dạng ngày tháng
import '../models/product.dart';
import '../models/imports.dart';
import '../repository/product_repository.dart';
import '../repository/import_repository.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen>
    with SingleTickerProviderStateMixin {
  final productRepo = ProductRepository();
  final importRepo = ImportRepository();

  List<Product> products = [];
  List<Product> filteredProducts = [];
  Product? selectedProduct;
  List<Imports> importHistory = [];
  List<Imports> filteredHistory = [];
  Imports? lastImport; // lần nhập vừa xong

  final quantityCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final searchProductCtrl = TextEditingController();

  bool isSaving = false;
  bool isLoadingHistory = false;
  bool isSearching = false;

  // Suggestions cho ô nhập liệu
  List<String> _quantitySuggestions = [];
  List<String> _priceSuggestions = [];

  // Filter variables mới
  String _selectedFilterType = 'day'; // day, month, year
  DateTime _selectedDate = DateTime.now();
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  // Danh sách tháng và năm
  final List<String> months = [
    'Tháng 1',
    'Tháng 2',
    'Tháng 3',
    'Tháng 4',
    'Tháng 5',
    'Tháng 6',
    'Tháng 7',
    'Tháng 8',
    'Tháng 9',
    'Tháng 10',
    'Tháng 11',
    'Tháng 12',
  ];

  List<int> years = [];

  late TabController _tabController;
  final FocusNode _searchFocusNode = FocusNode();

  Map<int, String> productNames = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _generateYears();
    loadProducts();
    loadImportHistory();
    searchProductCtrl.addListener(_onSearchChanged);
  }

  void _generateYears() {
    int currentYear = DateTime.now().year;
    for (int i = currentYear - 5; i <= currentYear + 1; i++) {
      years.add(i);
    }
  }

  Future<void> loadProducts() async {
    final data = await productRepo.getAll();
    setState(() {
      products = data;
      filteredProducts = data;
    });
  }

  void _onSearchChanged() {
    final query = searchProductCtrl.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredProducts = products;
        isSearching = false;
      } else {
        filteredProducts = products.where((product) {
          return product.name.toLowerCase().contains(query) ||
              product.barcode.toLowerCase().contains(query) ||
              (product.companyName.toLowerCase().contains(query));
        }).toList();
        isSearching = true;
      }
    });
  }

  // Sinh danh sách gợi ý thêm số 0
  // startZeros: số lượng số 0 tối thiểu phải có so với input gốc
  List<String> _generateSuggestions(String input, int startZeros) {
    final trimmed = input.trim();
    if (trimmed.isEmpty || int.tryParse(trimmed) == null) return [];
    final suggestions = <String>[];
    String current = trimmed;
    // Thêm đủ số 0 xuất phát trước
    for (int i = 0; i < startZeros; i++) {
      current = '${current}0';
    }
    // Sinh 4 gợi ý liên tiếp
    for (int i = 0; i < 4; i++) {
      suggestions.add(current);
      current = '${current}0';
    }
    return suggestions;
  }

  void _onQuantityChanged(String value) {
    setState(() {
      // Số lượng: gợi ý bắt đầu từ input + 1 số 0 (vd: gõ "1" → 10, 100, 1000, 10000)
      _quantitySuggestions = _generateSuggestions(value, 1);
    });
  }

  void _onPriceChanged(String value) {
    setState(() {
      // Giá nhập: gợi ý bắt đầu từ input + 4 số 0 (vd: gõ "1" → 10000, 100000, ...)
      _priceSuggestions = _generateSuggestions(value, 4);
    });
  }

  void _selectProduct(Product product) {
    setState(() {
      selectedProduct = product;
      searchProductCtrl.text =
          '${product.name} - ${product.companyName} (Tồn: ${product.quantity})';
      isSearching = false;
    });
    _searchFocusNode.unfocus();
  }

  void _clearSelectedProduct() {
    setState(() {
      selectedProduct = null;
      searchProductCtrl.clear();
      filteredProducts = products;
      isSearching = false;
    });
    _searchFocusNode.requestFocus();
  }

  Future<void> loadImportHistory() async {
    setState(() {
      isLoadingHistory = true;
    });

    List<Imports> history = await importRepo.getAll();

    // Lọc theo ngày/tháng/năm
    if (_selectedFilterType == 'day') {
      history = history.where((import) {
        final importDate = DateTime.tryParse(import.date);
        if (importDate == null) return false;
        return importDate.year == _selectedDate.year &&
            importDate.month == _selectedDate.month &&
            importDate.day == _selectedDate.day;
      }).toList();
    } else if (_selectedFilterType == 'month') {
      history = history.where((import) {
        final importDate = DateTime.tryParse(import.date);
        if (importDate == null) return false;
        return importDate.year == _selectedYear &&
            importDate.month == _selectedMonth;
      }).toList();
    } else if (_selectedFilterType == 'year') {
      history = history.where((import) {
        final importDate = DateTime.tryParse(import.date);
        if (importDate == null) return false;
        return importDate.year == _selectedYear;
      }).toList();
    }

    // Load product names
    for (var import in history) {
      if (!productNames.containsKey(import.productId)) {
        final product = await productRepo.getById(import.productId);
        if (product != null) {
          productNames[import.productId] = product.name;
        }
      }
    }

    // Sort mới nhất lên đầu: ưu tiên id (lớn hơn = nhập sau), fallback theo date
    history.sort((a, b) {
      // So sánh theo id trước (id lớn hơn = nhập sau = lên đầu)
      if (a.id != null && b.id != null) {
        return b.id!.compareTo(a.id!);
      }
      // Fallback theo ngày nếu không có id
      final da = DateTime.tryParse(a.date) ?? DateTime(2000);
      final db = DateTime.tryParse(b.date) ?? DateTime(2000);
      return db.compareTo(da);
    });

    if (mounted) {
      setState(() {
        importHistory = history;
        filteredHistory = history;
        isLoadingHistory = false;
      });
    }
  }

  Future<void> _deleteImport(Imports import) async {
    final productName =
        productNames[import.productId] ?? 'Sản phẩm ${import.productId}';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFE53935)),
            SizedBox(width: 8),
            Text('Xác nhận xóa', style: TextStyle(fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bạn có chắc muốn xóa lịch sử nhập này không?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Số lượng: ${import.quantity} cái'),
                  Text('Giá nhập: ${_formatCurrency(import.importPrice)} đ'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '⚠️ Tồn kho sẽ được hoàn trả tương ứng.',
              style: TextStyle(color: Color(0xFFE65100), fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await importRepo.delete(import);
      _showSnack('Đã xóa lịch sử nhập hàng');
      await loadImportHistory();
      loadProducts();
    } catch (e) {
      _showSnack('Lỗi khi xóa: $e', isError: true);
    }
  }

  Future<void> _deleteAllImports() async {
    if (filteredHistory.isEmpty) return;

    final periodLabel = _getPeriodTitle();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Color(0xFFE53935), size: 26),
            SizedBox(width: 8),
            Text('Xóa tất cả', style: TextStyle(fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn có chắc muốn xóa toàn bộ ${filteredHistory.length} lịch sử nhập hàng của "$periodLabel" không?',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFE53935),
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tồn kho sẽ được hoàn trả cho tất cả sản phẩm liên quan. Hành động này không thể hoàn tác!',
                      style: TextStyle(color: Color(0xFFE53935), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Xóa tuần tự từng item (mỗi cái hoàn trả tồn kho)
      for (final item in List.from(filteredHistory)) {
        await importRepo.delete(item);
      }
      _showSnack('Đã xóa ${filteredHistory.length} lịch sử nhập hàng');
      await loadImportHistory();
      loadProducts();
    } catch (e) {
      _showSnack('Lỗi khi xóa: $e', isError: true);
      await loadImportHistory();
    }
  }

  void saveImport() async {
    if (selectedProduct == null) {
      _showSnack("Vui lòng chọn sản phẩm", isError: true);
      return;
    }

    final quantity = int.tryParse(quantityCtrl.text) ?? 0;
    final price = double.tryParse(priceCtrl.text) ?? 0;

    if (quantity <= 0 || price <= 0) {
      _showSnack("Số lượng và giá nhập phải lớn hơn 0", isError: true);
      return;
    }

    setState(() => isSaving = true);

    final import = Imports(
      productId: selectedProduct!.id!,
      quantity: quantity,
      importPrice: price,
      date: DateTime.now().toIso8601String().split('T').first,
    );

    await importRepo.insert(import);

    if (!mounted) return;

    setState(() => isSaving = false);

    _showSnack("Nhập hàng thành công!");

    // Lưu lần nhập vừa xong để hiển thị nổi bật
    setState(() {
      lastImport = import;
      // Đặt filter về hôm nay để thấy lần nhập mới
      _selectedFilterType = 'day';
      _selectedDate = DateTime.now();
    });

    await loadImportHistory();
    loadProducts();

    setState(() {
      selectedProduct = null;
      searchProductCtrl.clear();
      quantityCtrl.clear();
      priceCtrl.clear();
      filteredProducts = products;
      _quantitySuggestions = [];
      _priceSuggestions = [];
    });
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(message),
          ],
        ),
        backgroundColor: isError
            ? const Color(0xFFE53935)
            : const Color(0xFF43A047),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _changeFilterType(String type) {
    setState(() {
      _selectedFilterType = type;
    });
    loadImportHistory();
  }

  void _previousPeriod() {
    setState(() {
      if (_selectedFilterType == 'day') {
        _selectedDate = _selectedDate.subtract(const Duration(days: 1));
      } else if (_selectedFilterType == 'month') {
        if (_selectedMonth == 1) {
          _selectedMonth = 12;
          _selectedYear--;
        } else {
          _selectedMonth--;
        }
      } else if (_selectedFilterType == 'year') {
        _selectedYear--;
      }
    });
    loadImportHistory();
  }

  void _nextPeriod() {
    setState(() {
      if (_selectedFilterType == 'day') {
        _selectedDate = _selectedDate.add(const Duration(days: 1));
      } else if (_selectedFilterType == 'month') {
        if (_selectedMonth == 12) {
          _selectedMonth = 1;
          _selectedYear++;
        } else {
          _selectedMonth++;
        }
      } else if (_selectedFilterType == 'year') {
        _selectedYear++;
      }
    });
    loadImportHistory();
  }

  String _getPeriodTitle() {
    if (_selectedFilterType == 'day') {
      return DateFormat('dd/MM/yyyy').format(_selectedDate);
    } else if (_selectedFilterType == 'month') {
      return 'Tháng $_selectedMonth/$_selectedYear';
    } else {
      return 'Năm $_selectedYear';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatCurrency(double value) {
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  double get totalCost {
    final qty = int.tryParse(quantityCtrl.text) ?? 0;
    final price = double.tryParse(priceCtrl.text) ?? 0;
    return qty * price;
  }

  double get totalImportValue {
    return filteredHistory.fold(
      0,
      (sum, item) => sum + (item.quantity * item.importPrice),
    );
  }

  @override
  void dispose() {
    quantityCtrl.dispose();
    priceCtrl.dispose();
    searchProductCtrl.dispose();
    _searchFocusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.input_outlined, size: 22),
            SizedBox(width: 8),
            Text(
              "Quản lý nhập hàng",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'NHẬP HÀNG', icon: Icon(Icons.add_shopping_cart)),
            Tab(text: 'LỊCH SỬ', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildImportTab(), _buildHistoryTab()],
      ),
    );
  }

  Widget _buildImportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Form card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel("Sản phẩm", Icons.widgets_outlined),
                const SizedBox(height: 10),
                _buildSearchableProductField(),
                const SizedBox(height: 24),
                _sectionLabel("Chi tiết nhập hàng", Icons.edit_note_outlined),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextField(
                            controller: quantityCtrl,
                            label: "Số lượng",
                            icon: Icons.format_list_numbered,
                            suffix: "cái",
                            onChanged: (v) {
                              _onQuantityChanged(v);
                              setState(() {});
                            },
                          ),
                          if (_quantitySuggestions.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _buildSuggestionChips(
                              suggestions: _quantitySuggestions,
                              onTap: (val) {
                                quantityCtrl.text = val;
                                quantityCtrl.selection =
                                    TextSelection.collapsed(offset: val.length);
                                setState(() {
                                  _quantitySuggestions = [];
                                });
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextField(
                            controller: priceCtrl,
                            label: "Giá nhập",
                            icon: Icons.attach_money,
                            suffix: "₫",
                            onChanged: (v) {
                              _onPriceChanged(v);
                              setState(() {});
                            },
                          ),
                          if (_priceSuggestions.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _buildSuggestionChips(
                              suggestions: _priceSuggestions,
                              onTap: (val) {
                                priceCtrl.text = val;
                                priceCtrl.selection = TextSelection.collapsed(
                                  offset: val.length,
                                );
                                setState(() {
                                  _priceSuggestions = [];
                                });
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Total summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Tổng tiền nhập",
                      style: TextStyle(color: Color(0xFF757575), fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${_formatCurrency(totalCost)} ₫",
                      style: const TextStyle(
                        color: Color(0xFF1565C0),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calculate_outlined,
                        color: Color(0xFF1565C0),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "${quantityCtrl.text.isEmpty ? 0 : quantityCtrl.text} cái × ${priceCtrl.text.isEmpty ? 0 : priceCtrl.text} ₫",
                        style: const TextStyle(
                          color: Color(0xFF1565C0),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: isSaving ? null : saveImport,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF90CAF9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save_outlined, size: 22),
                        SizedBox(width: 10),
                        Text(
                          "Xác nhận nhập hàng",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSearchableProductField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: searchProductCtrl,
          focusNode: _searchFocusNode,
          decoration: InputDecoration(
            hintText: "Nhập tên sản phẩm, mã vạch hoặc công ty...",
            prefixIcon: const Icon(Icons.search, color: Color(0xFF1565C0)),
            suffixIcon: selectedProduct != null
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: _clearSelectedProduct,
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFF5F7FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),

        if (isSearching && searchProductCtrl.text.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 300),
            child: filteredProducts.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'Không tìm thấy sản phẩm',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return InkWell(
                        onTap: () => _selectProduct(product),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey[200]!),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE3F2FD),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.inventory_2,
                                  color: Color(0xFF1565C0),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${product.companyName} | Mã: ${product.barcode}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE8F5E9),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            'Tồn: ${product.quantity}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF2E7D32),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        if (product.importPrice != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFF3E0),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Giá nhập: ${_formatCurrency(product.importPrice!)}₫',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFFE65100),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

        if (selectedProduct != null && !isSearching)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1565C0), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedProduct!.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Tồn kho: ${selectedProduct!.quantity} | Giá nhập gần nhất: ${selectedProduct!.importPrice != null ? _formatCurrency(selectedProduct!.importPrice!) + "₫" : "Chưa có"}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.edit,
                    size: 18,
                    color: Color(0xFF1565C0),
                  ),
                  onPressed: _clearSelectedProduct,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    return Column(
      children: [
        // ── Filter section ──────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              // 3 tab chọn kiểu lọc + nút xóa tất cả
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _filterTab('Ngày', 'day', Icons.today),
                          _filterTab('Tháng', 'month', Icons.calendar_month),
                          _filterTab('Năm', 'year', Icons.calendar_view_month),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: filteredHistory.isEmpty ? null : _deleteAllImports,
                    child: AnimatedOpacity(
                      opacity: filteredHistory.isEmpty ? 0.4 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEF9A9A)),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.delete_sweep_outlined,
                              color: Color(0xFFE53935),
                              size: 18,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Xóa tất cả',
                              style: TextStyle(
                                color: Color(0xFFE53935),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Navigator < kỳ >
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 26),
                    onPressed: _previousPeriod,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: const Color(0xFF1565C0),
                  ),
                  GestureDetector(
                    onTap: () => _pickPeriod(context),
                    child: Column(
                      children: [
                        Text(
                          _getPeriodTitle(),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _selectedFilterType == 'day'
                              ? 'Nhấn để chọn ngày'
                              : _selectedFilterType == 'month'
                              ? 'Nhấn để chọn tháng/năm'
                              : 'Nhấn để chọn năm',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 26),
                    onPressed: _nextPeriod,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: const Color(0xFF1565C0),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),

        // ── Summary card ────────────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tổng giá trị nhập',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Số lần nhập',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_formatCurrency(totalImportValue)} đ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${filteredHistory.length} lần',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── History list (đã sort mới nhất ở loadImportHistory) ──
        Expanded(
          child: isLoadingHistory
              ? const Center(child: CircularProgressIndicator())
              : filteredHistory.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 72,
                        color: Colors.grey[350],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Không có dữ liệu nhập hàng',
                        style: TextStyle(color: Colors.grey[500], fontSize: 15),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: filteredHistory.length,
                  itemBuilder: (context, index) {
                    final import = filteredHistory[index];
                    final importDate =
                        DateTime.tryParse(import.date) ?? DateTime.now();
                    // Kiểm tra item này có phải lần nhập vừa xong không
                    final isNew =
                        lastImport != null &&
                        index == 0 &&
                        import.productId == lastImport!.productId &&
                        import.quantity == lastImport!.quantity &&
                        import.importPrice == lastImport!.importPrice;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isNew
                            ? const Color(0xFFE8F5E9) // xanh lá nhạt nếu là mới
                            : const Color(0xFFF0F4FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isNew
                              ? const Color(0xFF43A047) // viền xanh lá
                              : const Color(0xFFDDE6FF),
                          width: isNew ? 1.5 : 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Icon
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: isNew
                                    ? const Color(0xFFC8E6C9)
                                    : const Color(0xFFDDE6FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.add_shopping_cart,
                                color: isNew
                                    ? const Color(0xFF2E7D32)
                                    : const Color(0xFF1565C0),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Thông tin
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          productNames[import.productId] ??
                                              'Sản phẩm ${import.productId}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Color(0xFF212121),
                                          ),
                                        ),
                                      ),
                                      if (isNew)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            left: 6,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF43A047),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: const Text(
                                            'MỚI',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Số lượng: ${import.quantity} cái',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF555555),
                                    ),
                                  ),
                                  Text(
                                    'Giá nhập: ${_formatCurrency(import.importPrice)} đ',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF555555),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Thành tiền: ${_formatCurrency(import.quantity * import.importPrice)} đ',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isNew
                                          ? const Color(0xFF2E7D32)
                                          : const Color(0xFF1565C0),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Ngày + nút xóa
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.calendar_month_outlined,
                                  size: 17,
                                  color: isNew
                                      ? const Color(0xFF43A047)
                                      : Colors.grey,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDate(importDate),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isNew
                                        ? const Color(0xFF43A047)
                                        : Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: () => _deleteImport(import),
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFEBEE),
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: const Icon(
                                      Icons.delete_outline,
                                      size: 16,
                                      color: Color(0xFFE53935),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // Tab button cho bộ lọc
  Widget _filterTab(String label, String type, IconData icon) {
    final bool selected = _selectedFilterType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => _changeFilterType(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF1565C0) : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected ? Colors.white : Colors.grey[600],
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Picker nhanh khi nhấn vào tiêu đề kỳ
  Future<void> _pickPeriod(BuildContext context) async {
    if (_selectedFilterType == 'day') {
      final picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF1565C0)),
          ),
          child: child!,
        ),
      );
      if (picked != null) {
        setState(() => _selectedDate = picked);
        loadImportHistory();
      }
    } else if (_selectedFilterType == 'month') {
      // Chọn tháng bằng bottom sheet đơn giản
      _showMonthYearPicker(context);
    } else {
      _showYearPicker(context);
    }
  }

  void _showMonthYearPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModal) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chọn tháng & năm',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Năm
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: years.map((y) {
                    final sel = y == _selectedYear;
                    return GestureDetector(
                      onTap: () {
                        setModal(() {});
                        setState(() => _selectedYear = y);
                        loadImportHistory();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: sel
                              ? const Color(0xFF1565C0)
                              : const Color(0xFFF0F4FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$y',
                          style: TextStyle(
                            color: sel ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),
              // Tháng grid
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.2,
                children: List.generate(12, (i) {
                  final sel = (i + 1) == _selectedMonth;
                  return GestureDetector(
                    onTap: () {
                      setModal(() {});
                      setState(() => _selectedMonth = i + 1);
                      loadImportHistory();
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: sel
                            ? const Color(0xFF1565C0)
                            : const Color(0xFFF0F4FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Th ${i + 1}',
                        style: TextStyle(
                          color: sel ? Colors.white : Colors.black87,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showYearPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chọn năm',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2,
              children: years.map((y) {
                final sel = y == _selectedYear;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedYear = y);
                    loadImportHistory();
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: sel
                          ? const Color(0xFF1565C0)
                          : const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$y',
                      style: TextStyle(
                        color: sel ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1565C0)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Color(0xFF212121),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionChips({
    required List<String> suggestions,
    required void Function(String) onTap,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: suggestions.map((s) {
          return GestureDetector(
            onTap: () => onTap(s),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF90CAF9)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 12, color: Color(0xFF1565C0)),
                  const SizedBox(width: 2),
                  Text(
                    s,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1565C0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? suffix,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF757575),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: const Color(0xFF1565C0)),
            suffixText: suffix,
            suffixStyle: const TextStyle(color: Color(0xFF757575)),
            filled: true,
            fillColor: const Color(0xFFF5F7FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}
