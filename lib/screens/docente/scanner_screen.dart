import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/api_service.dart';
import '../../utils/database_helper.dart'; // <--- Import corregido (utils)
import '../../utils/sound_manager.dart';

class ScannerScreen extends StatefulWidget {
  final int materiaId;
  final String nombreMateria;

  const ScannerScreen({
    super.key,
    required this.materiaId,
    required this.nombreMateria,
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _isProcessing = false; // Para evitar lecturas múltiples muy rápidas
  MobileScannerController cameraController = MobileScannerController();

  void _procesarCodigo(String codigoEscaneado) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Procesando...'),
        duration: Duration(milliseconds: 500),
      ),
    );

    try {
      final result = await ApiService.registrarAsistencia(
        codigoQr: codigoEscaneado,
        materiaId: widget.materiaId,
      );

      if (!mounted) return;

      if (result['success']) {
        SoundManager.playScan();
        _mostrarAlerta(
          "✅ Online",
          "Asistencia registrada para:\n${result['alumno']}",
          Colors.green,
        );
      } else {
        _mostrarAlerta(
          "⚠️ Atención",
          result['message'] ?? 'Error desconocido',
          Colors.orange,
        );
      }
    } catch (e) {
      print("Error de red detectado ($e). Activando Modo Offline...");

      await DatabaseHelper().insertarAsistencia(
        codigoQr: codigoEscaneado,
        materiaId: widget.materiaId,
        nombreMateria: widget.nombreMateria,
      );

      if (!mounted) return;
      SoundManager.playScan();
      _mostrarAlerta(
        "💾 Guardado Offline",
        "Sin internet. Se guardó en el celular.\n\nQR: $codigoEscaneado",
        Colors.blue,
      );
    }

    // Esperar 2 segundos antes de leer otro
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _isProcessing = false);
  }

  void _mostrarAlerta(String titulo, String mensaje, Color color) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info, color: color),
            const SizedBox(width: 10),
            Flexible(
              child: Text(titulo, style: TextStyle(color: color)),
            ),
          ],
        ),
        content: Text(mensaje, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Escanear: ${widget.nombreMateria}'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          // Botón de Flash SIMPLIFICADO (Sin listener complejo)
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => cameraController.toggleTorch(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: MobileScanner(
              controller: cameraController,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    _procesarCodigo(barcode.rawValue!);
                    break; // Procesar solo uno
                  }
                }
              },
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    "Apunta al código QR de la tarjeta",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Mantén el celular estable",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
