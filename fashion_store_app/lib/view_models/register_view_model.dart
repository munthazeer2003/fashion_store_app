import 'package:flutter/material.dart';

import '../core/mvvm/base_view_model.dart';
import '../services/firebase_auth_service.dart';
import '../services/firebase_error_mapper.dart';
import '../services/firestore_service.dart';

class RegisterViewModel extends BaseViewModel {
  final FirebaseAuthService _authService = FirebaseAuthService.instance;
  final FirestoreService _firestoreService = FirestoreService.instance;

  bool _passwordVisible = false;
  bool _confirmVisible = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  bool get passwordVisible => _passwordVisible;
  bool get confirmVisible => _confirmVisible;

  void togglePasswordVisibility() {
    _passwordVisible = !_passwordVisible;
    notifyListeners();
  }

  void toggleConfirmVisibility() {
    _confirmVisible = !_confirmVisible;
    notifyListeners();
  }

  Future<bool> register() async {
    clearError();
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirm = confirmController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      setError('Please fill in all fields.');
      return false;
    }
    if (!_isValidEmail(email)) {
      setError('Please enter a valid email address.');
      return false;
    }
    if (password.length < 6) {
      setError('Password must be at least 6 characters.');
      return false;
    }

    if (password != confirm) {
      setError('Passwords do not match.');
      return false;
    }

    try {
      setBusy(true);
      final credential = await _authService.register(email: email, password: password);
      await _firestoreService.ensureUserProfile(
        uid: credential.user!.uid,
        email: email,
        name: name,
      );
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
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }
}
