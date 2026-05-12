import 'package:appincidencias/screens/incident_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String userEmail;

  const UserProfileScreen({super.key, required this.userId, required this.userEmail});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isEditing = false;
  bool _isLoading = true;
  bool _isSaving = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? _currentRole;
  String? _currentSpecialty;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final doc = await FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'cantillana-native',
      ).collection('usuarios').doc(widget.userId).get();

      if (doc.exists) {
        final data = doc.data();
        setState(() {
          _nameController.text = data?['nombre'] ?? "";
          _dniController.text = data?['dni'] ?? "";
          _phoneController.text = data?['telefono'] ?? "";
          _currentRole = data?['rol'];
          _currentSpecialty = data?['especialidad'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    // VALIDACIÓN: No permitir campos vacíos y validar teléfono numérico
    final String phone = _phoneController.text.trim();
    if (_nameController.text.trim().isEmpty ||
        _dniController.text.trim().isEmpty ||
        phone.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Por favor, rellena todos los campos (Nombre, DNI y Teléfono)"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Comprobar que el teléfono sea numérico
    if (RegExp(r'^[0-9]+$').hasMatch(phone) == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ El teléfono debe contener solo números"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'cantillana-native',
      ).collection('usuarios').doc(widget.userId).set({
        'nombre': _nameController.text.trim(),
        'dni': _dniController.text.trim(),
        'telefono': _phoneController.text.trim(),
        // Mantenemos los campos sensibles si existen
        if (_currentRole != null) 'rol': _currentRole,
        if (_currentSpecialty != null) 'especialidad': _currentSpecialty,
        'email': widget.userEmail,
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Perfil actualizado"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint("Error saving profile: $e");
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al guardar: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  String _getAvatarUrl(String email) {
    final String name = email.split('@')[0];
    return "https://ui-avatars.com/api/?name=$name&background=random&color=fff&size=128";
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
    final currentUser = FirebaseAuth.instance.currentUser;
    final bool isMyProfile = currentUser?.uid == widget.userId;

    final query = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'cantillana-native',
    ).collection('incidencias')
     .where('uid_usuario', isEqualTo: widget.userId)
     .orderBy('fecha', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Perfil de Usuario", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (isMyProfile)
            _isSaving
              ? const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
              : IconButton(
                  icon: Icon(_isEditing ? Icons.save : Icons.edit),
                  onPressed: () {
                    if (_isEditing) {
                      _saveProfile();
                    } else {
                      setState(() => _isEditing = true);
                    }
                  },
                )
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator(color: Colors.orange))
        : Column(
            children: [
              Container(
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
                      backgroundImage: NetworkImage(_getAvatarUrl(widget.userEmail)),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      widget.userEmail,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    Text(
                      _formatRole(_currentRole, _currentSpecialty),
                      style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),

                    // CAMPOS EDITABLES
                    _buildEditableField("Nombre Completo", _nameController, Icons.person, _isEditing),
                    const SizedBox(height: 10),
                    _buildEditableField("DNI", _dniController, Icons.badge, _isEditing),
                    const SizedBox(height: 10),
                    _buildEditableField("Teléfono", _phoneController, Icons.phone, _isEditing),
                  ],
                ),
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

  Widget _buildEditableField(String label, TextEditingController controller, IconData icon, bool enabled) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: label == "Teléfono" ? TextInputType.phone : TextInputType.text,
      style: const TextStyle(fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.orange),
        border: enabled ? const OutlineInputBorder() : InputBorder.none,
        filled: enabled,
        fillColor: Colors.white,
        isDense: true,
      ),
    );
  }
}
