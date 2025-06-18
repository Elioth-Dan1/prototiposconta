import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> downloadAndSaveImage(String imageUrl) async {
  final status = await Permission.storage.request();

  if (!status.isGranted) {
    throw Exception("Permiso de almacenamiento denegado");
  }

  final response = await http.get(Uri.parse(imageUrl));

  if (response.statusCode == 200) {
    final Uint8List bytes = response.bodyBytes;
    final Directory? directory = await getExternalStorageDirectory();
    final String path = directory!.path;
    final String filePath =
        '$path/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final File file = File(filePath);
    await file.writeAsBytes(bytes);
    print("✅ Imagen guardada en: $filePath");
  } else {
    throw Exception("❌ Error al descargar la imagen");
  }
}
