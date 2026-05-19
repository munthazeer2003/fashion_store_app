import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../core/mvvm/base_view_model.dart';
import '../models/order_model.dart';
import '../services/firestore_service.dart';

class MyOrdersViewModel extends BaseViewModel {
  final FirestoreService _firestoreService = FirestoreService.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<OrderModel> _orders = [];
  StreamSubscription<List<OrderModel>>? _sub;

  MyOrdersViewModel() {
    _listenOrders();
  }

  List<OrderModel> ordersForStatus(OrderStatus status) {
    return _orders.where((order) => order.status == status).toList();
  }

  void _listenOrders() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return;
    }

    setBusy(true);
    _sub?.cancel();
    _sub = _firestoreService.streamOrders(uid).listen((orders) {
      _orders = orders;
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
