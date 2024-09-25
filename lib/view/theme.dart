import 'package:flutter/material.dart';

bool darkMode = true;

Color dialogColor = const Color.fromARGB(255, 63, 63, 63);

ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.green,
    scaffoldBackgroundColor: Colors.white,
    dialogBackgroundColor: Colors.white,
    canvasColor: Colors.white,
    hintColor: Colors.white70,
    textTheme: const TextTheme(
      bodyText1: TextStyle(),
      bodyText2: TextStyle(),
      button: TextStyle(),
    ).apply(
      bodyColor: Colors.black87,
      displayColor: Colors.black87,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.white10,
      iconColor: Colors.black87,
      hintStyle: TextStyle(color: Colors.black87),
      labelStyle: TextStyle(color: Colors.black87),
    ));

ThemeData darkTheme = ThemeData(
    sliderTheme: const SliderThemeData(
        valueIndicatorColor: Colors.deepPurple,
        showValueIndicator: ShowValueIndicator.onlyForContinuous,
        valueIndicatorTextStyle: TextStyle(color: Colors.white70)),
    colorScheme: ColorScheme(
        onPrimary: Colors.white70,
        brightness: Brightness.dark,
        primary: Colors.deepPurple,
        secondary: Colors.deepPurpleAccent,
        onSecondary: Colors.white70,
        error: Colors.red,
        onError: Colors.white70,
        background: Colors.grey.shade900,
        onBackground: Colors.white70,
        surface: Colors.deepPurple.shade700,
        onSurface: Colors.white70),
    primarySwatch: Colors.deepPurple,
    scaffoldBackgroundColor: Colors.grey.shade900,
    dialogBackgroundColor: Colors.grey.shade700,
    dialogTheme: DialogTheme(backgroundColor: Colors.grey.shade700),
    canvasColor: Colors.black,
    hintColor: Colors.black87,
    textTheme: const TextTheme().apply(
      bodyColor: Colors.white70,
      displayColor: Colors.white70,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade700,
      iconColor: Colors.white70,
      hintStyle: const TextStyle(color: Colors.white70),
      labelStyle: const TextStyle(color: Colors.white70),
    ));

Color getSelectedCardColor(bool selected) {
  var themeColor = !darkMode ? Colors.black12 : Colors.white10;
  return selected ? Colors.white24 : themeColor;
}
