import 'package:appincidencias/utils/validation_utils.dart'; // Añadido
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:appincidencias/utils/web_reload/web_reload.dart';

class DniRequiredScreen extends StatefulWidget {
  const DniRequiredScreen({super.key});

  @override
  State<DniRequiredScreen> createState() => _DniRequiredScreenState();
}

class _DniRequiredScreenState extends State<DniRequiredScreen> {
  final TextEditingController _dniController = TextEditingController();
  bool _isLoading = false;

  Future<void> _saveDni() async {
    final String dni = _dniController.text.trim().toUpperCase();
    if (dni.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, introduce tu DNI"), backgroundColor: Colors.orange)
      );
      return;
    }

    // VALIDACIÓN MATEMÁTICA DEL DNI
    if (!ValidationUtils.validarDNI(dni)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ El DNI o NIE introducido no es válido o la letra es incorrecta"),
          backgroundColor: Colors.redAccent
        )
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instanceFor(
          app: Firebase.app(),
          databaseId: 'cantillana-native',
        ).collection('usuarios').doc(user.uid).set({
          'dni': dni,
          'uid': user.uid,
          'email': user.email,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al guardar DNI: $e"), backgroundColor: Colors.redAccent)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.badge_rounded, size: 100, color: themeColor),
              const SizedBox(height: 30),
              const Text(
                "¡Casi listo!",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Para usar Cantillana Report necesitamos que registres tu DNI / NIE.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _dniController,
                decoration: InputDecoration(
                  hintText: "Escribe tu DNI / NIE aquí",
                  prefixIcon: Icon(Icons.edit_document, color: themeColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveDni,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Confirmar y Empezar", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () async {
                  try {
                    final googleSignIn = GoogleSignIn();
                    if (await googleSignIn.isSignedIn()) {
                      await googleSignIn.disconnect();
                      await googleSignIn.signOut();
                    }
                    await FirebaseAuth.instance.signOut();
                    if (kIsWeb) {
                      reloadApp();
                    }
                  } catch (e) {
                    debugPrint("Error al cerrar sesión: $e");
                  }
                },
                child: const Text("Cerrar Sesión", style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
