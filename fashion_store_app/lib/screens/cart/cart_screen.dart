import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/app_routes.dart';
import '../../core/mvvm/view_model_builder.dart';
import '../../view_models/cart_view_model.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  static const _accentColor = Color(0xFFF26B3A);

  Future<void> _updateQuantity({
    required String docId,
    required int quantity,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .doc(docId)
        .update({'quantity': quantity, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> _removeItem(String docId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return ViewModelBuilder<CartViewModel>(
      create: (_) => CartViewModel(),
      builder: (context, viewModel, child) {
        if (user == null) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: const Text('My Cart'),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: const Center(
              child: Text('Please login to view your cart.'),
            ),
          );
        }

        final cartStream = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cart')
            .orderBy('updatedAt', descending: true)
            .snapshots();

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('My Cart'),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: cartStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to load cart: ${snapshot.error}'),
                    ),
                  );
                });
                return const Center(child: Text('Unable to load cart items.'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final items = snapshot.data?.docs
                      .map((doc) => _CartLine.fromDoc(doc))
                      .toList() ??
                  <_CartLine>[];

              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 56,
                        color: Colors.black26,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Your cart is empty',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _buildCartRow(
                    item,
                    onRemove: () async {
                      try {
                        await _removeItem(item.docId);
                      } catch (e) {
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to remove item: $e')),
                        );
                      }
                    },
                    onIncrement: () async {
                      try {
                        await _updateQuantity(
                          docId: item.docId,
                          quantity: item.quantity + 1,
                        );
                      } catch (e) {
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to update item: $e')),
                        );
                      }
                    },
                    onDecrement: () async {
                      if (item.quantity <= 1) {
                        return;
                      }
                      try {
                        await _updateQuantity(
                          docId: item.docId,
                          quantity: item.quantity - 1,
                        );
                      } catch (e) {
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to update item: $e')),
                        );
                      }
                    },
                  );
                },
              );
            },
          ),
          bottomNavigationBar: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: cartStream,
            builder: (context, snapshot) {
              final items = snapshot.data?.docs
                      .map((doc) => _CartLine.fromDoc(doc))
                      .toList() ??
                  <_CartLine>[];
              return _buildSummaryBar(context, items, _accentColor);
            },
          ),
        );
      },
    );
  }

  Widget _buildSummaryBar(
    BuildContext context,
    List<_CartLine> items,
    Color accentColor,
  ) {
    final total = items.fold<double>(
      0,
      (sum, item) => sum + item.price * item.quantity,
    );

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'LKR ${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: items.isEmpty
                  ? null
                  : () {
                      Navigator.pushNamed(context, AppRoutes.checkout);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Checkout'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartRow(
    _CartLine item, {
    required VoidCallback onRemove,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _CartImage(image: item.image),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'LKR ${item.price.toStringAsFixed(1)}',
                  style: const TextStyle(
                    color: _accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, color: _accentColor),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFBE9E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildQtyButton(
                      icon: Icons.remove,
                      onTap: onDecrement,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    _buildQtyButton(
                      icon: Icons.add,
                      onTap: onIncrement,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQtyButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Icon(icon, size: 16, color: const Color(0xFFF26B3A)),
      ),
    );
  }
}

class _CartLine {
  _CartLine({
    required this.docId,
    required this.name,
    required this.price,
    required this.image,
    required this.quantity,
  });

  factory _CartLine.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return _CartLine(
      docId: doc.id,
      name: (data['name'] as String?) ?? 'Unknown Product',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      image: (data['image'] as String?) ?? '',
      quantity: (data['quantity'] as int?) ?? 1,
    );
  }

  final String docId;
  final String name;
  final double price;
  final String image;
  final int quantity;
}

class _CartImage extends StatelessWidget {
  const _CartImage({required this.image});

  final String image;

  @override
  Widget build(BuildContext context) {
    final isNetwork = image.startsWith('http://') || image.startsWith('https://');
    if (isNetwork) {
      return Image.network(
        image,
        width: 64,
        height: 64,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    return Image.asset(
      image,
      width: 64,
      height: 64,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      width: 64,
      height: 64,
      color: const Color(0xFFF2F2F2),
      child: const Icon(Icons.image_not_supported, size: 20),
    );
  }
}
