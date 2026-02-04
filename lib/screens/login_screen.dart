import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'docente/docente_home_screen.dart';
import 'estudiante/estudiante_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores para leer el texto de los campos
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Variable para mostrar el círculo de carga
  bool _isLoading = false;

  // Función que se ejecuta al presionar "INGRESAR"
  void _login() async {
    // 1. Validar que no estén vacíos
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingrese correo y contraseña')),
      );
      return;
    }

    // 2. Activar el modo carga
    setState(() {
      _isLoading = true;
    });

    // 3. Llamar al servicio API (Conectar con Laravel)
    final result = await ApiService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    // 4. Desactivar el modo carga
    setState(() {
      _isLoading = false;
    });

    // 5. Verificar el resultado
    if (result['success']) {
      // Login Exitoso: Leemos el rol y redirigimos
      final role = result['data']['rol']; // 'docente' o 'estudiante'

      if (!mounted) return; // Seguridad de Flutter

      if (role == 'docente') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DocenteHomeScreen()),
        );
      } else if (role == 'estudiante') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const EstudianteHomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Este rol no tiene acceso a la App')),
        );
      }
    } else {
      // Error (Credenciales o Conexión)
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        // SingleChildScrollView evita el error de "overflow" (líneas amarillas)
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- LOGO Y TÍTULO ---
                const Icon(
                  Icons.school, 
                  size: 100, 
                  color: Color(0xFFD32F2F) // Rojo Institucional
                ),
                const SizedBox(height: 20),
                const Text(
                  'SITA',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD32F2F),
                  ),
                ),
                const Text(
                  'Instituto Tecnológico Ayacucho',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 40),

                // --- CAMPO CORREO ---
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo Institucional',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                // --- CAMPO CONTRASEÑA ---
                TextField(
                  controller: _passwordController,
                  obscureText: true, // Ocultar texto
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 30),

                // --- BOTÓN INGRESAR ---
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'INGRESAR',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}