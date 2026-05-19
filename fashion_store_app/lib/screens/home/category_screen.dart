import 'package:flutter/material.dart';

import '../../core/mvvm/view_model_builder.dart';
import '../../models/product_model.dart';
import '../../view_models/product_catalog_view_model.dart';
import '../widgets/animated_product_card.dart';
import '../../core/navigation/app_navigator.dart';

class CategoryScreen extends StatelessWidget {
  final String categoryName;

  const CategoryScreen({
    super.key,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ProductCatalogViewModel>(
      create: (_) => ProductCatalogViewModel(),
      builder: (context, viewModel, child) {
        final normalizedCategory = categoryName.toLowerCase();
        final List<Product> filteredProducts = viewModel.products.where((product) {
          if (normalizedCategory == 'all') {
            return true;
          }
          if (product.category.toLowerCase() == normalizedCategory) {
            return true;
          }
          return product.name.toLowerCase().contains(normalizedCategory);
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(categoryName),
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
                final product = filteredProducts[index];
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
