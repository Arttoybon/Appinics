import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:appincidencias/services/api_service.dart'; // Asegúrate de que la ruta es correcta

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String? _categoriaSeleccionada;
  final TextEditingController _descController = TextEditingController();
  
  // Variables nuevas para funcionalidad
  File? _imagenSeleccionada;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();

  // Lista de categorías con sus iconos
  final List<Map<String, dynamic>> _categorias = [
    {'nombre': 'Alumbrado', 'icon': Icons.lightbulb},
    {'nombre': 'Limpieza', 'icon': Icons.cleaning_services},
    {'nombre': 'Mobiliario', 'icon': Icons.chair},
    {'nombre': 'Vías', 'icon': Icons.add_road},
  ];

  // Función para tomar la foto
  Future<void> _tomarFoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50, // Comprimimos para no saturar el servidor del IES
    );

    if (photo != null) {
      setState(() {
        _imagenSeleccionada = File(photo.path);
      });
    }
  }

  // Función para enviar el reporte
  Future<void> _enviarReporte() async {
    if (_categoriaSeleccionada == null || _descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecciona una categoría y escribe una descripción")),
      );
      return;
    }

    setState(() => _isLoading = true);

    bool exito = await _apiService.enviarIncidenciaCompleta(
      _categoriaSeleccionada!,
      _descController.text,
      _imagenSeleccionada,
    );

    setState(() => _isLoading = false);

    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Incidencia enviada correctamente"), backgroundColor: Colors.green),
      );
      // Limpiamos el formulario tras el éxito
      setState(() {
        _categoriaSeleccionada = null;
        _descController.clear();
        _imagenSeleccionada = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Error al enviar. Revisa tu conexión"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nuevo Reporte", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("1. Selecciona la categoría", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 15),
            
            // Grid de categorías
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.5,
              ),
              itemCount: _categorias.length,
              itemBuilder: (context, index) {
                bool seleccionada = _categoriaSeleccionada == _categorias[index]['nombre'];
                return InkWell(
                  onTap: () => setState(() => _categoriaSeleccionada = _categorias[index]['nombre']),
                  child: Container(
                    decoration: BoxDecoration(
                      color: seleccionada ? Colors.orange.withOpacity(0.2) : Colors.grey[100],
                      border: Border.all(color: seleccionada ? Colors.orange : Colors.transparent, width: 2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_categorias[index]['icon'], color: Colors.orange, size: 30),
                        Text(_categorias[index]['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 25),
            const Text("2. Descripción del problema", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            TextField(
              controller: _descController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Explica brevemente qué sucede...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),

            const SizedBox(height: 25),
            
            // Sección de Foto corregida
            const Text("3. Evidencia visual", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Center(
              child: Column(
                children: [
                  if (_imagenSeleccionada != null) 
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.file(_imagenSeleccionada!, height: 200, width: double.infinity, fit: BoxFit.cover),
                    ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _tomarFoto,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(_imagenSeleccionada == null ? "Añadir Foto" : "Cambiar Foto"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200], 
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            
            // Botón Enviar con estado de carga
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _enviarReporte,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("ENVIAR REPORTE", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}