import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventory_manage/database/firestore_service.dart';
import 'package:inventory_manage/models/imports.dart';

class ImportRepository {
  Future<void> insert(Imports import) async {
    final id = import.id ?? await FirestoreService.nextId('imports');
    final db = FirestoreService.instance;
    final importRef = db.collection('imports').doc(id.toString());
    final productRef = db
        .collection('products')
        .doc(import.productId.toString());

    await db.runTransaction((txn) async {
      final productSnap = await txn.get(productRef);
      if (!productSnap.exists) {
        throw Exception('Không tìm thấy sản phẩm');
      }

      final currentQuantity =
          (productSnap.data()?['quantity'] as num?)?.toInt() ?? 0;

      // Cập nhật giá nhập mới nhất nếu giá nhập hiện tại khác
      final currentImportPrice = (productSnap.data()?['importPrice'] as num?)
          ?.toDouble();

      txn.set(importRef, {...import.toMap(), 'id': id});
      txn.update(productRef, {
        'quantity': currentQuantity + import.quantity,
        // Cập nhật giá nhập mới nhất
        if (currentImportPrice == null ||
            import.importPrice != currentImportPrice)
          'importPrice': import.importPrice,
        'lastImportDate': import.date,
      });
    });
  }

  Future<List<Imports>> getAll() async {
    final result = await FirestoreService.collection(
      'imports',
    ).orderBy('date', descending: true).get();
    return result.docs.map((e) => Imports.fromMap(e.data())).toList();
  }

  // Lấy lịch sử nhập hàng theo ngày
  Future<List<Imports>> getByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final startStr = startDate.toIso8601String().split('T').first;
    final endStr = endDate.toIso8601String().split('T').first;

    final result = await FirestoreService.collection('imports')
        .where('date', isGreaterThanOrEqualTo: startStr)
        .where('date', isLessThanOrEqualTo: endStr)
        .orderBy('date', descending: true)
        .get();

    return result.docs.map((e) => Imports.fromMap(e.data())).toList();
  }

  // Lấy lịch sử nhập hàng theo tháng
  Future<List<Imports>> getByMonth(int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);
    return getByDateRange(startDate, endDate);
  }

  // Lấy lịch sử nhập hàng theo năm
  Future<List<Imports>> getByYear(int year) async {
    final startDate = DateTime(year, 1, 1);
    final endDate = DateTime(year, 12, 31);
    return getByDateRange(startDate, endDate);
  }

  // Xóa một lịch sử nhập hàng và hoàn trả số lượng về sản phẩm
  Future<void> delete(Imports import) async {
    final db = FirestoreService.instance;
    final importRef = db.collection('imports').doc(import.id.toString());
    final productRef = db
        .collection('products')
        .doc(import.productId.toString());

    await db.runTransaction((txn) async {
      final productSnap = await txn.get(productRef);
      if (!productSnap.exists) {
        throw Exception('Không tìm thấy sản phẩm');
      }

      final currentQuantity =
          (productSnap.data()?['quantity'] as num?)?.toInt() ?? 0;
      final newQuantity = (currentQuantity - import.quantity).clamp(0, 999999);

      txn.delete(importRef);
      txn.update(productRef, {'quantity': newQuantity});
    });
  }
}
