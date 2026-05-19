import '../data/dummy_products.dart';
import '../models/product_model.dart';
import 'product_catalog_view_model.dart';

class HomeViewModel extends ProductCatalogViewModel {
  List<Product> get popularProducts => dummyProducts;
  List<Product> get newArrivals => dummyProducts;
}
