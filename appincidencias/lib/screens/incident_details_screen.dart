import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class IncidentDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const IncidentDetailsScreen({super.key, required this.data});

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
            // Imagen a pantalla completa (o casi)
            if (data['foto_url'] != null)
              Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                ),
                child: Image.network(
                  data['foto_url'],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                  ),
                ),
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
                  // Estado y Categoría
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
                      Text(
                        fechaFormateada,
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Título Categoría
                  const Text("Categoría", style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.label_important, color: Colors.orange),
                      const SizedBox(width: 10),
                      Text(
                        data['categoria'] ?? "Sin categoría",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 40),

                  // Descripción
                  const Text("Descripción", style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      data['descripcion'] ?? "No se proporcionó descripción.",
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Información del Usuario
                  const Text("Información técnica", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 5),
                  Text("ID Usuario: ${data['uid_usuario'] ?? 'Anónimo'}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
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
