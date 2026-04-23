import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:appincidencias/firebase_options.dart';
import 'package:appincidencias/screens/login_screen.dart';
import 'package:appincidencias/screens/report_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // CONFIGURACIÓN PARA LA NUEVA BASE DE DATOS EN MODO NATIVO
  FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'cantillana-native',
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const ReportScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
