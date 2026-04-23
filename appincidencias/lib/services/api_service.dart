import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  // Usamos instanceFor para apuntar a tu nueva base de datos específica
  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'cantillana0ayunt',
  );
  
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Configuración de Cloudinary PERSONAL
  final String _cloudinaryUrl = "https://api.cloudinary.com/v1_1/dftjjcrtv/image/upload";
  final String _uploadPreset = "incidencias_preset"; 

  Future<bool> enviarIncidenciaCompleta(String categoria, String descripcion, XFile? imagen) async {
    try {
      debugPrint("--- INICIANDO ENVÍO (FIREBASE: cantillana0ayunt) ---");
      
      String uid = _auth.currentUser?.uid ?? "anonimo";
      String? fotoUrl;

      // 1. Subir a Cloudinary si hay imagen
      if (imagen != null) {
        debugPrint("Subiendo imagen a Cloudinary: ${imagen.name}...");
        var request = http.MultipartRequest('POST', Uri.parse(_cloudinaryUrl));
        
        Uint8List bytes = await imagen.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'file', 
          bytes, 
          filename: imagen.name
        ));
        
        request.fields['upload_preset'] = _uploadPreset;

        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);
        
        // ESTO NOS DIRÁ EL ERROR EXACTO EN TU TERMINAL
        debugPrint("RESPUESTA CLOUDINARY: ${response.body}");

        if (response.statusCode == 200 || response.statusCode == 201) {
          var jsonResponse = jsonDecode(response.body);
          fotoUrl = jsonResponse['secure_url'];
          debugPrint("URL GENERADA: $fotoUrl");
        } else {
          debugPrint("FALLO EN CLOUDINARY. Código: ${response.statusCode}");
        }
      }

      // 2. Guardar en Firestore
      debugPrint("Guardando en Firestore...");
      await _firestore.collection('incidencias').add({
        'uid_usuario': uid,
        'categoria': categoria,
        'descripcion': descripcion,
        'foto_url': fotoUrl,
        'fecha': FieldValue.serverTimestamp(),
        'estado': 'Pendiente',
      });

      debugPrint("--- PROCESO FINALIZADO ---");
      return true;
    } catch (e) {
      debugPrint("--- ERROR CRÍTICO: $e ---");
      return false;
    }
  }
}
