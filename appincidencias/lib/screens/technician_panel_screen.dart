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
  Widget build(BuildContext context) {
    // Consulta para obtener incidencias (el filtrado por especialidad se hará en el StreamBuilder para permitir "Otro")
    final query = FirebaseFirestore.instanceFor(
      app: Firebase.app(), 
      databaseId: 'cantillana-native'
    ).collection('incidencias')
     .orderBy('fecha', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: Text("Técnico: ${widget.especialidad}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueGrey,
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
      body: Column(
        children: [
          // Barra de búsqueda por ID o Descripción
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Buscar por ID o descripción...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
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
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
            ),
          ),

          // Filtros por Estado y Asignación
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
            child: Row(
              children: [
                // Chip de "Asignadas a mí"
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: const Text("Asignadas a mí"),
                    selected: _onlyShowAssigned,
                    onSelected: (val) => setState(() => _onlyShowAssigned = val),
                    selectedColor: Colors.blueGrey.withOpacity(0.3),
                    avatar: Icon(Icons.person, size: 16, color: _onlyShowAssigned ? Colors.blueGrey : Colors.grey),
                  ),
                ),
                // Chips de Estado
                ...["Todas", "Pendiente", "En proceso", "Resuelta"].map((status) {
                  bool isSelected = _selectedStatusFilter == status;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(status),
                      selected: isSelected,
                      onSelected: (val) => setState(() => _selectedStatusFilter = status),
                      selectedColor: Colors.orange.withOpacity(0.3),
                      labelStyle: TextStyle(color: isSelected ? Colors.orange[900] : Colors.black),
                    ),
                  );
                }).toList(),
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

                // Filtrado por especialidad + Categoría "Otro" + Búsqueda + Estado + Asignación
                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final docId = doc.id.toLowerCase();
                  final descripcion = (data['descripcion'] ?? "").toString().toLowerCase();
                  final categoria = (data['categoria'] ?? "").toString().trim();
                  final estado = data['estado'] ?? 'Pendiente';
                  final asignadoA = data['asignado_a_uid'];

                  // 1. Interés del técnico: Su especialidad O "Otro"
                  bool esDeSuInteres = categoria == widget.especialidad || categoria == "Otro";

                  // 2. Filtro de Asignación
                  bool cumpleAsignacion = !_onlyShowAssigned || (asignadoA == currentUser?.uid);

                  // 3. Filtro de Estado
                  bool cumpleEstado = _selectedStatusFilter == "Todas" || estado == _selectedStatusFilter;

                  // 4. Filtro de Búsqueda de texto
                  bool coincideBusqueda = docId.contains(_searchQuery) || descripcion.contains(_searchQuery);

                  return esDeSuInteres && cumpleAsignacion && cumpleEstado && coincideBusqueda;
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text("No se encontraron coincidencias"));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var doc = docs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    
                    return ListTile(
                      leading: data['foto_url'] != null 
                        ? CircleAvatar(backgroundImage: NetworkImage(data['foto_url']))
                        : const CircleAvatar(child: Icon(Icons.build)),
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
                          Text(
                            "#${doc.id.substring(0, 6)}", 
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                      subtitle: Text("Estado: ${data['estado'] ?? 'Pendiente'}"),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => IncidentDetailsScreen(data: data, docId: doc.id))
                      ).then((_) => setState(() {})),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
