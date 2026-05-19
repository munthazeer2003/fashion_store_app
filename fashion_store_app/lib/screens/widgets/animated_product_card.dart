import 'package:flutter/material.dart';
import '../../models/product_model.dart';

class AnimatedProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const AnimatedProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: product.image,
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.asset(
                  product.image,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFFF2F2F2),
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.black26,
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                product.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('LKR ${product.price}'),
            ),
          ],
        ),
      ),
    );
  }
}
