import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  // En v6.x usamos el constructor simple
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // 1. Inicializar
  Future<void> initAuth() async {
    // En v6.x no hay initialize()
  }

  // 2. Escuchar cambios de usuario
  Stream<GoogleSignInAccount?> get userStream => _googleSignIn.onCurrentUserChanged;

  // 3. Método para Loguearse
  Future<void> signIn() async {
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      // Manejar el error adecuadamente
    }
  }

  // 4. Método para Cerrar Sesión
  Future<void> signOut() async {
    try {
      await _googleSignIn.disconnect(); // Desconecta la cuenta y borra tokens de Google
      await _googleSignIn.signOut();
    } catch (error) {
      // Manejar el error adecuadamente
    }
  }

  // Limpieza
  void dispose() {
    // No es estrictamente necesario cerrar nada en v6 si no usamos StreamControllers
  }
}
