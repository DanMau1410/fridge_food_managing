import 'package:flutter/material.dart';

/// The app's teal Material 3 theme for [brightness].
ThemeData buildTheme(Brightness brightness) => ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.teal,
    brightness: brightness,
  ),
);
