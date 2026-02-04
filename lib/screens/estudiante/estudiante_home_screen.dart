import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../login_screen.dart';
import 'licencia_form_screen.dart';
import 'mis_licencias_screen.dart';

class EstudianteHomeScreen extends StatefulWidget {
  const EstudianteHomeScreen({super.key});

  @override
  State<EstudianteHomeScreen> createState() => _EstudianteHomeScreenState();
}

class _EstudianteHomeScreenState extends State<EstudianteHomeScreen> {
  bool _isLoading = true;
  List<dynamic> _materias = []; 

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  void _cargarDatos() async {
    setState(() => _isLoading = true);
    final materias = await ApiService.getMateriasEstudiante();
    
    if (mounted) {
      setState(() {
        _materias = materias;
        _isLoading = false;
      });
    }
  }

  void _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Rendimiento'),
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargarDatos),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // --- SECCIÓN DE BOTONES RÁPIDOS ---
                Container(
                  padding: const EdgeInsets.all(15),
                  color: Colors.grey.shade100,
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                             Navigator.push(context, MaterialPageRoute(builder: (_) => const LicenciaFormScreen()));
                          },
                          icon: const Icon(Icons.add_a_photo, size: 18),
                          label: const Text("PEDIR LICENCIA"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD32F2F), 
                            foregroundColor: Colors.white
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                             Navigator.push(context, MaterialPageRoute(builder: (_) => const MisLicenciasScreen()));
                          },
                          icon: const Icon(Icons.history, size: 18),
                          label: const Text("TRÁMITES"),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),

                // --- LISTA DE MATERIAS ---
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: _materias.length,
                    itemBuilder: (context, index) {
                      final materia = _materias[index];
                      final porcentaje = materia['porcentaje']; // 0 a 100
                      final esRiesgo = materia['riesgo']; // true/false
                      
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 15),
                        shape: RoundedRectangleBorder(
                          side: esRiesgo ? const BorderSide(color: Colors.red, width: 2) : BorderSide.none,
                          borderRadius: BorderRadius.circular(10)
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Título y Porcentaje
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      materia['nombre'],
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: esRiesgo ? Colors.red : Colors.green,
                                      borderRadius: BorderRadius.circular(8)
                                    ),
                                    child: Text(
                                      "$porcentaje%",
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 10),
                              
                              // Barra de Progreso
                              ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: LinearProgressIndicator(
                                  value: porcentaje / 100, 
                                  minHeight: 10,
                                  backgroundColor: Colors.grey.shade300,
                                  color: esRiesgo ? Colors.red : Colors.green,
                                ),
                              ),
                              
                              const SizedBox(height: 5),
                              
                              // Detalles Texto (SIN "REPROBADO")
                              Text(
                                "Clases asistidas: ${materia['asistencias_puntos']} de ${materia['total_clases']}",
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}