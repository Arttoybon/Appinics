import 'package:appincidencias/screens/login_screen.dart'; 
import 'package:appincidencias/screens/my_incidents_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Añadido este import que faltaba
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:appincidencias/services/api_service.dart';
import 'dart:io';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String? _categoriaSeleccionada;
  final TextEditingController _descController = TextEditingController();
  XFile? _imagenSeleccionada;
  bool _isLoading = false;
  Position? _currentPosition;
  
  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();

  final List<Map<String, dynamic>> _categorias = [
    {'nombre': 'Alumbrado', 'icon': Icons.lightbulb},
    {'nombre': 'Limpieza', 'icon': Icons.cleaning_services},
    {'nombre': 'Mobiliario', 'icon': Icons.chair},
    {'nombre': 'Vías', 'icon': Icons.add_road},
  ];

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  // Función para obtener la ubicación automáticamente
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Servicio de ubicación desactivado.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Permisos de ubicación denegados.');
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      debugPrint('Permisos denegados permanentemente.');
      return;
    } 

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      debugPrint("Error obteniendo ubicación: $e");
    }
  }

  Future<void> _tomarFoto() async {
    final XFile? photo = await _picker.pickImage(
      source: kIsWeb ? ImageSource.gallery : ImageSource.camera,
      imageQuality: 50,
    );

    if (photo != null) {
      setState(() {
        _imagenSeleccionada = photo;
      });
    }
  }

  Future<void> _enviarReporte() async {
    if (_categoriaSeleccionada == null || _descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecciona una categoría y escribe una descripción")),
      );
      return;
    }

    setState(() => _isLoading = true);

    bool exito = await _apiService.enviarIncidenciaCompleta(
      categoria: _categoriaSeleccionada!,
      descripcion: _descController.text,
      imagen: _imagenSeleccionada,
      latitud: _currentPosition?.latitude,
      longitud: _currentPosition?.longitude,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Incidencia enviada con ubicación"), backgroundColor: Colors.green),
      );
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
        leading: IconButton(
          icon: const Icon(Icons.list_alt, color: Colors.white),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyIncidentsScreen())),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              final GoogleSignIn googleSignIn = GoogleSignIn();
              await googleSignIn.signOut();
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("1. Selecciona la categoría", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 15),
            
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
            const Text("3. Evidencia visual", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Center(
              child: Column(
                children: [
                  if (_imagenSeleccionada != null) 
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: kIsWeb 
                        ? Image.network(_imagenSeleccionada!.path, height: 200, width: double.infinity, fit: BoxFit.cover)
                        : Image.file(File(_imagenSeleccionada!.path), height: 200, width: double.infinity, fit: BoxFit.cover),
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

            const SizedBox(height: 20),
            // Indicador de Ubicación
            Row(
              children: [
                Icon(
                  _currentPosition != null ? Icons.location_on : Icons.location_searching,
                  color: _currentPosition != null ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 10),
                Text(
                  _currentPosition != null 
                    ? "Ubicación capturada correctamente" 
                    : "Obteniendo ubicación...",
                  style: TextStyle(
                    color: _currentPosition != null ? Colors.green : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
            
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
