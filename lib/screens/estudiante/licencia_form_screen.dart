import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/api_service.dart';
import '../../utils/sound_manager.dart';

class LicenciaFormScreen extends StatefulWidget {
  const LicenciaFormScreen({super.key});

  @override
  State<LicenciaFormScreen> createState() => _LicenciaFormScreenState();
}

class _LicenciaFormScreenState extends State<LicenciaFormScreen> {
  final _motivoController = TextEditingController();
  final _fechaInicioController = TextEditingController();
  final _fechaFinController = TextEditingController();

  File? _archivoAdjunto; // Puede ser Foto o PDF
  String? _tipoArchivo; // 'imagen' o 'pdf'
  bool _isLoading = false;

  // Selector de Fecha
  Future<void> _seleccionarFecha(TextEditingController controller) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        controller.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  // Selector Inteligente (Foto o PDF)
  Future<void> _seleccionarArchivo() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Tomar Foto (Cámara)'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? photo = await ImagePicker().pickImage(
                  source: ImageSource.camera,
                );
                if (photo != null) {
                  setState(() {
                    _archivoAdjunto = File(photo.path);
                    _tipoArchivo = 'imagen';
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.image, color: Colors.green),
              title: const Text('Galería de Imágenes'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                );
                if (image != null) {
                  setState(() {
                    _archivoAdjunto = File(image.path);
                    _tipoArchivo = 'imagen';
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Subir Documento PDF'),
              onTap: () async {
                Navigator.pop(context);
                // Usamos FilePicker para buscar PDFs
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['pdf'],
                );

                if (result != null && result.files.single.path != null) {
                  setState(() {
                    _archivoAdjunto = File(result.files.single.path!);
                    _tipoArchivo = 'pdf';
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // Enviar al servidor
  void _enviar() async {
    if (_motivoController.text.isEmpty ||
        _fechaInicioController.text.isEmpty ||
        _fechaFinController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Llene los campos obligatorios')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.enviarLicencia(
      motivo: _motivoController.text,
      fechaInicio: _fechaInicioController.text,
      fechaFin: _fechaFinController.text,
      archivo: _archivoAdjunto,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      SoundManager.playScan();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Enviado con éxito!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    }
  }

  // Widget para mostrar la vista previa según el tipo
  Widget _buildVistaPrevia() {
    if (_archivoAdjunto == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.cloud_upload, size: 40, color: Colors.grey),
          SizedBox(height: 10),
          Text(
            'Tocar para adjuntar Foto o PDF',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      );
    }

    // Si es PDF, mostramos icono y nombre
    if (_tipoArchivo == 'pdf') {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.picture_as_pdf, size: 50, color: Colors.red),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              _archivoAdjunto!.path.split('/').last,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Text(
            "(Documento PDF listo)",
            style: TextStyle(fontSize: 12, color: Colors.green),
          ),
        ],
      );
    }

    // Si es Imagen, mostramos la foto
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.file(
        _archivoAdjunto!,
        fit: BoxFit.cover,
        width: double.infinity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Licencia'),
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Motivo:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            TextField(
              controller: _motivoController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ej: Baja médica...',
              ),
            ),

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _fechaInicioController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Desde',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                    onTap: () => _seleccionarFecha(_fechaInicioController),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _fechaFinController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Hasta',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                    onTap: () => _seleccionarFecha(_fechaFinController),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Text(
              'Evidencia (Opcional):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Área de Vista Previa
            GestureDetector(
              onTap: _seleccionarArchivo,
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(
                    color: Colors.grey.shade400,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _buildVistaPrevia(),
              ),
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _enviar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('ENVIAR SOLICITUD'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
