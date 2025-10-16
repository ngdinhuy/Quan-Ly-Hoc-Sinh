import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

class ImageService {

  static String BASE_URL = "http://103.112.211.148:5001";

  String uint8ListToBase64(Uint8List? bytes) {
    if (bytes == null) {
      return '';
    }
    return base64Encode(bytes);
  }

  static Future<Map<String, dynamic>> sendImageForOCR({
    required dynamic imageSource,
    String endpoint = '/ocr_student_card',
  }) async {
    try {
      final uri = Uri.parse('$BASE_URL$endpoint');

      var request = http.MultipartRequest('POST', uri);

      if (imageSource is File) {
        // File from device
        final fileName = path.basename(imageSource.path);
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          imageSource.path,
          filename: fileName,
        ));
      } else if (imageSource is Uint8List) {
        // Bytes (from camera, etc.)
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          imageSource,
          filename: 'image.jpg',
        ));
      } else {
        throw Exception('Unsupported image source type');
      }

      // Send request
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      debugPrint('OCR Response: $responseData');
      // Parse response
      if (response.statusCode == 200) {
        return jsonDecode(responseData);
      } else {
        throw Exception('Failed to process image: ${response.statusCode}, $responseData');
      }
    } catch (e) {
      debugPrint('Error sending image for OCR: $e');
      throw Exception('Failed to process image: $e');
    }
  }
}