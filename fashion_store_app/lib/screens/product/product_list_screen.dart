import 'package:flutter/material.dart';
import '../../core/navigation/app_navigator.dart';
import '../../data/dummy_products.dart';
import '../../models/product_model.dart';
import '../widgets/animated_product_card.dart';

class ProductListScreen extends StatelessWidget {
  final String title;

  const ProductListScreen({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          itemCount: dummyProducts.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final Product product = dummyProducts[index];
            return AnimatedProductCard(
              product: product,
              onTap: () {
                AppNavigator.toProductDetails(context, product);
              },
            );
          },
        ),
      ),
    );
  }
}