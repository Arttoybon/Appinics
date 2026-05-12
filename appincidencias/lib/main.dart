import 'package:appincidencias/screens/dni_required_screen.dart';
import 'package:appincidencias/screens/login_screen.dart';
import 'package:appincidencias/screens/report_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:google_sign_in/google_sign_in.dart'; // Añadido
import 'package:appincidencias/firebase_options.dart';

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

        final user = snapshot.data;
        if (user != null) {
          // COMPROBAR VERIFICACIÓN DE EMAIL (Excepto cuentas de prueba)
          final List<String> bypassEmails = [
            'ciudadano1@gmail.com',
            'tecnico@gmail.com',
            'admin@gmail.com'
          ];

          if (!user.emailVerified && !bypassEmails.contains(user.email)) {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.mark_email_unread_outlined, size: 80, color: Colors.orange),
                      const SizedBox(height: 20),
                      const Text(
                        "Confirma tu correo",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Hemos enviado un enlace a ${user.email}. Por favor, confírmalo para continuar.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: () async {
                          await user.reload(); // Recarga estado del usuario
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                        child: const Text("YA HE CONFIRMADO", style: TextStyle(color: Colors.white)),
                      ),
                      TextButton(
                        onPressed: () async {
                          await user.sendEmailVerification();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Correo reenviado")));
                          }
                        },
                        child: const Text("Reenviar correo de verificación"),
                      ),
                      TextButton(
                        onPressed: () async {
                          final googleSignIn = GoogleSignIn();
                          if (await googleSignIn.isSignedIn()) {
                            await googleSignIn.disconnect();
                          }
                          await googleSignIn.signOut();
                          await FirebaseAuth.instance.signOut();
                        },
                        child: const Text("Cerrar Sesión"),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // ASEGURAR QUE EL USUARIO EXISTE EN FIRESTORE (Especialmente para Google Login)
          FirebaseFirestore.instanceFor(
            app: Firebase.app(),
            databaseId: 'cantillana-native',
          ).collection('usuarios').doc(user.uid).get().then((doc) {
            if (!doc.exists) {
              FirebaseFirestore.instanceFor(
                app: Firebase.app(),
                databaseId: 'cantillana-native',
              ).collection('usuarios').doc(user.uid).set({
                'email': user.email,
                'uid': user.uid,
                'rol': 'user',
                'fecha_registro': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
            }
          });

          // Si hay usuario y está verificado, comprobamos si tiene DNI en Firestore
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instanceFor(
              app: Firebase.app(),
              databaseId: 'cantillana-native',
            ).collection('usuarios').doc(user.uid).snapshots(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                final String? dni = userData?['dni'];
                final bool isBlocked = userData?['estaBloqueado'] == true;

                if (isBlocked) {
                  return Scaffold(
                    body: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_person, size: 80, color: Colors.red),
                            const SizedBox(height: 20),
                            const Text(
                              "Acceso Restringido",
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Su usuario ha sido bloqueado por un administrador, contacte con alguno para resolver este problema",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 30),
                            ElevatedButton(
                              onPressed: () async {
                                final googleSignIn = GoogleSignIn();
                                if (await googleSignIn.isSignedIn()) {
                                  await googleSignIn.disconnect();
                                }
                                await googleSignIn.signOut();
                                await FirebaseAuth.instance.signOut();
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                              child: const Text("Volver al Login", style: TextStyle(color: Colors.white)),
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                }

                if (dni != null && dni.isNotEmpty) {
                  return const ReportScreen();
                }
              }

              // Si no existe el documento o no tiene DNI, forzamos registro de DNI
              return const DniRequiredScreen();
            },
          );
        }

        return const LoginScreen();
      },
    );
  }
}
