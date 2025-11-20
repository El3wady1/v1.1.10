import 'package:flutter/material.dart';

class AppThemes {
  static var DarkMode = ThemeData.dark(useMaterial3: true).copyWith(
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedLabelStyle: TextStyle(fontSize: 15),
          selectedItemColor: Colors.white,
          unselectedLabelStyle: TextStyle(color: Colors.white),
          showSelectedLabels: true,
          unselectedItemColor: Colors.white,
          backgroundColor: Colors.white),
      appBarTheme: AppBarTheme(
          backgroundColor: Colors.black45,
          titleTextStyle: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)));

  static var LigthMode = ThemeData.light(useMaterial3: true).copyWith(
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: Colors.teal,
          unselectedLabelStyle: TextStyle(color: Colors.teal),
          showSelectedLabels: true,
          unselectedItemColor: Colors.teal,
          backgroundColor: Colors.teal),
      appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 5,
          titleTextStyle: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)));
}
