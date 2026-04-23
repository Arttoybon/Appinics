import 'package:appincidencias/screens/incident_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // Cambiar el rol de un usuario (Dar o Quitar Admin)
  Future<void> _toggleAdmin(String uid, String currentRol, String email) async {
    // Seguridad: No quitarse el admin a uno mismo por accidente
    if (uid == FirebaseAuth.instance.currentUser?.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No puedes quitarte el rango a ti mismo")),
      );
      return;
    }

    final String newRol = currentRol == 'admin' ? 'user' : 'admin';
    
    try {
      await FirebaseFirestore.instanceFor(
        app: Firebase.app(), 
        databaseId: 'cantillana-native'
      ).collection('usuarios').doc(uid).update({'rol': newRol});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newRol == 'admin' ? "$email ahora es Admin" : "Permisos quitados a $email"),
            backgroundColor: newRol == 'admin' ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Gestión Ayuntamiento", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.orange,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.people), text: "Usuarios"),
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

  // PESTAÑA 1: GESTIÓN DE USUARIOS CON BUSCADOR
  Widget _buildUserManagement() {
    final query = FirebaseFirestore.instanceFor(
      app: Firebase.app(), 
      databaseId: 'cantillana-native'
    ).collection('usuarios');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(15.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Buscar usuario por email...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              suffixIcon: _searchQuery.isNotEmpty 
                ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = "");
                  })
                : null,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.trim().toLowerCase();
              });
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: query.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No hay usuarios registrados"));

              // Filtrado manual para las sugerencias en tiempo real
              final docs = snapshot.data!.docs.where((doc) {
                final email = (doc.data() as Map<String, dynamic>)['email']?.toString().toLowerCase() ?? "";
                return email.contains(_searchQuery);
              }).toList();

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  var data = docs[index].data() as Map<String, dynamic>;
                  String email = data['email'] ?? "Sin email";
                  String rol = data['rol'] ?? "user";
                  bool isAdmin = rol == 'admin';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isAdmin ? Colors.orange : Colors.grey[200],
                      child: Icon(isAdmin ? Icons.security : Icons.person, color: isAdmin ? Colors.white : Colors.grey),
                    ),
                    title: Text(email, style: TextStyle(fontWeight: isAdmin ? FontWeight.bold : FontWeight.normal)),
                    subtitle: Text("Rol: ${isAdmin ? 'Administrador' : 'Ciudadano'}"),
                    trailing: Switch(
                      value: isAdmin,
                      activeColor: Colors.orange,
                      onChanged: (val) => _toggleAdmin(docs[index].id, rol, email),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // PESTAÑA 2: TODAS LAS INCIDENCIAS
  Widget _buildIncidentsList() {
    final query = FirebaseFirestore.instanceFor(
      app: Firebase.app(), 
      databaseId: 'cantillana-native'
    ).collection('incidencias').orderBy('fecha', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Sin incidencias"));

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            return ListTile(
              leading: data['foto_url'] != null 
                ? CircleAvatar(backgroundImage: NetworkImage(data['foto_url']))
                : const CircleAvatar(child: Icon(Icons.report)),
              title: Text(data['categoria'] ?? "Sin título"),
              subtitle: Text(data['descripcion'] ?? ""),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => IncidentDetailsScreen(data: data, docId: doc.id))),
            );
          },
        );
      },
    );
  }
}
