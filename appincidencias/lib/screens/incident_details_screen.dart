import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class IncidentDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final String docId;

  const IncidentDetailsScreen({super.key, required this.data, required this.docId});

  @override
  State<IncidentDetailsScreen> createState() => _IncidentDetailsScreenState();
}

class _IncidentDetailsScreenState extends State<IncidentDetailsScreen> {
  bool _isAdmin = false;
  bool _isTechnician = false; // Nueva detección
  bool _isSuperAdmin = false;
  String? _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.data['estado'] ?? 'Pendiente';
    _checkUserPrivileges();
  }

  Future<void> _checkUserPrivileges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (user.email == 'rosadelalbaxx@gmail.com') {
        if (mounted) setState(() => _isSuperAdmin = true);
      }
      
      try {
        final doc = await FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'cantillana-native')
            .collection('usuarios').doc(user.uid).get();
            
        if (doc.exists) {
          String? rol = doc.data()?['rol']?.toString().trim().toLowerCase();
          
          if (mounted) {
            setState(() {
              if (rol == 'admin' || _isSuperAdmin) {
                _isAdmin = true;
              } else if (rol == 'tecnico') {
                _isTechnician = true;
              }
            });
          }
        } else if (_isSuperAdmin) {
          if (mounted) setState(() => _isAdmin = true);
        }
      } catch (e) {
        if (_isSuperAdmin) {
          if (mounted) setState(() => _isAdmin = true);
        }
      }
    }
  }

  Future<void> _updateStatus(String? newStatus) async {
    if (newStatus == null) return;
    try {
      await FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'cantillana-native')
          .collection('incidencias').doc(widget.docId).update({'estado': newStatus});
      setState(() => _currentStatus = newStatus);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Estado actualizado"), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  Future<void> _deleteIncident() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Eliminar incidencia?"),
        content: const Text("Esta acción no se puede deshacer."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCELAR")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("ELIMINAR", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        await FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'cantillana-native')
            .collection('incidencias').doc(widget.docId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Incidencia eliminada"), backgroundColor: Colors.red));
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al eliminar: $e")));
      }
    }
  }

  Future<void> _openMap() async {
    final double? lat = widget.data['latitud'];
    final double? lng = widget.data['longitud'];
    if (lat != null && lng != null) {
      final Uri url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) throw 'Error al abrir mapa';
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime? fecha = (widget.data['fecha'] != null) ? (widget.data['fecha'] as Timestamp).toDate() : null;
    String fechaStr = fecha != null ? DateFormat('dd/MM/yyyy HH:mm').format(fecha) : "S/F";

    // Un Admin o un Técnico pueden cambiar el estado
    bool canChangeStatus = _isAdmin || _isTechnician;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalles"), 
        backgroundColor: Colors.orange, 
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isSuperAdmin)
            IconButton(icon: const Icon(Icons.delete_forever, color: Colors.white), onPressed: _deleteIncident),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (widget.data['foto_url'] != null) Image.network(widget.data['foto_url'], width: double.infinity, height: 250, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (canChangeStatus) ...[
                    Text(
                      _isAdmin ? "GESTIÓN DE ESTADO (ADMIN)" : "GESTIÓN DE ESTADO (TÉCNICO)", 
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)
                    ),
                    DropdownButton<String>(
                      value: _currentStatus,
                      isExpanded: true,
                      items: ['Pendiente', 'En proceso', 'Resuelta'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                      onChanged: _updateStatus,
                    ),
                  ] else ...[
                    Text("ESTADO: $_currentStatus", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                  const Divider(height: 30),
                  Text("Categoría: ${widget.data['categoria']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("Fecha: $fechaStr", style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  const Text("Descripción:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(widget.data['descripcion'] ?? ""),
                  const SizedBox(height: 30),
                  if (widget.data['latitud'] != null)
                    ElevatedButton.icon(onPressed: _openMap, icon: const Icon(Icons.map), label: const Text("Ver en Mapa")),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
