import 'package:appincidencias/screens/incident_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserProfileScreen extends StatelessWidget {
  final String userId;
  final String userEmail;

  const UserProfileScreen({super.key, required this.userId, required this.userEmail});

  String _getAvatarUrl(String email) {
    final String name = email.split('@')[0];
    return "https://ui-avatars.com/api/?name=$name&background=random&color=fff&size=128";
  }

  Future<Map<String, dynamic>?> _getUserData() async {
    try {
      final doc = await FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'cantillana-native',
      ).collection('usuarios').doc(userId).get();
      return doc.data();
    } catch (e) {
      debugPrint("Error fetching user data: $e");
      return null;
    }
  }

  String _formatRole(String? role, String? specialty) {
    if (role == null) return "Ciudadano";
    switch (role.toLowerCase()) {
      case 'admin':
        return "Administrador";
      case 'tecnico':
        return specialty != null ? "Técnico ($specialty)" : "Técnico";
      case 'user':
        return "Ciudadano";
      default:
        return "Usuario";
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'cantillana-native',
    ).collection('incidencias')
     .where('uid_usuario', isEqualTo: userId)
     .orderBy('fecha', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Perfil de Usuario", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          FutureBuilder<Map<String, dynamic>?>(
            future: _getUserData(),
            builder: (context, snapshot) {
              String roleText = "Cargando...";
              if (snapshot.connectionState == ConnectionState.done) {
                final data = snapshot.data;
                roleText = _formatRole(data?['rol'], data?['especialidad']);
              }

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  border: const Border(bottom: BorderSide(color: Colors.orange, width: 0.5)),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(_getAvatarUrl(userEmail)),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      userEmail,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      roleText,
                      style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.all(15),
            child: Row(
              children: [
                Icon(Icons.history, color: Colors.grey),
                SizedBox(width: 10),
                Text("HISTORIAL DE INCIDENCIAS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Este usuario no tiene incidencias"));

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    DateTime? fecha = (data['fecha'] as Timestamp?)?.toDate();
                    String fechaStr = fecha != null ? DateFormat('dd/MM/yyyy').format(fecha) : "S/F";
                    String estado = data['estado'] ?? 'Pendiente';

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: data['foto_url'] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                data['foto_url'],
                                width: 45,
                                height: 45,
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.medium,
                              ),
                            )
                          : const Icon(Icons.report, color: Colors.orange),
                        title: Text(data['categoria'] ?? "Sin categoría", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Estado: $estado\nFecha: $fechaStr"),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => IncidentDetailsScreen(data: data, docId: doc.id))),
                      ),
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
