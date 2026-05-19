import 'product_model.dart';

class CartItemModel {
  final String productId;
  final String name;
  final String image;
  final double price;
  final int quantity;
  final String category;

  const CartItemModel({
    required this.productId,
    required this.name,
    required this.image,
    required this.price,
    required this.quantity,
    required this.category,
  });

  bool get isNetworkImage => image.startsWith('http://') || image.startsWith('https://');

  double get lineTotal => price * quantity;

  factory CartItemModel.fromProduct(Product product, {int quantity = 1}) {
    return CartItemModel(
      productId: product.id,
      name: product.name,
      image: product.image,
      price: product.price,
      quantity: quantity,
      category: product.category,
    );
  }

  factory CartItemModel.fromMap(String id, Map<String, dynamic> map) {
    return CartItemModel(
      productId: id,
      name: (map['name'] ?? '') as String,
      image: (map['imageUrl'] ?? map['image'] ?? '') as String,
      price: ((map['price'] ?? 0) as num).toDouble(),
      quantity: (map['quantity'] ?? 1) as int,
      category: (map['category'] ?? 'Other') as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageUrl': image,
      'price': price,
      'quantity': quantity,
      'category': category,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  CartItemModel copyWith({int? quantity}) {
    return CartItemModel(
      productId: productId,
      name: name,
      image: image,
      price: price,
      quantity: quantity ?? this.quantity,
      category: category,
    );
  }
}
