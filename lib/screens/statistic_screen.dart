import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:inventory_manage/models/imports.dart';
import 'package:inventory_manage/models/product.dart';
import 'package:inventory_manage/models/sale.dart';
import 'package:inventory_manage/repository/import_repository.dart';
import 'package:inventory_manage/repository/product_repository.dart';
import 'package:inventory_manage/repository/sale_repository.dart';

class StatisticScreen extends StatefulWidget {
  const StatisticScreen({super.key});

  @override
  State<StatisticScreen> createState() => _StatisticScreenState();
}

enum _PresetFilter { last7Days, last30Days, thisMonth, thisYear, custom }

class _StatisticScreenState extends State<StatisticScreen>
    with SingleTickerProviderStateMixin {
  final SaleRepository _saleRepository = SaleRepository();
  final ImportRepository _importRepository = ImportRepository();
  final ProductRepository _productRepository = ProductRepository();

  final NumberFormat _moneyFormat = NumberFormat.decimalPattern('vi_VN');
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _dateKeyFormat = DateFormat('yyyy-MM-dd');

  late TabController _tabController;
  _PresetFilter _selectedFilter = _PresetFilter.last30Days;

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _isLoading = true;

  List<Sale> _allSales = [];
  List<Imports> _allImports = [];
  List<Sale> _filteredSales = [];
  List<Imports> _filteredImports = [];
  Map<int, Product> _productsById = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _applyPreset(_PresetFilter.last30Days, reload: false);
    _loadReportData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReportData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final results = await Future.wait([
        _saleRepository.getAll(),
        _importRepository.getAll(),
        _productRepository.getAll(),
      ]);

      final sales = (results[0] as List<Sale>).toList();
      final imports = (results[1] as List<Imports>).toList();
      final products = (results[2] as List<Product>).toList();

      final productMap = <int, Product>{};
      for (final product in products) {
        if (product.id != null) {
          productMap[product.id!] = product;
        }
      }

      sales.sort((a, b) => b.date.compareTo(a.date));
      imports.sort(
        (a, b) => _parseImportDate(b).compareTo(_parseImportDate(a)),
      );

      if (!mounted) return;

      setState(() {
        _allSales = sales;
        _allImports = imports;
        _productsById = productMap;
      });
      _applyFilters();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể tải dữ liệu báo cáo')),
      );
    }
  }

  void _applyPreset(_PresetFilter filter, {bool reload = true}) {
    final now = DateTime.now();
    DateTime start;
    DateTime end;

    switch (filter) {
      case _PresetFilter.last7Days:
        end = DateTime(now.year, now.month, now.day);
        start = end.subtract(const Duration(days: 6));
        break;
      case _PresetFilter.last30Days:
        end = DateTime(now.year, now.month, now.day);
        start = end.subtract(const Duration(days: 29));
        break;
      case _PresetFilter.thisMonth:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0);
        break;
      case _PresetFilter.thisYear:
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year, 12, 31);
        break;
      case _PresetFilter.custom:
        start = _startDate;
        end = _endDate;
        break;
    }

    setState(() {
      _selectedFilter = filter;
      _startDate = DateTime(start.year, start.month, start.day);
      _endDate = DateTime(end.year, end.month, end.day);
    });

    if (reload) {
      _applyFilters();
    }
  }

  void _applyFilters() {
    final endOfDay = DateTime(
      _endDate.year,
      _endDate.month,
      _endDate.day,
      23,
      59,
      59,
      999,
    );

    final sales = _allSales.where((sale) {
      return !sale.date.isBefore(_startDate) && !sale.date.isAfter(endOfDay);
    }).toList()..sort((a, b) => b.date.compareTo(a.date));

    final imports =
        _allImports.where((item) {
            final date = _parseImportDate(item);
            return !date.isBefore(_startDate) && !date.isAfter(endOfDay);
          }).toList()
          ..sort((a, b) => _parseImportDate(b).compareTo(_parseImportDate(a)));

    setState(() {
      _filteredSales = sales;
      _filteredImports = imports;
      _isLoading = false;
    });
  }

  DateTime _parseImportDate(Imports item) {
    return DateTime.tryParse(item.date) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _productNameOf(int productId) {
    return _productsById[productId]?.name ?? 'SP #$productId';
  }

  double get _totalRevenue {
    return _filteredSales.fold<double>(
      0,
      (sum, item) => sum + (item.sellPrice * item.quantity),
    );
  }

  double get _totalProfit {
    return _filteredSales.fold<double>(0, (sum, item) => sum + item.profit);
  }

  double get _totalImportCost {
    return _filteredImports.fold<double>(
      0,
      (sum, item) => sum + (item.importPrice * item.quantity),
    );
  }

  int get _totalItemsSold {
    return _filteredSales.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  int get _totalItemsImported {
    return _filteredImports.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  String _money(double value) => '${_moneyFormat.format(value.round())} đ';

  List<_SeriesPoint> _buildDailySalesSeries() {
    final result = <String, double>{};
    for (final sale in _filteredSales) {
      final key = _dateKeyFormat.format(sale.date);
      result[key] = (result[key] ?? 0) + (sale.sellPrice * sale.quantity);
    }
    return _buildTimelineSeries(result);
  }

  List<_SeriesPoint> _buildDailyImportSeries() {
    final result = <String, double>{};
    for (final item in _filteredImports) {
      final key = _dateKeyFormat.format(_parseImportDate(item));
      result[key] = (result[key] ?? 0) + (item.importPrice * item.quantity);
    }
    return _buildTimelineSeries(result);
  }

  List<_SeriesPoint> _buildTimelineSeries(Map<String, double> source) {
    final points = <_SeriesPoint>[];
    var cursor = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final end = DateTime(_endDate.year, _endDate.month, _endDate.day);
    var index = 0;

    while (!cursor.isAfter(end)) {
      final key = _dateKeyFormat.format(cursor);
      points.add(
        _SeriesPoint(
          index.toDouble(),
          source[key] ?? 0,
          _dateFormat.format(cursor),
        ),
      );
      cursor = cursor.add(const Duration(days: 1));
      index++;
    }
    return points;
  }

  List<_TopProduct> _topSoldProducts() {
    final map = <int, int>{};
    for (final sale in _filteredSales) {
      map[sale.productId] = (map[sale.productId] ?? 0) + sale.quantity;
    }

    final items = map.entries
        .map((e) => _TopProduct(_productNameOf(e.key), e.value.toDouble()))
        .toList();
    items.sort((a, b) => b.value.compareTo(a.value));
    return items.take(5).toList();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      helpText: 'Chọn khoảng thời gian',
      saveText: 'Áp dụng',
      cancelText: 'Hủy',
    );

    if (picked == null) return;

    setState(() {
      _selectedFilter = _PresetFilter.custom;
      _startDate = DateTime(
        picked.start.year,
        picked.start.month,
        picked.start.day,
      );
      _endDate = DateTime(picked.end.year, picked.end.month, picked.end.day);
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo thống kê'),
        actions: [
          IconButton(
            onPressed: _loadReportData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới dữ liệu',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tổng quan', icon: Icon(Icons.dashboard_outlined)),
            Tab(text: 'Bán hàng', icon: Icon(Icons.sell_outlined)),
            Tab(text: 'Nhập hàng', icon: Icon(Icons.inventory_2_outlined)),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildSaleHistoryTab(),
                      _buildImportHistoryTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    final rangeText =
        '${_dateFormat.format(_startDate)} - ${_dateFormat.format(_endDate)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x11000000))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _filterChip('7 ngày', _PresetFilter.last7Days),
              _filterChip('30 ngày', _PresetFilter.last30Days),
              _filterChip('Tháng này', _PresetFilter.thisMonth),
              _filterChip('Năm nay', _PresetFilter.thisYear),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  rangeText,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              TextButton.icon(
                onPressed: _pickDateRange,
                icon: const Icon(Icons.date_range_outlined),
                label: const Text('Tùy chọn'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, _PresetFilter value) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedFilter == value,
      onSelected: (_) => _applyPreset(value),
    );
  }

  Widget _buildOverviewTab() {
    final salesSeries = _buildDailySalesSeries();
    final importSeries = _buildDailyImportSeries();
    final topProducts = _topSoldProducts();
    final summaryCards = [
      _SummaryCardData(
        title: 'Doanh thu bán',
        value: _money(_totalRevenue),
        icon: Icons.payments_outlined,
        color: const Color(0xFF2E7D32),
      ),
      _SummaryCardData(
        title: 'Lợi nhuận',
        value: _money(_totalProfit),
        icon: Icons.trending_up,
        color: const Color(0xFF1B5E20),
      ),
      _SummaryCardData(
        title: 'Chi phí nhập',
        value: _money(_totalImportCost),
        icon: Icons.shopping_cart_checkout,
        color: const Color(0xFF1565C0),
      ),
      _SummaryCardData(
        title: 'Số lượng bán / nhập',
        value: '$_totalItemsSold / $_totalItemsImported',
        icon: Icons.inventory,
        color: const Color(0xFF6A1B9A),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1100;
        final summaryCrossAxisCount = constraints.maxWidth >= 900
            ? 4
            : (constraints.maxWidth >= 650 ? 3 : 2);

        Widget summaryGrid() {
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: summaryCards.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: summaryCrossAxisCount,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: isDesktop ? 2.0 : 1.4,
            ),
            itemBuilder: (context, index) =>
                _buildSummaryCard(summaryCards[index]),
          );
        }

        final linePanel = _buildPanel(
          title: 'Biểu đồ bán hàng và nhập hàng theo ngày',
          child: _buildLineChart(salesSeries, importSeries),
        );

        final topPanel = _buildPanel(
          title: 'Top 5 sản phẩm bán chạy (theo số lượng)',
          child: _buildTopProductsChart(topProducts),
        );

        if (!isDesktop) {
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              summaryGrid(),
              const SizedBox(height: 14),
              linePanel,
              const SizedBox(height: 12),
              topPanel,
            ],
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              summaryGrid(),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 7, child: linePanel),
                  const SizedBox(width: 12),
                  Expanded(flex: 5, child: topPanel),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(_SummaryCardData data) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x14000000)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: data.color.withOpacity(0.12),
            child: Icon(data.icon, size: 18, color: data.color),
          ),
          const Spacer(),
          Text(
            data.value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(data.title, style: const TextStyle(color: Color(0xFF616161))),
        ],
      ),
    );
  }

  Widget _buildPanel({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x14000000)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildLineChart(
    List<_SeriesPoint> salesSeries,
    List<_SeriesPoint> importSeries,
  ) {
    if (salesSeries.isEmpty && importSeries.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(
          child: Text('Chưa có dữ liệu trong khoảng thời gian này'),
        ),
      );
    }

    final allValues = [
      ...salesSeries.map((e) => e.y),
      ...importSeries.map((e) => e.y),
      0.0,
    ];
    final maxY = allValues.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 260,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (salesSeries.length - 1).toDouble().clamp(0, double.infinity),
          minY: 0,
          maxY: maxY == 0 ? 1 : maxY * 1.2,
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: const Color(0x22000000)),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => Colors.black87,
              getTooltipItems: (spots) {
                return spots.map((spot) {
                  final label = spot.barIndex == 0 ? 'Bán' : 'Nhập';
                  return LineTooltipItem(
                    '$label: ${_money(spot.y)}',
                    const TextStyle(color: Colors.white),
                  );
                }).toList();
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 56),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: salesSeries.length > 10
                    ? (salesSeries.length / 5).ceilToDouble()
                    : 1,
                getTitlesWidget: (value, meta) {
                  final i = value.round();
                  if (i < 0 || i >= salesSeries.length) {
                    return const SizedBox.shrink();
                  }
                  final label = salesSeries[i].label;
                  final parts = label.split('/');
                  final text = parts.length >= 2
                      ? '${parts[0]}/${parts[1]}'
                      : label;
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(text, style: const TextStyle(fontSize: 10)),
                  );
                },
                reservedSize: 30,
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: salesSeries.map((e) => FlSpot(e.x, e.y)).toList(),
              isCurved: true,
              barWidth: 3,
              color: const Color(0xFF2E7D32),
              dotData: const FlDotData(show: false),
            ),
            LineChartBarData(
              spots: importSeries.map((e) => FlSpot(e.x, e.y)).toList(),
              isCurved: true,
              barWidth: 3,
              color: const Color(0xFF1565C0),
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductsChart(List<_TopProduct> products) {
    if (products.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(child: Text('Chưa có dữ liệu bán hàng')),
      );
    }

    final maxY = products
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b)
        .clamp(1, double.infinity);

    return SizedBox(
      height: 260,
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: maxY * 1.2,
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: const Color(0x22000000)),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 36),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.round();
                  if (i < 0 || i >= products.length) {
                    return const SizedBox.shrink();
                  }
                  final text = products[i].name;
                  final shortText = text.length > 10
                      ? '${text.substring(0, 10)}…'
                      : text;
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      shortText,
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
                reservedSize: 32,
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.black87,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${products[groupIndex].name}\n${rod.toY.round()} sản phẩm',
                  const TextStyle(color: Colors.white),
                );
              },
            ),
          ),
          barGroups: List.generate(products.length, (index) {
            final item = products[index];
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: item.value,
                  width: 18,
                  borderRadius: BorderRadius.circular(4),
                  color: const Color(0xFFE53935),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSaleHistoryTab() {
    if (_filteredSales.isEmpty) {
      return const Center(
        child: Text('Không có lịch sử bán hàng trong kỳ này'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _filteredSales.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = _filteredSales[index];
        final total = item.sellPrice * item.quantity;
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0x1A000000)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            title: Text(
              _productNameOf(item.productId),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ngày bán: ${_dateFormat.format(item.date)}'),
                  Text('Số lượng: ${item.quantity}'),
                  Text('Giá bán: ${_money(item.sellPrice)}'),
                  Text('Doanh thu: ${_money(total)}'),
                  Text('Lợi nhuận: ${_money(item.profit)}'),
                ],
              ),
            ),
            leading: CircleAvatar(
              backgroundColor: const Color(0x1AE53935),
              child: const Icon(Icons.sell_outlined, color: Color(0xFFE53935)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImportHistoryTab() {
    if (_filteredImports.isEmpty) {
      return const Center(
        child: Text('Không có lịch sử nhập hàng trong kỳ này'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _filteredImports.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = _filteredImports[index];
        final date = _parseImportDate(item);
        final total = item.importPrice * item.quantity;
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0x1A000000)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            title: Text(
              _productNameOf(item.productId),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ngày nhập: ${_dateFormat.format(date)}'),
                  Text('Số lượng: ${item.quantity}'),
                  Text('Giá nhập: ${_money(item.importPrice)}'),
                  Text('Tổng tiền nhập: ${_money(total)}'),
                ],
              ),
            ),
            leading: CircleAvatar(
              backgroundColor: const Color(0x1A1565C0),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: Color(0xFF1565C0),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SummaryCardData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  _SummaryCardData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _SeriesPoint {
  final double x;
  final double y;
  final String label;

  _SeriesPoint(this.x, this.y, this.label);
}

class _TopProduct {
  final String name;
  final double value;

  _TopProduct(this.name, this.value);
}
