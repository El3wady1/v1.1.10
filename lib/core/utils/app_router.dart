import 'package:flutter/material.dart';

class Routting {
  static void push(BuildContext context, Widget route) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => route),
    );
  }
  static void pushreplaced(BuildContext context, Widget route) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => route),
    );
  }

  static void popWithRoute (BuildContext context, Widget route) {
    Navigator.pop(
      context,
      MaterialPageRoute(builder: (context) => route),
    );
  }

  static void popNoRoute (BuildContext context,) {
    Navigator.of(context).pop();
  }

}

//Routting.push(context, BoardView())


//NavigationService
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>();

  static Future? navigateTo(String routeName, {Object? arguments}) {
    return navigatorKey.currentState?.pushNamed(routeName, arguments: arguments);
  }

  static Future? replaceWith(String routeName, {Object? arguments}) {
    return navigatorKey.currentState?.pushReplacementNamed(routeName, arguments: arguments);
  }
}
