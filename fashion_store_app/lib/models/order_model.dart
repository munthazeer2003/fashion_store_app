import 'cart_item_model.dart';

enum OrderStatus { active, completed, cancelled }

class OrderModel {
  final String id;
  final String userId;
  final List<CartItemModel> items;
  final double subtotal;
  final double shipping;
  final double tax;
  final double total;
  final String shippingTitle;
  final String shippingSubtitle;
  final String paymentTitle;
  final String paymentSubtitle;
  final DateTime createdAt;
  final OrderStatus status;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.shipping,
    required this.tax,
    required this.total,
    required this.shippingTitle,
    required this.shippingSubtitle,
    required this.paymentTitle,
    required this.paymentSubtitle,
    required this.createdAt,
    required this.status,
  });

  int get itemsCount => items.fold(0, (sum, item) => sum + item.quantity);

  String get previewImage => items.isEmpty ? '' : items.first.image;

  factory OrderModel.fromMap(String id, Map<String, dynamic> map) {
    final rawItems = (map['items'] as List<dynamic>? ?? const []);
    final items = rawItems
        .map((e) => CartItemModel.fromMap(
              (e['productId'] ?? '') as String,
              Map<String, dynamic>.from(e as Map),
            ))
        .toList();

    final statusValue = (map['status'] ?? 'active') as String;

    return OrderModel(
      id: id,
      userId: (map['userId'] ?? '') as String,
      items: items,
      subtotal: ((map['subtotal'] ?? 0) as num).toDouble(),
      shipping: ((map['shipping'] ?? 0) as num).toDouble(),
      tax: ((map['tax'] ?? 0) as num).toDouble(),
      total: ((map['total'] ?? 0) as num).toDouble(),
      shippingTitle: (map['shippingTitle'] ?? 'Home') as String,
      shippingSubtitle: (map['shippingSubtitle'] ?? '') as String,
      paymentTitle: (map['paymentTitle'] ?? 'Card') as String,
      paymentSubtitle: (map['paymentSubtitle'] ?? '') as String,
      createdAt: DateTime.tryParse((map['createdAt'] ?? '') as String) ?? DateTime.now(),
      status: switch (statusValue) {
        'completed' => OrderStatus.completed,
        'cancelled' => OrderStatus.cancelled,
        _ => OrderStatus.active,
      },
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'items': items
          .map((item) => {
                'productId': item.productId,
                ...item.toMap(),
              })
          .toList(),
      'subtotal': subtotal,
      'shipping': shipping,
      'tax': tax,
      'total': total,
      'shippingTitle': shippingTitle,
      'shippingSubtitle': shippingSubtitle,
      'paymentTitle': paymentTitle,
      'paymentSubtitle': paymentSubtitle,
      'status': switch (status) {
        OrderStatus.active => 'active',
        OrderStatus.completed => 'completed',
        OrderStatus.cancelled => 'cancelled',
      },
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
