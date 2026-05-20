// ignore_for_file: public_member_api_docs, sort_constructors_first
class Imports {
  int? id;
  int productId;
  int quantity;
  double importPrice;
  String date;
  String? productName; // Thêm trường này để hiển thị tên sản phẩm

  Imports({
    this.id,
    required this.productId,
    required this.quantity,
    required this.importPrice,
    required this.date,
    this.productName,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'productId': productId,
      'quantity': quantity,
      'importPrice': importPrice,
      'date': date,
    };
  }

  factory Imports.fromMap(Map<String, dynamic> map) {
    int? readInt(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    double readDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    return Imports(
      id: readInt(map['id']),
      productId: readInt(map['productId']) ?? 0,
      quantity: readInt(map['quantity']) ?? 0,
      importPrice: readDouble(map['importPrice']),
      date: map['date']?.toString() ?? '',
    );
  }
}
