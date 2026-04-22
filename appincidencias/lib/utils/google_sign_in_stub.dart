import 'package:flutter/material.dart';

Widget getGoogleSignInButton({
  required bool isLoading,
  required VoidCallback onPressed,
  required bool isWebInitialized,
}) {
  throw UnsupportedError('Cannot create Google Sign In button without a platform implementation.');
}

Future<void> performWebInit(Function(bool) onInitialized) async {
  // No-op on mobile
}