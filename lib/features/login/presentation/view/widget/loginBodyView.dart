import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as flutter;
import 'package:saladafactory/core/utils/styles.dart';
import 'package:saladafactory/features/login/data/services/loginService.dart';
import 'package:saladafactory/features/login/presentation/view/widget/loginBtn.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

import '../../../../profile/presentation/widget/languageDropdown.dart';

class LoginBodyView extends StatefulWidget {
  const LoginBodyView({super.key});

  @override
  State<LoginBodyView> createState() => _LoginBodyViewState();
}

class _LoginBodyViewState extends State<LoginBodyView> {
  final TextEditingController _passwordController = TextEditingController();
  List<bool> codeFilled = [false, false, false, false];
  bool isloading = false;

  // الألوان
  final Color primaryColor = const Color(0xFF74826A);
  final Color accentColor = const Color(0xFFEDBE2C);
  final Color secondaryColor = const Color(0xFFCDBCA2);
  final Color backgroundColor = const Color(0xFFF3F4EF);

  // دالة تحويل الأرقام العربية -> أرقام إنجليزية
  String normalizeNumber(String input) {
    final arabicNumbers = ['0','1','2','3','4','5','6','7','8','9'];
    final englishNumbers = ['0','1','2','3','4','5','6','7','8','9'];

    for (int i = 0; i < arabicNumbers.length; i++) {
      input = input.replaceAll(arabicNumbers[i], englishNumbers[i]);
    }
    return input;
  }

  void _handleInput(String value) {
    final currentText = _passwordController.text;
    if (currentText.length < 4) {
      final newText = currentText + value;
      _passwordController.text = newText;
      setState(() {
        codeFilled[newText.length - 1] = true;
      });
    }
  }

  void _handleBackspace() {
    final currentText = _passwordController.text;
    if (currentText.isNotEmpty) {
      final newText = currentText.substring(0, currentText.length - 1);
      _passwordController.text = newText;
      setState(() {
        codeFilled[newText.length] = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final boxWidth = size.width * 0.12;
    final boxHeight = size.height * 0.07;

    return ModalProgressHUD(
      opacity: 0.8,
      color: Colors.black,
      inAsyncCall: isloading,
      child: Scaffold(
        
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Container(
            width: size.width,
            height: size.height,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                       Row(
                children: [
                 
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: LanguageDropdown(),
                  )
                ],
              ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "تسجيل الدخول".tr(),
                        style:
                            TextAppStyles.cairo24.copyWith(color: primaryColor),
                      ),
                    ),
                    Icon(
                      Icons.lock_outline,
                      size: size.height * 0.1,
                      color: primaryColor,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'مرحباً بعودتك'.tr(),
                      style:
                          TextAppStyles.cairo18.copyWith(color: primaryColor),
                    ),
                    const SizedBox(height: 40),

                    // Password Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          width: boxWidth,
                          height: boxHeight,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: secondaryColor,
                              width: 2,
                            ),
                          ),
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: codeFilled[index]
                                  ? accentColor
                                  : Colors.transparent,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),

                    // Keyboard
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Directionality(
                        textDirection:flutter. TextDirection.ltr,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                         _buildRow(['1', '2', '3']),
                        const SizedBox(height: 16),
                        _buildRow(['4', '5', '6']),
                        const SizedBox(height: 16),
                        _buildRow(['7', '8', '9']),
                        const SizedBox(height: 16),
                        _buildRow(['0', '✖']),
                        
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Login Button
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15.0, vertical: 5),
                      child: Loginbtn(
                        ontap: () async {
                          if (_passwordController.text.length == 4) {
                            setState(() {
                              isloading = true;
                            });
                            await Future.delayed(Duration(seconds: 2));
                            await LoginService.login(
                              password: normalizeNumber(_passwordController.text),
                              context: context,
                            );
                            setState(() {
                              isloading = false;
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("يرجى إدخال 4 أرقام".tr()),
                                backgroundColor: accentColor,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) {
        return _KeyButton(
          keySymbol: key,
          onTap: () => key == '✖' ? _handleBackspace() : _handleInput(key),
          primaryColor: primaryColor,
          accentColor: accentColor,
        );
      }).toList(),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String keySymbol;
  final VoidCallback onTap;
  final Color primaryColor;
  final Color accentColor;

  const _KeyButton({
    required this.keySymbol,
    required this.onTap,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isBackspace = keySymbol == '✖';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: isBackspace
              ? Icon(
                  Icons.backspace_outlined,
                  size: 25,
                  color: primaryColor,
                )
              : Text(
                  keySymbol,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w300,
                    color: primaryColor,
                  ),
                ),
        ),
      ),
    );
  }
}
