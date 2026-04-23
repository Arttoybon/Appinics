import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Añadido para el portapapeles
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
  bool _isTechnician = false;
  bool _isSuperAdmin = false;
  String? _currentStatus;
  String? _assignedTo;
  String? _techSpecialty;
  List<Map<String, dynamic>> _availableTechnicians = [];

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.data['estado'] ?? 'Pendiente';
    _assignedTo = widget.data['asignado_a_uid'];
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
          final data = doc.data();
          String? rol = data?['rol']?.toString().trim().toLowerCase();
          
          if (mounted) {
            setState(() {
              if (rol == 'admin' || _isSuperAdmin) {
                _isAdmin = true;
                _fetchTechnicians(); 
              } else if (rol == 'tecnico') {
                _isTechnician = true;
                _techSpecialty = data?['especialidad']?.toString().trim().toLowerCase();
              }
            });
          }
        } else if (_isSuperAdmin) {
          if (mounted) setState(() => _isAdmin = true);
        }
      } catch (e) {
        debugPrint("Error privileges: $e");
      }
    }
  }

  Future<void> _fetchTechnicians() async {
    final String categoriaIncidencia = (widget.data['categoria'] ?? "").toString().trim().toLowerCase();
    try {
      final query = await FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'cantillana-native')
          .collection('usuarios').get();

      final List<Map<String, dynamic>> techList = [];
      for (var doc in query.docs) {
        final data = doc.data();
        if (data['rol'] == 'tecnico' && data['especialidad']?.toString().trim().toLowerCase() == categoriaIncidencia) {
          techList.add({'uid': doc.id, 'email': data['email'] ?? "Sin email"});
        }
      }
      if (mounted) setState(() => _availableTechnicians = techList);
    } catch (e) {
      debugPrint("Error fetching technicians: $e");
    }
  }

  Future<void> _selfAssign() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'cantillana-native')
          .collection('incidencias').doc(widget.docId).update({
            'asignado_a_uid': user.uid,
            'tecnico_email': user.email,
          });
      
      setState(() => _assignedTo = user.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Te has asignado esta incidencia"), backgroundColor: Colors.blue)
        );
      }
    } catch (e) {
      debugPrint("Error in self-assignment: $e");
    }
  }

  Future<void> _assignTechnician(String? techUid) async {
    if (techUid == null) return;
    try {
      final tech = _availableTechnicians.firstWhere((t) => t['uid'] == techUid);
      await FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'cantillana-native')
          .collection('incidencias').doc(widget.docId).update({
            'asignado_a_uid': techUid,
            'tecnico_email': tech['email'],
          });
      
      setState(() => _assignedTo = techUid);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Técnico asignado"), backgroundColor: Colors.blue));
    } catch (e) {
      debugPrint("Error assigning: $e");
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
        if (mounted) Navigator.pop(context);
      } catch (e) {
        debugPrint("Error deleting: $e");
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

  // Función para copiar el ID al portapapeles
  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.docId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("ID copiado al portapapeles"),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.blueGrey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    DateTime? fecha = (widget.data['fecha'] != null) ? (widget.data['fecha'] as Timestamp).toDate() : null;
    String fechaStr = fecha != null ? DateFormat('dd/MM/yyyy HH:mm').format(fecha) : "S/F";
    bool canChangeStatus = _isAdmin || _isTechnician;
    
    bool canSelfAssign = _isTechnician && 
                         _assignedTo == null && 
                         _techSpecialty == (widget.data['categoria'] ?? "").toString().trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalles"), backgroundColor: Colors.orange, iconTheme: const IconThemeData(color: Colors.white),
        actions: [if (_isSuperAdmin) IconButton(icon: const Icon(Icons.delete_forever), onPressed: _deleteIncident)],
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
                  if (canSelfAssign) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.touch_app, color: Colors.white),
                        label: const Text("ASIGNÁRMELA A MÍ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.all(15)),
                        onPressed: _selfAssign,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (_isAdmin) ...[
                    const Text("ASIGNAR A TÉCNICO", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    DropdownButton<String>(
                      hint: Text(_availableTechnicians.isEmpty ? "No hay técnicos compatibles" : "Elegir Técnico"),
                      value: _assignedTo, isExpanded: true,
                      items: _availableTechnicians.map((t) => DropdownMenuItem<String>(
                        value: t['uid'].toString(), 
                        child: Text(t['email'].toString())
                      )).toList(),
                      onChanged: _availableTechnicians.isEmpty ? null : _assignTechnician,
                    ),
                    const Divider(height: 30),
                  ] else if (widget.data['tecnico_email'] != null) ...[
                    Text("ASIGNADO A: ${widget.data['tecnico_email']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    const Divider(height: 30),
                  ],

                  if (canChangeStatus) ...[
                    const Text("GESTIÓN DE ESTADO", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    DropdownButton<String>(
                      value: _currentStatus, isExpanded: true,
                      items: ['Pendiente', 'En proceso', 'Resuelta'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                      onChanged: _updateStatus,
                    ),
                  ] else ...[
                    Text("ESTADO: $_currentStatus", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                  
                  const Divider(height: 30),
                  
                  // ID de la incidencia con botón de copiar
                  InkWell(
                    onTap: _copyToClipboard,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "ID de Reporte: #${widget.docId}", 
                              style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'monospace'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.copy, size: 14, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  Text("Categoría: ${widget.data['categoria']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("Fecha: $fechaStr", style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  const Text("Descripción:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(widget.data['descripcion'] ?? ""),
                  const SizedBox(height: 30),
                  if (widget.data['latitud'] != null) ElevatedButton.icon(onPressed: _openMap, icon: const Icon(Icons.map), label: const Text("Ver en Mapa")),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
