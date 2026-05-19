import 'package:flutter/material.dart';

import '../../core/mvvm/view_model_builder.dart';
import '../../core/navigation/app_navigator.dart';
import '../../models/product_model.dart';
import '../../view_models/product_catalog_view_model.dart';
import '../widgets/animated_product_card.dart';

class ProductListScreen extends StatelessWidget {
  final String title;

  const ProductListScreen({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ProductCatalogViewModel>(
      create: (_) => ProductCatalogViewModel(),
      builder: (context, viewModel, child) {
        final normalized = title.toLowerCase();
        final List<Product> filteredProducts = viewModel.products.where((product) {
          return product.name.toLowerCase().contains(normalized) ||
              product.category.toLowerCase().contains(normalized);
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
          ),
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.builder(
              itemCount: filteredProducts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final Product product = filteredProducts[index];
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
      },
    );
  }
}
