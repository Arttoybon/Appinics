import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  static const String url = "https://alumno24.fpcantillana.org/save_incidencia.php";

  Future<bool> enviarIncidenciaCompleta(String categoria, String descripcion, File? imagen) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(url));
      
      // Datos de texto
      request.fields['uid_usuario'] = FirebaseAuth.instance.currentUser?.uid ?? "anonimo";
      request.fields['categoria'] = categoria;
      request.fields['descripcion'] = descripcion;

      // Adjuntar la foto si existe
      if (imagen != null) {
        request.files.add(await http.MultipartFile.fromPath('foto', imagen.path));
      }

      var response = await request.send();

      return response.statusCode == 200;
    } catch (e) {
      print("Error enviando: $e");
      return false;
    }
  }
}