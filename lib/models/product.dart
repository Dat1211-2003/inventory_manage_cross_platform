import 'dart:convert';

class Product {
  int? id;
  String barcode;
  String name;
  String companyName;
  String image;
  List<String> galleryImages;
  String expiryDate;
  String manufacturingDate;
  String? specifications;
  int quantity;
  double? costPrice;
  double? sellPrice;
  int? categoryId;
  String? createAt;

  double? importPrice; // Thêm giá nhập mới nhất
  String? lastImportDate; // Thêm ngày nhập gần nhất

  Product({
    this.id,
    required this.barcode,
    required this.name,
    required this.companyName,
    this.specifications,
    required this.image,
    this.galleryImages = const [],
    required this.expiryDate,
    required this.manufacturingDate,
    int? quantity,
    this.costPrice,
    this.sellPrice,
    this.importPrice,
    this.lastImportDate,
    this.categoryId,
    this.createAt,
  }) : quantity = quantity ?? 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'company_name': companyName,
      'specifications': specifications,
      'image': image,
      'gallery_images': galleryImages,
      'expiry_date': expiryDate,
      'manufacturing_date': manufacturingDate,
      'quantity': quantity,
      'costPrice': costPrice,
      'sellPrice': sellPrice,
      'categoryId': categoryId,
      'createAt': createAt,

      'importPrice': importPrice,
      'lastImportDate': lastImportDate,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    int? readInt(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    List<String> readGalleryImages(dynamic raw) {
      if (raw == null) {
        return [];
      }

      if (raw is List) {
        return raw
            .map((item) => item.toString())
            .where((path) => path.trim().isNotEmpty)
            .toList();
      }

      if (raw is String && raw.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is List) {
            return decoded
                .map((item) => item.toString())
                .where((path) => path.trim().isNotEmpty)
                .toList();
          }
        } catch (_) {
          return [];
        }
      }

      return [];
    }

    double? readDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    return Product(
      id: readInt(map['id']),
      barcode: map['barcode']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      companyName: map['company_name']?.toString() ?? '',
      specifications: map['specifications']?.toString(),
      image: map['image']?.toString() ?? '',
      galleryImages: readGalleryImages(map['gallery_images']),
      expiryDate: map['expiry_date']?.toString() ?? '',
      manufacturingDate: map['manufacturing_date']?.toString() ?? '',
      quantity: readInt(map['quantity']) ?? 0,
      costPrice: readDouble(map['costPrice']),
      sellPrice: readDouble(map['sellPrice']),
      categoryId: readInt(map['categoryId']),
      createAt: map['createAt']?.toString(),
      importPrice: readDouble(map['importPrice']),
      lastImportDate: map['lastImportDate']?.toString(),
    );
  }
}
