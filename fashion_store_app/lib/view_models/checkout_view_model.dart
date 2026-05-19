import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants.dart';
import '../core/mvvm/base_view_model.dart';
import '../models/cart_item_model.dart';
import '../models/user_profile_model.dart';
import '../services/firestore_service.dart';

class CheckoutViewModel extends BaseViewModel {
  final FirestoreService _firestoreService = FirestoreService.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<CartItemModel> _items = [];
  UserProfileModel? _profile;
  StreamSubscription<List<CartItemModel>>? _cartSub;
  StreamSubscription<UserProfileModel?>? _profileSub;

  static const double _shippingValue = 10.0;
  static const double _taxRate = 0.08;

  CheckoutViewModel() {
    _listenData();
  }

  String get shippingTitle => _profile?.defaultAddress?.title ?? 'Home';
  String get shippingSubtitle => _profile?.defaultAddress == null
      ? 'Please add a shipping address'
      : '${_profile!.defaultAddress!.addressLine1}\n${_profile!.defaultAddress!.addressLine2}';

  String get paymentTitle => 'Visa ending in 4242';
  String get paymentSubtitle => 'Expires 12/24';

  double get subtotalValue => _items.fold(0, (sum, item) => sum + item.lineTotal);
  double get shippingValue => _items.isEmpty ? 0 : _shippingValue;
  double get taxValue => subtotalValue * _taxRate;
  double get totalValue => subtotalValue + shippingValue + taxValue;

  String get subtotal => '${AppConstants.currency} ${subtotalValue.toStringAsFixed(2)}';
  String get shipping => '${AppConstants.currency} ${shippingValue.toStringAsFixed(2)}';
  String get tax => '${AppConstants.currency} ${taxValue.toStringAsFixed(2)}';
  String get total => '${AppConstants.currency} ${totalValue.toStringAsFixed(2)}';

  Future<String?> placeOrder() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      setError('Please login to place your order.');
      return null;
    }
    if (_items.isEmpty) {
      setError('Your cart is empty.');
      return null;
    }

    try {
      setBusy(true);
      final orderId = await _firestoreService.placeOrder(
        uid: uid,
        items: _items,
        shippingTitle: shippingTitle,
        shippingSubtitle: shippingSubtitle,
        paymentTitle: paymentTitle,
        paymentSubtitle: paymentSubtitle,
        shipping: shippingValue,
        tax: taxValue,
      );
      return orderId;
    } catch (error) {
      setError(error.toString());
      return null;
    } finally {
      setBusy(false);
    }
  }

  void _listenData() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return;
    }

    _cartSub?.cancel();
    _cartSub = _firestoreService.streamCart(uid).listen((items) {
      _items = items;
      notifyListeners();
    });

    _profileSub?.cancel();
    _profileSub = _firestoreService.streamUserProfile(uid).listen((profile) {
      _profile = profile;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _cartSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}
