import '../core/mvvm/base_view_model.dart';

class RegisterViewModel extends BaseViewModel {
  bool _passwordVisible = false;
  bool _confirmVisible = false;

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
}
