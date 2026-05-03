import 'package:flutter/material.dart';

class AppTheme {
  static const _seed = Color(0xFF00BFA5);

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.dark,
          surface: const Color(0xFF1C1C1E),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        cardTheme: CardThemeData(
          color: const Color(0xFF1C1C1E),
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F0F0F),
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF1C1C1E),
          indicatorColor: const Color(0xFF00BFA5).withOpacity(0.2),
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2C2C2E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _seed, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFF2C2C2E),
          selectedColor: const Color(0xFF00BFA5).withOpacity(0.25),
          side: BorderSide.none,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFF2C2C2E),
          thickness: 1,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF00BFA5),
          foregroundColor: Colors.black,
        ),
      );
}
