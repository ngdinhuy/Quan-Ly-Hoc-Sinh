import 'dart:convert';
import 'dart:developer';
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

  /// Alternative method using JSON/base64 approach
  static Future<Map<String, dynamic>> uploadFaceImageBase64({
    required Uint8List imageBytes,
    required String studentId,
    bool isUpload = true,
  }) async {
    try {
      // Endpoint for face registration
      final endpoint = isUpload ? '/embed_face' : '/recognize_face';
      final uri = Uri.parse('$BASE_URL$endpoint');

      // Convert image to base64
      final base64Image = base64Encode(imageBytes);

      // Create request body
      final body = {
        'image_base64': base64Image,
        'student_id': studentId,
      };

      // Log request details (without showing the entire base64 image)
      debugPrint('FACE REQUEST PARAMS: $body', wrapWidth: 1024);

      // Send request
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final responseData = jsonDecode(response.body);
      debugPrint('Face upload response: $responseData');

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception('Failed to upload face image: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      debugPrint('Error uploading face image: $e');
      throw Exception('Failed to upload face image: $e');
    }
  }


  static Future<Map<String, dynamic>> uploadFaceImage({
    required dynamic imageData,
    required String studentId,
    bool isUpload = true,
  }) async {
    try {
      // Endpoint for face registration
      final endpoint = isUpload ? '/embed_face' : '/recognize_face';
      final uri = Uri.parse('$BASE_URL$endpoint');

      // Create multipart request
      var request = http.MultipartRequest('POST', uri);

      // Add student info fields
      request.fields['student_id'] = studentId;

      // Add the image file based on its type
      if (imageData is File) {
        // File from device
        final fileName = path.basename(imageData.path);
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          imageData.path,
          filename: fileName,
        ));

        debugPrint('=== FACE API REQUEST (MULTIPART) ===');
        debugPrint('URL: $uri');
        debugPrint('FILE: ${imageData.path}, size: ${await imageData.length()} bytes');
      } else if (imageData is Uint8List) {
        // Bytes (from camera, etc.)
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          imageData,
          filename: 'face.jpg',
        ));

        debugPrint('=== FACE API REQUEST (MULTIPART) ===');
        debugPrint('URL: $uri');
        debugPrint('BYTES: ${imageData.length} bytes');
      } else {
        throw Exception('Unsupported image data type');
      }

      final startTime = DateTime.now();

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final duration = DateTime.now().difference(startTime);

      // Log response
      debugPrint('=== FACE API RESPONSE ===');
      debugPrint('STATUS: ${response.statusCode}');
      debugPrint('DURATION: ${duration.inMilliseconds}ms');
      debugPrint('BODY: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData;
      } else {
        throw Exception('Failed to upload face image: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      debugPrint('=== FACE API ERROR ===');
      debugPrint('$e');
      throw Exception('Failed to upload face image: $e');
    }
  }
}