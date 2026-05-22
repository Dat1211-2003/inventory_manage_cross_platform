import 'package:inventory_manage/database/firestore_service.dart';
import 'package:inventory_manage/models/sale.dart';

class SaleRepository {
  Future<List<Sale>> getAll() async {
    final result = await FirestoreService.collection(
      'sales',
    ).orderBy('id').get();

    return result.docs.map((e) => Sale.fromMap(e.data())).toList();
  }

  Future<void> insert(Sale sale) async {
    await insertAll([sale]);
  }

  Future<void> insertAll(List<Sale> sales) async {
    final db = FirestoreService.instance;

    // Lấy ID cao nhất hiện tại trước khi bắt đầu transaction
    final int startId = await FirestoreService.nextId('sales');

    await db.runTransaction((txn) async {
      int idOffset = 0;
      for (var sale in sales) {
        final id = sale.id ?? (startId + idOffset++);
        final saleRef = db.collection('sales').doc(id.toString());
        final productRef = db.collection('products').doc(sale.productId.toString());

        final productSnap = await txn.get(productRef);
        if (!productSnap.exists) {
          throw Exception('Không tìm thấy sản phẩm ID: ${sale.productId}');
        }

        final currentQty = (productSnap.data()?['quantity'] as num?)?.toInt() ?? 0;
        if (sale.quantity > currentQty) {
          throw Exception('Sản phẩm ${productSnap.data()?['name']} không đủ hàng trong kho');
        }

        txn.set(saleRef, {...sale.toMap(), 'id': id});
        txn.update(productRef, {'quantity': currentQty - sale.quantity});
      }
    });
  }

  Future<double> getTotalProfit() async {
    final result = await FirestoreService.collection('sales').get();
    return result.docs.fold<double>(
      0,
      (total, doc) => total + ((doc.data()['profit'] as num?)?.toDouble() ?? 0),
    );
  }
}
