import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/app_routes.dart';
import '../../core/mvvm/view_model_builder.dart';
import '../../view_models/checkout_view_model.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  static const Color _accent = Color(0xFFF26B3A);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textMuted = Color(0xFF7A7A7A);
  static const Color _cardBorder = Color(0xFFE8E8E8);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalController = TextEditingController();

  bool _isPlacingOrder = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder(
    BuildContext context, {
    required double subtotal,
    required double shipping,
    required double tax,
    required double total,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to place order.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isPlacingOrder = true;
    });

    try {
      final cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart');
      final cartSnapshot = await cartRef.get();

      if (cartSnapshot.docs.isEmpty) {
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your cart is empty.')),
        );
        return;
      }

      final items = cartSnapshot.docs.map((doc) {
        final data = doc.data();
        return <String, dynamic>{
          'productId': data['productId'] ?? doc.id,
          'name': data['name'] ?? 'Unknown Product',
          'price': (data['price'] as num?)?.toDouble() ?? 0,
          'image': data['image'] ?? '',
          'quantity': (data['quantity'] as int?) ?? 1,
          'category': data['category'] ?? '',
        };
      }).toList();

      final orderRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('orders')
          .doc();

      final batch = FirebaseFirestore.instance.batch();

      batch.set(orderRef, {
        'orderId': orderRef.id,
        'status': 'active',
        'items': items,
        'subtotal': subtotal,
        'shipping': shipping,
        'tax': tax,
        'total': total,
        'itemsCount': items.fold<int>(
          0,
          (sum, item) => sum + ((item['quantity'] as int?) ?? 1),
        ),
        'delivery': {
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'city': _cityController.text.trim(),
          'postalCode': _postalController.text.trim(),
        },
        'paymentMethod': 'Visa ending in 4242',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      for (final cartItem in cartSnapshot.docs) {
        batch.delete(cartItem.reference);
      }

      await batch.commit();

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully.')),
      );

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Success'),
          content: const Text('Your order has been placed successfully.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (!context.mounted) {
        return;
      }
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.orderConfirmation,
        (route) => route.settings.name == AppRoutes.home,
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place order: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
        });
      }
    }
  }

  String _price(double value) => 'LKR ${value.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return ViewModelBuilder<CheckoutViewModel>(
      create: (_) => CheckoutViewModel(),
      builder: (context, viewModel, child) {
        if (user == null) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back,
                  color: CheckoutScreen._textPrimary,
                ),
              ),
              title: const Text(
                'Checkout',
                style: TextStyle(
                  color: CheckoutScreen._textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              centerTitle: true,
            ),
            body: const Center(child: Text('Please login to checkout.')),
          );
        }

        final cartStream = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cart')
            .snapshots();

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: cartStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to load checkout data: ${snapshot.error}'),
                  ),
                );
              });
            }

            final cartDocs = snapshot.data?.docs ?? [];
            final subtotal = cartDocs.fold<double>(
              0,
              (sum, doc) {
                final data = doc.data();
                final qty = (data['quantity'] as int?) ?? 1;
                final price = (data['price'] as num?)?.toDouble() ?? 0;
                return sum + (qty * price);
              },
            );
            final shipping = cartDocs.isEmpty ? 0.0 : 10.0;
            final tax = subtotal * 0.08;
            final total = subtotal + shipping + tax;

            return Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back,
                    color: CheckoutScreen._textPrimary,
                  ),
                ),
                title: const Text(
                  'Checkout',
                  style: TextStyle(
                    color: CheckoutScreen._textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                centerTitle: true,
              ),
              body: snapshot.connectionState == ConnectionState.waiting
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      children: [
                        const Text(
                          'Shipping Address',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: CheckoutScreen._textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Form(
                          key: _formKey,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: CheckoutScreen._cardBorder),
                            ),
                            child: Column(
                              children: [
                                _AddressField(
                                  controller: _nameController,
                                  label: 'Full Name',
                                  icon: Icons.person_outline,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Name is required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 10),
                                _AddressField(
                                  controller: _phoneController,
                                  label: 'Phone Number',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  validator: (value) {
                                    final text = value?.trim() ?? '';
                                    if (text.length < 8) {
                                      return 'Enter a valid phone number';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 10),
                                _AddressField(
                                  controller: _addressController,
                                  label: 'Street Address',
                                  icon: Icons.location_on_outlined,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Address is required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 10),
                                _AddressField(
                                  controller: _cityController,
                                  label: 'City',
                                  icon: Icons.location_city_outlined,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'City is required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 10),
                                _AddressField(
                                  controller: _postalController,
                                  label: 'Postal Code',
                                  icon: Icons.markunread_mailbox_outlined,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Postal code is required';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Payment Method',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: CheckoutScreen._textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _InfoCard(
                          leading: Image.asset(
                            'assets/images/Mastercard/visa logo.jpg',
                            width: 22,
                            height: 22,
                            fit: BoxFit.contain,
                            alignment: Alignment.center,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.credit_card,
                                color: CheckoutScreen._accent,
                                size: 18,
                              );
                            },
                          ),
                          title: 'Visa ending in 4242',
                          subtitle: 'Expires 12/24',
                          onEdit: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PaymentMethodsScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Order Summary',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: CheckoutScreen._textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: CheckoutScreen._cardBorder),
                          ),
                          child: Column(
                            children: [
                              _SummaryRow(
                                label: 'Subtotal',
                                value: _price(subtotal),
                              ),
                              const SizedBox(height: 10),
                              _SummaryRow(
                                label: 'Shipping',
                                value: _price(shipping),
                              ),
                              const SizedBox(height: 10),
                              _SummaryRow(label: 'Tax', value: _price(tax)),
                              const SizedBox(height: 12),
                              const Divider(
                                height: 1,
                                color: CheckoutScreen._cardBorder,
                              ),
                              const SizedBox(height: 12),
                              _SummaryRow(
                                label: 'Total',
                                value: _price(total),
                                highlight: true,
                              ),
                            ],
                          ),
                        ),
                        if (cartDocs.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              'Your cart is empty. Add products before placing an order.',
                              style: TextStyle(color: Colors.red.shade400),
                            ),
                          ),
                      ],
                    ),
              bottomNavigationBar: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isPlacingOrder || cartDocs.isEmpty
                          ? null
                          : () => _placeOrder(
                                context,
                                subtotal: subtotal,
                                shipping: shipping,
                                tax: tax,
                                total: total,
                              ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CheckoutScreen._accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isPlacingOrder
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text('Place Order (${_price(total)})'),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AddressField extends StatelessWidget {
  const _AddressField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.validator,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: CheckoutScreen._textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CheckoutScreen._cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CheckoutScreen._cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CheckoutScreen._accent),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onEdit,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CheckoutScreen._cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: CheckoutScreen._accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: leading),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: CheckoutScreen._textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: CheckoutScreen._textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: CheckoutScreen._accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.edit_outlined,
                color: CheckoutScreen._accent,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: highlight ? CheckoutScreen._accent : CheckoutScreen._textMuted,
            fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: highlight
                ? CheckoutScreen._accent
                : CheckoutScreen._textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: highlight ? 16 : 14,
          ),
        ),
      ],
    );
  }
}

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
        ),
        title: const Text(
          'Payment Methods',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: const [
          ListTile(
            leading: Icon(Icons.credit_card, color: Color(0xFFF26B3A)),
            title: Text('Visa ending in 4242'),
            subtitle: Text('Expires 12/24'),
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.credit_card, color: Color(0xFFF26B3A)),
            title: Text('Mastercard ending in 1122'),
            subtitle: Text('Expires 08/25'),
          ),
        ],
      ),
    );
  }
}
