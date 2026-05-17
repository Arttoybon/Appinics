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
    _checkShowGuide(); // Comprobar si mostrar la guia
  }

  Future<void> _checkShowGuide() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'cantillana-native')
          .collection('usuarios').doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data();
        bool guiaVista = data?['guiaVista'] ?? false;
        if (!guiaVista) {
          if (mounted) _showOnboardingGuide();
        }
      }
    } catch (e) {
      debugPrint("Error checking guide: $e");
    }
  }

  void _showOnboardingGuide() {
    final List<Map<String, String>> guideSteps = [
      {
        'titulo': '¡Bienvenido a Cantillana Report!',
        'mensaje': 'Esta app te permite avisar al ayuntamiento de cualquier desperfecto en el municipio de forma rápida y directa.',
        'icono': '👋'
      },
      {
        'titulo': 'Tus Incidencias (Icono Lista)',
        'mensaje': 'Pulsa el icono de la lista arriba a la izquierda para ver el historial y estado de todos tus reportes enviados.',
        'icono': '📋'
      },
      {
        'titulo': 'Notificaciones (Campana)',
        'mensaje': 'Aquí verás un punto rojo si un técnico ha comentado tu incidencia o si ya ha sido resuelta.',
        'icono': '🔔'
      },
      {
        'titulo': 'Tu Perfil (Usuario)',
        'mensaje': 'Desde aquí puedes consultar tu correo y DNI, o cerrar la sesión de forma segura.',
        'icono': '👤'
      },
      {
        'titulo': '1. Selecciona la Categoría',
        'mensaje': 'Elige el tipo de problema pulsando en los iconos. Si no ves uno que encaje, usa "Otro".',
        'icono': '💡'
      },
      {
        'titulo': '2. Evidencia (Foto)',
        'mensaje': 'Pulsa "Añadir Foto" para subir una imagen clara. ¡Es de gran ayuda para nuestros técnicos!',
        'icono': '📸'
      },
      {
        'titulo': '3. ¡Activa el GPS!',
        'mensaje': 'Es obligatorio pulsar "ACTIVAR GPS". Así sabremos el lugar exacto sin que tengas que escribir la dirección.',
        'icono': '📍'
      },
      {
        'titulo': '4. Envío Final',
        'mensaje': 'Cuando todo esté listo, pulsa "ENVIAR INCIDENCIA". ¡Gracias por colaborar con tu municipio!',
        'icono': '🚀'
      },
    ];

    _showNextGuideStep(0, guideSteps);
  }

  void _showNextGuideStep(int index, List<Map<String, String>> steps) {
    if (index >= steps.length) {
      // Marcar guia como vista en Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'cantillana-native')
            .collection('usuarios').doc(user.uid).update({'guiaVista': true});
      }
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Text(steps[index]['icono']!, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 10),
            Text(steps[index]['titulo']!, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(steps[index]['mensaje']!, textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showNextGuideStep(index + 1, steps);
            },
            child: Text(index == steps.length - 1 ? "¡EMPEZAR!" : "SIGUIENTE", style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
        // En WEB, LocationAccuracy.high puede causar timeouts infinitos. Usamos medium.
        LocationAccuracy desiredAccuracy = kIsWeb ? LocationAccuracy.medium : LocationAccuracy.high;

        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: desiredAccuracy,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (e) {
        debugPrint("Error al obtener posición actual, intentando última conocida: $e");
        position = await Geolocator.getLastKnownPosition();
        if (position == null) {
          throw 'No se pudo obtener la ubicación. Asegúrate de dar permisos en el navegador y tener internet.';
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
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.redAccent),
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
          content: Text("Por favor, completa todos los campos (Categoría, Descripción, Foto y Ubicación)"),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Incidencia enviada"), backgroundColor: Colors.green));
      setState(() { _categoriaSeleccionada = null; _descController.clear(); _imagenSeleccionada = null; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nuevo Reporte", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: themeColor,
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: Column(
              children: [
                const Text("1. Selecciona la categoría", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    int gridCount = constraints.maxWidth > 500 ? 3 : 2;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: gridCount,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        childAspectRatio: 1.8
                      ),
                      itemCount: _categorias.length,
                      itemBuilder: (context, index) {
                        bool seleccionada = _categoriaSeleccionada == _categorias[index]['nombre'];
                        return InkWell(
                          onTap: () => setState(() => _categoriaSeleccionada = _categorias[index]['nombre']),
                          child: Container(
                            decoration: BoxDecoration(
                              color: seleccionada ? themeColor.withOpacity(0.2) : Colors.grey[100],
                              border: Border.all(color: seleccionada ? themeColor : Colors.transparent, width: 2),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(_categorias[index]['icon'], color: themeColor, size: 35),
                                const SizedBox(height: 5),
                                Text(_categorias[index]['nombre'], style: const TextStyle(fontWeight: FontWeight.bold))
                              ]
                            ),
                          ),
                        );
                      },
                    );
                  }
                ),
                const SizedBox(height: 35),
                const Text("2. Describe lo que sucede", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 15),
                TextField(
                  controller: _descController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: "Escribe aquí los detalles de la incidencia...",
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)
                  )
                ),
                const SizedBox(height: 35),
                const Text("3. Evidencia visual", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 15),
                Center(
                  child: Column(
                    children: [
                      if (_imagenSeleccionada != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: kIsWeb
                              ? Image.network(_imagenSeleccionada!.path, height: 300, width: double.infinity, fit: BoxFit.cover, filterQuality: FilterQuality.medium)
                              : Image.file(File(_imagenSeleccionada!.path), height: 300, width: double.infinity, fit: BoxFit.cover),
                          ),
                        ),
                      ElevatedButton.icon(
                        onPressed: _tomarFoto,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text("Añadir Foto"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 35),
                const Text("4. Ubicación exacta", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(15),
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
                            size: 30,
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentPosition != null
                                    ? "Ubicación detectada correctamente"
                                    : (_isLocationLoading ? "Obteniendo GPS..." : (_locationError ?? "Ubicación requerida")),
                                  style: TextStyle(
                                    color: _currentPosition != null ? Colors.green : (_locationError != null ? Colors.red : Colors.black87),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                if (_currentPosition == null && !_isLocationLoading)
                                  const Text(
                                    "Pulsa el botón de la derecha para geolocalizar la incidencia",
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (!_isLocationLoading)
                            ElevatedButton(
                              onPressed: _determinePosition,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _currentPosition != null ? Colors.green : Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                              ),
                              child: Text(_currentPosition != null ? "ACTUALIZAR" : "ACTIVAR GPS"),
                            ),
                        ],
                      ),
                      if (_isLocationLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 15.0),
                          child: LinearProgressIndicator(minHeight: 3, color: Colors.orange),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _enviarReporte,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("ENVIAR INCIDENCIA", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))
                  )
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
