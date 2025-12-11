import 'package:flutter/material.dart';

class KDRTColors {
  KDRTColors._();

  //******************  BASIC COLORS ******************
  static const Color blue = Colors.blue;
  static const Color darkBlue = Color(0xFF1A2980);
  static const Color cyan = Color(0xFF26D0CE);
  static const Color pink = Colors.pink;
  static const Color purple = Colors.purple;
  static const Color red = Colors.red;
  static const Color primary = Color.fromRGBO(157, 37, 116, 1);
  static const Color secondary = Color(0xFFFFE24B);
  static const Color success = Color(0xFF4CAF50);
  static const Color danger = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFFF9800);
  static const Color star = Colors.amber;
  static const Color grey = Colors.grey;
  static const Color green = Colors.green;
  static const Color orange = Colors.orange;
  static const Color black12 = Colors.black12;
  static const Color whiteShade = Color.fromARGB(255, 199, 227, 250);
  static const Color purple1 = Colors.purple;

  //******************  TEXT COLORS ******************
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF6C7570);
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static Color white01 = Colors.white.withOpacity(0.1);
  static Color blackOpacity = Colors.black.withOpacity(0.5);
  static const Color transparent = Colors.transparent;

  //******************  BACKGROUND COLORS ******************
  static const Color light = Color(0xFFF6F6F6);
  static const Color dark = Color(0xFF272727);
  static const Color primaryBackground = Color(0xFFF3F5FF);

  /// BACKGROUND CONTAINER COLORS
  static const Color lightContainer = Color(0xFFF6F6F6);
  static Color darkContainer = Colors.white.withOpacity(0.1);

  /// BUTTON COLORS
  static const Color buttonPrimary = Color(0xFF4b68ff);
  static const Color buttonSecondary = Color(0xFF6c7570);
  static const Color buttonDisabled = Color(0xFFC4C4C4);

  /// BORDER COLORS
  static const Color borderPrimary = Color(0xFFD9D9D9);
  static const Color borderSecondary = Color(0xFFE6E6E6);

  static const LinearGradient gradientColor = LinearGradient(
    colors: [Color(0xFF1A2980), Color(0xFF26D0CE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppGradients {
  static const LinearGradient gradientColor = LinearGradient(
    colors: [Color(0xFF1A2980), Color(0xFF26D0CE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
