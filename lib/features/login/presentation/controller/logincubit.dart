import 'package:flutter_bloc/flutter_bloc.dart';
import 'loginstate.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit() : super(LoginInitialState());

  bool isLoading = false;
  bool obscurePassword = true;  // حالة إظهار أو إخفاء كلمة المرور

  void loginLoading() {
    isLoading = true;
    emit(LoginLoadingState());
  }

  void loginNotLoading() {
    isLoading = false;
    emit(LoginNotLoadingState());
  }

  // دالة لتغيير حالة إظهار كلمة المرور
  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    emit(LoginTogglePasswordState(obscurePassword));
  }
}
