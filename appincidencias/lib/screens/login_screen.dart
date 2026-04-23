import 'package:appincidencias/screens/register_screen.dart';
import 'package:appincidencias/screens/report_screen.dart';
import 'package:appincidencias/utils/google_sign_in_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Añadido
import 'package:firebase_core/firebase_core.dart'; // Añadido
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isWebInitialized = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile', 'openid'],
  );

  @override
  void initState() {
    super.initState();
    _initWeb();
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      _handleGoogleSignInResult(account);
    });
    _googleSignIn.signInSilently();
  }

  Future<void> _initWeb() async {
    if (kIsWeb) {
      await initWebGoogleSignIn((initialized) {
        if (mounted) {
          setState(() {
            _isWebInitialized = initialized;
          });
        }
      });
    }
  }

  Future<void> _handleGoogleSignInResult(GoogleSignInAccount? googleUser) async {
    if (googleUser == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      if (mounted) setState(() => _isLoading = true);

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? accessToken = googleAuth.accessToken;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      // Guardar/Actualizar datos del usuario en la colección 'usuarios'
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        debugPrint("--- REGISTRANDO USUARIO GOOGLE EN DB: cantillana-native ---");
        try {
          await FirebaseFirestore.instanceFor(
            app: Firebase.app(),
            databaseId: 'cantillana-native',
          ).collection('usuarios').doc(user.uid).set({
            'email': user.email,
            'uid': user.uid,
          }, SetOptions(merge: true));
          debugPrint("--- REGISTRO GOOGLE EXITOSO ---");
        } catch (e) {
          debugPrint("--- ERROR AL REGISTRAR USUARIO GOOGLE: $e ---");
        }
      }

      if (mounted) {
        debugPrint("Logueado con éxito en Firebase");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ReportScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        debugPrint("ERROR DETECTADO: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error en el login: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor, introduce email y contraseña"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Guardar/Actualizar datos del usuario en la colección 'usuarios'
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        debugPrint("--- REGISTRANDO USUARIO EN DB: cantillana-native ---");
        try {
          await FirebaseFirestore.instanceFor(
            app: Firebase.app(),
            databaseId: 'cantillana-native',
          ).collection('usuarios').doc(user.uid).set({
            'email': user.email,
            'uid': user.uid,
          }, SetOptions(merge: true));
          debugPrint("--- REGISTRO EXITOSO ---");
        } catch (e) {
          debugPrint("--- ERROR AL REGISTRAR USUARIO: $e ---");
        }
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ReportScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = "Error en el login";
      if (e.code == 'user-not-found') {
        message = "Usuario no encontrado";
      } else if (e.code == 'wrong-password') {
        message = "Contraseña incorrecta";
      } else if (e.code == 'invalid-email') {
        message = "Email no válido";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    if (kIsWeb) return;

    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      await _handleGoogleSignInResult(googleUser);
    } catch (e) {
      if (mounted) {
        debugPrint("ERROR DETECTADO: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error en el login: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            children: [
              const SizedBox(height: 80),
              const Icon(Icons.report_problem_rounded, size: 80, color: Colors.orange),
              const Text("Cantillana Report", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(hintText: "Email", prefixIcon: const Icon(Icons.email_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(hintText: "Contraseña", prefixIcon: const Icon(Icons.lock_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Entrar", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
              const Text("O inicia sesión con"),
              const SizedBox(height: 20),
              buildGoogleSignInButton(
                isLoading: _isLoading,
                onPressed: _signInWithGoogle,
                isWebInitialized: _isWebInitialized,
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                child: const Text("¿No tienes cuenta? Regístrate aquí"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}