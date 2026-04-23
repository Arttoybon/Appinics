import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Añadido para Settings
import 'package:appincidencias/firebase_options.dart';
// Importamos las pantallas usando la ruta del paquete (la más segura)
import 'package:appincidencias/screens/login_screen.dart';
import 'package:appincidencias/screens/report_screen.dart';

void main() async {
  // 1. Asegura que los widgets se inicialicen antes que Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Inicializa Firebase con las opciones de tu proyecto
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configurar Firestore para usar la base de datos específica 'cantillana0ayunt'
  // y forzar el host de Google para evitar errores de región
  FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'cantillana0ayunt',
  ).settings = const Settings(
    persistenceEnabled: true,
    host: 'firestore.googleapis.com',
  );
  
  runApp(const CantillanaReportApp());
}

class CantillanaReportApp extends StatelessWidget {
  const CantillanaReportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cantillana Report',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Usamos naranja como color principal según tu diseño
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      // AuthWrapper decide si mostrar Login o Formulario
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Escucha en tiempo real si el usuario está logueado o no
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Mientras Firebase responde, mostramos un círculo de carga
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        // Si snapshot tiene datos (hay un usuario), vamos al Formulario de Envío
        if (snapshot.hasData) {
          return const ReportScreen();
        }
        
        // Si no hay datos (no hay sesión), vamos al Login
        return const LoginScreen();
      },
    );
  }
}