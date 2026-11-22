import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  const rojoInstitucional = Color(0xFFD32F2F);

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SITA App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: rojoInstitucional),
        scaffoldBackgroundColor: const Color(0xFFF6F7FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: rojoInstitucional,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const SplashScreen(),
    ),
  );
}
