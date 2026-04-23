import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // Para abrir Google Maps

class IncidentDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const IncidentDetailsScreen({super.key, required this.data});

  // Función para abrir la ubicación en Google Maps
  Future<void> _openMap() async {
    final double? lat = data['latitud'];
    final double? lng = data['longitud'];

    if (lat != null && lng != null) {
      final Uri url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('No se pudo abrir el mapa');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime? fecha = (data['fecha'] != null) ? data['fecha'].toDate() : null;
    String fechaFormateada = fecha != null 
        ? DateFormat('dd/MM/yyyy HH:mm').format(fecha) 
        : "Sin fecha";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalles de Incidencia", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data['foto_url'] != null)
              Image.network(
                data['foto_url'],
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
              )
            else
              Container(
                width: double.infinity,
                height: 150,
                color: Colors.orange.withOpacity(0.1),
                child: const Icon(Icons.image_not_supported, size: 50, color: Colors.orange),
              ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(data['estado']),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          (data['estado'] ?? "Pendiente").toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      Text(fechaFormateada, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  const Text("Categoría", style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(data['categoria'] ?? "Sin categoría", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  
                  const Divider(height: 40),

                  const Text("Descripción", style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(data['descripcion'] ?? "Sin descripción", style: const TextStyle(fontSize: 16)),
                  
                  const Divider(height: 40),

                  // Sección de Ubicación
                  const Text("Ubicación", style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  if (data['latitud'] != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.location_on, color: Colors.red),
                      title: const Text("Ver en Google Maps"),
                      subtitle: Text("Lat: ${data['latitud']}, Lng: ${data['longitud']}"),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: _openMap,
                    )
                  else
                    const Text("Ubicación no disponible", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Resuelta': return Colors.green;
      case 'En proceso': return Colors.blue;
      default: return Colors.orange;
    }
  }
}
