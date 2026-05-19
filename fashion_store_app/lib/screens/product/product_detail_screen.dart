import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_routes.dart';
import '../../core/constants.dart';
import '../../core/mvvm/view_model_builder.dart';
import '../../models/product_model.dart';
import '../../view_models/product_detail_view_model.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  static const _accentColor = Color(0xFFF26B3A);

  String _productDocId(String name) {
    return name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }

  Future<Map<String, dynamic>?> _loadProductData() async {
    final docId = _productDocId(product.name);
    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .doc(docId)
        .get();
    if (!snapshot.exists) {
      return null;
    }
    return snapshot.data();
  }

  Future<void> _addToCart({
    required BuildContext context,
    required ProductDetailViewModel viewModel,
    required Product resolvedProduct,
    required int quantity,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to add items to cart.')),
      );
      return;
    }

    try {
      viewModel.setBusy(true);
      final docId = _productDocId(resolvedProduct.name);
      final cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(docId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final current = await transaction.get(cartRef);
        final currentQty = (current.data()?['quantity'] as int?) ?? 0;
        transaction.set(cartRef, {
          'productId': docId,
          'name': resolvedProduct.name,
          'price': resolvedProduct.price,
          'image': resolvedProduct.image,
          'category': resolvedProduct.category,
          'quantity': currentQty + quantity,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });

      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to cart successfully.')),
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add to cart: $e')),
      );
    } finally {
      viewModel.setBusy(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ProductDetailViewModel>(
      create: (_) => ProductDetailViewModel(),
      builder: (context, viewModel, child) {
        return FutureBuilder<Map<String, dynamic>?>(
          future: _loadProductData(),
          builder: (context, snapshot) {
            final firestoreData = snapshot.data;
            final resolvedProduct = Product(
              name: (firestoreData?['name'] as String?) ?? product.name,
              price:
                  (firestoreData?['price'] as num?)?.toDouble() ?? product.price,
              image: (firestoreData?['image'] as String?) ?? product.image,
              category:
                  (firestoreData?['category'] as String?) ?? product.category,
            );
            final description =
                (firestoreData?['description'] as String?)?.trim().isNotEmpty ==
                    true
                ? firestoreData!['description'] as String
                : 'Premium quality ${resolvedProduct.name} for everyday comfort and style.';

            return Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                elevation: 0,
                backgroundColor: Colors.white,
                centerTitle: true,
                title: const Text(
                  'Details',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                leading: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                ),
                actions: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ShareProductScreen(
                            product: resolvedProduct,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.share, color: Colors.black87),
                  ),
                  IconButton(
                    onPressed: viewModel.toggleFavorite,
                    icon: Icon(
                      viewModel.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: viewModel.isFavorite
                          ? _accentColor
                          : Colors.black87,
                    ),
                  ),
                ],
              ),
              body: SafeArea(
                child: snapshot.connectionState == ConnectionState.waiting
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 260,
                            width: double.infinity,
                            color: const Color(0xFFF8F8F8),
                            child: Hero(
                              tag: product.image,
                              child: _ProductImage(imagePath: resolvedProduct.image),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      resolvedProduct.name,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      resolvedProduct.category,
                                      style: const TextStyle(color: Colors.black54),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${AppConstants.currency} ${resolvedProduct.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Select Size',
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      height: 40,
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: viewModel.sizes.length,
                                        separatorBuilder: (context, index) =>
                                            const SizedBox(width: 10),
                                        itemBuilder: (context, index) {
                                          final isSelected =
                                              viewModel.selectedSizeIndex == index;
                                          return GestureDetector(
                                            onTap: () => viewModel.selectSize(index),
                                            child: Container(
                                              width: 46,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? _accentColor
                                                    : Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: isSelected
                                                      ? _accentColor
                                                      : Colors.grey.shade300,
                                                ),
                                              ),
                                              child: isSelected
                                                  ? const Icon(
                                                      Icons.check,
                                                      color: Colors.white,
                                                      size: 16,
                                                    )
                                                  : Text(
                                                      viewModel.sizes[index],
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    const Text(
                                      'Quantity',
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        _QtyButton(
                                          icon: Icons.remove,
                                          onTap: viewModel.decrementQuantity,
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          child: Text(
                                            '${viewModel.quantity}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        _QtyButton(
                                          icon: Icons.add,
                                          onTap: viewModel.incrementQuantity,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 18),
                                    const Text(
                                      'Description',
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      description,
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        height: 1.4,
                                      ),
                                    ),
                                    if (snapshot.hasError)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: Text(
                                          'Unable to refresh product from server, showing available details.',
                                          style: TextStyle(
                                            color: Colors.red.shade400,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              bottomNavigationBar: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: viewModel.isBusy
                              ? null
                              : () async {
                                  await _addToCart(
                                    context: context,
                                    viewModel: viewModel,
                                    resolvedProduct: resolvedProduct,
                                    quantity: viewModel.quantity,
                                  );
                                  if (!context.mounted) {
                                    return;
                                  }
                                  Navigator.pushNamed(context, AppRoutes.cart);
                                },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: viewModel.isBusy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Add To Cart'),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: viewModel.isBusy
                              ? null
                              : () async {
                                  await _addToCart(
                                    context: context,
                                    viewModel: viewModel,
                                    resolvedProduct: resolvedProduct,
                                    quantity: viewModel.quantity,
                                  );
                                  if (!context.mounted) {
                                    return;
                                  }
                                  Navigator.pushNamed(context, AppRoutes.checkout);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Text('Buy Now'),
                        ),
                      ),
                    ],
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

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final isNetwork = imagePath.startsWith('http://') ||
        imagePath.startsWith('https://');

    if (isNetwork) {
      return Image.network(
        imagePath,
        width: double.infinity,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    return Image.asset(
      imagePath,
      width: double.infinity,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      color: const Color(0xFFF2F2F2),
      child: const Center(
        child: Icon(
          Icons.image_not_supported,
          color: Colors.black26,
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFBE9E2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFFF26B3A)),
      ),
    );
  }
}

class ShareProductScreen extends StatelessWidget {
  final Product product;

  const ShareProductScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final link =
        'https://fashion-store.app/products?name=${Uri.encodeComponent(product.name)}';
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
          'Share Product',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(link, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: link));
                  if (!context.mounted) {
                    return;
                  }
                  showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Link Copied'),
                      content: const Text(
                        'The product link is ready to share.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF26B3A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Copy Link'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
