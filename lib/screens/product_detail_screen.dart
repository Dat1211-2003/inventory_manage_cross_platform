import 'dart:io';

import 'package:flutter/material.dart';

import '../models/product.dart';
import '../repository/product_repository.dart';
import 'add_product_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Product product;
  final repo = ProductRepository();

  @override
  void initState() {
    super.initState();
    product = widget.product;
  }

  void _openImageViewer(String imagePath, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ImageViewerScreen(imagePath: imagePath, title: title),
      ),
    );
  }

  Future<void> _editProduct() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AddProductScreen(barcode: product.barcode, productToEdit: product),
      ),
    );

    if (result == true) {
      final updatedProduct = await repo.getByBarcode(product.barcode);
      if (updatedProduct != null && mounted) {
        setState(() {
          product = updatedProduct;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Sản phẩm đã cập nhật')));
      }
    }
  }

  void _deleteProduct() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa?'),
        content: Text('Xác nhận xóa ${product.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final productId = product.id;
              if (productId == null) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('Không thể xóa: thiếu ID sản phẩm'),
                    ),
                  );
                }
                return;
              }

              try {
                await repo.delete(productId);
                if (!mounted) return;
                Navigator.pop(context);
                Navigator.pop(this.context);
                ScaffoldMessenger.of(
                  this.context,
                ).showSnackBar(const SnackBar(content: Text('Xóa sản phẩm')));
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  this.context,
                ).showSnackBar(SnackBar(content: Text('Xóa thất bại: $e')));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B43FF),
        foregroundColor: Colors.white,
        title: const Text('Chi tiết sản phẩm'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editProduct,
            tooltip: 'Chỉnh sửa sản phẩm',
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _deleteProduct,
            tooltip: 'Xóa sản phẩm',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child:
                        product.image.isNotEmpty &&
                            File(product.image).existsSync()
                        ? GestureDetector(
                            onTap: () => _openImageViewer(
                              product.image,
                              'Ảnh bìa sản phẩm',
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(product.image),
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        : Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.image,
                              size: 80,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ảnh phụ (${product.galleryImages.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (product.galleryImages.isEmpty)
                        const Text(
                          'Chưa có ảnh phụ',
                          style: TextStyle(color: Colors.grey),
                        )
                      else
                        SizedBox(
                          height: 96,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: product.galleryImages.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              final imagePath = product.galleryImages[index];
                              final imageFile = File(imagePath);
                              if (!imageFile.existsSync()) {
                                return Container(
                                  width: 96,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.broken_image),
                                );
                              }

                              return GestureDetector(
                                onTap: () => _openImageViewer(
                                  imagePath,
                                  'Ảnh phụ ${index + 1}',
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    imageFile,
                                    width: 96,
                                    height: 96,
                                    fit: BoxFit.cover,
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
              const SizedBox(height: 20),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRow('Mã vạch', product.barcode),
                      const Divider(),
                      _buildRow('Tên', product.name),
                      const Divider(),
                      _buildRow('Công ty', product.companyName),
                      const Divider(),
                      _buildRow(
                        'Quy cách',
                        product.specifications ?? 'Chưa có',
                      ),
                      const Divider(),
                      _buildRow('Ngày sản xuất', product.manufacturingDate),
                      const Divider(),
                      _buildRow('Hạn sử dụng', product.expiryDate),

                      // them de cap nhat gia ban va gia nhap moi nhat
                      _buildRow(
                        'Giá nhập mới nhất',
                        product.importPrice != null
                            ? '${product.importPrice!.toStringAsFixed(0)} ₫'
                            : 'Chưa có',
                      ),
                      const Divider(),
                      _buildRow(
                        'Ngày nhập gần nhất',
                        product.lastImportDate ?? 'Chưa có',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _editProduct,
                      icon: const Icon(Icons.edit),
                      label: const Text('Chỉnh sửa'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _deleteProduct,
                      icon: const Icon(Icons.delete),
                      label: const Text('Xóa'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$title:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}

class _ImageViewerScreen extends StatelessWidget {
  final String imagePath;
  final String title;

  const _ImageViewerScreen({required this.imagePath, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF6B43FF),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4,
          child: Image.file(File(imagePath)),
        ),
      ),
    );
  }
}
