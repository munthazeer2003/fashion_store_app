import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants.dart';
import '../data/dummy_products.dart';
import '../models/cart_item_model.dart';
import '../models/category_model.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../models/user_profile_model.dart';

class FirestoreService {
  FirestoreService._();

  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users => _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _products => _firestore.collection('products');
  CollectionReference<Map<String, dynamic>> get _categories => _firestore.collection('categories');
  CollectionReference<Map<String, dynamic>> get _orders => _firestore.collection('orders');

  CollectionReference<Map<String, dynamic>> _cartItems(String uid) {
    return _firestore.collection('carts').doc(uid).collection('items');
  }

  Stream<List<Product>> streamProducts() {
    return _products.snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return _fallbackProducts;
      }
      return snapshot.docs
          .map((doc) => Product.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  List<Product> get _fallbackProducts => dummyProducts
      .asMap()
      .entries
      .map((entry) => Product(
            id: 'local_${entry.key}',
            name: entry.value.name,
            price: entry.value.price,
            image: entry.value.image,
            category: entry.value.category,
            description: entry.value.description,
            isPopular: entry.value.isPopular,
            isNewArrival: entry.value.isNewArrival,
          ))
      .toList();

  Stream<List<CategoryModel>> streamCategories() {
    return _categories.snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return AppConstants.categories
            .map((name) => CategoryModel(id: name.toLowerCase(), name: name))
            .toList();
      }
      return snapshot.docs
          .map((doc) => CategoryModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Stream<List<CartItemModel>> streamCart(String uid) {
    return _cartItems(uid).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => CartItemModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> addToCart({
    required String uid,
    required Product product,
    int quantity = 1,
  }) async {
    final ref = _cartItems(uid).doc(product.id);
    final existing = await ref.get();
    if (existing.exists) {
      final current = CartItemModel.fromMap(existing.id, existing.data()!);
      await ref.update({'quantity': current.quantity + quantity, 'updatedAt': DateTime.now().toIso8601String()});
      return;
    }
    final item = CartItemModel.fromProduct(product, quantity: quantity);
    await ref.set(item.toMap());
  }

  Future<void> updateCartQuantity({
    required String uid,
    required String productId,
    required int quantity,
  }) async {
    final ref = _cartItems(uid).doc(productId);
    if (quantity <= 0) {
      await ref.delete();
      return;
    }
    await ref.update({'quantity': quantity, 'updatedAt': DateTime.now().toIso8601String()});
  }

  Future<void> removeCartItem({required String uid, required String productId}) {
    return _cartItems(uid).doc(productId).delete();
  }

  Future<void> clearCart(String uid) async {
    final snapshot = await _cartItems(uid).get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> ensureUserProfile({
    required String uid,
    required String email,
    String? name,
  }) async {
    final ref = _users.doc(uid);
    final snapshot = await ref.get();
    if (snapshot.exists) {
      return;
    }
    final profile = UserProfileModel(
      uid: uid,
      name: name == null || name.trim().isEmpty ? 'New User' : name.trim(),
      email: email,
      phone: '',
      profileImageUrl: '',
      addresses: const [],
    );
    await ref.set(profile.toMap());
  }

  Stream<UserProfileModel?> streamUserProfile(String uid) {
    return _users.doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) {
        return null;
      }
      return UserProfileModel.fromMap(snapshot.id, data);
    });
  }

  Future<void> updateUserProfile({required UserProfileModel profile}) {
    return _users.doc(profile.uid).set(profile.toMap(), SetOptions(merge: true));
  }

  Future<String> placeOrder({
    required String uid,
    required List<CartItemModel> items,
    required String shippingTitle,
    required String shippingSubtitle,
    required String paymentTitle,
    required String paymentSubtitle,
    required double shipping,
    required double tax,
  }) async {
    final subtotal = items.fold<double>(0, (sum, item) => sum + item.lineTotal);
    final total = subtotal + shipping + tax;

    final doc = _orders.doc();
    final order = OrderModel(
      id: doc.id,
      userId: uid,
      items: items,
      subtotal: subtotal,
      shipping: shipping,
      tax: tax,
      total: total,
      shippingTitle: shippingTitle,
      shippingSubtitle: shippingSubtitle,
      paymentTitle: paymentTitle,
      paymentSubtitle: paymentSubtitle,
      createdAt: DateTime.now(),
      status: OrderStatus.active,
    );

    await doc.set(order.toMap());
    await clearCart(uid);
    return doc.id;
  }

  Stream<List<OrderModel>> streamOrders(String uid) {
    return _orders
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => OrderModel.fromMap(doc.id, doc.data())).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }
}
