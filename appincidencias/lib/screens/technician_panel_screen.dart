import 'package:appincidencias/screens/incident_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class TechnicianPanelScreen extends StatelessWidget {
  final String especialidad;

  const TechnicianPanelScreen({super.key, required this.especialidad});

  @override
  Widget build(BuildContext context) {
    // Consulta filtrada SOLO por la especialidad del técnico
    final query = FirebaseFirestore.instanceFor(
      app: Firebase.app(), 
      databaseId: 'cantillana-native'
    ).collection('incidencias')
     .where('categoria', isEqualTo: especialidad)
     .orderBy('fecha', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: Text("Técnico: $especialidad", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueGrey,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No hay incidencias de $especialidad pendientes"));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              
              return ListTile(
                leading: data['foto_url'] != null 
                  ? CircleAvatar(backgroundImage: NetworkImage(data['foto_url']))
                  : const CircleAvatar(child: Icon(Icons.build)),
                title: Text(data['descripcion'] ?? "Sin descripción", maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text("Estado: ${data['estado'] ?? 'Pendiente'}"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => IncidentDetailsScreen(data: data, docId: doc.id))
                ),
              );
            },
          );
        },
      ),
    );
  }
}
