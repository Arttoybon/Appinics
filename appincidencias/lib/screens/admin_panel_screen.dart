import 'package:appincidencias/screens/incident_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

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

  void _showRoleDialog(String uid, String email, String currentRol, String? currentEspecialidad) {
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
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Gestión Municipal", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.orange,
          iconTheme: const IconThemeData(color: Colors.white),
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
    final query = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'cantillana-native').collection('usuarios');
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(15),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: "Buscar por email...", 
            prefixIcon: const Icon(Icons.search), 
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))
          ),
          onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
        ),
      ),
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: query.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs.where((d) => (d.data() as Map)['email'].toString().toLowerCase().contains(_searchQuery)).toList();
            
            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                var data = docs[index].data() as Map<String, dynamic>;
                String email = data['email'] ?? "";
                String rol = data['rol'] ?? 'user';
                String? esp = data['especialidad'];

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(_getAvatarUrl(email)),
                    ),
                    title: Text(email, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text("Rol: ${rol.toUpperCase()} ${esp != null ? '($esp)' : ''}"),
                    trailing: const Icon(Icons.edit, size: 20),
                    onTap: () => _showRoleDialog(docs[index].id, email, rol, esp),
                  ),
                );
              },
            );
          },
        ),
      ),
    ]);
  }

  Widget _buildIncidentsList() {
    final query = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'cantillana-native').collection('incidencias').orderBy('fecha', descending: true);
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Row(
            children: ["Todas", "Pendiente", "En proceso", "Resuelta"].map((status) {
              bool isSelected = _selectedStatusFilter == status;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(status),
                  selected: isSelected,
                  onSelected: (val) => setState(() => _selectedStatusFilter = status),
                  selectedColor: Colors.orange,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: query.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              
              final docs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final statusMatch = _selectedStatusFilter == "Todas" || (data['estado'] ?? "Pendiente") == _selectedStatusFilter;
                return statusMatch;
              }).toList();

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  var doc = docs[index];
                  var data = doc.data() as Map<String, dynamic>;
                  return ListTile(
                    leading: data['foto_url'] != null 
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            data['foto_url'],
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.medium,
                          ),
                        )
                      : const CircleAvatar(child: Icon(Icons.report)),
                    title: Text(data['categoria'] ?? "General", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(data['descripcion'] ?? "", maxLines: 1),
                    trailing: Text("#${doc.id.substring(0,6)}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => IncidentDetailsScreen(data: data, docId: doc.id))),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
