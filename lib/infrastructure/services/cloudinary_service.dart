import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

enum CloudinaryResourceType { video, image }

class CloudinaryService {
  static const String _cloudName = 'bxkie2tw';
  static const String _uploadPreset = 'toktik_files';

  static String _uploadUrl(CloudinaryResourceType type) {
    final resource = type == CloudinaryResourceType.video ? 'video' : 'image';
    return 'https://api.cloudinary.com/v1_1/$_cloudName/$resource/upload';
  }

  /// Sube un archivo a Cloudinary.
  /// [type] determina si se sube como video o imagen.
  /// Devuelve la URL pública segura (https).
  Future<String> uploadFile(
    File file, {
    CloudinaryResourceType type = CloudinaryResourceType.video,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl(type)));

    request.fields['upload_preset'] = _uploadPreset;
    request.fields['resource_type'] =
        type == CloudinaryResourceType.video ? 'video' : 'image';

    request.files.add(
      await http.MultipartFile.fromPath('file', file.path),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['secure_url'] as String;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
        'Error al subir archivo a Cloudinary: ${error['error']['message']}',
      );
    }
  }
}
