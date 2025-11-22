// Stub for non-web platforms
class WebExport {
  static Future<void> downloadFile(String filename, String content) async {
    throw UnimplementedError('WebExport is only available on web platform');
  }
}
