import 'package:appincidencias/screens/incident_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Inicia sesión para ver notificaciones")));

    final query = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'cantillana-native')
        .collection('notificaciones')
        .where('uid_usuario', isEqualTo: user.uid)
        .orderBy('fecha', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notificaciones", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        backgroundColor: themeColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: "Marcar todas como leídas",
            onPressed: () => _markAllAsRead(user.uid),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 80, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("No tienes notificaciones", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              bool leida = data['leida'] ?? false;
              DateTime fecha = (data['fecha'] as Timestamp).toDate();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                color: leida ? Colors.white : Colors.orange[50],
                color: leida ? Colors.white : themeColor.withOpacity(0.05),
                elevation: leida ? 1 : 3,
                child: ListTile(
                  leading: Icon(
                    data['tipo'] == 'estado'
                        ? Icons.info_outline
                        : data['tipo'] == 'comentario'
                            ? Icons.comment_outlined
                            : Icons.assignment_ind_outlined,
                    color: Colors.orange,
                    color: themeColor,
                  ),
                  title: Text(
                    data['titulo'] ?? "Notificación",
                    style: TextStyle(fontWeight: leida ? FontWeight.normal : FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['mensaje'] ?? ""),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(fecha),
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                  onTap: () => _handleTap(context, doc.id, data['incidencia_id']),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => doc.reference.delete(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleTap(BuildContext context, String notifId, String? incidentId) async {
    // Marcar como leída
    await FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'cantillana-native')
        .collection('notificaciones').doc(notifId).update({'leida': true});

    if (incidentId != null && context.mounted) {
      // Ir a la incidencia
      try {
        final doc = await FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'cantillana-native')
            .collection('incidencias').doc(incidentId).get();

        if (doc.exists && context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IncidentDetailsScreen(data: doc.data()!, docId: doc.id),
            ),
          );
        }
      } catch (e) {
        debugPrint("Error navegando a incidencia: $e");
      }
    }
  }

  Future<void> _markAllAsRead(String uid) async {
    final query = await FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'cantillana-native')
        .collection('notificaciones')
        .where('uid_usuario', isEqualTo: uid)
        .where('leida', isEqualTo: false)
        .get();

    for (var doc in query.docs) {
      doc.reference.update({'leida': true});
    }
  }
}
