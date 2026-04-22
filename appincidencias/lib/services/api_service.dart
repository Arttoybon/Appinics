import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  // Asegúrate de que la URL es correcta y accesible
  static const String url = "https://alumno24.fpcantillana.org/save_incidencia.php";

  Future<bool> enviarIncidenciaCompleta(String categoria, String descripcion, XFile? imagen) async {
    try {
      debugPrint("--- INICIANDO ENVÍO DE INCIDENCIA ---");
      debugPrint("URL: $url");
      
      var request = http.MultipartRequest('POST', Uri.parse(url));
      
      // Datos de texto
      String uid = FirebaseAuth.instance.currentUser?.uid ?? "anonimo";
      request.fields['uid_usuario'] = uid;
      request.fields['categoria'] = categoria;
      request.fields['descripcion'] = descripcion;

      debugPrint("Campos: uid=$uid, cat=$categoria, desc=$descripcion");

      // Adjuntar la foto si existe
      if (imagen != null) {
        debugPrint("Adjuntando imagen: ${imagen.name}");
        Uint8List bytes = await imagen.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'foto',
          bytes,
          filename: imagen.name,
        ));
      } else {
        debugPrint("No hay imagen para adjuntar");
      }

      debugPrint("Enviando petición...");
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      debugPrint("Respuesta recibida. Código: ${response.statusCode}");
      debugPrint("Cuerpo de la respuesta: ${response.body}");

      if (response.statusCode == 200) {
        debugPrint("--- ENVÍO EXITOSO ---");
        return true;
      } else {
        debugPrint("--- ERROR EN EL SERVIDOR: ${response.statusCode} ---");
        return false;
      }
    } catch (e) {
      debugPrint("--- ERROR CRÍTICO EN ApiService: $e ---");
      return false;
    }
  }
}