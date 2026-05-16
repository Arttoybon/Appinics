import 'package:appincidencias/screens/login_screen.dart'; 
import 'package:appincidencias/screens/my_incidents_screen.dart';
import 'package:appincidencias/screens/admin_panel_screen.dart';
import 'package:appincidencias/screens/technician_panel_screen.dart';
import 'package:appincidencias/screens/user_profile_screen.dart';
import 'package:appincidencias/screens/notifications_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:appincidencias/services/api_service.dart';
import 'dart:io' show File;
import 'package:appincidencias/utils/web_reload/web_reload.dart';

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
  bool _isAdmin = false;
  bool _isTechnician = false;
  String? _especialidad;
  Position? _currentPosition;
  bool _isLocationLoading = false;
  String? _locationError;

  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();

  final List<Map<String, dynamic>> _categorias = [
    {'nombre': 'Alumbrado', 'icon': Icons.lightbulb},
    {'nombre': 'Limpieza', 'icon': Icons.cleaning_services},
    {'nombre': 'Mobiliario', 'icon': Icons.chair},
    {'nombre': 'Vías', 'icon': Icons.add_road},
    {'nombre': 'Otro', 'icon': Icons.more_horiz},
  ];

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _determinePosition();
    }
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'cantillana-native')
            .collection('usuarios').doc(user.uid).get();

        if (doc.exists) {
          final data = doc.data();
          String? rol = data?['rol']?.toString().trim().toLowerCase();
          
          if (rol == 'admin') {
            if (mounted) setState(() => _isAdmin = true);
          } else if (rol == 'tecnico') {
            if (mounted) setState(() {
              _isTechnician = true;
              _especialidad = data?['especialidad'];
            });
          }
        }
      } catch (e) {
        debugPrint("Error checkUserRole: $e");
      }
    }
  }

  Future<void> _determinePosition() async {
    if (!mounted) return;
    setState(() {
      _isLocationLoading = true;
      _locationError = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!kIsWeb) throw 'El servicio de ubicación está desactivado.';
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!kIsWeb) await Geolocator.openAppSettings();
          throw 'Permiso de ubicación denegado. Por favor, acéptalo para reportar.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Permiso bloqueado permanentemente. Actívalo en los ajustes del navegador (icono del candado).';
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 8),
        );
      } catch (e) {
        debugPrint("Error al obtener posición actual, intentando última conocida: $e");
        position = await Geolocator.getLastKnownPosition();
        if (position == null) {
          throw 'No se pudo obtener la ubicación. Asegúrate de tener el GPS activo y cobertura.';
        }
      }

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLocationLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error ubicación detallado: $e");
      String errorMsg = e.toString().replaceAll("Exception: ", "");

      if (mounted) {
        setState(() {
          _locationError = errorMsg;
          _isLocationLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("📍 $errorMsg"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _tomarFoto() async {
    final XFile? photo = await _picker.pickImage(
      source: kIsWeb ? ImageSource.gallery : ImageSource.camera,
      imageQuality: 90,
      maxWidth: 1920,
      maxHeight: 1080,
    );
    if (photo != null) setState(() => _imagenSeleccionada = photo);
  }

  Future<void> _enviarReporte() async {
    if (_categoriaSeleccionada == null ||
        _descController.text.trim().isEmpty ||
        _imagenSeleccionada == null ||
        _currentPosition == null) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Por favor, completa todos los campos (Categoría, Descripción, Foto y Ubicación)"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    bool exito = await _apiService.enviarIncidenciaCompleta(
      categoria: _categoriaSeleccionada!,
      descripcion: _descController.text.trim(),
      imagen: _imagenSeleccionada,
      latitud: _currentPosition?.latitude,
      longitud: _currentPosition?.longitude,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Incidencia enviada"), backgroundColor: Colors.green));
      setState(() { _categoriaSeleccionada = null; _descController.clear(); _imagenSeleccionada = null; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nuevo Reporte", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        centerTitle: true,
        leading: _isTechnician || _isAdmin
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            )
          : IconButton(
              icon: const Icon(Icons.list_alt, color: Colors.white),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyIncidentsScreen())),
            ),
        actions: [
          if (!_isTechnician && !_isAdmin) ...[
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'cantillana-native')
                  .collection('notificaciones')
                  .where('uid_usuario', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .where('leida', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                int unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications, color: Colors.white),
                      tooltip: 'Notificaciones',
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen())),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.account_circle, color: Colors.white),
              tooltip: 'Mi Perfil',
              onPressed: () {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfileScreen(
                        userId: user.uid,
                        userEmail: user.email ?? "",
                      ),
                    ),
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () async {
                try {
                  final googleSignIn = GoogleSignIn();
                  if (await googleSignIn.isSignedIn()) {
                    await googleSignIn.disconnect();
                    await googleSignIn.signOut();
                  }

                  await FirebaseAuth.instance.signOut();

                  if (kIsWeb) {
                    reloadApp();
                  }
                } catch (e) {
                  debugPrint("Error al cerrar sesión: $e");
                }
              },
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("1. Selecciona la categoría", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 15),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.5),
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
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(_categorias[index]['icon'], color: Colors.orange, size: 30), Text(_categorias[index]['nombre'], style: const TextStyle(fontWeight: FontWeight.bold))]),
                  ),
                );
              },
            ),
            const SizedBox(height: 25),
            TextField(controller: _descController, maxLines: 4, decoration: InputDecoration(hintText: "Descripción...", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
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
                        ? Image.network(_imagenSeleccionada!.path, height: 200, width: double.infinity, fit: BoxFit.cover, filterQuality: FilterQuality.medium)
                        : Image.file(File(_imagenSeleccionada!.path), height: 200, width: double.infinity, fit: BoxFit.cover),
                    ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _tomarFoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Añadir Foto"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _currentPosition != null ? Colors.green.withOpacity(0.1) : Colors.grey[50],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: _currentPosition != null ? Colors.green : (_locationError != null ? Colors.red : Colors.grey[300]!),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        _currentPosition != null ? Icons.location_on : Icons.location_off,
                        color: _currentPosition != null ? Colors.green : (_locationError != null ? Colors.red : Colors.orange),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentPosition != null
                                ? "Ubicación detectada"
                                : (_isLocationLoading ? "Obteniendo GPS..." : (_locationError ?? "Ubicación requerida")),
                              style: TextStyle(
                                color: _currentPosition != null ? Colors.green : (_locationError != null ? Colors.red : Colors.black87),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_currentPosition == null && !_isLocationLoading)
                              const Text(
                                "Pulsa el botón para activar el GPS",
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                      if (!_isLocationLoading)
                        ElevatedButton(
                          onPressed: _determinePosition,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _currentPosition != null ? Colors.green : Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          child: Text(_currentPosition != null ? "ACTUALIZAR" : "ACTIVAR GPS"),
                        ),
                    ],
                  ),
                  if (_isLocationLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: LinearProgressIndicator(minHeight: 2, color: Colors.orange),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: _isLoading ? null : _enviarReporte, style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("ENVIAR", style: TextStyle(color: Colors.white)))),
          ],
        ),
      ),
    );
  }
}
