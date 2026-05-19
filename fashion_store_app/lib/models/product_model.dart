class Product {
  final String id;
  final String name;
  final double price;
  final String image;
  final String category;
  final String description;
  final bool isPopular;
  final bool isNewArrival;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    required this.category,
    this.description = '',
    this.isPopular = true,
    this.isNewArrival = true,
  });

  bool get isNetworkImage => image.startsWith('http://') || image.startsWith('https://');

  factory Product.fromMap(String id, Map<String, dynamic> map) {
    return Product(
      id: id,
      name: (map['name'] ?? '') as String,
      price: ((map['price'] ?? 0) as num).toDouble(),
      image: (map['imageUrl'] ?? map['image'] ?? '') as String,
      category: (map['category'] ?? 'Other') as String,
      description: (map['description'] ?? '') as String,
      isPopular: (map['isPopular'] ?? true) as bool,
      isNewArrival: (map['isNewArrival'] ?? true) as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'imageUrl': image,
      'category': category,
      'description': description,
      'isPopular': isPopular,
      'isNewArrival': isNewArrival,
    };
  }
}
