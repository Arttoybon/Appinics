import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'cantillana0ayunt',
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
      debugPrint("--- INICIANDO ENVÍO CON UBICACIÓN ---");
      
      String uid = _auth.currentUser?.uid ?? "anonimo";
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
        'categoria': categoria,
        'descripcion': descripcion,
        'foto_url': fotoUrl,
        'latitud': latitud,
        'longitud': longitud,
        'fecha': FieldValue.serverTimestamp(),
        'estado': 'Pendiente',
      });

      debugPrint("--- GUARDADO CON ÉXITO ---");
      return true;
    } catch (e) {
      debugPrint("--- ERROR CRÍTICO: $e ---");
      return false;
    }
  }
}
