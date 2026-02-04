import 'package:flutter/material.dart';
import 'screens/splash_screen.dart'; // <--- Importa el Splash

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SITA App',
      home: SplashScreen(), // <--- Arranca aquí
    ),
  );
}
