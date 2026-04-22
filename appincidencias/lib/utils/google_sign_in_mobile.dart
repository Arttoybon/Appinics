import 'package:flutter/material.dart';

Widget getGoogleSignInButton({
  required bool isLoading,
  required VoidCallback onPressed,
  required bool isWebInitialized,
}) {
  return SizedBox(
    width: double.infinity,
    height: 55,
    child: OutlinedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: Image.network(
          'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
          height: 24),
      label: const Text("Continuar con Google",
          style: TextStyle(color: Colors.black87, fontSize: 16)),
      style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.grey),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
    ),
  );
}

Future<void> performWebInit(Function(bool) onInitialized) async {
  // No-op on mobile
}