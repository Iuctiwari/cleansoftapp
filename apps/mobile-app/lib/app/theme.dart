import 'package:flutter/material.dart';

const Color kPrimary = Color(0xFF3558E8);
const Color kPrimaryLight = Color(0xFFEEF2FD);
const Color kPrimaryDark = Color(0xFF2444C4);
const Color kBackground = Color(0xFFF4F6FB);
const Color kSurface = Colors.white;
const Color kTextPrimary = Color(0xFF0F1B3C);
const Color kTextSecondary = Color(0xFF6B7A99);
const Color kBorder = Color(0xFFDDE3F0);
const Color kChipSelected = Color(0xFF3558E8);
const Color kProgressBar = Color(0xFF3558E8);
const Color kProgressBarBg = Color(0xFFE0E7F5);

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: kPrimary,
      surface: kSurface,
      onPrimary: Colors.white,
      onSurface: kTextPrimary,
    ),
    scaffoldBackgroundColor: kSurface,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: kSurface,
      foregroundColor: kTextPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: kTextPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPrimary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      hintStyle: const TextStyle(color: kTextSecondary, fontSize: 15),
      prefixIconColor: kTextSecondary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kTextPrimary,
        minimumSize: const Size(double.infinity, 52),
        side: const BorderSide(color: kBorder, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return kPrimary;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      side: const BorderSide(color: kPrimary, width: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
  );
}
