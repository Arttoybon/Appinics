import 'package:appincidencias/screens/incident_details_screen.dart';
import 'package:appincidencias/screens/my_incidents_screen.dart';
import 'package:appincidencias/screens/report_screen.dart';
import 'package:appincidencias/screens/notifications_screen.dart';
import 'package:appincidencias/screens/user_profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:appincidencias/utils/web_reload/web_reload.dart';

class TechnicianPanelScreen extends StatefulWidget {
  final String especialidad;

  const TechnicianPanelScreen({super.key, required this.especialidad});

  @override
  State<TechnicianPanelScreen> createState() => _TechnicianPanelScreenState();
}

class _TechnicianPanelScreenState extends State<TechnicianPanelScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedStatusFilter = "Pendiente";
  bool _onlyShowAssigned = true;

  @override
  void initState() {
    super.initState();
    _checkShowGuide();
  }

  Future<void> _checkShowGuide() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'cantillana-native')
          .collection('usuarios').doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data();
        bool guiaTecnicoVista = data?['guiaTecnicoVista'] ?? false;
        if (!guiaTecnicoVista) {
          if (mounted) _showTechnicianGuide();
        }
      }
    } catch (e) {
      debugPrint("Error checking tech guide: $e");
    }
  }

  void _showTechnicianGuide() {
    final List<Map<String, String>> steps = [
      {
        'titulo': '¡Bienvenido Técnico!',
        'mensaje': 'Este es tu panel central de trabajo. Aquí gestionarás las incidencias de tu especialidad.',
        'icono': '🛠️'
      },
      {
        'titulo': 'Crear Reporte (+)',
        'mensaje': 'Si detectas un problema mientras trabajas, pulsa el icono "+" arriba a la derecha para crear un nuevo reporte tú mismo.',
        'icono': '➕'
      },
      {
        'titulo': 'Filtros de Eficiencia',
        'mensaje': 'Por defecto verás solo las incidencias "Pendientes" que tienes "Asignadas a ti". Pulsa los botones para ver el resto.',
        'icono': '📍'
      },
      {
        'titulo': 'Búsqueda Maestro',
        'mensaje': 'Usa el buscador para localizar un ID o descripción. Al escribir, se ignorarán los otros filtros automáticamente.',
        'icono': '🔍'
      },
      {
        'titulo': 'Gestión de Estados',
        'mensaje': 'Al pulsar en una incidencia, recuerda cambiar el estado a "En proceso" o "Resuelta" para notificar al ciudadano.',
        'icono': '✅'
      },
      {
        'titulo': 'Perfil y Salida',
        'mensaje': 'Usa los iconos de usuario para ver tus datos o el de salida para cerrar tu sesión técnica.',
        'icono': '👤'
      },
    ];
    _showNextGuideStep(0, steps);
  }

  void _showNextGuideStep(int index, List<Map<String, String>> steps) {
    if (index >= steps.length) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'cantillana-native')
            .collection('usuarios').doc(user.uid).update({'guiaTecnicoVista': true});
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
            child: Text(index == steps.length - 1 ? "ENTENDIDO" : "SIGUIENTE"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;
    final query = FirebaseFirestore.instanceFor(
      app: Firebase.app(), 
      databaseId: 'cantillana-native'
    ).collection('incidencias')
     .orderBy('fecha', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: Text("Técnico: ${widget.especialidad}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: themeColor,
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Crear Incidencia',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Mis Incidencias',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyIncidentsScreen())),
          ),
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
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
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
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 800;

          return Column(
            children: [
              // Barra de busqueda y Filtros en una fila si es Web
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: isWide
                  ? Row(
                      children: [
                        Expanded(flex: 3, child: _buildSearchBar()),
                        const SizedBox(width: 20),
                        Expanded(flex: 4, child: _buildFilters(themeColor)),
                      ],
                    )
                  : Column(
                      children: [
                        _buildSearchBar(),
                        const SizedBox(height: 10),
                        _buildFilters(themeColor),
                      ],
                    ),
              ),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: query.snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text("No hay incidencias de ${widget.especialidad} pendientes"));
                    }

                    final currentUser = FirebaseAuth.instance.currentUser;

                    final queryText = _searchQuery.trim().toLowerCase();
                    final bool isSearching = queryText.isNotEmpty;

                    // Filtrado por especialidad + Categoria "Otro" + Busqueda + Estado + Asignacion
                    final docs = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final categoria = (data['categoria'] ?? "").toString().trim();

                      // Regla 0: Siempre debe ser de su especialidad u "Otro"
                      bool esDeSuInteres = (categoria == widget.especialidad || categoria == "Otro");
                      if (!esDeSuInteres) return false;

                      if (isSearching) {
                        // Modo Busqueda: Ignoramos botones de estado y asignacion
                        final docId = doc.id.toLowerCase();
                        final descripcion = (data['descripcion'] ?? "").toString().toLowerCase();
                        return docId.contains(queryText) || descripcion.contains(queryText);
                      } else {
                        // Modo Normal: Aplicamos todos los filtros
                        final estado = data['estado'] ?? 'Pendiente';
                        final asignadoA = data['asignado_a_uid'];

                        bool cumpleAsignacion = !_onlyShowAssigned || (asignadoA == currentUser?.uid);
                        bool cumpleEstado = (_selectedStatusFilter == "Todas" || estado == _selectedStatusFilter);

                        return cumpleAsignacion && cumpleEstado;
                      }
                    }).toList();

                    if (docs.isEmpty) {
                      return const Center(child: Text("No se encontraron coincidencias"));
                    }

                    // GRID para WEB, LISTA para MOVIL
                    return isWide
                      ? GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                            childAspectRatio: 3.5,
                          ),
                          itemCount: docs.length,
                          itemBuilder: (context, index) => _buildIncidentCard(docs[index], themeColor),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          itemCount: docs.length,
                          itemBuilder: (context, index) => _buildIncidentCard(docs[index], themeColor),
                        );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: "Buscar por ID o descripción...",
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        suffixIcon: _searchQuery.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = "");
              }
            )
          : null,
      ),
      onChanged: (value) => setState(() => _searchQuery = value.trim().toLowerCase()),
    );
  }

  Widget _buildFilters(Color themeColor) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: const Text("Asignadas a mí"),
            selected: _onlyShowAssigned,
            onSelected: (val) => setState(() => _onlyShowAssigned = val),
            selectedColor: themeColor.withOpacity(0.3),
            avatar: Icon(Icons.person, size: 16, color: _onlyShowAssigned ? themeColor : Colors.grey),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(width: 8),
          ...["Todas", "Pendiente", "En proceso", "Resuelta"].map((status) {
            bool isSelected = _selectedStatusFilter == status;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                label: Text(status),
                selected: isSelected,
                onSelected: (val) => setState(() => _selectedStatusFilter = status),
                selectedColor: themeColor.withOpacity(0.3),
                labelStyle: TextStyle(color: isSelected ? themeColor : Colors.black),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildIncidentCard(DocumentSnapshot doc, Color themeColor) {
    final data = doc.data() as Map<String, dynamic>;
    String estado = data['estado'] ?? 'Pendiente';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: data['foto_url'] != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                data['foto_url'],
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
              ),
            )
          : CircleAvatar(backgroundColor: themeColor.withOpacity(0.1), child: const Icon(Icons.build, color: Colors.blueGrey)),
        title: Row(
          children: [
            Expanded(
              child: Text(
                data['descripcion'] ?? "Sin descripción",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Text("#${doc.id.substring(0, 6)}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Categoría: ${data['categoria']}", style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(estado).withOpacity(0.1),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                estado,
                style: TextStyle(color: _getStatusColor(estado), fontSize: 10, fontWeight: FontWeight.bold)
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => IncidentDetailsScreen(data: data, docId: doc.id))
        ).then((_) => setState(() {})),
      ),
    );
  }

  Color _getStatusColor(String estado) {
    switch (estado) {
      case 'Resuelta': return Colors.green;
      case 'En proceso': return Colors.blue;
      default: return Colors.orange;
    }
  }
}
