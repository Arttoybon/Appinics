import 'package:appincidencias/utils/validation_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dniController = TextEditingController();
  bool _isLoading = false;

  Future<void> _registrarse() async {
    final String dni = _dniController.text.trim().toUpperCase();

    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        dni.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, rellena todos los campos"), backgroundColor: Colors.orange)
      );
      return;
    }

    // VALIDACION MATEMATICA DEL DNI
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
      debugPrint("INICIANDO REGISTRO...");
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = credential.user;
      debugPrint("USUARIO CREADO: ${user?.uid}");

      if (user != null) {
        debugPrint("GUARDANDO EN FIRESTORE ANTES QUE NADA...");
        // Primero guardamos los datos para evitar que el AuthWrapper falle por falta de DNI
        await FirebaseFirestore.instanceFor(
          app: Firebase.app(),
          databaseId: 'cantillana-native',
        ).collection('usuarios').doc(user.uid).set({
          'email': user.email,
          'uid': user.uid,
          'dni': _dniController.text.trim().toUpperCase(),
          'rol': 'user',
          'fecha_registro': FieldValue.serverTimestamp(),
        });
        debugPrint("FIRESTORE ACTUALIZADO");

        // ENVIAR CORREO DE VERIFICACION
        try {
          debugPrint("ENVIANDO EMAIL DE VERIFICACIÓN...");
          await user.sendEmailVerification();
          debugPrint("EMAIL ENVIADO CON ÉXITO");
        } catch (e) {
          debugPrint("ERROR AL ENVIAR EMAIL: $e");
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint("MOSTRANDO DIÁLOGO DE ÉXITO");

        // Usamos Future.delayed para asegurar que el teclado se cierre y el contexto este listo
        Future.delayed(Duration.zero, () {
          if (!mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text("📧 Verifica tu correo"),
              content: Text("Te hemos enviado un enlace de confirmación a ${_emailController.text.trim()}. Por favor, revisa tu bandeja de entrada."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Cierra dialogo
                    Navigator.of(context).pop(); // Vuelve al login
                  },
                  child: const Text("CERRAR Y VOLVER AL LOGIN"),
                ),
              ],
            ),
          );
        });
      }
    } on FirebaseAuthException catch (e) {
      debugPrint("FIREBASE AUTH ERROR: ${e.code} - ${e.message}");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? "Error al registrarse"), backgroundColor: Colors.redAccent));
      }
    } catch (e) {
      debugPrint("ERROR DESCONOCIDO: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error inesperado: $e"), backgroundColor: Colors.redAccent));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Crear Cuenta", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          children: [
            const Icon(Icons.person_add_rounded, size: 80, color: Colors.orange),
            const SizedBox(height: 30),
            TextField(
              controller: _dniController,
              decoration: InputDecoration(
                hintText: "DNI / NIE",
                prefixIcon: const Icon(Icons.badge_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: "Email",
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: "Contraseña",
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _registrarse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Registrarme", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
