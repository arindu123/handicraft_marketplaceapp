import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class CloudinaryUpload {
  CloudinaryUpload({this.client});
  final http.Client? client;
  Future<String> upload(Uint8List bytes) async {
    if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
      throw const FormatException('Invalid image size');
    }
    final transport = client ?? http.Client();
    try {
      final request =
          http.MultipartRequest(
              'POST',
              Uri.parse(
                'https://api.cloudinary.com/v1_1/yrpisypt/image/upload',
              ),
            )
            ..fields['upload_preset'] = 'craftisan_products'
            ..files.add(
              http.MultipartFile.fromBytes(
                'file',
                bytes,
                filename: 'product.jpg',
              ),
            );
      final response = await (() async {
        return http.Response.fromStream(await transport.send(request));
      })().timeout(const Duration(seconds: 60));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const FormatException('Upload rejected');
      }
      final data = jsonDecode(response.body);
      final value = data is Map ? data['secure_url'] : null;
      final uri = value is String ? Uri.tryParse(value) : null;
      if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
        throw const FormatException('Missing secure image URL');
      }
      return value as String;
    } finally {
      if (client == null) transport.close();
    }
  }
}
