abstract class LoginState {}

class LoginInitialState extends LoginState {}

class LoginLoadingState extends LoginState {}

class LoginNotLoadingState extends LoginState {}

// حالة عند تغيير حالة عرض كلمة المرور مع تمرير القيمة الحالية
class LoginTogglePasswordState extends LoginState {
  final bool obscurePassword;
  LoginTogglePasswordState(this.obscurePassword);
}
