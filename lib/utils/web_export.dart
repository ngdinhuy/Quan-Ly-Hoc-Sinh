// Web-specific export implementation
import 'dart:html' as html;

class WebExport {
  /// Download file in web browser
  static Future<void> downloadFile(String filename, String content) async {
    // Create Blob from content
    final blob = html.Blob([content], 'text/csv');

    // Create URL for blob
    final url = html.Url.createObjectUrlFromBlob(blob);

    // Create anchor element and trigger download
    html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();

    // Clean up
    html.Url.revokeObjectUrl(url);
  }
}
