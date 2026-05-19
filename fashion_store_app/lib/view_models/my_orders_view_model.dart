import '../core/mvvm/base_view_model.dart';

class MyOrdersViewModel extends BaseViewModel {
  final List<OrderItem> _orders = [
    OrderItem(
      id: '#1234',
      itemsCount: 2,
      total: 299.99,
      image: 'assets/images/products/shoes/shoe_1.jpg',
      status: OrderStatus.active,
    ),
    OrderItem(
      id: '#1235',
      itemsCount: 1,
      total: 89.50,
      image: 'assets/images/products/shoes/shoe_2.jpg',
      status: OrderStatus.active,
    ),
    OrderItem(
      id: '#1236',
      itemsCount: 3,
      total: 159.75,
      image: 'assets/images/products/women/women_dress_1.jpg',
      status: OrderStatus.completed,
    ),
    OrderItem(
      id: '#1237',
      itemsCount: 1,
      total: 49.99,
      image: 'assets/images/products/men/men_shirt_1.jpg',
      status: OrderStatus.cancelled,
    ),
  ];

  List<OrderItem> ordersForStatus(OrderStatus status) {
    return _orders.where((order) => order.status == status).toList();
  }
}

enum OrderStatus { active, completed, cancelled }

class OrderItem {
  OrderItem({
    required this.id,
    required this.itemsCount,
    required this.total,
    required this.image,
    required this.status,
  });

  final String id;
  final int itemsCount;
  final double total;
  final String image;
  final OrderStatus status;
}
