import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  // Usamos .instance como en tu ejemplo
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // En v7+, debemos trackear el usuario nosotros mismos si queremos un stream simple de GoogleSignInAccount.
  // Usamos un StreamController para mantener la compatibilidad con el resto de la app.
  final StreamController<GoogleSignInAccount?> _userController = StreamController<GoogleSignInAccount?>.broadcast();

  // 1. Inicializar (Llamar en el initState de tu pantalla principal)
  Future<void> initAuth() async {
    await _googleSignIn.initialize(
      clientId: 'TU_CLIENT_ID.apps.googleusercontent.com', // Opcional en Android
    );

    // Escuchar eventos para actualizar nuestro controlador manual
    _googleSignIn.authenticationEvents.listen((event) {
      if (event is GoogleSignInAuthenticationEventSignIn) {
        _userController.add(event.user);
      } else if (event is GoogleSignInAuthenticationEventSignOut) {
        _userController.add(null);
      }
    });

    // Opcional: Intentar re-autenticar silenciosamente
    try {
      final user = await _googleSignIn.attemptLightweightAuthentication();
      if (user != null) {
        _userController.add(user);
      }
    } catch (e) {
      // Ignoramos errores de auth silenciosa
    }
  }

  // 2. Escuchar cambios de usuario (Ahora usando nuestro controlador manual)
  Stream<GoogleSignInAccount?> get userStream => _userController.stream;

  // 3. Método para Loguearse
  Future<void> signIn() async {
    try {
      // En la nueva versión se prefiere .authenticate()
      await _googleSignIn.authenticate();
    } catch (error) {
      // Manejar el error adecuadamente
    }
  }

  // 4. Método para Cerrar Sesión
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (error) {
      // Manejar el error adecuadamente
    }
  }

  // Limpieza del controlador
  void dispose() {
    _userController.close();
  }
}