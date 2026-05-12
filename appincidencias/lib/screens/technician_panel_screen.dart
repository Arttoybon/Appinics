import 'package:appincidencias/screens/incident_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class TechnicianPanelScreen extends StatefulWidget {
  final String especialidad;

  const TechnicianPanelScreen({super.key, required this.especialidad});

  @override
  State<TechnicianPanelScreen> createState() => _TechnicianPanelScreenState();
}

class _TechnicianPanelScreenState extends State<TechnicianPanelScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

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
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No hay incidencias de ${widget.especialidad} pendientes"));
                }

                // Filtrado por especialidad + Categoría "Otro" + Búsqueda
                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final docId = doc.id.toLowerCase();
                  final descripcion = (data['descripcion'] ?? "").toString().toLowerCase();
                  final categoria = (data['categoria'] ?? "").toString().trim();

                  // El técnico ve: Su especialidad O las de categoría "Otro"
                  bool esDeSuInteres = categoria == widget.especialidad || categoria == "Otro";

                  // Aplicar también el filtro de búsqueda por texto
                  bool coincideBusqueda = docId.contains(_searchQuery) || descripcion.contains(_searchQuery);

                  return esDeSuInteres && coincideBusqueda;
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
