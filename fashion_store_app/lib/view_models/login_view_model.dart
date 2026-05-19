import 'package:flutter/material.dart';

import '../core/mvvm/base_view_model.dart';
import '../services/firebase_auth_service.dart';
import '../services/firebase_error_mapper.dart';
import '../services/firestore_service.dart';

class LoginViewModel extends BaseViewModel {
  final FirebaseAuthService _authService = FirebaseAuthService.instance;
  final FirestoreService _firestoreService = FirestoreService.instance;

  bool _obscurePassword = true;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool get obscurePassword => _obscurePassword;

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  Future<bool> login() async {
    clearError();
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setError('Email and password are required.');
      return false;
    }
    if (!_isValidEmail(email)) {
      setError('Please enter a valid email address.');
      return false;
    }

    try {
      setBusy(true);
      final credential = await _authService.signIn(email: email, password: password);
      if (credential.user != null) {
        await _firestoreService.ensureUserProfile(
          uid: credential.user!.uid,
          email: credential.user!.email ?? email,
        );
      }
      return true;
    } catch (error) {
      setError(mapFirebaseError(error));
      return false;
    } finally {
      setBusy(false);
    }
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return regex.hasMatch(email);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
