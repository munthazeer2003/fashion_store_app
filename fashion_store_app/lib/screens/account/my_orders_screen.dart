import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/mvvm/view_model_builder.dart';
import '../../view_models/my_orders_view_model.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  static const _accentColor = Color(0xFFF26B3A);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return DefaultTabController(
      length: 3,
      child: ViewModelBuilder<MyOrdersViewModel>(
        create: (_) => MyOrdersViewModel(),
        builder: (context, viewModel, child) {
          if (user == null) {
            return Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                elevation: 0,
                backgroundColor: Colors.white,
                leading: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                ),
                title: const Text(
                  'My Orders',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              body: const Center(
                child: Text('Please login to view your orders.'),
              ),
            );
          }

          final ordersStream = FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('orders')
              .orderBy('createdAt', descending: true)
              .snapshots();

          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.white,
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
              ),
              title: const Text(
                'My Orders',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(44),
                child: TabBar(
                  indicator: UnderlineTabIndicator(
                    borderSide: BorderSide(width: 2, color: Color(0xFFF26B3A)),
                    insets: EdgeInsets.symmetric(horizontal: 18),
                  ),
                  labelColor: _accentColor,
                  unselectedLabelColor: Colors.black54,
                  labelStyle: TextStyle(fontWeight: FontWeight.w600),
                  tabs: [
                    Tab(text: 'Active'),
                    Tab(text: 'Completed'),
                    Tab(text: 'Cancelled'),
                  ],
                ),
              ),
            ),
            body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: ordersStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!context.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to load orders: ${snapshot.error}'),
                      ),
                    );
                  });
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final orders = snapshot.data?.docs
                        .map((doc) => _OrderData.fromDoc(doc))
                        .toList() ??
                    <_OrderData>[];

                return TabBarView(
                  children: [
                    _buildOrdersList(
                      orders.where((o) => o.status == _OrderStatus.active).toList(),
                    ),
                    _buildOrdersList(
                      orders
                          .where((o) => o.status == _OrderStatus.completed)
                          .toList(),
                    ),
                    _buildOrdersList(
                      orders
                          .where((o) => o.status == _OrderStatus.cancelled)
                          .toList(),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrdersList(List<_OrderData> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Text(
          'No orders here yet',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      itemCount: orders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(context, order);
      },
    );
  }

  Widget _buildOrderCard(BuildContext context, _OrderData order) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _OrderImage(image: order.firstImage),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order ${order.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${order.itemsCount} items - LKR ${order.total.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusBackground(order.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusLabel(order.status),
                        style: TextStyle(
                          color: statusText(order.status),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 16, color: Color(0xFFEDEDED)),
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderDetailsScreen(order: order),
                  ),
                );
              },
              style: TextButton.styleFrom(foregroundColor: _accentColor),
              child: const Text(
                'View Details',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color statusBackground(_OrderStatus status) {
  switch (status) {
    case _OrderStatus.active:
      return const Color(0xFFE4F4F7);
    case _OrderStatus.completed:
      return const Color(0xFFEAF7EC);
    case _OrderStatus.cancelled:
      return const Color(0xFFFFEFEF);
  }
}

Color statusText(_OrderStatus status) {
  switch (status) {
    case _OrderStatus.active:
      return const Color(0xFF3B9FB1);
    case _OrderStatus.completed:
      return const Color(0xFF3B8A4B);
    case _OrderStatus.cancelled:
      return const Color(0xFFC23B3B);
  }
}

String statusLabel(_OrderStatus status) {
  switch (status) {
    case _OrderStatus.active:
      return 'Active';
    case _OrderStatus.completed:
      return 'Completed';
    case _OrderStatus.cancelled:
      return 'Cancelled';
  }
}

class OrderDetailsScreen extends StatelessWidget {
  final _OrderData order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFF26B3A);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
        ),
        title: Text(
          'Order ${order.id}',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF0F0F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _OrderImage(image: order.firstImage),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Order Summary',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${order.itemsCount} items - LKR ${order.total.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusBackground(order.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusLabel(order.status),
                        style: TextStyle(
                          color: statusText(order.status),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Total: LKR ${order.total.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF0F0F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Items',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 10),
                if (order.items.isEmpty)
                  const Text('No item details available.')
                else
                  ...order.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Text('x${item.quantity}'),
                          const SizedBox(width: 10),
                          Text('LKR ${item.price.toStringAsFixed(2)}'),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Back to Orders',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderData {
  _OrderData({
    required this.id,
    required this.itemsCount,
    required this.total,
    required this.status,
    required this.items,
  });

  factory _OrderData.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final rawItems = (data['items'] as List<dynamic>?) ?? [];

    final items = rawItems.map((entry) {
      final map = entry is Map
          ? Map<String, dynamic>.from(entry)
          : <String, dynamic>{};
      return _OrderLine(
        name: (map['name'] as String?) ?? 'Unknown Item',
        image: (map['image'] as String?) ?? '',
        quantity: (map['quantity'] as int?) ?? 1,
        price: (map['price'] as num?)?.toDouble() ?? 0,
      );
    }).toList();

    return _OrderData(
      id: (data['orderId'] as String?) ?? doc.id,
      itemsCount: (data['itemsCount'] as int?) ??
          items.fold<int>(0, (sum, i) => sum + i.quantity),
      total: (data['total'] as num?)?.toDouble() ?? 0,
      status: _OrderStatusX.fromString((data['status'] as String?) ?? 'active'),
      items: items,
    );
  }

  final String id;
  final int itemsCount;
  final double total;
  final _OrderStatus status;
  final List<_OrderLine> items;

  String get firstImage => items.isNotEmpty ? items.first.image : '';
}

class _OrderLine {
  _OrderLine({
    required this.name,
    required this.image,
    required this.quantity,
    required this.price,
  });

  final String name;
  final String image;
  final int quantity;
  final double price;
}

enum _OrderStatus { active, completed, cancelled }

extension _OrderStatusX on _OrderStatus {
  static _OrderStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'completed':
        return _OrderStatus.completed;
      case 'cancelled':
        return _OrderStatus.cancelled;
      case 'active':
      default:
        return _OrderStatus.active;
    }
  }
}

class _OrderImage extends StatelessWidget {
  const _OrderImage({required this.image});

  final String image;

  @override
  Widget build(BuildContext context) {
    final isNetwork = image.startsWith('http://') || image.startsWith('https://');

    if (isNetwork) {
      return Image.network(
        image,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    return Image.asset(
      image,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() {
    return const Icon(Icons.image_not_supported, color: Colors.black26);
  }
}
