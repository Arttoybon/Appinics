import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
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
  
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.data['estado'] ?? 'Pendiente';
    _assignedTo = widget.data['asignado_a_uid'];
    _checkUserPrivileges();
  }

  String _getAvatarUrl(String email) {
    final String name = email.split('@')[0];
    return "https://ui-avatars.com/api/?name=$name&background=random&color=fff";
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

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'cantillana-native')
          .collection('incidencias').doc(widget.docId).collection('comentarios').add({
        'texto': _commentController.text.trim(),
        'autor_email': user.email,
        'autor_uid': user.uid,
        'fecha': FieldValue.serverTimestamp(),
      });
      _commentController.clear();
      if (mounted) FocusScope.of(context).unfocus();
    } catch (e) {
      debugPrint("Error adding comment: $e");
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
    } catch (e) {
      debugPrint("Error self-assigning: $e");
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
    } catch (e) {
      debugPrint("Error status: $e");
    }
  }

  Future<void> _deleteIncident() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Eliminar?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("NO")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("SÍ")),
        ],
      ),
    ) ?? false;
    if (confirm) {
      await FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'cantillana-native').collection('incidencias').doc(widget.docId).delete();
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _openMap() async {
    final double? lat = widget.data['latitud'];
    final double? lng = widget.data['longitud'];
    if (lat != null && lng != null) {
      final Uri url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.docId));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ID copiado")));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    DateTime? fecha = (widget.data['fecha'] != null) ? (widget.data['fecha'] as Timestamp).toDate() : null;
    String fechaStr = fecha != null ? DateFormat('dd/MM/yyyy HH:mm').format(fecha) : "S/F";
    
    bool canChangeStatus = _isAdmin || _isTechnician;
    bool canSelfAssign = _isTechnician && _assignedTo == null && _techSpecialty == (widget.data['categoria'] ?? "").toString().trim().toLowerCase();
    
    bool canComment = _isAdmin || (_isTechnician && _assignedTo == user?.uid);

    // Email del creador de la incidencia
    String reporterEmail = widget.data['email_usuario'] ?? "Anónimo";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalles", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), 
        backgroundColor: Colors.orange, 
        iconTheme: const IconThemeData(color: Colors.white),
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
                  // CUADRO DEL CREADOR (REPORTERO)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.orange.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(_getAvatarUrl(reporterEmail)),
                          radius: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("REPORTADO POR:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.orange)),
                              Text(reporterEmail, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (canSelfAssign) ...[
                    SizedBox(width: double.infinity, child: ElevatedButton.icon(icon: const Icon(Icons.touch_app), label: const Text("ASIGNÁRMELA"), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue), onPressed: _selfAssign)),
                    const SizedBox(height: 20),
                  ],

                  if (_isAdmin) ...[
                    const Text("ASIGNAR A TÉCNICO", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 12)),
                    DropdownButton<String>(
                      hint: Text(_availableTechnicians.isEmpty ? "Sin técnicos" : "Elegir Técnico"),
                      value: _assignedTo, isExpanded: true,
                      items: _availableTechnicians.map((t) => DropdownMenuItem<String>(
                        value: t['uid'].toString(), 
                        child: Text(t['email'].toString())
                      )).toList(),
                      onChanged: _assignTechnician,
                    ),
                    const Divider(height: 30),
                  ] else if (widget.data['tecnico_email'] != null) ...[
                    Text("ASIGNADO A: ${widget.data['tecnico_email']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    const Divider(height: 30),
                  ],

                  if (canChangeStatus) ...[
                    const Text("GESTIÓN DE ESTADO", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12)),
                    DropdownButton<String>(
                      value: _currentStatus, isExpanded: true,
                      items: ['Pendiente', 'En proceso', 'Resuelta'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                      onChanged: _updateStatus,
                    ),
                  ] else ...[
                    Text("ESTADO ACTUAL: $_currentStatus", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                  
                  const Divider(height: 30),
                  
                  // Información General
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Categoría: ${widget.data['categoria']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      InkWell(
                        onTap: _copyToClipboard,
                        child: Row(children: [Text("#${widget.docId.substring(0,6)}", style: const TextStyle(color: Colors.grey, fontSize: 12)), const SizedBox(width: 4), const Icon(Icons.copy, size: 12, color: Colors.grey)]),
                      ),
                    ],
                  ),
                  Text("Fecha: $fechaStr", style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 15),
                  const Text("Descripción:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(widget.data['descripcion'] ?? "Sin descripción"),
                  const SizedBox(height: 20),
                  if (widget.data['latitud'] != null) ElevatedButton.icon(onPressed: _openMap, icon: const Icon(Icons.map, color: Colors.white), label: const Text("VER UBICACIÓN", style: TextStyle(color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange)),
                  
                  const Divider(height: 40),
                  const Text("COMENTARIOS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey)),
                  const SizedBox(height: 10),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'cantillana-native')
                        .collection('incidencias').doc(widget.docId).collection('comentarios')
                        .orderBy('fecha', descending: false).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      return Column(
                        children: snapshot.data!.docs.map((doc) {
                          var cData = doc.data() as Map<String, dynamic>;
                          String email = cData['autor_email'] ?? "Anónimo";
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(backgroundImage: NetworkImage(_getAvatarUrl(email)), radius: 15),
                            title: Text(email, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            subtitle: Text(cData['texto'] ?? ""),
                          );
                        }).toList(),
                      );
                    },
                  ),

                  if (canComment) 
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              decoration: InputDecoration(
                                hintText: "Añadir comentario...",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                                isDense: true,
                              ),
                            ),
                          ),
                          IconButton(icon: const Icon(Icons.send, color: Colors.orange), onPressed: _addComment),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
