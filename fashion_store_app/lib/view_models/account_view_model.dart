import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../core/mvvm/base_view_model.dart';
import '../models/user_profile_model.dart';
import '../services/firebase_auth_service.dart';
import '../services/firebase_error_mapper.dart';
import '../services/firestore_service.dart';

class AccountViewModel extends BaseViewModel {
  final FirebaseAuthService _authService = FirebaseAuthService.instance;
  final FirestoreService _firestoreService = FirestoreService.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserProfileModel? _profile;
  StreamSubscription<UserProfileModel?>? _sub;

  AccountViewModel() {
    _listenProfile();
  }

  String get userName => _profile?.name ?? 'Guest User';
  String get userEmail => _profile?.email ?? (_auth.currentUser?.email ?? 'No email');
  String get profileImage => _profile?.profileImageUrl ?? '';
  bool get hasNetworkProfileImage => profileImage.startsWith('http://') || profileImage.startsWith('https://');

  Future<bool> logout() async {
    clearError();
    try {
      setBusy(true);
      await _authService.signOut();
      return true;
    } catch (error) {
      setError(mapFirebaseError(error));
      return false;
    } finally {
      setBusy(false);
    }
  }

  void _listenProfile() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      _profile = null;
      notifyListeners();
      return;
    }
    setBusy(true);
    _sub?.cancel();
    _sub = _firestoreService.streamUserProfile(uid).listen((profile) {
      _profile = profile;
      setBusy(false);
      notifyListeners();
    }, onError: (error) {
      setBusy(false);
      setError(mapFirebaseError(error));
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
