import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:saladafactory/core/utils/localls.dart';
import 'package:saladafactory/features/home/presentation/view/widget/homeBodyView.dart';
import 'package:saladafactory/features/login/presentation/view/loginView.dart';

import '../splashView.dart';
class Animated_SplashView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: Localls.getToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return AnimatedSplashScreen(
            duration: 3000,
            splash: SplashView(),
            nextScreen: Center(child: CircularProgressIndicator()),
            centered: true,
            splashIconSize: double.infinity,
          );
        }

        final hasToken = snapshot.data != null;

        return AnimatedSplashScreen(
          duration: 3000,
          splash: SplashView(),
          nextScreen: hasToken ? HomeBodyView() : Loginview(),
          centered: true,
          splashIconSize: double.infinity,
        );
      },
    );
  }
}
