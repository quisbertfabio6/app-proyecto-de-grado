import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'docente/docente_home_screen.dart';
import 'estudiante/estudiante_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _verificarSesion();
  }

  void _verificarSesion() async {
    // Damos tiempo para que se luzca el logo (2.5 segundos)
    await Future.delayed(const Duration(milliseconds: 2500));

    final token = await ApiService.getToken();
    final rol = await ApiService.getStoredRole();

    if (!mounted) return;

    if (token != null && rol != null) {
      if (rol == 'docente') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DocenteHomeScreen()),
        );
      } else if (rol == 'estudiante') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const EstudianteHomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo blanco o rojo (según prefieras, el blanco hace resaltar más el logo)
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- LOGO ---
            // Usamos Image.asset en lugar de Icon
            Image.asset(
              'assets/icon/app_icon.png',
              width: 150, // Tamaño controlado
              height: 150,
            ),

            const SizedBox(height: 20),

            // --- TÍTULO ---
            const Text(
              'SITA APP',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD32F2F), // Rojo Institucional
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Instituto Tecnológico Ayacucho',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
            ),

            const SizedBox(height: 50),

            // --- CARGANDO ---
            const CircularProgressIndicator(
              color: Color(0xFFD32F2F), // Rojo
            ),
          ],
        ),
      ),
    );
  }
}
