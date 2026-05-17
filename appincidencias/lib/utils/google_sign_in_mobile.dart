import 'package:flutter/material.dart';

Widget getGoogleSignInButton({
  required bool isLoading,
  required VoidCallback onPressed,
  required bool isWebInitialized,
}) {
  return SizedBox(
    width: double.infinity,
    height: 55,
    child: OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.grey),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Usamos una imagen de red mas fiable (icono oficial de Google)
          // Si este falla, el Row no explotara porque esta dentro de un Row con mainAxisAlignment center
          Image.network(
            'https://auth.services.adobe.com/img/google_logo.svg',
            height: 24,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.login, color: Colors.blue),
          ),
          const SizedBox(width: 10),
          const Text("Continuar con Google",
              style: TextStyle(color: Colors.black87, fontSize: 16)),
        ],
      ),
    ),
  );
}

Future<void> performWebInit(Function(bool) onInitialized) async {
  // No-op on mobile
}