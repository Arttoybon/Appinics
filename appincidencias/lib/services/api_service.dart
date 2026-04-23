import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  // Apuntamos a la nueva base de datos MODO NATIVO
  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'cantillana-native',
  );
  
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final String _cloudinaryUrl = "https://api.cloudinary.com/v1_1/dftjjcrtv/image/upload";
  final String _uploadPreset = "incidencias_preset"; 

  Future<bool> enviarIncidenciaCompleta({
    required String categoria,
    required String descripcion,
    XFile? imagen,
    double? latitud,
    double? longitud,
  }) async {
    try {
      debugPrint("--- INICIANDO ENVÍO (NATIVE MODE: cantillana-native) ---");
      
      final user = _auth.currentUser;
      String uid = user?.uid ?? "anonimo";
      String email = user?.email ?? "anonimo@gmail.com";
      String? fotoUrl;

      if (imagen != null) {
        var request = http.MultipartRequest('POST', Uri.parse(_cloudinaryUrl));
        Uint8List bytes = await imagen.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: imagen.name));
        request.fields['upload_preset'] = _uploadPreset;

        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          var jsonResponse = jsonDecode(response.body);
          fotoUrl = jsonResponse['secure_url'];
        }
      }

      await _firestore.collection('incidencias').add({
        'uid_usuario': uid,
        'email_usuario': email, // Guardamos el email del reportero
        'categoria': categoria,
        'descripcion': descripcion,
        'foto_url': fotoUrl,
        'latitud': latitud,
        'longitud': longitud,
        'fecha': FieldValue.serverTimestamp(),
        'estado': 'Pendiente',
      });

      debugPrint("--- GUARDADO EXITOSO ---");
      return true;
    } catch (e) {
      debugPrint("--- ERROR: $e ---");
      return false;
    }
  }
}
