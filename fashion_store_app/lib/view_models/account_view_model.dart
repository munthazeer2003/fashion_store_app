import '../core/constants.dart';
import '../core/mvvm/base_view_model.dart';

class AccountViewModel extends BaseViewModel {
  String get userName => AppConstants.userName;
  String get userEmail => AppConstants.userEmail;
  String get profileImage => 'assets/images/profile/profile.png';
}
