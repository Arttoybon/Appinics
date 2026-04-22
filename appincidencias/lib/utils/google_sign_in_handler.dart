import 'package:flutter/material.dart';
import 'google_sign_in_stub.dart'
    if (dart.library.js_interop) 'google_sign_in_web.dart'
    if (dart.library.io) 'google_sign_in_mobile.dart';

Widget buildGoogleSignInButton({
  required bool isLoading,
  required VoidCallback onPressed,
  required bool isWebInitialized,
}) {
  return getGoogleSignInButton(
    isLoading: isLoading,
    onPressed: onPressed,
    isWebInitialized: isWebInitialized,
  );
}

Future<void> initWebGoogleSignIn(Function(bool) onInitialized) async {
  await performWebInit(onInitialized);
}