import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart'; // <-- NUEVA LIBRERÍA
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

  bool _cargandoDatos = true;
  String? _errorDatos;
  List<dynamic> _categorias = [];
  Map<String, dynamic>? _cupo;
  int? _categoriaId;
  int? _subcategoriaId;

  bool get _puedeSolicitar =>
      !_cargandoDatos &&
      _errorDatos == null &&
      _cupo?['puede_solicitar'] == true;

  List<dynamic> get _subcategoriasDisponibles {
    for (final categoria in _categorias) {
      if (categoria is Map && categoria['id'] == _categoriaId) {
        final subcategorias = categoria['subcategorias'];
        return subcategorias is List ? subcategorias : [];
      }
    }
    return [];
  }

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _cargandoDatos = true;
      _errorDatos = null;
    });

    final resultados = await Future.wait([
      ApiService.getCategoriasLicencia(),
      ApiService.getCupoLicencias(),
    ]);

    if (!mounted) return;
    final categorias = resultados[0];
    final cupo = resultados[1];

    if (categorias['success'] == true &&
        categorias['data'] is List &&
        cupo['success'] == true &&
        cupo['data'] is Map) {
      setState(() {
        _categorias = categorias['data'] as List<dynamic>;
        _cupo = Map<String, dynamic>.from(cupo['data'] as Map);
        if (!_categorias.any((categoria) => categoria['id'] == _categoriaId)) {
          _categoriaId = null;
          _subcategoriaId = null;
        } else if (!_subcategoriasDisponibles.any(
          (subcategoria) => subcategoria['id'] == _subcategoriaId,
        )) {
          _subcategoriaId = null;
        }
        _cargandoDatos = false;
      });
    } else {
      setState(() {
        _cupo = null;
        _categorias = [];
        _categoriaId = null;
        _subcategoriaId = null;
        _errorDatos = categorias['success'] != true
            ? (categorias['message']?.toString() ??
                'No se pudo cargar el catálogo de categorías.')
            : (cupo['message']?.toString() ??
                'No se pudo consultar el cupo semestral.');
        _cargandoDatos = false;
      });
    }
  }

  @override
  void dispose() {
    _motivoController.dispose();
    _fechaInicioController.dispose();
    _fechaFinController.dispose();
    super.dispose();
  }

  // --- NUEVA FUNCIÓN: Compresión de imagen ---
  Future<File?> _comprimirImagen(File file) async {
    final filePath = file.absolute.path;
    // Creamos una nueva ruta para el archivo comprimido
    final outPath = "${filePath.substring(0, filePath.lastIndexOf('.'))}_compressed.jpg";

    final XFile? result = await FlutterImageCompress.compressAndGetFile(
      filePath, 
      outPath,
      quality: 60, // 60% de calidad es perfecto para documentos sin perder legibilidad
      minWidth: 1024, // Redimensiona si la imagen es gigante (ej. 4K)
      minHeight: 1024,
    );

    if (result != null) {
      print("Tamaño original: ${file.lengthSync()} bytes");
      print("Tamaño comprimido: ${await result.length()} bytes");
      return File(result.path);
    }
    return file; // Si falla por alguna razón, devuelve el archivo original
  }
  // ------------------------------------------

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
                  // Aplicamos la compresión antes de guardar en el estado
                  File imagenOriginal = File(photo.path);
                  File? imagenComprimida = await _comprimirImagen(imagenOriginal);

                  setState(() {
                    _archivoAdjunto = imagenComprimida ?? imagenOriginal;
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
                  // Aplicamos la compresión antes de guardar en el estado
                  File imagenOriginal = File(image.path);
                  File? imagenComprimida = await _comprimirImagen(imagenOriginal);

                  setState(() {
                    _archivoAdjunto = imagenComprimida ?? imagenOriginal;
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
                // Usamos FilePicker para buscar PDFs (Los PDF no se comprimen con esta librería)
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

  // Enviar al servidor: Laravel vuelve a validar el cupo.
  Future<void> _enviar() async {
    if (!_puedeSolicitar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay cupos disponibles o no se pudo consultar el límite.')),
      );
      return;
    }

    if (_categoriaId == null ||
        _subcategoriaId == null ||
        _fechaInicioController.text.isEmpty ||
        _fechaFinController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona categoría, subcategoría y fechas.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.enviarLicencia(
      motivo: _motivoController.text.trim(),
      fechaInicio: _fechaInicioController.text,
      fechaFin: _fechaFinController.text,
      archivo: _archivoAdjunto,
      categoriaId: _categoriaId,
      subcategoriaId: _subcategoriaId,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
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
        SnackBar(
          content: Text(result['message']?.toString() ?? 'No se pudo enviar.'),
          backgroundColor: Colors.red,
        ),
      );
      if (result['status'] == 409) {
        await _cargarDatos();
      }
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
            if (_cargandoDatos)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_errorDatos != null) ...[
              Text(
                _errorDatos!,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _cargarDatos,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
              const SizedBox(height: 18),
            ],
            if (_cupo != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _puedeSolicitar ? Colors.blue.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _puedeSolicitar ? Colors.blue.shade200 : Colors.red.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Máximo 3 licencias por semestre',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Semestre ${_cupo!['semestre']} de ${_cupo!['anio']} '
                      '(${_cupo!['fecha_inicio']} al ${_cupo!['fecha_fin']})',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Utilizadas: ${_cupo!['utilizadas']} de ${_cupo!['maximo']}. '
                      'Disponibles: ${_cupo!['disponibles']}.',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (!_puedeSolicitar) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Has alcanzado el límite de 3 licencias por semestre. '
                        'No puedes enviar otra solicitud hasta que se libere un cupo '
                        'o comience el siguiente semestre.',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            const Text(
              'Categoría:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<int>(
              value: _categoriaId,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Selecciona una categoría',
              ),
              items: _categorias.map<DropdownMenuItem<int>>((categoria) {
                return DropdownMenuItem<int>(
                  value: categoria['id'] as int,
                  child: Text(
                    categoria['nombre']?.toString() ?? '',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: _puedeSolicitar && !_isLoading
                  ? (valor) => setState(() {
                        _categoriaId = valor;
                        _subcategoriaId = null;
                      })
                  : null,
            ),
            const SizedBox(height: 20),
            const Text(
              'Motivo específico:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<int>(
              value: _subcategoriaId,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Selecciona el motivo',
              ),
              items: _subcategoriasDisponibles.map<DropdownMenuItem<int>>((subcategoria) {
                return DropdownMenuItem<int>(
                  value: subcategoria['id'] as int,
                  child: Text(
                    subcategoria['nombre']?.toString() ?? '',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: _puedeSolicitar && !_isLoading && _categoriaId != null
                  ? (valor) => setState(() => _subcategoriaId = valor)
                  : null,
            ),
            const SizedBox(height: 20),
            const Text(
              'Detalle adicional (opcional):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _motivoController,
              maxLines: 3,
              maxLength: 500,
              enabled: _puedeSolicitar && !_isLoading,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Explica tu situación si necesitas añadir información...',
              ),
            ),

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _fechaInicioController,
                    readOnly: true,
                    enabled: _puedeSolicitar && !_isLoading,
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
                    enabled: _puedeSolicitar && !_isLoading,
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
              onTap: _puedeSolicitar && !_isLoading ? _seleccionarArchivo : null,
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
                onPressed: _puedeSolicitar && !_isLoading ? _enviar : null,
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