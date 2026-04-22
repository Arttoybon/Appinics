import 'package:flutter/material.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart' as web;

Widget getGoogleSignInButton({
  required bool isLoading,
  required VoidCallback onPressed,
  required bool isWebInitialized,
}) {
  return Center(
    child: Container(
      constraints: const BoxConstraints(maxWidth: 300),
      child: isWebInitialized
          ? (GoogleSignInPlatform.instance as web.GoogleSignInPlugin).renderButton(
              configuration: web.GSIButtonConfiguration(
                theme: web.GSIButtonTheme.outline,
                size: web.GSIButtonSize.large,
                shape: web.GSIButtonShape.pill,
              ),
            )
          : const CircularProgressIndicator(),
    ),
  );
}

bool _webInitStarted = false;

Future<void> performWebInit(Function(bool) onInitialized) async {
  if (_webInitStarted) return;
  _webInitStarted = true;

  try {
    await Future.delayed(const Duration(milliseconds: 500));
    final plugin = GoogleSignInPlatform.instance as web.GoogleSignInPlugin;
    await plugin.init();
    onInitialized(true);
  } catch (e) {
    debugPrint("Error inicializando GoogleSignIn en Web: $e");
    onInitialized(true);
  }
}