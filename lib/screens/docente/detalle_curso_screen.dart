import 'package:flutter/material.dart';
import 'scanner_screen.dart';
import 'control_manual_screen.dart'; // Crearemos este archivo en el siguiente paso

class DetalleCursoScreen extends StatelessWidget {
  final int materiaId;
  final String nombreMateria;
  final String nombreCurso;

  const DetalleCursoScreen({
    super.key,
    required this.materiaId,
    required this.nombreMateria,
    required this.nombreCurso,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Opciones de Clase'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tarjeta de Información
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.indigo.shade100),
              ),
              child: Column(
                children: [
                  Text(
                    nombreMateria,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    nombreCurso,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // BOTÓN 1: TOMAR ASISTENCIA (ESCÁNER)
            _botonGrande(
              context,
              icon: Icons.qr_code_scanner,
              titulo: "Escanear QR",
              subtitulo: "Registrar asistencia con cámara",
              color: Colors.indigo,
              destino: ScannerScreen(materiaId: materiaId, nombreMateria: nombreMateria),
            ),
            
            const SizedBox(height: 20),

            // BOTÓN 2: CONTROL MANUAL (LISTA)
            _botonGrande(
              context,
              icon: Icons.edit_note,
              titulo: "Lista y Control Manual",
              subtitulo: "Marcar atrasos, faltas o ver lista",
              color: Colors.orange.shade800,
              destino: ControlManualScreen(materiaId: materiaId, nombreMateria: nombreMateria),
            ),
          ],
        ),
      ),
    );
  }

  Widget _botonGrande(BuildContext context, {
    required IconData icon, 
    required String titulo, 
    required String subtitulo, 
    required Color color, 
    required Widget destino
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(15),
      elevation: 5,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => destino),
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 35, color: Colors.white),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(subtitulo, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}