import 'package:appincidencias/screens/incident_details_screen.dart';
import 'package:appincidencias/screens/my_incidents_screen.dart';
import 'package:appincidencias/screens/report_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:appincidencias/utils/web_reload/web_reload.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  final String _selectedStatus = "Todas";
  final TextEditingController _incidentSearchController = TextEditingController();
  String _incidentSearchQuery = "";
  String _selectedStatusFilter = "Todas";

  // Generar URL de avatar dinámico basado en el email
  String _getAvatarUrl(String email) {
    final String name = email.split('@')[0];
    return "https://ui-avatars.com/api/?name=$name&background=random&color=fff&size=128";
  }

  Future<void> _updateUserRole(String uid, String newRol, {String? especialidad}) async {
    if (uid == FirebaseAuth.instance.currentUser?.uid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No puedes editarte a ti mismo")));
      return;
    }
    try {
      await FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'cantillana-native')
          .collection('usuarios').doc(uid).update({
            'rol': newRol,
            'especialidad': especialidad
          });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Permisos actualizados correctamente"), 
          backgroundColor: Colors.green
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al actualizar: $e")));
    }
  }

  Future<void> _toggleBlockUser(String uid, bool currentStatus) async {
    if (uid == FirebaseAuth.instance.currentUser?.uid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No puedes bloquearte a ti mismo")));
      return;
    }
    try {
      await FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'cantillana-native')
          .collection('usuarios').doc(uid).update({'estaBloqueado': !currentStatus});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(!currentStatus ? "Usuario BLOQUEADO" : "Usuario DESBLOQUEADO"),
          backgroundColor: !currentStatus ? Colors.red : Colors.green
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _deleteUser(String uid) async {
    if (uid == FirebaseAuth.instance.currentUser?.uid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No puedes eliminarte a ti mismo")));
      return;
    }

    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Eliminar usuario?"),
        content: const Text("Esta acción desactivará la cuenta permanentemente."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCELAR")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("ELIMINAR", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        final batch = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'cantillana-native').batch();

        // 1. Referencia al usuario
        final userRef = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'cantillana-native')
            .collection('usuarios').doc(uid);
        batch.delete(userRef);

        // 2. Buscar y borrar sus incidencias
        final incidentsQuery = await FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'cantillana-native')
            .collection('incidencias').where('uid_usuario', isEqualTo: uid).get();

        for (var doc in incidentsQuery.docs) {
          batch.delete(doc.reference);
        }

        // Ejecutar todo en un solo proceso
        await batch.commit();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Usuario e incidencias eliminados permanentemente"),
            backgroundColor: Colors.red
          ));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  void _showRoleDialog(String uid, String email, String currentRol, String? currentEspecialidad, bool isBlocked) {
    String selectedRol = currentRol;
    String? selectedEspecialidad = currentEspecialidad;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              CircleAvatar(backgroundImage: NetworkImage(_getAvatarUrl(email)), radius: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(email, style: const TextStyle(fontSize: 14))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Selecciona el Rol:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              DropdownButton<String>(
                value: selectedRol,
                isExpanded: true,
                items: ['user', 'tecnico', 'admin'].map((v) => DropdownMenuItem(
                  value: v, 
                  child: Text(v == 'user' ? "Ciudadano" : v.toUpperCase())
                )).toList(),
                onChanged: (v) => setDialogState(() {
                  selectedRol = v!;
                  if (selectedRol != 'tecnico') selectedEspecialidad = null;
                }),
              ),
              const SizedBox(height: 20),
              if (selectedRol == 'tecnico') ...[
                const Text("Selecciona Especialidad:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                DropdownButton<String>(
                  hint: const Text("Elegir Categoría"),
                  value: selectedEspecialidad,
                  isExpanded: true,
                  items: ['Alumbrado', 'Limpieza', 'Mobiliario', 'Vías'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                  onChanged: (v) => setDialogState(() => selectedEspecialidad = v),
                ),
              ],
              const Divider(height: 30),
              const Text("MODERACIÓN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.grey)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _toggleBlockUser(uid, isBlocked);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: isBlocked ? Colors.green : Colors.red),
                    child: Text(isBlocked ? "DESBLOQUEAR" : "BLOQUEAR", style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteUser(uid);
                    },
                  )
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CERRAR")),
            ElevatedButton(
              onPressed: () {
                if (selectedRol == 'tecnico' && selectedEspecialidad == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Debes elegir una especialidad")));
                  return;
                }
                _updateUserRole(uid, selectedRol, especialidad: selectedEspecialidad);
                Navigator.pop(context);
              }, 
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text("GUARDAR", style: TextStyle(color: Colors.white))
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Gestión Municipal", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: themeColor,
          iconTheme: const IconThemeData(color: Colors.white),
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
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.people), text: "Roles"),
              Tab(icon: Icon(Icons.assignment), text: "Incidencias"),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
          ),
        ),
        body: TabBarView(
          children: [
            _buildUserManagement(),
            _buildIncidentsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserManagement() {
    final themeColor = Theme.of(context).primaryColor;
    final usersQuery = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'cantillana-native').collection('usuarios');
    final incidentsQuery = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'cantillana-native').collection('incidencias');

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWide = constraints.maxWidth > 800;

        return Column(children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Buscar por email...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: usersQuery.snapshots(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());

                return StreamBuilder<QuerySnapshot>(
                  stream: incidentsQuery.snapshots(),
                  builder: (context, incidentSnapshot) {
                    Set<String> reporters = {};
                    if (incidentSnapshot.hasData) {
                      for (var doc in incidentSnapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        if (data['email_usuario'] != null) {
                          reporters.add(data['email_usuario'].toString().toLowerCase());
                        }
                      }
                    }

                    final registeredUsers = userSnapshot.data!.docs.map((d) => d.data() as Map<String, dynamic>).toList();
                    final registeredEmails = registeredUsers.map((u) => u['email'].toString().toLowerCase()).toSet();
                    List<String> missingEmails = reporters.where((email) => !registeredEmails.contains(email)).toList();

                    final docs = userSnapshot.data!.docs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      return data['email'].toString().toLowerCase().contains(_searchQuery);
                    }).toList();

                    if (isWide) {
                      // VISTA WEB: Grid de Usuarios
                      return GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          childAspectRatio: 2.5,
                        ),
                        itemCount: docs.length + (missingEmails.isNotEmpty && _searchQuery.isEmpty ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (missingEmails.isNotEmpty && _searchQuery.isEmpty && index == 0) {
                            return _buildMissingUsersAlert(missingEmails);
                          }
                          final actualIndex = (missingEmails.isNotEmpty && _searchQuery.isEmpty) ? index - 1 : index;
                          return _buildUserCard(docs[actualIndex], themeColor);
                        },
                      );
                    } else {
                      // VISTA MÓVIL: Lista normal
                      return ListView(
                        children: [
                          if (missingEmails.isNotEmpty && _searchQuery.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(15),
                              child: _buildMissingUsersAlert(missingEmails),
                            ),
                          ...docs.map((doc) => _buildUserCard(doc, themeColor)).toList(),
                        ],
                      );
                    }
                  },
                );
              },
            ),
          ),
        ]);
      },
    );
  }

  Widget _buildMissingUsersAlert(List<String> missingEmails) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.amber[100], borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 10),
                Text("Usuarios no registrados", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
              ],
            ),
            const SizedBox(height: 5),
            const Text("Han enviado incidencias pero aún no tienen perfil oficial:", style: TextStyle(fontSize: 11)),
            const SizedBox(height: 10),
            ...missingEmails.take(5).map((e) => Text("• $e", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
            if (missingEmails.length > 5) Text("... y ${missingEmails.length - 5} más", style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(DocumentSnapshot doc, Color themeColor) {
    var data = doc.data() as Map<String, dynamic>;
    String email = data['email'] ?? "";
    String rol = data['rol'] ?? 'user';
    String? esp = data['especialidad'];
    bool isBlocked = data['estaBloqueado'] == true;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isBlocked ? Colors.red[50] : null,
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: CircleAvatar(
          backgroundImage: NetworkImage(_getAvatarUrl(email)),
          child: isBlocked ? const Icon(Icons.block, color: Colors.red, size: 25) : null,
        ),
        title: Text(email, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Rol: ${rol.toUpperCase()}", style: const TextStyle(fontSize: 11)),
            if (esp != null) Text("Espec.: $esp", style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
            if (isBlocked) const Text("BLOQUEADO", style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: Icon(Icons.edit, size: 18, color: themeColor),
        onTap: () => _showRoleDialog(doc.id, email, rol, esp, isBlocked),
      ),
    );
  }

  Widget _buildIncidentsList() {
    final themeColor = Theme.of(context).primaryColor;
    final query = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'cantillana-native').collection('incidencias').orderBy('fecha', descending: true);

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWide = constraints.maxWidth > 800;

        return Column(
          children: [
            // Barra de búsqueda y Filtros en una sola fila si es Web
            Padding(
              padding: const EdgeInsets.all(20),
              child: isWide
                ? Row(
                    children: [
                      Expanded(flex: 2, child: _buildIncidentSearchBar()),
                      const SizedBox(width: 20),
                      Expanded(flex: 3, child: _buildStatusFilters()),
                    ],
                  )
                : Column(
                    children: [
                      _buildIncidentSearchBar(),
                      const SizedBox(height: 10),
                      _buildStatusFilters(),
                    ],
                  ),
            ),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: query.snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final docs = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final q = _incidentSearchQuery.trim().toLowerCase();
                    final bool isSearching = q.isNotEmpty;

                    if (isSearching) {
                      final idMatch = doc.id.toLowerCase().contains(q);
                      final descMatch = (data['descripcion'] ?? "").toString().toLowerCase().contains(q);
                      return idMatch || descMatch;
                    } else {
                      final statusMatch = _selectedStatusFilter == "Todas" || (data['estado'] ?? "Pendiente") == _selectedStatusFilter;
                      return statusMatch;
                    }
                  }).toList();

                  if (docs.isEmpty) {
                    return const Center(child: Text("No se encontraron incidencias"));
                  }

                  // GRID para WEB, LISTA para MÓVIL
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
    );
  }

  Widget _buildIncidentSearchBar() {
    return TextField(
      controller: _incidentSearchController,
      decoration: InputDecoration(
        hintText: "Buscar por ID o descripción...",
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _incidentSearchQuery.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _incidentSearchController.clear();
                setState(() => _incidentSearchQuery = "");
              }
            )
          : null,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
      ),
      onChanged: (v) => setState(() => _incidentSearchQuery = v.toLowerCase()),
    );
  }

  Widget _buildStatusFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ["Todas", "Pendiente", "En proceso", "Resuelta"].map((status) {
          bool isSelected = _selectedStatusFilter == status;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(status),
              selected: isSelected,
              onSelected: (val) => setState(() => _selectedStatusFilter = status),
              selectedColor: Theme.of(context).primaryColor,
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }).toList(),
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
          : CircleAvatar(backgroundColor: themeColor.withOpacity(0.1), child: Icon(Icons.report, color: themeColor)),
        title: Row(
          children: [
            Expanded(child: Text(data['categoria'] ?? "General", style: const TextStyle(fontWeight: FontWeight.bold))),
            Text("#${doc.id.substring(0,6)}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data['descripcion'] ?? "", maxLines: 1, overflow: TextOverflow.ellipsis),
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
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => IncidentDetailsScreen(data: data, docId: doc.id))),
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
