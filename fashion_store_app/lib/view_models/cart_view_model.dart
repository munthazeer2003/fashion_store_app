import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../core/mvvm/base_view_model.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../services/firestore_service.dart';

class CartViewModel extends BaseViewModel {
  final FirestoreService _firestoreService = FirestoreService.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<CartItemModel> _items = [];
  StreamSubscription<List<CartItemModel>>? _sub;

  CartViewModel() {
    _listenCart();
  }

  List<CartItemModel> get items => List.unmodifiable(_items);

  bool get isLoggedIn => _auth.currentUser != null;

  double get total {
    double result = 0;
    for (final item in _items) {
      result += item.lineTotal;
    }
    return result;
  }

  String? get _uid => _auth.currentUser?.uid;

  Future<bool> addProduct(Product product, {int quantity = 1}) async {
    final uid = _uid;
    if (uid == null) {
      setError('Please login to add items to cart.');
      return false;
    }
    try {
      await _firestoreService.addToCart(uid: uid, product: product, quantity: quantity);
      return true;
    } catch (error) {
      setError(error.toString());
      return false;
    }
  }

  Future<void> removeAt(int index) async {
    final uid = _uid;
    if (uid == null || index < 0 || index >= _items.length) {
      return;
    }
    await _firestoreService.removeCartItem(uid: uid, productId: _items[index].productId);
  }

  Future<void> increment(int index) async {
    final uid = _uid;
    if (uid == null || index < 0 || index >= _items.length) {
      return;
    }
    final item = _items[index];
    await _firestoreService.updateCartQuantity(
      uid: uid,
      productId: item.productId,
      quantity: item.quantity + 1,
    );
  }

  Future<void> decrement(int index) async {
    final uid = _uid;
    if (uid == null || index < 0 || index >= _items.length) {
      return;
    }
    final item = _items[index];
    await _firestoreService.updateCartQuantity(
      uid: uid,
      productId: item.productId,
      quantity: item.quantity - 1,
    );
  }

  void _listenCart() {
    final uid = _uid;
    if (uid == null) {
      _items = [];
      notifyListeners();
      return;
    }

    setBusy(true);
    _sub?.cancel();
    _sub = _firestoreService.streamCart(uid).listen((items) {
      _items = items;
      setBusy(false);
    }, onError: (error) {
      setBusy(false);
      setError(error.toString());
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
