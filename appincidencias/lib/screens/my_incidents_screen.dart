import 'package:appincidencias/screens/incident_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyIncidentsScreen extends StatefulWidget {
  const MyIncidentsScreen({super.key});

  @override
  State<MyIncidentsScreen> createState() => _MyIncidentsScreenState();
}

class _MyIncidentsScreenState extends State<MyIncidentsScreen> {
  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    // Apuntamos a la base de datos NATIVA para permitir Snapshots (Tiempo Real)
    final query = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'cantillana-native',
    ).collection('incidencias')
     .where('uid_usuario', isEqualTo: uid)
     .orderBy('fecha', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Incidencias", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(), // ¡Ya podemos usar Snapshots en Modo Nativo!
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No tienes incidencias registradas"));

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              DateTime? fecha = (data['fecha'] as Timestamp?)?.toDate();
              String fechaStr = fecha != null ? DateFormat('dd/MM/yyyy').format(fecha) : "S/F";

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
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
                    : const Icon(Icons.report, color: Colors.orange),
                  title: Text(data['categoria'] ?? "Sin título", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${data['descripcion']}\n$fechaStr"),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => IncidentDetailsScreen(data: data, docId: doc.id))),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
